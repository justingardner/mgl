%        $Id$
%      usage: [currentMatrix, ackTime, processedTime] = mglTransform(operation, value, socketInfo)
%         by: Ben Heasly
%       date: 2021-12-03
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: applies view transformations
%  arguments: operation: 'get', 'set', 'scale', 'translate'
%             value: 4x4 matrix or xyz vector, if required.
%             returns: the final 4x4 matrix value that was applied
%
%             Here are some examples:
%               currentMatrix = mglTransform('get');
%               currentMatrix = mglTransform('set', eye(4));
%               currentMatrix = mglTransform('scale', [2, 2, 1]);
%               currentMatrix = mglTransform('translate', [-100, -100, 0]);
%
%             This function is usually not called directly, but
%             called by mglVisualAngleCoordinates or
%             mglScreenCoordinates to set the transforms
function [currentMatrix, ackTime, processedTime] = mglTransform(operation, value, socketInfo)

ackTime = [];
processedTime = [];

persistent mglTransformIsNotOpenGLAnymore
if isempty(mglTransformIsNotOpenGLAnymore)
    mglTransformIsNotOpenGLAnymore = true;
    fprintf("(mglTransform) Notice: mglTransform no longer supports OpenGL transforms and constants.\n")
end

global mgl
if nargin < 3
    socketInfo = mgl.s;
end

switch operation
    case 'get'
        currentMatrix = mgl.currentMatrix;
        return;
    case 'set'
        currentMatrix = value;
    case 'scale'
        newMatrix = eye(4);
        newMatrix([1,6,11]) = value;
        currentMatrix = mgl.currentMatrix * newMatrix;
    case 'translate'
        newMatrix = eye(4);
        newMatrix([13,14,15]) = value;
        currentMatrix = mgl.currentMatrix * newMatrix;
end

% Only update the mgl context from the primary window.
if isequal(socketInfo, mgl.s)
    mgl.currentMatrix = currentMatrix;
end

% Always update the mglMetal process with the new matrix.
mglSocketWrite(socketInfo, socketInfo.command.mglSetXform);
ackTime = mglSocketRead(socketInfo, 'double');
mglSocketWrite(socketInfo, single(mgl.currentMatrix));
processedTime = mglSocketRead(socketInfo, 'double');
