# A few points about drawables

Here are some notes about Metal / macOS [drawables](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html).

# What's a drawable?

A [drawable]([url](https://developer.apple.com/documentation/metal/mtldrawable)) is a system resource that we need to acquire before we can put rendering results on the display.
I (BSH) think of drawables as a combination of:

 - a Metal texture that can receive our rendering results
 - other, hidden config and resources that the system needs for scheduling WRT the display refresh cycle and data transfer to the display

We don't implement or manage drawables ourselves.
The system creates them and manages them in a limited pool.
We request a drawable when we're ready to render a frame and release the drawable once we're done with each frame.
Each drawable is good for one frame only, then the system needs it back for recycling before we can request it again for a future frame.
If we request too many drawables at once, our app will block, waiting for one to be released and recycled.

# Drawable timing

In Mgl Metal we're keeping track of two timestamps per frame that are related to drawables:

 - `drawableAcquired` is a CPU "get secs" timestamps that we take right after requesting and acquiring the drawable before rendering on a frame.  This can tell us if we're blocking unexpectedly, waiting for the drawable, perhaps for performance reasons like low graphics memory.
 - `drawablePresented` is a CPU timestamp [reported to us by the system]([url](https://developer.apple.com/documentation/metal/mtldrawable/2806855-presentedtime)https://developer.apple.com/documentation/metal/mtldrawable/2806855-presentedtime).  This may be our best estimate of frame timing, although we don't have access to how the system records it.

Here's a simplified sequence of events to illustrate how these timestamps line up.

| frame 0 | frame 1 | frame 1 |
| --- | --- | --- |
| begin `draw()` |  |  |
| request drawable |  |  |
| measure `drawableAcquired` |  |  |
| encode render commands for drawable |  |  |
| request drawable presentation  |  |  |
| return from `draw()`  |  |  |
| ...  |  |  |
| system presents drawable |  |  |
| system calls our `presentationHandler` |  |  |
| read `drawablePresented` |  |  |
| ...  |  |  |
|  | begin `draw()` |  |
|  | report `drawablePresented` for **frame 0** |  |
|  | request drawable |  |
|  | measure `drawableAcquired` |  |
|  | encode render commands for drawable |  |
|  | request drawable presentation  |  |
|  | return from `draw()`  |  |
|  | ... |  |
|  | system presents drawable |  |
|  | system calls our `presentationHandler` |  |
|  | read `drawablePresented` |  |
|  | ... |  |
|  |  | begin `draw()` |
|  |  | report `drawablePresented` for **frame 1** |
|  |  | request drawable |
|  |  | ... |

A lot of this happens asynchrononously, via callbacks from the system to our Mgl Metal code.  Specifically:

 - The system calls our `draw()` callback when it wants us to start working on the next frame, on a system-managed schedule ([CADisplayLink](https://developer.apple.com/documentation/quartzcore/cadisplaylink)).
 - The system calls our `presentationHandler` some time later, after a frame has been presented on the display.
 - The `draw()` and `presentationHandler` schedules both must be tied to the same display and the callbacks tend to alternate, but seem not to be explicitly synchronized.

# Triple buffering vs one-flush-at-a-time

Apple recommends "triple buffering" as a [best practice]([url](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html)https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html).
By this they mean apps should let the system manage a pool of 3 drawables, and synchronize these to a corresponding pool of data buffers that the app manipulates.
In this way custom app code running on the CPU can be working up to 2 frames ahead of the GPU, preparing data ahead of time and keeping the GPU as busy as possible.
This approach is good for maximizing throughput and for not dropping frames while waiting for irregular CPU tasks to complete.
This approach also adds some implementation complexity and lag of up to 2 frames between what the CPU might consider "now" vs what's appearing on the display.

Mgl Metal isn't doing this, currently.

Our current model for client code expects to issue drawing commands, issue a flush command, and wait up to one refresh interval for the flush command to complete.
If a flush command isn't presented, and therefore isn't complete, until 2 frames later, this would mean blocking the client for a long time and dropping the intermediate frames.
Keeping the client unblocked and sending drawing commands, while also waiting for 1-2 incomplete frames in flight, would require a different design for the client code.

Our current compromise is to send a flush, and wait up to one refresh interval for the next `draw()` callback, and then unblock the client.
As a consequence, the `drawablePresented` time we see reported on the flush for **frame 1** is really whatever timestamp we read most recently, for **frame 0**.
This allows us to make use of the system-reported `drawablePresented` timestamps, and keep existing client code as-is.
It also means we need to shift `drawablePresented` timestamps by one frame when interpreting command results.

# Double buffering

It should be possible to configure the Mgl Metal app to use 2, rather than 3 drawables ([2 and 3 are the only options](https://developer.apple.com/documentation/quartzcore/cametallayer/2938720-maximumdrawablecount)).
Currently we're using the default of 3.
For now, we are assuming that having an extra drawable sitting around in the system's pool is not harmful.
One way this might prove false is if we are somehow, accidentally, asking the system to present more than 2 drawables at once, and if these then get queued up ahead of the CPU, as in Apple's triple buffering example.

If we start seeing trouble with the current one-flush-at-a-time compromise, we could investigate whether using 2 drawables has advantages for us.

# Triple buffering in batch mode

We recently enhanced Mgl Metal to support a "batch mode" where multiple drawing and flush commands can be enqueued ahead of time, then processed by `draw()` as fast as possible.
The inspiration for this was to decouple client communication work, which is potentally slow and introduces timing jutter, from rendering work, which we want to be steady and solid.

Batch mode might have an added benefit of decoupling frame presentations from client flush calls.
We might be free to adopt the recommended triple buffering approach, and to associate system reported `drawablePresented` timestamps with the corresponding flush commands, even if these are known 2 frames after the fact.
We'd be free to do this because in batch mode the client would not be blocked waiting for a reply to the most recent flush command.

If we start seeing trouble with stimuli dropping frames, even in batch mode, then we could consider reworking the `drawablePresented` bookkeeping to allow multiple flushes in flight at once.

# When to request the drawable

Apple's drawables [best practice](https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/MTLBestPracticesGuide/Drawables.html) guidance encourages us to hold each drawable for the shortest time possible.
Currently Mgl Metal is doing pretty well at this, by distinguising between drawing vs non-drawing commands, and only requesting a drawable when it sees a drawing command.
However, we are still holding the drawable while processing potentially multiple drawing commands, until we get a flush command. 

We could potentially tighten this a notch further by rendering drawing commands to an offscreen texture, instead of directly to the onscreen drawable's texture.
We could process muliple drawing commands and render offscreen without requesting a drawable at all.
Then, when we get a flush command, we could finally request the drawable and set up a short render pass to blit the offscreen texture to the drawable's texture.
For complicated frames with many or slow drawing commands, this could reduce the time we spend holding the drawable.

If we start seeing trouble with many or slow drawing commands, we could consider reworking our rendering pipeline to work offscreen as much as possible.
One side-benefit of this approach would be to make "screen grab" as easy as reading the main offscreen texture.
