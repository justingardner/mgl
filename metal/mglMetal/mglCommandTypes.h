//
//  mglCommandTypes.h
//  mglMetal
//
//  Created by Benjamin Heasly on 12/7/21.
//  Copyright © 2021 GRU. All rights reserved.
//

#ifndef mglCommandTypes_h
#define mglCommandTypes_h

#include <stdio.h>
#include <stdint.h>

// Source of truth for supported commands and their numeric codes.
// Communication code should use these enum symbols, not the numeric values themselves.
// Matlab and mglMetal should share this header so that they agree on the commands.
typedef enum mglCommandCode : uint16_t {
    mglPing = 0,
    mglDrainSystemEvents = 1,
    mglFullscreen = 2,
    mglWindowed = 3,
    mglCreateTexture = 5,
    mglReadTexture = 6,
    mglSetRenderTarget = 7,
    mglSetWindowFrameInDisplay = 8,
    mglGetWindowFrameInDisplay = 9,
    mglDeleteTexture = 10,
    mglSetViewColorPixelFormat = 11,
    mglStartStencilCreation = 12,
    mglFinishStencilCreation = 13,
    mglInfo = 14,
    mglSendString = 15,
    mglSendDouble = 16,
    mglSendDoubleArray = 17,
    mglSendFinished = 18,
    mglGetErrorMessage = 19,
    mglFrameGrab = 20,
    mglMinimize = 21,
    mglDisplayCursor = 22,
    mglSampleTimestamps = 23,
    mglStartBatch = 100,
    mglProcessBatch = 101,
    mglFinishBatch = 102,
    mglDrawingCommands = 1000,
    mglFlush = 1001,
    mglBltTexture = 1003,
    mglSetXform = 1004,
    mglDots = 1005,
    mglLine = 1006,
    mglQuad = 1007,
    mglPolygon = 1008,
    mglArcs = 1009,
    mglUpdateTexture = 1010,
    mglSelectStencil = 1011,
    mglSetClearColor = 1012,
    mglRepeatFlicker = 1013,
    mglRepeatBlts = 1014,
    mglRepeatQuads = 1015,
    mglRepeatDots = 1017,
    mglRepeatFlush = 1018,
    mglMovieCreate = 1019,
    mglMoviePlay = 1020,
    mglUnknownCommand = UINT16_MAX
} mglCommandCode;

// Utilities to list out and describe supported commands.
// These should be useful for exposing supported commands in dynamic environments like Matlab.
// It's tedious to create these by hand, but better to do it once, here in the source of truth.
const mglCommandCode mglCommandCodes[] = {
    mglPing,
    mglDrainSystemEvents,
    mglFullscreen,
    mglWindowed,
    mglCreateTexture,
    mglReadTexture,
    mglSetRenderTarget,
    mglSetWindowFrameInDisplay,
    mglGetWindowFrameInDisplay,
    mglDeleteTexture,
    mglSetViewColorPixelFormat,
    mglStartStencilCreation,
    mglFinishStencilCreation,
    mglInfo,
    mglSendString,
    mglSendDouble,
    mglSendDoubleArray,
    mglSendFinished,
    mglGetErrorMessage,
    mglFrameGrab,
    mglMinimize,
    mglDisplayCursor,
    mglSampleTimestamps,
    mglStartBatch,
    mglProcessBatch,
    mglFinishBatch,
    mglFlush,
    mglBltTexture,
    mglSetXform,
    mglDots,
    mglLine,
    mglQuad,
    mglPolygon,
    mglArcs,
    mglUpdateTexture,
    mglSelectStencil,
    mglSetClearColor,
    mglRepeatFlicker,
    mglRepeatBlts,
    mglRepeatQuads,
    mglRepeatDots,
    mglRepeatFlush,
    mglMovieCreate,
    mglMoviePlay
};
const char* mglCommandNames[] = {
    "mglPing",
    "mglDrainSystemEvents",
    "mglFullscreen",
    "mglWindowed",
    "mglCreateTexture",
    "mglReadTexture",
    "mglSetRenderTarget",
    "mglSetWindowFrameInDisplay",
    "mglGetWindowFrameInDisplay",
    "mglDeleteTexture",
    "mglSetViewColorPixelFormat",
    "mglStartStencilCreation",
    "mglFinishStencilCreation",
    "mglInfo",
    "mglSendString",
    "mglSendDouble",
    "mglSendDoubleArray",
    "mglSendFinished",
    "mglGetErrorMessage",
    "mglFrameGrab",
    "mglMinimize",
    "mglDisplayCursor",
    "mglSampleTimestamps",
    "mglStartBatch",
    "mglProcessBatch",
    "mglFinishBatch",
    "mglFlush",
    "mglBltTexture",
    "mglSetXform",
    "mglDots",
    "mglLine",
    "mglQuad",
    "mglPolygon",
    "mglArcs",
    "mglUpdateTexture",
    "mglSelectStencil",
    "mglSetClearColor",
    "mglRepeatFlicker",
    "mglRepeatBlts",
    "mglRepeatQuads",
    "mglRepeatDots",
    "mglRepeatFlush",
    "mglFrameGrab",
    "mglMovieCreate",
    "mglMoviePlay"
};

// Type aliases for supported scalar data types of known, fixed sizes.
// Communication code should use these types instead of environment-specific types.
// Matlab and mglMetal should share this header so that they agree on the data sizes.
typedef uint32_t mglUInt32;
typedef double mglDouble;
typedef float mglFloat;

// Utils to calculate bytes sizes of arrays of supported scalar types.
// Communication code should use these sizes for buffers, reads, and writes.
// Matlab and mglMetal should share this header so that they agree on the array sizes.
static inline mglUInt32 mglSizeOfCommandCodeArray(mglUInt32 n) { return sizeof(mglCommandCode) * n; }
static inline mglUInt32 mglSizeOfUInt32Array(mglUInt32 n) { return sizeof(mglUInt32) * n; }
static inline mglUInt32 mglSizeOfDoubleArray(mglUInt32 n) { return sizeof(mglDouble) * n; }
static inline mglUInt32 mglSizeOfFloatArray(mglUInt32 n) { return sizeof(mglFloat) * n; }
static inline mglUInt32 mglSizeOfFloatVertexArray(mglUInt32 nVertices, mglUInt32 nDimensions) { return mglSizeOfFloatArray(nVertices * nDimensions); }
static inline mglUInt32 mglSizeOfFloatRgbaTexture(mglUInt32 width, mglUInt32 height) { return mglSizeOfFloatArray(4 * width * height); }
static inline mglUInt32 mglSizeOfFloatRgbColor(void) { return mglSizeOfFloatArray(3); }
static inline mglUInt32 mglSizeOfFloat4x4Matrix(void) { return mglSizeOfFloatArray(16); }

#endif /* mglCommandTypes_h */
