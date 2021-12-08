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
    ping = 0,
    clearScreen = 1,
    dots = 2,
    flush = 3,
    setXform = 4,
    line = 5,
    quad = 6,
    createTexture = 7,
    bltTexture = 8,
    test = 9,
    fullscreen = 10,
    windowed = 11,
    blocking = 12,
    nonblocking = 13,
    profileon = 14,
    profileoff = 15,
    polygon = 16,
    getSecs = 17,
    errorOrUnknown = UINT16_MAX
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

mglCommandCode readCommandCode(mglReader read) {
    mglCommandCode value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return errorOrUnknown;
    }
}
size_t writeCommandCode(mglWriter write, mglCommandCode value) {
    return write(&value, sizeof(value));
}

uint32_t readUInt32(mglReader read) {
    uint32_t value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return UINT32_MAX;
    }
}
size_t writeUInt32(mglWriter write, uint32_t value) {
    return write(&value, sizeof(value));
}

double readDouble(mglReader read) {
    double value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return NAN;
    }
}
size_t writeDouble(mglWriter write, double value) {
    return write(&value, sizeof(value));
}

float readFloat(mglReader read) {
    float value;
    size_t nRead = read(&value, sizeof(value));
    if (nRead == sizeof(value)) {
        return value;
    } else {
        return NAN;
    }
}
size_t writeFloat(mglWriter write, float value) {
    return write(&value, sizeof(value));
}

//
// Read and write arrays of various types.
//

size_t sizeOfUInt32Array(size_t n) {
    return sizeof(uint32_t) * n;
}
size_t readUInt32Array(mglReader read, uint32_t * destinationBuffer, size_t n) {
    return read(destinationBuffer, sizeOfUInt32Array(n));
}
size_t writeUInt32Array(mglWriter write, const uint32_t * sourceBuffer, size_t n) {
    return write(sourceBuffer, sizeOfUInt32Array(n));
}

size_t sizeOfDoubleArray(size_t n) {
    return sizeof(double) * n;
}
size_t readDoubleArray(mglReader read, double * destinationBuffer, size_t n) {
    return read(destinationBuffer, sizeOfDoubleArray(n));
}
size_t writeDoubleArray(mglWriter write, const double * sourceBuffer, size_t n) {
    return write(sourceBuffer, sizeOfDoubleArray(n));
}

size_t sizeOfFloatArray(size_t n) {
    return sizeof(float) * n;
}
size_t sizeOfFloatVertexArray(size_t nVertices, size_t nDimensions) {
    return sizeOfFloatArray(nVertices * nDimensions);
}
size_t sizeOfFloatRgbaTexture(size_t width, size_t height) {
    return sizeOfFloatArray(4 * width * height);
}
size_t sizeOfFloatRgb() {
    return sizeOfFloatArray(3);
}
size_t sizeOfFloat4x4Matrix() {
    return sizeOfFloatArray(16);
}
size_t readFloatArray(mglReader read, float * destinationBuffer, size_t n) {
    return read(destinationBuffer, sizeOfFloatArray(n));
}
size_t writeFloatArray(mglWriter write, const float * sourceBuffer, size_t n) {
    return write(sourceBuffer, sizeOfFloatArray(n));
}

#endif /* mglCommandBytes_h */
