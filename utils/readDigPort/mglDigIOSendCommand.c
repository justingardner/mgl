#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

#define BUFLEN (8192)
#define DIGINEVENTSIZE 6
int main(int argc, char *argv[]) {
  struct sockaddr_un addr;
  char buf[BUFLEN];
  int fd,rc;

  if ( (fd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    perror("socket error");
    exit(-1);
  }

  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  strncpy(addr.sun_path, ".mglDigIO", sizeof(addr.sun_path)-1);

  if (connect(fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
    perror("connect error");
    exit(-1);
  }

  if( (rc=read(STDIN_FILENO, buf, sizeof(buf))) > 0) {
    // write command
    if (write(fd, buf, rc) != rc) {
      if (rc > 0) fprintf(stderr,"partial write");
      else {
        perror("write error");
        exit(-1);
      }
    }
  }

  unsigned char readbuf[BUFLEN];
  int numEvents,eventCount,numThisEvents,readCount;

  // read a byte specifying how many digin events there are
  printf("Waiting for ack\n");
  readCount = read(fd,readbuf,BUFLEN);

  // convert from uchar to int
  numEvents = *(unsigned int *)(readbuf),
  printf("received: %i bytes numEvents: %i\n",readCount,numEvents);

  // get each one of the digin events associated with it.
  while (numEvents) {
    // read a block at most at a time. 
    readCount = read(fd,readbuf,floor(BUFLEN/DIGINEVENTSIZE)*DIGINEVENTSIZE);
    numThisEvents = readCount/DIGINEVENTSIZE;
    printf("received: %i bytes numThisEvents: %i of %i\n",readCount,numThisEvents,numEvents);
    // update the number of events left to read
    numEvents = numEvents-numThisEvents;
    // display them
    for(eventCount = 0;eventCount < numThisEvents; eventCount++) {
      printf("%i: Digin: %i line: %i time: %f (sizeof: %i)\n",eventCount+1,(int)(readbuf[0+DIGINEVENTSIZE*eventCount]),(int)(readbuf[1+DIGINEVENTSIZE*eventCount]),*(float*)(readbuf+2+DIGINEVENTSIZE*eventCount),(int)sizeof(float));
    }
  }
  // tell the other side we are closing
  write(fd,"close",5);

  // and close
  close(fd);

  return 0;
}
