//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
//
//  mglCommunicator.m
//  mglMetal
//
//  Created by justin gardner on 12/22/2019.
//  Copyright © 2019 GRU. All rights reserved.
//  Purpose: Implementation of mglComm which connects via
//           POSIX sockets to matlab, so this application
//           can have a simple means of communicating with
//           matlab to get commands to draw the screen
//
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/

#import "mglCommunicator.h"

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// include section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#include <stdio.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <memory.h>
#include <signal.h>
#include <errno.h>
#include <unistd.h>
#include <poll.h>
#include <CoreServices/CoreServices.h>

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// define section
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#define BUFLEN 1024

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// mglCommSocket
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
@implementation mglCommunicatorSocket

// descriptors used for the socket
int socketDescriptor = -1;

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// implementation: open
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(BOOL) open:(NSString *)connectionName error:(NSError **)error
{
    // log what we are called with
    NSLog(@"%@", connectionName);
    
    // declare things for possible errors.
    NSMutableDictionary* errorDetails = [NSMutableDictionary dictionary];
    NSString *errorDomain = @"gru.mglSocket";

    char cdbuf[256];
    getcwd(cdbuf,256);
    printf("pwd: %s\n",cdbuf);
    // create socket and check for error
    if ((socketDescriptor = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
        // Set error description
        [errorDetails setValue:@"Could not create socket to communicate between matlab and mglMetal" forKey:NSLocalizedDescriptionKey];
        // set the error
        *error = [NSError errorWithDomain:errorDomain code:-101 userInfo:errorDetails];
        return(FALSE);
    }

    // set up socket address
    struct sockaddr_un socketAddress;
    memset(&socketAddress, 0, sizeof(socketAddress));
    socketAddress.sun_family = AF_UNIX;
    strncpy(socketAddress.sun_path, [connectionName UTF8String], sizeof(socketAddress.sun_path)-1);
    if (connect(socketDescriptor, (struct sockaddr*)&socketAddress, sizeof(socketAddress)) == -1) {
        // Set error description
        [errorDetails setValue:[NSString stringWithFormat:@"(mglCommunicatorSocket:open) Could not connect to socket name %s This prevents communication between matlab and mglMetal. This might have happened because matlab has not yet created the socket (need to run mglSocketOpen)",[connectionName UTF8String]] forKey:NSLocalizedDescriptionKey];
        // set the error
        *error = [NSError errorWithDomain:errorDomain code:-103 userInfo:errorDetails];

      return(FALSE);
    }

    printf("(mglCommunicatorSocket:open) Opened socket %s\n",[connectionName UTF8String]);
    return(TRUE);
}
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// implementation: close
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(void) close
{
    // close the socket if it is opened
    if (socketDescriptor != -1) close(socketDescriptor);
    socketDescriptor = -1;
}
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// implementation: dataWaiting
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(BOOL) dataWaiting
{
    // use poll function to return whether there is data waiting
    struct pollfd pfd;
    pfd.fd = socketDescriptor;
    pfd.events = POLLIN;
    pfd.revents = 0;
    poll(&pfd,1,0);
    
    // return true or false
    if (pfd.revents == POLLIN)
        return true;
    else
        return false;
}
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// implementation: readData
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(void)readData:(int)byteCount buf:(void *)buf
{
    // declare variables
    ssize_t readCount;

    // read buffer
    readCount = recv(socketDescriptor,buf,byteCount,0);
    if (readCount < byteCount) {
        // error on read, assume that connection was closed.
        if (errno != EAGAIN) {
            close(socketDescriptor);
            socketDescriptor = -1;
        }
        // FIX: This should probably throw an error if we got here
    }
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// implementation: readCommand
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(int) readCommand
{
    // declare variables
    ssize_t readCount;
    
    // buffer to receive commands and size
    static uint16 commandBuffer;
    static size_t commandBufferLen = sizeof(uint16);

    // clear command buffer
    memset(&commandBuffer,0,commandBufferLen);

    // read command
    if ((readCount=recv(socketDescriptor,&commandBuffer,commandBufferLen,0)) != commandBufferLen) {
        // FIX: error on read, assume that connection was closed.
        if (errno != EAGAIN) {
            close(socketDescriptor);
            socketDescriptor = -1;
        }
    }
    return(commandBuffer);
}

//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
// implementation: writeDataDouble
//\/\/\/\/\/\/\/\/\/\/\/\/\/\/
-(void) writeDataDouble:(double)data
{
    if (write(socketDescriptor,&data,sizeof(double)) < sizeof(double))
        printf("(mglCommunicatorSocket:writeDouble) Unable to write data\n");
}
@end
