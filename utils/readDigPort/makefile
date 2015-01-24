all: mglStandaloneDigIO mglDigIOSendCommand
mglStandaloneDigIO: mglStandaloneDigIO.c makefile
	     g++  -x objective-c -fPIC mglStandaloneDigIO.c -fno-common -no-cpp-precomp -arch i386 -F/Library/Frameworks  -framework Cocoa -pthread -framework nidaqmxbase -framework nidaqmxbaselv -o mglStandaloneDigIO
mglDigIOSendCommand: mglDigIOSendCommand.c
	     g++  -fPIC mglDigIOSendCommand.c -fno-common -no-cpp-precomp -arch x86_64 -o mglDigIOSendCommand
		    