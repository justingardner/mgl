//
//  mglCommandBytes.h
//  mglMetal
//
//  Created by Benjamin Heasly on 12/7/21.
//  Copyright © 2021 GRU. All rights reserved.
//

#ifndef mglCommandBytes_h
#define mglCommandBytes_h

#include <stdio.h>
#include <stdint.h>
#include <math.h>

typedef enum mglCommandCode : uint16_t {
    mglPing = 0,
    mglClearScreen = 1,
    mglDots = 2,
    mglFlush = 3,
    mglSetXform = 4,
    mglLine = 5,
    mglQuad = 6,
    mglCreateTexture = 7,
    mglBltTexture = 8,
    mglTest = 9,
    mglFullscreen = 10,
    mglWindowed = 11,
    mglBlocking = 12,
    mglNonblocking = 13,
    mglProfileon = 14,
    mglProfileoff = 15,
    mglPolygon = 16,
    mglGetSecs = 17,
    mglErrorOrUnknown = UINT16_MAX
} mglCommandCode;

//
// Abstract callbacks for reading and writing bytes from and to a socket.
// MGL endpoints like Matlab and Metal need to provide implementations for these, to pass in as callback pointers.
// From there, these utilities can safely read and write the supported data types for interoperation.
//

// Read up to n bytes from some stream (eg a socket) into a destination buffer.  Return the number of bytes actually read.
typedef size_t (*mglReader) (void * destinationBuffer, size_t n);

// Write up to n bytes from a source buffer into some stream (eg a socket), return the number of bytes actually written.
typedef size_t (*mglWriter) (const void * sourceBuffer, size_t n);

//
// Read and write various scalars.
//

static inline mglCommandCode mglReadCommandCode(mglReader read) {
    mglCommandCode value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return mglErrorOrUnknown;
    }
}
static inline size_t mglWriteCommandCode(mglWriter write, mglCommandCode value) {
    return write(&value, sizeof(value));
}

static inline uint32_t mglReadUInt32(mglReader read) {
    uint32_t value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return UINT32_MAX;
    }
}
static inline size_t mglWriteUInt32(mglWriter write, uint32_t value) {
    return write(&value, sizeof(value));
}

static inline double mglReadDouble(mglReader read) {
    double value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return NAN;
    }
}
static inline size_t mglWriteDouble(mglWriter write, double value) {
    return write(&value, sizeof(value));
}

static inline float mglReadFloat(mglReader read) {
    float value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return NAN;
    }
}
static inline size_t mglWriteFloat(mglWriter write, float value) {
    return write(&value, sizeof(value));
}

//
// Read and write arrays of various types.
//

static inline size_t mglReadByteArray(mglReader read, void * destinationBuffer, size_t n) {
    return read(destinationBuffer, n);
}
static inline size_t mglWriteByteArray(mglWriter write, const void * sourceBuffer, size_t n) {
    return write(sourceBuffer, n);
}

static inline size_t mglSizeOfUInt32Array(size_t n) {
    return sizeof(uint32_t) * n;
}
static inline size_t mglReadUInt32Array(mglReader read, uint32_t * destinationBuffer, size_t n) {
    return read(destinationBuffer, mglSizeOfUInt32Array(n));
}
static inline size_t mglWriteUInt32Array(mglWriter write, const uint32_t * sourceBuffer, size_t n) {
    return write(sourceBuffer, mglSizeOfUInt32Array(n));
}

static inline size_t mglSizeOfDoubleArray(size_t n) {
    return sizeof(double) * n;
}
static inline size_t mglReadDoubleArray(mglReader read, double * destinationBuffer, size_t n) {
    return read(destinationBuffer, mglSizeOfDoubleArray(n));
}
static inline size_t mglWriteDoubleArray(mglWriter write, const double * sourceBuffer, size_t n) {
    return write(sourceBuffer, mglSizeOfDoubleArray(n));
}

static inline size_t mglSizeOfFloatArray(size_t n) {
    return sizeof(float) * n;
}
static inline size_t mglSizeOfFloatVertexArray(size_t nVertices, size_t nDimensions) {
    return mglSizeOfFloatArray(nVertices * nDimensions);
}
static inline size_t mglSizeOfFloatRgbaTexture(size_t width, size_t height) {
    return mglSizeOfFloatArray(4 * width * height);
}
static inline size_t mglSizeOfFloatRgb(void) {
    return mglSizeOfFloatArray(3);
}
static inline size_t mglSizeOfFloat4x4Matrix(void) {
    return mglSizeOfFloatArray(16);
}
static inline size_t mglReadFloatArray(mglReader read, float * destinationBuffer, size_t n) {
    return read(destinationBuffer, mglSizeOfFloatArray(n));
}
static inline size_t mglWriteFloatArray(mglWriter write, const float * sourceBuffer, size_t n) {
    return write(sourceBuffer, mglSizeOfFloatArray(n));
}

#endif /* mglCommandBytes_h */
