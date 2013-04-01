all: mglStandaloneDigIO
mglStandaloneDigIO: mglStandaloneDigIO.c makefile
	     g++  -x objective-c -fPIC mglStandaloneDigIO.c -fno-common -no-cpp-precomp -arch i386   -framework Cocoa -pthread -framework nidaqmxbase -framework nidaqmxbaselv -o mglStandaloneDigIO
mglMovieSendCommand: mglMovieSendCommand.c
	     g++  -fPIC mglMovieSendCommand.c -fno-common -no-cpp-precomp -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -o mglMovieSendCommand
		    