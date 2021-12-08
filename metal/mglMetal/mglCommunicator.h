//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglCommunicator.h
//  mglMetal
//
//  Created by justin gardner on 12/25/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

#import <Foundation/Foundation.h>
#import "mglCommandBytes.h"

NS_ASSUME_NONNULL_BEGIN

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Protocol for communication classes with matlab.
// This defines a set of methods that can be used
// to open/close and read/write to matlab.
//
// It is declared as a protocol so that future
// versions of the code need simply conform to this
// protocol and can replace the underlying
// communication strucutre.  The key task to
// implement is to read and write bytes to and from
// a stream, like a socket.
//
// Utilities in mglCommandBytes.h can work on top
// of the byte-level comminication to safely read
// and write supported data types and arrays.  The
// callback types mglReader and mglWriter make this
// integration possible.  This app and matlab
// should share the same header, mglCommandBytes.h,
// and this should make for smooth interoperation!
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
@protocol mglCommunicatorProtocol
-(BOOL) open:(NSString *)connectionName error:(NSError **)error;
-(void) close;
-(BOOL) dataWaiting;
-(mglReader) reader;
-(mglWriter) writer;
@end

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// a class which implements the above protocol using
// POSIX sockets.
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
@interface mglCommunicatorSocket : NSObject <mglCommunicatorProtocol> {
    // set to true if you want the object to provide verbose info
    BOOL verbose;
}
@end

NS_ASSUME_NONNULL_END
