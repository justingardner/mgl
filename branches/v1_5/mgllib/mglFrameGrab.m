% mglFrameGrab.m
%
%        $Id$
%      usage: mglFrameGrab(<[x y width height])
%         by: justin gardner
%       date: 03/01/08
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: does a frame grab of the current mgl screen and
%             returns it as matrix of dimensions widthxheightx3
%      usage: To grab the whole screen
%             frame = mglFrameGrab;
% 
%             To grab a rectangular region of the screen at position
%             (e.g.) 30,40 with a width and height of 100 x 200
%             mglFrameGrab([30 40 100 200]);
%       e.g.: 
%
%mglOpen();
%mglScreenCoordinates;
%mglClearScreen([0 0 0]);
%global MGL;
%mglPoints2(MGL.screenWidth*rand(5000,1),MGL.screenHeight*rand(5000,1));
%mglPolygon([0 0 MGL.screenWidth MGL.screenWidth],[MGL.screenHeight/3 MGL.screenHeight*2/3 MGL.screenHeight*2/3 MGL.screenHeight/3],0);
% mglTextSet('Helvetica',32,[1 1 1]);
%mglTextDraw('Frame Grab',[MGL.screenWidth/2 MGL.screenHeight/2]);
%frame = mglFrameGrab;
%imagesc(mean(frame,3)');colormap('gray')
%mglFlush



