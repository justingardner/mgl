% mglBltTexture.m
%
%        $Id$
%      usage: [ackTime, processedTime, setupTime] = mglBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height)
%         by: justin gardner
%       date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Draw a texture to the screen in desired position.
%
%             tex: A texture structure created by mglCreateTexture or
%                  mglText.
%             position: Either a 2-vector [xpos ypos] or
%                       4-vector [xpos ypos width height]
%                       For 1d textures, you can also specify a 3-vector
%                       [xpos ypos height]
%             hAlignment = {-1 = left,0 = center,1 = right}
%                          defaults to center
%             vAlignment = {-1 = top,0 = center,1 = bottom}
%                          defaults to center
%             rotation: rotation in degrees, defaults to 0
%             width: alternative way to specify the displayed width, this
%                    takes precidence over position(3), if given.
%             height: alternative way to specify the displayed height, this
%                    takes precidence over position(4), if given.
%
%             To display several textures at once, texture
%             can be an array of n textures, position is nx2, or nx4
%             and hAlignment, vAlignment, rotation, width, and height are
%             either a single value or an array of n:
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
function [ackTime, processedTime, setupTime] = mglBltTexture(tex, position, hAlignment, vAlignment, rotation, phase, width, height)

% if nargin < 2, position = [0 0]; end
% if nargin < 3, hAlignment = 0; end
% if nargin < 4, vAlignment = 0; end
% if nargin < 5, rotation = 0; end
% if nargin < 6, phase = 0; end
% if nargin < 7
%   if length(position)<3
%     % get width in device coordinates
%     width = tex.imageWidth*mglGetParam('xPixelsToDevice');
%   else
%     width = position(3);
%   end
% end
% if nargin < 8
%   if length(position)<4
%     % get height in device coordinates
%     height = tex.imageHeight*mglGetParam('yPixelsToDevice');
%   else
%     height = position(4);
%   end
% end

% Expand arguments and/or defaults to match the number of textures.
textureCount = numel(tex);
if nargin < 2
    position = zeros(textureCount, 2);
elseif size(position, 1) == 1
    position = repmat(position, textureCount, 1);
end

if nargin < 3
    hAlignment = zeros(textureCount, 1);
elseif numel(hAlignment) == 1
    hAlignment = repmat(hAlignment, textureCount, 1);
end

if nargin < 4
    vAlignment = zeros(textureCount, 1);
elseif numel(vAlignment) == 1
    vAlignment = repmat(vAlignment, textureCount, 1);
end

if nargin < 5
    rotation = zeros(textureCount, 1);
elseif numel(rotation) == 1
    rotation = repmat(rotation, textureCount, 1);
end

if nargin < 6
    phase = zeros(textureCount, 1);
elseif numel(phase) == 1
    phase = repmat(phase, textureCount, 1);
end

if nargin < 7
    if size(position, 2) < 3
        % default: get width in device coordinates
        width = [tex.imageWidth] * mglGetParam('xPixelsToDevice');
    else
        % alternative way to specify, as part of position vector
        width = position(:, 3);
    end
elseif numel(width) == 1
    width = repmat(width, textureCount, 1);
end

if nargin < 8
    if size(position, 2) < 4
        % default: get height in device coordinates
        height = [tex.imageHeight] * mglGetParam('yPixelsToDevice');
    else
        height = position(:, 4);
    end
elseif numel(height) == 1
    height = repmat(height, textureCount, 1);
end

ackTime = zeros([1, textureCount]);
processedTime = zeros([1, textureCount]);
setupTime = zeros([1, textureCount]);
for ii = 1:textureCount
    [ackTime(ii), processedTime(ii), setupTime(ii)] = mglMetalBltTexture( ...
        tex(ii), ...
        position(ii,:), ...
        hAlignment(ii), ...
        vAlignment(ii), ...
        rotation(ii), ...
        phase(ii), ...
        width(ii), ...
        height(ii));
end
