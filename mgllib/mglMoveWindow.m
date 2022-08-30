% mglMoveWindow.m
%
%        $Id$
%      usage: mglMoveWindow(leftPos, topPos, socketInfo)
%         by: Christopher Broussard
%       date: 10/23/07
%    purpose: Moves the current AGL window with the left edge of the window
%	      at 'leftPos', the top edge at 'topPos'.
%
%            % move the primary window
%            mglOpen(0);
%            mglMoveWindow(100, 100);
%
%            % move a mirrored window
%            % (only the first element of socketInfo is used)
%            mglOpen(0);
%            socketInfo = mglMirrorOpen(0);
%            mglMoveWindow(100, 100, socketInfo);
%
function mglMoveWindow(leftPos, topPos, socketInfo)

if nargin < 2 || nargin > 3
    help mglMoveWindow
    return
end

if ~isscalar(leftPos) || ~isscalar(topPos)
    help mglMoveWindow
    return
end

global mgl
if nargin < 3 || isempty(socketInfo)
    socketInfo = mgl.s;
end

if numel(socketInfo) > 0
    fprintf('(mglMoveWindow) Using only the first of %d elements of socketInfo\n', numel(socketInfo));
    socketInfo = socketInfo(1);
end

% Get the current window position.
[displayNumber, rect] = mglMetalGetWindowFrameInDisplay(socketInfo);

% Modify the position of the rect.
rect(1) = leftPos;
rect(2) = topPos - rect(4);
mglMetalSetWindowFrameInDisplay(displayNumber, rect, socketInfo);

% Only update the mgl context from the primary window.
if isfield(mgl, 's') && isequal(socketInfo, mgl.s)
    [displayNumber, rect] = mglMetalGetWindowFrameInDisplay(socketInfo);
    mglSetParam('displayNumber', displayNumber);

    deviceWidth = mglGetParam('deviceWidth');
    deviceHeight = mglGetParam('deviceHeight');
    mglSetParam('screenWidth', rect(3));
    mglSetParam('screenHeight', rect(4));
    mglSetParam('xPixelsToDevice', deviceWidth / rect(3));
    mglSetParam('yPixelsToDevice', deviceHeight / rect(4));
    mglSetParam('xDeviceToPixels', rect(3) / deviceWidth);
    mglSetParam('yDeviceToPixels', rect(4)/ deviceHeight);
    mglSetParam('deviceRect', [rect(1), rect(2), rect(1)+rect(3), rect(2)+rect(4)]);
end
