% mglMetalGetWindowFrameInDisplay.m
%
%      usage: [displayNumber, rect, results] = mglMetalGetWindowFrameInDisplay(socketInfo)
%         by: Benjamin Heasly
%       date: 03/11/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Returns current mgl displayNumber and window frame rectangle.
%
%             % Get info for the primary window
%             mglOpen(0);
%             [displayNumber, rect] = mglMetalGetWindowFrameInDisplay()
%
%             % Get info a mirrored window, by index
%             % mglOpen(0);
%             % socketInfo = mglMirrorOpen(0);
%             [displayNumber, rect] = mglMetalGetWindowFrameInDisplay(socketInfo)
%
function [displayNumber, rect, results] = mglMetalGetWindowFrameInDisplay(socketInfo)

global mgl
if nargin < 1 || isempty(socketInfo)
    socketInfo = mgl.activeSockets;
end

% Request window info from all the given sockets.
mglSocketWrite(socketInfo, socketInfo(1).command.mglGetWindowFrameInDisplay);
ackTime = mglSocketRead(socketInfo, 'double');

% Check if the command was processed OK or with error, for each socket.
responseIncoming = mglSocketRead(socketInfo, 'double');
resultCell = cell([1, numel(socketInfo)]);
displayNumber = zeros([1, numel(socketInfo)]);
x = zeros([1, numel(socketInfo)]);
y = zeros([1, numel(socketInfo)]);
width = zeros([1, numel(socketInfo)]);
height = zeros([1, numel(socketInfo)]);
rect = zeros(numel(socketInfo), 4);
for ii = 1:numel(socketInfo)
    if (responseIncoming(ii) < 0)
        % This socket shows an error processing the command.
        resultCell{ii} = mglReadCommandResults(socketInfo(ii), ackTime(1, 1, 1, ii));
        fprintf('(mglMetalGetWindowFrameInDisplay) Error getting Metal window and display info, you might try again with Console running, or: log stream --level info --process mglMetal\n');
    else
        % This socket shows processing was OK, read the response.
        displayNumber(ii) = mglSocketRead(socketInfo(ii), 'uint32');
        x = mglSocketRead(socketInfo(ii), 'uint32');
        y = mglSocketRead(socketInfo(ii), 'uint32');
        width = mglSocketRead(socketInfo(ii), 'uint32');
        height = mglSocketRead(socketInfo(ii), 'uint32');
        resultCell{ii} = mglReadCommandResults(socketInfo(ii), ackTime(1, 1, 1, ii));
        rect(ii,:) = [x, y, width, height];
    end

    % Only update the mgl context from the primary window.
    if isequal(socketInfo(ii), mgl.s)
        mglSetParam('displayNumber', displayNumber);
        mglSetParam('screenX', x);
        mglSetParam('screenY', y);
        mglSetParam('screenWidth', width);
        mglSetParam('screenHeight', height);
    end
end
results = [resultCell{:}];
