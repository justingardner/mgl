% mglBltTexture.m
%
%      usage: mglBltTexture(texture,position,hAlignment,vAlignment)
%         by: justin gardner
%       date: 05/10/06
%    purpose: Draw a texture to the screen in desired position.
%
%             texture: A texture structure created by mglCreateTexture or
%                      mglText.
%             position: Either a 2-vector [xpos ypos] or 
%                       4-vector [xpos ypos width height]
%             hAlignment = {-1 = left,0 = center,1 = right}
%                          defaults to center
%             vAlignment = {-1 = top,0 = center,1 = bottom}
%                          defaults to center
%
%       e.g.: 
%
% mglOpen
% mglVisualAngleCoordinates(57,[16 12]);
% image = rand(200,200)*255;
% imageTex = mglCreateTexture(image);
% mglBltTexture(imageTex,[0 0]);
% mglFlush;
%
