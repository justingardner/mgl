% mglTestQuads: an automated and/or interactive test for rendering.
%
%      usage: mglTestQuads(isInteractive)
%         by: Benjamin Heasly
%       date: 03/10/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Test rendering a checkerboard.
%      usage:
%             % You can run it by hand with no args.
%             mglTestQuads();
%
%             % Or mglRunRenderingTests can run it, in non-interactive mode.
%             mglTestQuads(false);
%
function mglTestQuads(isInteractive)

if nargin < 1
    isInteractive = true;
end

if (isInteractive)
    mglOpen();
    cleanup = onCleanup(@() mglClose());
end

%% How to:

% Create a black and white checkerboard grid.
xWidth = 0.1;
yWidth = 0.1;
iQuad = 1;
c = 0;
for xStart = -1:xWidth:(1-xWidth)
    c = 1-c;
    for yStart = -1:yWidth:(1-xWidth)
        c = c-(1*c)+(1-c);
        x(1:4, iQuad) = [xStart xStart+xWidth xStart+xWidth xStart];
        y(1:4, iQuad) = [yStart yStart yStart+xWidth yStart+xWidth];
        color(1:3, iQuad) = [c c c];
        inverseColor(1:3, iQuad) = [1-c 1-c 1-c];
        iQuad = iQuad + 1;
    end
end

mglQuad(x,y,color);
disp('The window should be filled with 100 regular black and white checkers.')

mglFlush;

if (isInteractive)
    input('Hit ENTER to flicker: ');

    % Animate the checkers in a flickering pattern.
    nFlicker = 10;
    nFlush = 10;
    resultCell = cell(1, nFlicker + nFlush + nFlush);
    iFrame = 1;
    for iFlicker = 1:nFlicker
        % Draw several frames of regular color.
        for iFlush = 1:nFlush
            mglQuad(x,y,color);
            resultCell{iFrame} = mglFlush();
            iFrame = iFrame + 1;
        end

        % Draw several frames of alternate color.
        for iFlush = 1:nFlush
            % draw the quads
            mglQuad(x,y,inverseColor);
            resultCell{iFrame} = mglFlush();
            iFrame = iFrame + 1;
        end
    end
    results = [resultCell{:}];
    mglPlotFrameTimes(results, 'Flickering quads');
end
