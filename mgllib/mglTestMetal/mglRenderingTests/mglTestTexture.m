% mglTestTexture: an automated and/or interactive test for rendering.
%
%      usage: mglTestTexture(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering a smoothly varying texture.
%      usage:
%             % You can run it by hand with no args.
%             mglTestTexture();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestTexture(false);
%
function mglTestTexture(isInteractive)

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

% Create a smoothly varying texture.
textureWidth = 256;
textureHeight = 256;
maxVal = 1.0;
sigma = 0.5;
[tx ty] = meshgrid(0:2*pi/(textureWidth-1):2*pi,0:2*pi/(textureHeight-1):2*pi);
[ex ey] = meshgrid(-1:2/(textureWidth-1):1,-1:2/(textureHeight-1):1);
sf = 6;
texture(:,:,1) = maxVal*(cos(sf*ty+pi/4)+1)/2;
texture(:,:,2) = maxVal*(cos(sf*ty+pi/4)+1)/2;
texture(:,:,3) = maxVal*(cos(sf*ty+pi/4)+1)/2;
texture(:,:,4) = maxVal*(exp(-((ex.^2+ey.^2)/sigma^2)));

tex = mglMetalCreateTexture(texture);
mglMetalBltTexture(tex);
disp('There should be a smoothly varying gray texture (Gabor) in the center.');

mglFlush();

if (isInteractive)
    input('Hit ENTER to test blt with drifting phase (fullscreen): ');
    mglFlush();
    mglMetalFullscreen();
    pause(0.5);

    nFrames = 300;
    frameTimes = zeros(1,nFrames);
    phase = 0;
    for iFrame = 1:nFrames
        mglMetalBltTexture(tex,[0 0],0,0,0,phase);
        phase = phase + (1/60)/4;
        [~, frameTimes(iFrame)] = mglFlush();
    end
    mglMetalFullscreen(false);
    mglPlotFrameTimes(frameTimes)

    input('Hit ENTER to test multiple blt with rotation and drifting phase (fullscreen): ');
    mglFlush();
    mglMetalFullscreen();
    pause(0.5);

    nFrames = 300;
    frameTimes = zeros(1,nFrames);
    phase = 0;rotation = 0;width = 0.25;height = 0.25;
    for iFrame = 1:nFrames
        mglMetalBltTexture(tex,[-0.5 -0.5],0,0,rotation,phase,width,height);
        mglMetalBltTexture(tex,[-0.5 0.5],0,0,-rotation,phase,width,height);
        mglMetalBltTexture(tex,[0.5 0.5],0,0,rotation,phase,width,height);
        mglMetalBltTexture(tex,[0.5 -0.5],0,0,-rotation,phase,width,height);
        mglMetalBltTexture(tex,[0 -0.5],0,0,rotation,phase,width,height);
        mglMetalBltTexture(tex,[0 0.5],0,0,-rotation,phase,width,height);
        mglMetalBltTexture(tex,[-0.5 0],0,0,rotation,phase,width,height);
        mglMetalBltTexture(tex,[0.5 0],0,0,-rotation,phase,width,height);

        mglMetalBltTexture(tex,[0 0],1,-1,rotation,phase,width,height);
        mglMetalBltTexture(tex,[0 0],1,1,rotation,phase,width,height);
        mglMetalBltTexture(tex,[0 0],-1,-1,rotation,phase,width,height);
        mglMetalBltTexture(tex,[0 0],-1,1,rotation,phase,width,height);

        phase = phase + (1/60)/4;
        rotation = rotation+360/nFrames;
        [~, frameTimes(iFrame)] = mglFlush();
    end
    mglMetalFullscreen(false);
    mglPlotFrameTimes(frameTimes)
end
