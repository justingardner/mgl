% mglText.m
%
%        $Id$
%      usage: mglText('string')
%         by: justin gardner
%       date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns image of string.
%
%       e.g.: 
%
%mglOpen
%mglScreenCoordinates
%mglTextSet('Helvetica',32,[1 1 1]);
%thisText = mglText('hello')
%mglBltTexture(thisText,[0 0],-1,1); % -1 = left; 1 = bottom
%mglFlush;

