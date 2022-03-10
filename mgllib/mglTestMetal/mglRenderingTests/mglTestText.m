% mglTestText: an automated and/or interactive test for rendering.
%
%      usage: mglTestText(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some text as an image.
%      usage:
%             % You can run it by hand with no args.
%             mglTestText();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestText(false);
%
function mglTestText(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Configure all mgl text settings to get consistent behavior.
mglTextSet('Helvetica', 32, [1 1 1 1], 1, 0, 30, 0, 1, 0, 0);

% Using those settings, render some text into an image/texture.
texture = mglText('Hello Text');
mglMetalBltTexture(texture);
disp('It should say "Hello Text", in white, at a fun and jaunty angle, centered in the window.')

mglFlush;

if (isInteractive)
    pause();
end
