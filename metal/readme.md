# Mgl Metal App and Commands

This Readme describes the design of the Mgl Metal App, with a focus on commands.
Commands are objects that the app is able to receive, enqueue, and process / render.

To start with, here's a visual overview.

![Overview of Mgl Metal app command model](metal/command-model-etc.png)

## Components

Here are descriptions of the main components that Mgl Metal uses to process commands.

### client (Matlab)
also xcode tests

### Command Interface
[command interface](metal/mglMetal/mglCommandInterface.swift)
socket [server](metal/mglMetal/mglServer.swift)
todo queue
done queue
isBuilding batch

commandWaiting
awaitNext
done

### Renderer
[renderer](metal/mglMetal/mglRenderer2.swift)

command interface

render passes and system drawables

[depth and stencil state](metal/mglMetal/mglDepthStencilConfig.swift)
[color rendering state](metal/mglMetal/mglColorRenderingConfig.swift), including textures
deg2metal coordinate transform
gpu device

render one command or tight loop until flush command

### Command Model
[command model](metal/mglMetal/mglCommandModel.swift)
[implementations]([url](https://github.com/justingardner/mgl/tree/commandModel/metal/mglMetal/commands))
init in memory for testing
init? from commandInterface normally, able to fail

framesRemaining for draw/no draw

doNondrawingWork
writeQueryResults
draw

## Lifecycle of a Command

Here's a walkthroiugh of how a command moves through the Mgl Metal app.
Steps in order for a successful command.
Aim for similarity of non-drawing, drawing, and flush.

### bytes from client
Read a [command code](metal/mglMetal/mglCommandTypes.h) from the client
Send back an ack timestamp
Choose a command implementation based on command code.
Use failable init? method of chosen command implementation.
Some init are trivial, as with [mglFlushCommand](metal/mglMetal/commands/mglFlushCommand.swift)
Some read command-specific params from the command interface into their own fields, as with setter commands like [mglSetClearColorCommand](metal/mglMetal/commands/mglSetClearColorCommand.swift)
Some read command-specific params data directly into GPU device buffers, as with drawing commands like [mglDotsCommand](metal/mglMetal/commands/mglDotsCommand.swift)

### todo queue
Enqueue fully-read command for processing.

Normally will be processed next time the system calls render()
If building a batch, send back an immediate placeholder response to satisfy Matlab client
Then wait until caller releases the batch.

### rendering
Renderer has render() called periodically by the system.
Check for a command todo.
Call doNondrawingWork()
 - set the view clear color for the next frame like [mglSetClearColorCommand](metal/mglMetal/commands/mglSetClearColorCommand.swift)
 - create a new texture like [mglCreateTextureCommand](metal/mglMetal/commands/mglCreateTextureCommand.swift)
 - default no-op like [mglDotsCommand](metal/mglMetal/commands/mglDotsCommand.swift)

No framesRemaining, send to done queue

Any framesRemaining, set up a render pass and enter a drawing tight loop
call draw()
 - configure the current render pass and draw things, like [mglDotsCommand](metal/mglMetal/commands/mglDotsCommand.swift)
 - default no-op like [mglDotsCommand](metal/mglMetal/commands/mglDotsCommand.swift) or [mglCreateTextureCommand](metal/mglMetal/commands/mglCreateTextureCommand.swift)
send to done

Check for any more commands todo.
 - call doNondrawingWork, draw and send to done
 - Until flush

[mglFlushCommand](metal/mglMetal/commands/mglFlushCommand.swift) breaks the tight loop and presents the frame
Collect detailed timing for drawable and rendering stages
Sent to done after the frame has been presented

### done queue
Send back any query results
 - number of new texture created by [mglCreateTextureCommand](metal/mglMetal/commands/mglCreateTextureCommand.swift)
 - default no-op like [mglDotsCommand](metal/mglMetal/commands/mglDotsCommand.swift) or [mglSetClearColorCommand](metal/mglMetal/commands/mglSetClearColorCommand.swift)

Send back a timestamps for command processing
And drawable and rendering stages, if present for a flush command

Normally immediate
If building a batch, wait until Matlab requests it
