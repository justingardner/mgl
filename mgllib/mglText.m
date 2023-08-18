% mglText.m
%
%        $Id$
%      usage: [tex, ackTime, processedTime] = mglText('string')
%         by: justin gardner
%       date: 09/28/2021 Based on version from 05/10/06
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns a texture for a string
%
%       e.g.:
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglTextSet('Helvetica',32,[1 1 1],0,0,0);
%thisText = mglText('Hello')
%mglBltTexture(thisText,[0 0],'left','top');
%mglFlush;
function [tex, ackTime, processedTime] = mglText(str)

if (nargin ~= 1) || ~isstr(str)
  help mglText;
  return
end

% get the image of the text
im = mglPrivateText(str);

% flip vertical
if isequal(mglGetParam('fontVFlip'),1)
  im.textImage = flipud(im.textImage);
end

% flip horizontal
if isequal(mglGetParam('fontHFlip'),1)
  im.textImage = fliplr(im.textImage);
end

% need to reshape
im.textImage = reshape(flipud(im.textImage),im.imageHeight,im.imageWidth,4);

% set alpha to 255
im.textImage(:,:,4) = 255*(im.textImage(:,:,1)>0 | im.textImage(:,:,2)>0 | im.textImage(:,:,3)>0);

% create the texture
[tex, ackTime, processedTime] = mglCreateTexture(im.textImage);
