% mglTestGlassDots: an automated and/or interactive test for rendering.
%
%      usage: mglTestGlassDots(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering a whole bunch of dots.
%      usage:
%             % You can run it by hand with no args.
%             mglTestGlassDots();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestGlassDots(false);
%
function mglTestGlassDots(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglClearScreen(0.5);
disp('The background should be medium-gray.');

% Set a consistent rng state so that dots come out the same each time.
rng(4242, 'twister');

% Make a Glass pattern.
nDots = 1000;
r = rand(1,nDots);
theta = rand(1,nDots)*2*pi;
x = r.*cos(theta);
y = r.*sin(theta);
deltaTheta = pi*(2/180);
x(end+1:end+nDots) = r.*cos(theta+deltaTheta);
y(end+1:end+nDots) = r.*sin(theta+deltaTheta);

mglPoints2(x,y,0.01,[1 1 1]);
disp('There should be 1000 dots in a circular pattern (Glass) centered in the window.');

mglFlush();

if (isInteractive)
    mglFlush();
    input('Hit ENTER to test moving dots (fullscreen): ');
    mglMetalFullscreen;
    mglPause(0.5)

    nVertices = 1000;
    deltaR = 0.005;
    deltaTheta = 0.03;
    nFrames = 1000;
    r = 0.25*rand(1,nVertices)+0.01;
    theta = rand(1,nVertices)*2*pi;
    x = cos(theta).*r;
    y = sin(theta).*r;

    draws = cell(1, nFrames);
    flushes = cell(1, nFrames);
    for iFrame = 1:nFrames
        draws{iFrame} = mglPoints2(x,y,0.01,[1 1 1]);
        flushes{iFrame} = mglFlush();

        r = r + deltaR;
        theta = theta + deltaTheta;
        badpoints = find(r>0.75);
        r(badpoints) = 0.74*rand(1,length(badpoints))+0.01;
        x = cos(theta).*r;
        y = sin(theta).*r;
    end
    mglPlotCommandResults(flushes, draws, 'moving dots');
end
