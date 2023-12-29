% mglFigureText.m
%
%      usage: textImage = mglFigureText(textString)
%         by: Benjamin heasly
%       date: 12/15/2023
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Render the given textString to an image.
%      usage: textImage = mglFigureText(textString)
%
%             Returns textImage, a single float image matrix with size
%             [height, width, 4], where the 4 slices are RGBA.
%
%             This is a workaround / placeholder!
%
%             Usually MGL renders text to bitmaps (and then textures) using
%             Apple's ATSUI API.  As of macOS 14 Sonoma, the ATSUI APIis no
%             longer supported.  Calling the API causes Matlab to exit with
%             a Mac system error dialog:
%               This version of "MATLAB" is not compatible with macOS 14 or
%               later and needs to be updated.
%
%             This is "expected", in the sense of being mentioned in the
%             macOS 14 Sonoma release notes here:
%               https://developer.apple.com/documentation/macos-release-notes/macos-14-release-notes#ATS-and-ATSUI
%
%             The intended sense of "needs to be updated" is probably to
%             migrate text rendering from ATSUI to Core Text, which is
%             newer and apparently comparable accodring to this overview:
%               https://developer.apple.com/library/archive/documentation/TextFonts/Conceptual/CocoaTextArchitecture/UsingCoreText/UsingCoreText.html
%
%             Migrating seems doable and resasonable but would be a small
%             project. Meanwhile, this funciton is a pure Matlab workaround
%             that abuses Matlab figure text rendering and scrapes out the
%             results into an image matrix.  It's probably quite slow.
%
% Pure Matlab example:
%   mglTextSet('Helvetica',32,[1 1 1],0,0,0);
%   textImage = mglFigureText("Hellog Text!");
%   imshow(textImage(:,:,1:3));
%
% Metal texture example:
%   mglOpen();
%   mglVisualAngleCoordinates(57,[16 12]);
%   mglTextSet('Helvetica',16,[1 1 1],0,0,0);
%   textImage = mglFigureText("Hellog Text!");
%   metalTexture = mglCreateTexture(textImage);
%   mglBltTexture(metalTexture);
%   mglFlush();
function textImage = mglFigureText(textString)

%% Set up Matlab figure rendering objects.
% White text on black background makes it easier to trip edges.
fig = figure( ...
    'Units', 'pixels', ...
    'Color', [0, 0, 0], ...
    'Visible', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none');
closeFigure = onCleanup(@()close(fig));

ax = axes( ...
    'Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1], ...
    'Visible', 'off');

txt = text( ...
    'Parent', ax, ...
    'Units', 'pixels', ...
    'Position', [0 0], ...
    'Interpreter', 'none', ...
    'String', textString, ...
    'FontUnits', 'points', ...
    'ColorMode', 'manual', ...
    'Color', [1, 1, 1], ...
    'EdgeColor', 'none', ...
    'BackgroundColor', 'none', ...
    'LineStyle', 'none', ...
    'Margin', 1, ...
    'Clipping', 'off');

%% Map our mglTextSet() properties onto Matlab counterparts.
fontName = mglGetParam('fontName');
if ~isempty(fontName)
    set(txt, 'FontName', fontName);
end

fontSize = mglGetParam('fontSize');
if ~isempty(fontSize)
    % judging by eye from mgl rendering tests,
    % it seems Matlab's fontSize is twice what mgl expects.
    set(txt, 'FontSize', fontSize / 2);
end

fontBold = mglGetParam('fontBold');
if ~isempty(fontBold) && fontBold
    set(txt, 'FontWeight', 'bold');
end

fontItalic = mglGetParam('fontItalic');
if ~isempty(fontItalic) && fontItalic
    set(txt, 'FontAngle', 'italic');
end

fontRotation = mglGetParam('fontRotation');
if ~isempty(fontRotation)
    set(txt, 'Rotation', fontRotation);
end

%% Let Matlab render into the figure.
drawnow()

%% Scrape out the rendered text from the figure axes.

% Resize figure and move text so the text fits in the figure/axes.
% This doesn't need to be exact, the text just needs to fit within.
% Adding a margin of 1 pixel just seems to make it look right.
renderedWidth = txt.Extent(3);
renderedHeight = txt.Extent(4);
fig.Position = [0 0 renderedWidth renderedHeight] * 2;
txt.Position = [1 1] + [renderedWidth renderedHeight] / 2;

% Matlab built-in utils convert axes contents to image matrix.
% Adding a margin of 1 pixel just seems to make it look right.
frame = getframe(ax, txt.Extent + [-1 -1 2 2]);
whiteImage = single(frame2im(frame));

% Trim extra margin around the rendered text (Matlab forces margin > 0).
[rows, cols] = find(whiteImage(:,:,1));
trimmedMask = whiteImage(min(rows):max(rows), min(cols):max(cols), 1);

%% Fill out a full RGBA image to use.
fontColor = mglGetParam('fontColor');
if isempty(fontColor)
    fontColor = [1 1 1 1];
end
if numel(fontColor) < 4
    fontColor(4) = 1;
end

% Expand the two-color trimmed mask into the specified RGBA color.
textImage = cat(3, ...
    trimmedMask * fontColor(1), ...
    trimmedMask * fontColor(2), ...
    trimmedMask * fontColor(3), ...
    trimmedMask * fontColor(4));
