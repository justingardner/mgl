% mglTestUpdateTexture: an automated and/or interactive test for rendering.
%
%      usage: mglTestUpdateTexture(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering a smoothly varying texture.
%      usage:
%             % You can run it by hand with no args.
%             mglTestUpdateTexture();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestUpdateTexture(false);
%
function mglTestUpdateTexture(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Create a blank texture to start with.
textureWidth = 640;
textureHeight = 480;
blankImage = ones([textureHeight, textureWidth, 4], 'single');
tex = mglMetalCreateTexture(blankImage, 0, 1, 0);

% Update the texture with a new, more interesting image.
x = linspace(0, 1, textureWidth);
y = linspace(0, 1, textureHeight);
gradient= y'*x;
newImage = ones([textureHeight, textureWidth, 4], 'single');
newImage(:,:,1) = gradient;
newImage(:,:,2) = flipud(gradient);
newImage(:,:,3) = fliplr(gradient);
mglUpdateTexture(tex, newImage);
mglMetalBltTexture(tex,[0 0],0,0,0,0,2,2);
disp('A texture with a smooth rainbow gradient should appear -- it should not be blank.');

mglFlush();

if (isInteractive)
    input('Hit ENTER to test frame-by-frame texture updates (fullscreen): ');
    mglMetalFullscreen();
    mglPause(0.5);
    mglFlush();

    nFrames = 300;
    draws = cell(1, nFrames);
    flushes = cell(1, nFrames);
    shiftedImage = newImage;
    for iFrame = 1:nFrames
        shiftedImage(:,:,1) = circshift(shiftedImage(:,:,1), 1);
        shiftedImage(:,:,2) = circshift(shiftedImage(:,:,2), 1);
        shiftedImage(:,:,3) = circshift(shiftedImage(:,:,3), 1);
        draws{iFrame} = mglUpdateTexture(tex, shiftedImage);
        mglMetalBltTexture(tex,[0 0],0,0,0,0,2,2);
        flushes{iFrame} = mglFlush();
    end
    name = sprintf('frame-by-frame texture updates %d x %d', textureWidth, textureHeight);
    mglPlotCommandResults(flushes, draws, name);
end

% Delete will have little effect, since we're about to mglClose().
% But it's still good to exercise the code.
mglDeleteTexture(tex);
