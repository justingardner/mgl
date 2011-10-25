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
%
%             Note that on Mac if you want to draw to an off-screen buffer
%             i.e. you want to use frame grab to create images but not
%             necessarily open a window, you can use an "offscreenContext" by setting
%             the following before using mglOpen:
%
%             mglSetParam('useCGL',0);
%             mglSetParam('offscreenContext',1);
%             % and open a windowed context:
%             mglOpen(0);
%       e.g.: 
%
%mglOpen();
%mglScreenCoordinates;
%mglClearScreen([0 0 0]);
%mglPoints2(mglGetParam('screenWidth')*rand(5000,1),mglGetParam('screenHeight')*rand(5000,1));
%mglPolygon([0 0 mglGetParam('screenWidth') mglGetParam('screenWidth')],[mglGetParam('screenHeight')/3 mglGetParam('screenHeight')*2/3 mglGetParam('screenHeight')*2/3 mglGetParam('screenHeight')/3],0);
% mglTextSet('Helvetica',32,[1 1 1]);
%mglTextDraw('Frame Grab',[mglGetParam('screenWidth')/2 mglGetParam('screenHeight')/2]);
%frame = mglFrameGrab;
%imagesc(mean(frame,3)');colormap('gray')
%mglFlush



