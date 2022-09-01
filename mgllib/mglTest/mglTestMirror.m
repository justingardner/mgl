% mglTestMirror.m
%
%        $Id: mglTestMirror.m
%      usage: mglTestMirror()
%         by: ben heasly
%       date: 09/01/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Demonstrate usage of "mirror mode" graphics windows.
%
%             This script demos mgl "mirror mode" functionality which
%             allows multiple simultaneous drawing windows via the
%             functions mglMirrorOpen and mglMirrorActivate.
% 
%             mglMirrorOpen lets you open additional "mirror" drawing
%             windows, after the primary window is opened with mglOpen.
%             Each mirror window can be assigned to its own physical 
%             display and have its own fullscreen/windowed state.  By
%             default each mirror will receive a copy of mgl drawing
%             commands that are sent to the primary window, so that the
%             same graphics will appear on the primary and the mirrors, at
%             approximately the same time.
%
%             mglMirrorActivate lets you manage which windows will receive
%             drawing commands -- the primary window and/or one or more
%             mirror windows.  This allows some windows to show extra
%             graphics in addition to the mirrored graphics.
%
%             This demo uses mglOpen and mglMirrorOpen to show the same
%             stimulus in two different windows at the same time.  The idea
%             is that the primary window might be presented fullscreen to a
%             study participant, while a mirror window might be shown to
%             a study operator behind the scenes.  This demo uses
%             mglMirrorActivate to overlay a mock point of gaze indicator
%             on top of the stimulus, on the operator's mirror window only.
%
function mglTestMirror()

% Prefer to open the primary, participant graphics window in fullscreen on
% a secondary display.  If none is available, open in a big window.
displayInfo = mglDescribeDisplays();
if numel(displayInfo) == 1
    % Open a big window for the participant.
    mglOpen(0, 1024, 768);
else
    % Open a fullscreen window for the participant, on the last display.
    mglOpen();
end

% Open a small "mirror" window for the operator.
mglMirrorOpen(0, 1200, 100, 640, 480);

% The mirror will share context info with the primiary window, like
% coordinate transform, pixels per degree, etc.  If the mirror window has a
% different physical size, it should appear as a scaled version of the
% participant's window.
mglVisualAngleCoordinates(57,[16 12]);

% By default, drawing and related commands will affect both windows.
mglClearScreen([0.5 0.5 0.5]);
mglFlush();

mglWaitSecs(1);

% Create a Gabor stimulus for the participant.
textureWidth = 256;
textureHeight = 256;
sigma = 0.5;
[tx, ty] = meshgrid(0:2*pi/(textureWidth-1):2*pi,0:2*pi/(textureHeight-1):2*pi);
[ex, ey] = meshgrid(-1:2/(textureWidth-1):1,-1:2/(textureHeight-1):1);
sf = 6;
textureImage(:,:,1) = (cos(sf*ty+pi/4)+1)/2;
textureImage(:,:,2) = (cos(sf*ty+pi/4)+1)/2;
textureImage(:,:,3) = (cos(sf*ty+pi/4)+1)/2;
textureImage(:,:,4) = (exp(-((ex.^2+ey.^2)/sigma^2)));

% The primary and mirror each will load the same image data into a texture.
% The return value tex will contain both, but we only need the first one.
tex = mglMetalCreateTexture(textureImage);
primaryTex = tex(1);

% The primary and mirror each can blt and show the same texture.
mglMetalBltTexture(primaryTex);
mglFlush();

mglWaitSecs(1);

% Create a sequence of mock gaze positions, as if the participant were
% looking around.
gazeX = cat(2, 6*ones([1, 200]), linspace(6, 0, 50), zeros([1, 200]));
gazeY = cat(2, 3*ones([1, 200]), linspace(3, 0, 50), zeros([1, 200]));

% Animate the stimulus and overlay the mock gaze position for the operator.
refreshRate = displayInfo(1).refreshRate;
for ii = 1:numel(gazeX)
    % Activate primary and mirror both, for the stimulus.
    mglMirrorActivate();
    phase = ii / refreshRate;
    mglMetalBltTexture(primaryTex, [], [], [], [], phase);

    % Just for fun, add wobble to the gaze position.
    wobbX = 0.2 * sin(6 * pi * ii / refreshRate);
    wobbY = 0.2 * cos(6 * pi * ii / refreshRate);

    % Activate the mirror window only, to overlay the gaze position.
    % Passing index 1 activates the first mirror only.
    % Passing 0 would activate the primary window only.
    mglMirrorActivate(1);
    mglPoints2(gazeX(ii) + wobbX, gazeY(ii) + wobbY, 0.3, [1 0 0], true);

    % Activate primary and mirror both, to flush the frame.
    mglMirrorActivate();
    mglFlush();
end

% Close will close all known windows, the primary and any mirrors.
% "clear all" would do the same.
mglClose();
