% mglCreateTexture.m
%
%        $Id$
%      usage: mglCreateTexture(image)
%         by: justin gardner
%       date: 04/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Create a texture for display on the screen with mglBltTexture
%             image can either be grayscale nxm, color nxmx3 or
%             color+alpha nxmx4
% 
%       e.g.: mglOpen;
%             mglClearScreen
%             mglScreenCoordinates
%             texture = mglCreateTexture(round(rand(100,100)*255));
%             mglBltTexture(texture,[0 0]);
%             mglFlush;

