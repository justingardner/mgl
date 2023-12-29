% mglTestTextureOddSizes: an automated and/or interactive test for rendering.
%
%      usage: mglTestTextureOddSizes(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering some text as an image.
%      usage:
%             % You can run it by hand with no args.
%             mglTestTextureOddSizes();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestTextureOddSizes(false);
%
function mglTestTextureOddSizes(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

mglScreenCoordinates();

% Create oddly sized textures to flush out issues with byte alignment etc.
% For simplicity, choose nearest-neighbor filtering and no wrapping.

% An image shorter than it is wide.
w = 17;
h = 13;
shortImage = ones(h, w, 4, 'single') * 0.5;
shortImage(:,:,4) = 1.0;
shortImage(1,:,1:3) = 1.0;
shortImage(end,:,1:3) = 1.0;
shortImage(:,1,1:3) = 1.0;
shortImage(:,end,1:3) = 1.0;

shortTexture = mglMetalCreateTexture(shortImage, 0, 1, 0);
x = cumsum([w/2+1, w/2+w+1, w+2.5*w+1, 2.5*w+5*w+1]);
y = [h/2+1, h+1, 2.5*h+1, 5*h+1];
mglBltTexture(shortTexture, [x(1), y(1), w, h]);
mglBltTexture(shortTexture, [x(2), y(2), 2*w, 2*h]);
mglBltTexture(shortTexture, [x(3), y(3), 5*w, 5*h]);
mglBltTexture(shortTexture, [x(4), y(4), 10*w, 10*h]);
disp('There should 4 short gray boxes at different scales, bottom-aligned, with one pixel spacing.')

% An image taller than it is wide.
w = 11;
h = 31;
tallImage = ones(h, w, 4, 'single') * 0.5;
tallImage(:,:,4) = 1.0;
tallImage(1,:,1:3) = 1.0;
tallImage(end,:,1:3) = 1.0;
tallImage(:,1,1:3) = 1.0;
tallImage(:,end,1:3) = 1.0;

tallTexture = mglMetalCreateTexture(tallImage, 0, 1, 0);
x = cumsum([w/2+1, w/2+w+1, w+2.5*w+1, 2.5*w+5*w+1]);
y = 200 + [h/2+1, h+1, 2.5*h+1, 5*h+1];
mglBltTexture(tallTexture, [x(1), y(1), w, h]);
mglBltTexture(tallTexture, [x(2), y(2), 2*w, 2*h]);
mglBltTexture(tallTexture, [x(3), y(3), 5*w, 5*h]);
mglBltTexture(tallTexture, [x(4), y(4), 10*w, 10*h]);
disp('There should 4 tall gray boxes at different scales, bottom-aligned, with one pixel spacing.')

mglFlush();

if (isInteractive)
    mglPause();
end
