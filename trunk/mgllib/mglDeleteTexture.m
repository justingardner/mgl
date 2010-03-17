% mglDeleteTexture.m
%
%        $Id$
%      usage: mglDeleteTexture(tex)
%         by: justin gardner
%       date: 02/29/08
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
function texture = mglDeleteTexture(texture)

if nargin ~= 1
  help mglDeleteTexture
  return
end

if isfield(texture,'textureNumber')
  % if texture is an array then we delete each element separately
  for i = 1:length(texture)
    mglPrivateDeleteTexture(texture(i).textureNumber,texture(i).liveBuffer);
  end
  texture(i).textureNumber = -1;
else
  disp('(mglDeleteTexture) Input is not a texture');
end


