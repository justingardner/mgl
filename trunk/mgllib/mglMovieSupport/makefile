all: libjavamovie.so javaMovie.class mglMovieStandAlone mglMovieSendCommand
javaMovie.class: javaMovie.java
		 javac javaMovie.java
javaMovie.h: javaMovie.class
	     javah javaMovie
javaMovie.o: javaMovie.c javaMovie.h
	     g++  -x objective-c -fPIC -c javaMovie.c -I /Developer/SDKs/MacOSX10.5.sdk/System/Library/Frameworks/JavaVM.framework/Versions/A/Headers -fno-common -no-cpp-precomp -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -pthread
libjavamovie.so: javaMovie.o
		 gcc javaMovie.o -shared -o libjavamovie.so -Wl -framework agl -framework Carbon -framework Cocoa -framework CoreServices -framework openGL -pthread -framework QTKit
clean:
	rm javaMovie.o javaMovie.h javaMovie.class libjavamovie.so
	rm -f *.~
mglMovieStandAlone: mglMovieStandAlone.c
	     g++  -x objective-c -fPIC mglMovieStandAlone.c -fno-common -no-cpp-precomp -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5  -framework agl -framework Carbon -framework Cocoa -framework CoreServices -framework openGL -pthread -framework QTKit -o mglMovieStandAlone
mglMovieSendCommand: mglMovieSendCommand.c
	     g++  -fPIC mglMovieSendCommand.c -fno-common -no-cpp-precomp -arch x86_64 -isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -o mglMovieSendCommand
		    