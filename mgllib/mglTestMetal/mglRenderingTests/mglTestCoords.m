% mglTestCoords: an automated and/or interactive test for rendering.
%
%      usage: mglTestCoords(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test changing the coordinate transform within a frame.
%      usage:
%             % You can run it by hand with no args.
%             mglTestCoords();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestCoords(false);
%
function mglTestCoords(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:


% Set up an arbitrary, known coordinate transform.
xform = eye(4);
xform(:,4) = [-0.2 0.2 0 1];
mglTransform('set', xform);

% Draw some points in a triangle arrangement.
x = [0 -0.5 0.5];
y = [0.5 -0.5 -0.5];
mglPoints2(x, y, 30, [1 1 1]);
disp('There should be 3 white squares in a triangle arrangement.')

% Pick a different, known coordinate transform.
xform = eye(4);
mglTransform('set', xform);

% Re-draw the same arrangement, this time offset from before.
mglPoints2(x, y, 20, [0 1 1], true);
disp('There should be 3 cyan circles in the same arrangement -- NOT on top of the squares.')

mglFlush;

if (isInteractive)
    mglPause();
end
