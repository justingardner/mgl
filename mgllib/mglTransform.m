% mglTransform.m
%
%        $Id$
%      usage: currentMatrix = mglTransform(operation, value)
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
function currentMatrix = mglTransform(operation, value)

persistent mglTransformIsNotOpenGLAnymore
if isempty(mglTransformIsNotOpenGLAnymore)
    mglTransformIsNotOpenGLAnymore = true;
    fprintf("(mglTransform) Notice: mglTransform no longer supports OpenGL transforms and constants.\n")
end

global mgl
switch operation
    case 'get'
        currentMatrix = mgl.currentMatrix;
        return;
    case 'set'
        mgl.currentMatrix = value;
    case 'scale'
        newMatrix = eye(4);
        newMatrix([1,6,11]) = value;
        mgl.currentMatrix = mgl.currentMatrix * newMatrix;
    case 'translate'
        newMatrix = eye(4);
        newMatrix([13,14,15]) = value;
        mgl.currentMatrix = mgl.currentMatrix * newMatrix;
end
currentMatrix = mgl.currentMatrix;

mglSocketWrite(mgl.s, mgl.command.mglSetXform);
mglSocketWrite(mgl.s, single(mgl.currentMatrix));
