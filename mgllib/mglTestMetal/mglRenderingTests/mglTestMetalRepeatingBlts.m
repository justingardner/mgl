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
textures = cell(1, nTextures);
for ii = 1:nTextures
    % Choose "nearest" sample filtering and "repeat" address mode.
    texture = mglCreateTexture(rand(500, 500, 4));
    texture.minMagFilter = 0;
    texture.mipFilter = 1;
    texture.addressMode = 2;
    textures{ii} = texture;
end

% Enqueue blits of the textures sequentually, frame by frame.
nFrames = 32;
mglMetalStartBatch();
for ii = 1 + mod(0:nFrames-1, nTextures)
    mglBltTexture(textures{ii}, [0 0 2 2]);
    mglFlush();
end

% Start processing the commands as fast as possible.
mglMetalProcessBatch();
disp('Mgl Metal is repeating blt and flush commands asynchronously.');

% Wait for the commands to finish and gather the timing results.
results = mglMetalFinishBatch();
assert(numel(results) == 2 * nFrames, 'Number of batched command results must equal number of batched commands.');

disp('Random noise textures should fill the screen.  The last texture should come out the same every time.');

if (isInteractive)
    mglPause();
end
