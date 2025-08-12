% mglText.m
%
%        $Id$
%      usage: [tex, results] = mglText('string')
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
function [tex, results] = mglText(str)

if (nargin ~= 1) || ~isstr(str)
  help mglText;
  return
end

% get the image of the text

% BSH: Apple's ATSUI API, used by mglPrivateText,
% is no longer supported on macOS 14 Sonoma.
%im = mglPrivateText(str);

% BSH: This is a placeholder, pure Matlab workaround for ATSUI.
textImage = mglFigureText(str);
im.textImage = textImage;
im.imageHeight = size(textImage, 1);
im.imageWidth = size(textImage, 2);

% flip vertical
if isequal(mglGetParam('fontVFlip'),1)
  im.textImage = flipud(im.textImage);
end

% flip horizontal
if isequal(mglGetParam('fontHFlip'),1)
  im.textImage = fliplr(im.textImage);
end

% BSH: I think these are not needed when using mglFigureText() above --
% I think mglTestText looks correct without them.
% need to reshape
%im.textImage = reshape(flipud(im.textImage),im.imageHeight,im.imageWidth,4);
% set alpha to 255
%im.textImage(:,:,4) = 255*(im.textImage(:,:,1)>0 | im.textImage(:,:,2)>0 | im.textImage(:,:,3)>0);

% create the texture
[tex, results] = mglCreateTexture(im.textImage);
