//
//  mglCommandModel.swift
//  mglMetal
//
//  Created by Benjamin Heasly on 6/15/22.
//  Copyright © 2022 GRU. All rights reserved.
//

import Foundation

/**
 Over in mglRenderer, we're handling all of the socket and rendering flow control, as well as the inner details of rendering commands.
 As we go and grow, I think a pattern is emerging among the rendering commands, which we might want to factor out into an explicit OOP command model.
 This could help us clarify what we want a "command" to be, and separate the duties between socket stuff, flow control stuff, and inner graphics details.
 Doing this might give us confidence that adding or modifying a particular command would not have unintended effects on other commands.
 It might also allow user-defined commands to be loaded as runtime plugins, if we go that route, but providing a protocol/interface to write code to.
 It might also support future commands that are "close to the metal", which may need to maintain and manage their own state, across several frames.

 As a start, I'll make notes here about the config, state, and operations that seem to might go into each command, things we might want to factor out.
 My source for this is the current code in mglRenderer, which has grown to be somewhat long, around 1000 lines.
 Later, maybe this file here can become the place where we define an actual Swift protocol called mglCommandModel.

 Many commands seem to:
  - have its own, associated command code in mglCommandTypes
  - have a few utility functions associated with it, for example to parse numeric params into Swift Enum values.
  - have side-effects on the overall mglMetal app with things like fullscreen vs windowed mode, stencil state, clear color, etc.
  - be able to create a suitable render pipeline descriptor, for a given set of pixel formats
  - be able to configure an instance of itself with any necessary params, given an mglCommandInterface to read from
  - report configuration success or failure as a return value
  - be able to add itself to a render pass, given the current view and command encoder
  - report render pass success or failure as a return value
  - be able to write any requested data back to the caller, given an mglCommandInterface to write to
  - report data write pass success or failure as a return value

 It might be that commands also should:
  - have a counter for how many times to repeat itself as part of a frame sequence
  - be able to load configuration (as from a socket) once at the start of a frame sequence, and reuse the config throughout the sequence
  - be able to report whether it's in the middle of a repetition sequence
  - be able to configure an instance of itself from a regular init() method, *without* an mglCommandInterface, for standalone testing.
  - be able to return requested data back to the caller as regular variables, *without* an mglCommandInterface, for standalone testing.
 */
