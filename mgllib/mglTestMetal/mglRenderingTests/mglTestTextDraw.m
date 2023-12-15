% mglTestTextDraw: an automated and/or interactive test for rendering.
%
%      usage: mglTestTextDraw(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some text as an image.
%      usage:
%             % You can run it by hand with no args.
%             mglTestTextDraw();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestTextDraw(false);
%
function mglTestTextDraw(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Configure all mgl text settings to get consistent behavior.
mglTextSet('Helvetica', 32, [1 1 1 1], 0, 0, 0, 0, 1, 0, 0);

% mglTestTextDraw() is a utility to create, blt, and delete a texture with
% some written text, all in one command, for convenience.
% It does texture management commands create and delete mixed with the
% drawing command blt, along with any other drawing commands on the same
% frame.  Test that commands that are "out of order" from a performance
% point of view are nevertheless workable.
mglFillRect(-0.5, 0.5, [1, 2/3], [0.25 0 0]);
mglTextDraw('Top Left', [-0.5, 0.5]);
disp('There should be text in a red box in the top left.')

mglFillRect(0, 0, [1, 2/3], [0 0.25 0]);
mglTextDraw('mglTestTextDraw!', [0, 0]);
disp('There should be text in a green box in the center.')

mglFillRect(0.5, -0.5, [1, 2/3], [0 0 0.25]);
mglTextDraw('Bottom Right', [0.5, -0.5]);
disp('There should be text in a blue box in the bottom right.')

mglFlush;

if (isInteractive)
    mglPause();
end
