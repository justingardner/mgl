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

NS_ASSUME_NONNULL_BEGIN

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// Protocol for communication classes with matlab.
// This defines a set of methods that can be used
// by mglController to open/close and read/write
// to matlab. It is declared as a protocol so that
// future versions of the code need simply conform
// to this protocol and can replace the underlying
// communication strucutre
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
@protocol mglCommunicatorProtocol
-(BOOL) open:(NSString *)connectionName error:(NSError **)error;
-(void) close;
-(BOOL) dataWaiting;
-(void) readData:(int)byteCount buf:(void *)buf;
-(void) writeDataDouble:(double)data;
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
