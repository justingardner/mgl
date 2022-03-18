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
textureWidth = 256;
textureHeight = 256;
blankImage = ones([textureHeight, textureWidth, 4], 'single');
tex = mglMetalCreateTexture(blankImage);

% Update the texture with a new, more interesting image.
x = linspace(0, 1, textureWidth);
y = linspace(0, 1, textureHeight);
gradient= y'*x;
newImage = ones([textureHeight, textureWidth, 4], 'single');
newImage(:,:,1) = gradient;
newImage(:,:,2) = flipud(gradient);
newImage(:,:,3) = fliplr(gradient);
mglUpdateTexture(tex, newImage);
mglBltTexture(tex);
disp('A texture with a smooth rainbow gradient should appear -- it should not be blank.');

mglFlush();

% Delete will have little effect, since we're about to mglClose().
% But it's still good to exercise the code.
mglDeleteTexture(tex);

if (isInteractive)
    pause();
end
