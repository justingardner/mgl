% mglTestTextureMultiple: an automated and/or interactive test for rendering.
%
%      usage: mglTestTextureMultiple(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering a smoothly varying texture.
%      usage:
%             % You can run it by hand with no args.
%             mglTestTextureMultiple();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestTextureMultiple(false);
%
function mglTestTextureMultiple(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

% TODO: mglText() is broken under Apple Silicon.
return

%% How to:

% Create several textures, each showing a number.
textureCount = 10;
textureCell = cell(textureCount, 1);
mglTextSet('Helvetica', 32, [1 1 1 1], 1, 0, 0, 0, 0, 0, 0);
for ii = 1:textureCount
    textureCell{ii} = mglText(num2str(ii));
end
textures = [textureCell{:}];

% Choose positions along a diagonal.
x = linspace(-0.9, 0.9, textureCount);
y = linspace(-0.9, 0.9, textureCount);
position = [x' y'];

% Choose arbitrary alignments from the allowed values -1, 0, or 1.
hAlignment = mod(1:textureCount, 3) - 1;
vAlignment = circshift(hAlignment, 1);

% Choose arbitrary rotations in degrees.
rotation = linspace(0, 360, textureCount);

% Currently phase doesn't make sense with text, it slides rgb under alpha.
phase = 0;

% Wobble the sizes.
width = linspace(0.5, 1.5, textureCount) .* [textures.imageWidth] .* mglGetParam('xPixelsToDevice');
height = linspace(1.5, 0.5, textureCount) .* [textures.imageHeight] .* mglGetParam('yPixelsToDevice');

% Blt all the textures and per-texture parameters in one call.
disp('There should be several textures, each a different digit, each a different position, rotation, etc.');
mglBltTexture(textures, position, hAlignment, vAlignment, rotation, phase, width, height);

mglFlush();

for ii = 1:textureCount
    mglDeleteTexture(textures(ii));
end

if (isInteractive)
    mglPause();
end
