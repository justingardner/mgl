% mglTestMetalStencil: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalStencil(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some points.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalStencil();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalStencil(false);
%
function mglTestMetalStencil(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglSetParam('reuseMglMetal', 1);
    mglSetParam('reuseMglMetal', 0);
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglVisualAngleCoordinates(50, [20, 20]);
mglClearScreen(0.5);

% Stencil 1 hides everything except a circle on the left side of the screen.
mglStencilCreateBegin(1);
mglFillOval(-4, 0, [200, 200]);
mglStencilCreateEnd();

% Stencil 2 shows everything except a circle on the right side of the screen.
mglStencilCreateBegin(2, 1);
mglFillOval(4, 0, [200, 200]);
mglStencilCreateEnd();

% Stencil 3 is initialized to clear, hiding all regions.
mglStencilCreateBegin(3);
mglStencilCreateEnd();

disp('We should be able to select and un-select multiple stencils during one frame AKA "render pass".')

mglFillRect(0, -5, [150 150], [0 1 1]);
disp('No stencil: a cyan square near the bottom middle should appear since no stencil is selected yet.')

mglStencilSelect(1);
mglFillRect(-4, 0, [175 175], [1 0 0]);
disp('Stencil 1: a red square on the left should have its corners stenciled off.')

mglStencilSelect(0);
mglFillRect(0, 5, [150 150], [1 0 1]);
disp('Stencil 0: a magenta square near the top middle should appear since since stencil 0 means "no stencil".')

mglStencilSelect(2);
mglFillRect(4, 0, [175 175], [0 1 0]);
disp('Stencil 2: a green square on the right should have corners *only*, with all the rest stenciled out.')

mglStencilSelect(3);
mglFillRect(0, 0, [350 350], [1 1 1]);
disp('Stencil 3: a large white square in the middle should *not* appear since stencil 3 is all cleared out.')

mglFlush();

if (isInteractive)
    mglPause();
end
