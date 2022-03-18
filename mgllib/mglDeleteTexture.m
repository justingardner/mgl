% mglDeleteTexture.m
%
%        $Id$
%      usage: mglDeleteTexture(tex)
%         by: Benjamin Heasly
%       date: 03/18/2022
%  copyright: (c) 2008 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Deletes a texture. This will free up memory for
%             textures that will not be drawn again. Note that when
%             you call mglClose texture memory is freed up.
%             The only time you need to call this is if you are
%             running out of memory and have textures that you do
%             not need to use anymore.
%
%       e.g.:
% mglOpen;
% mglClearScreen
% mglScreenCoordinates
% texture = mglCreateTexture(round(rand(100,100)*255));
% mglBltTexture(texture,[0 0]);
% mglFlush;
% mglDeleteTexture(texture);
function [texture, ackTime, processedTime] = mglDeleteTexture(texture)

if nargin ~= 1
    help mglDeleteTexture
    return
end

if isfield(texture,'textureNumber')
    % if texture is an array then we delete each element separately
    for i = 1:length(texture)
        [ackTime, processedTime] = deleteTexture(texture(i).textureNumber);
    end
    texture(i).textureNumber = -1;
else
    disp('(mglDeleteTexture) Input is not a texture');
end

function [ackTime, processedTime] = deleteTexture(textureNumber)
global mgl
mglSocketWrite(mgl.s, mgl.command.mglDeleteTexture);
ackTime = mglSocketRead(mgl.s, 'double');
mglSocketWrite(mgl.s, textureNumber);
processedTime = mglSocketRead(mgl.s, 'double');

