% mglTestMetalRepeatingBlts: an automated and/or interactive test for rendering.
%
%      usage: mglTestMetalRepeatingBlts(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test lots of texture blts, repeated by the Metal app.
%      usage:
%             % You can run it by hand with no args.
%             mglTestMetalRepeatingBlts();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestMetalRepeatingBlts(false);
%
function mglTestMetalRepeatingBlts(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Create some arbitrary textures ahead of time.
% Set a consistent rng state so they come out the same each time.
rng(4242, 'twister');
nTextures = 5;
for ii = 1:nTextures
    textures(ii) = mglCreateTexture(rand(500, 500, 4));
end

% Blt those textures sequentually, frame by frame.
nFrames = 31;
mglMetalRepeatingBlts(nFrames);

% mglMetalRepeatingBlts should flush all on its own.
disp('Random noise textures should fill the screen.  The last texture should come out the same every time.');

if (isInteractive)
    mglPause();
end
