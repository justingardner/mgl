% mglTestContextStash.m
%
%        $Id: mglTestContextStash.m
%      usage: mglTestContextStash()
%         by: ben heasly
%       date: 09/07/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Demonstrate how to stash and reactivate mgl contexts.
%
%             This script demos how to stash and reactivate the mgl state
%             and config, also known as the mgl "context".  Doing this sets
%             aside the context data normally stored in "global mgl", to
%             another location.  While stashed, a context becomes inactive,
%             although is its system resources and drawing windows remain
%             intact.  When activated, a context is can be used as
%             normal.  By stashing and activating contexts, multiple
%             instances of mgl can be controlled from one Matlab session.
%
%             The mgl contexts can be managed with four functions:
%              - mglContextStash -- inactivate the active context in "global mgl"
%              - mglContextList -- list known contexts, active and stashed
%              - mglContextActivate -- reactivate a context that was previously stashed
%              - mglContextCloseAll -- close known contexts, active and stashed
%
%             This demo uses stashing to manage two separate mgl contexts
%             named "left" and "right", as if they were being used to
%             present dichoptic stimuli.  Each context has full,
%             independent control over things like coordinate transform,
%             pixels per degree, etc, and drawing commands affect only one
%             context at a time.  This way, the dichoptic presentation
%             would be able to treat each eye independently.
function mglTestContextStash()

% Open two independent, windowded mgl contexts.
% These could just as easily be fullscreen, but that would make the demo
% less portable.

% Left eye context, stashed under the name "left".
mglOpen(0, 800, 600);
mglClearScreen([0.5 0.5 0.5]);
mglVisualAngleCoordinates(57,[16 12]);

% Transform the left context "nasally" to the right.
mglTransform('translate', [2, 0 0]);
mglFlush();

mglContextStash('left');

% Right eye context, stashed under the name "right".
mglOpen(0, 800, 600);
mglMoveWindow(900, 700);
mglClearScreen([0.5 0.5 0.5]);
mglVisualAngleCoordinates(57,[16 12]);

% Transform the right context "nasally" to the left.
mglTransform('translate', [-2, 0 0]);
mglFlush();

mglContextStash('right');

mglWaitSecs(1);

% Create a Gabor image to show in each context.
textureWidth = 512;
textureHeight = 512;
sigma = 0.5;
[tx, ty] = meshgrid(0:2*pi/(textureWidth-1):2*pi,0:2*pi/(textureHeight-1):2*pi);
[ex, ey] = meshgrid(-1:2/(textureWidth-1):1,-1:2/(textureHeight-1):1);
sf = 6;
textureImage(:,:,1) = (cos(sf*tx+pi/4)+1)/2;
textureImage(:,:,2) = (cos(sf*tx+pi/4)+1)/2;
textureImage(:,:,3) = (cos(sf*tx+pi/4)+1)/2;
textureImage(:,:,4) = (exp(-((ex.^2+ey.^2)/sigma^2)));

% Create the stimulus texture in the left context.
mglContextActivate('left');
leftTex = mglMetalCreateTexture(textureImage);
mglMetalBltTexture(leftTex);
mglFlush();

mglWaitSecs(1);

% Create the stimulus texture in the right context.
mglContextActivate('right');
rightTex = mglMetalCreateTexture(textureImage);
mglMetalBltTexture(rightTex, [], [], [], 2);
mglFlush();

mglWaitSecs(1);

% Animate the stimulus in each context, independently.
displayInfo = mglDescribeDisplays();
refreshRate = displayInfo(1).refreshRate;
for ii = 1:500
    phase = ii / refreshRate;

    % Draw in the left context.
    mglContextActivate('left');
    mglMetalBltTexture(leftTex, [], [], [], [], phase);
    mglFlush();

    % Draw in the right context, slightly rotated just to be different.
    mglContextActivate('right');
    mglMetalBltTexture(rightTex, [], [], [], 2, phase);
    mglFlush();
end

% mglContextCloseAll will close all known contexts, active and stashed.
% "clear all" would do roughly the same.
mglContextCloseAll();
