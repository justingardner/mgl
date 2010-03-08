% mglBltTexture.m
%
%        $Id$
%      usage: mglBltTexture(texture,position,hAlignment,vAlignment,rotation)
%         by: justin gardner
%       date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Draw a texture to the screen in desired position.
%
%             texture: A texture structure created by mglCreateTexture or
%                      mglText.
%             position: Either a 2-vector [xpos ypos] or 
%                       4-vector [xpos ypos width height]
%                       For 1d textures, you can also specify a 3-vector
%                       [xpos ypos height]
%             hAlignment = {-1 = left,0 = center,1 = right}
%                          defaults to center
%             vAlignment = {-1 = top,0 = center,1 = bottom}
%                          defaults to center
%             rotation: rotation in degrees, defaults to 0
%
%             To display several textures at once, texture
%             can be an array of n textures, position is nx2, or nx4
%             and hAlignment, vAlignment and rotation are either
%             a single value or an array of n:
%       e.g.: multiple textures
%
% mglOpen
% mglVisualAngleCoordinates(57,[16 12]);
% image = rand(200,200)*255;
% imageTex = mglCreateTexture(image);
% mglBltTexture([imageTex imageTex],[-3 0;3 0],0,0,[-15 15]);
% mglFlush;
%
%       e.g.: single textures
%
% mglOpen
% mglVisualAngleCoordinates(57,[16 12]);
% image = rand(200,200)*255;
% imageTex = mglCreateTexture(image);
% mglBltTexture(imageTex,[0 0]);
% mglFlush;
%
%       e.g.: single 1D textures (like sine wave gratings)
% mglOpen
% mglVisualAngleCoordinates(57,[16 12]);
% image1d = rand(1,300)*255;
% imageTex = mglCreateTexture(image1d);
% mglBltTexture(imageTex,[0 0 5]);
% mglFlush;
