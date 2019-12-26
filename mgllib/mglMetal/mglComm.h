//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglComm.h
//  mglStandaloneDisplay
//
//  Created by justin gardner on 12/25/2019.
//  Copyright © 2019 GRU. All rights reserved.
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// emnumeration for meaning of numeric commands
typedef NS_ENUM(NSInteger, mglCommCommands) {
    kPing,
    kClose,
    kAck,
    kClearScreen,
    kFlush
};

// emnumeration for types of data
typedef NS_ENUM(NSInteger, mglDataType) {
    kUINT8,
    kUINT16,
    kUINT32,
    kDOUBLE,
};

// Protocol for communication classes with matlab.
// This defines a set of methods that can be used
// by mglController to open/close and read/write
// to matlab. It is declared as a protocol so that
// future versions of the code need simply conform
// to this protocol and can replace the underlying
// communication strucutre
@protocol mglCommProtocol
-(BOOL) open:(NSString *)connectionName error:(NSError **)error;
-(void) close;
-(BOOL) dataWaiting;
//FIX this should return a mglCommCommands - but how to get swift to recognize enum?
-(int) readCommand;
-(NSData *) readData:(int)nBytes dataType: (mglDataType)dataType;
-(int) readUINT32;
-(void) writeDouble:(double)data;
-(void) writeDoubleHuh;
@end

// a class which implements the above protocol using
// POSIX sockets.
@interface mglCommSocket : NSObject <mglCommProtocol> {
    // set to true if you want the object to provide verbose info
    BOOL verbose;
}
@end

NS_ASSUME_NONNULL_END
