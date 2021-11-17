% mglTransform.m
%
%        $Id$
%      usage: mglTransform(whichMatrix, whichTransform, [whichParameters])
%         by: Jonas Larsson
%       date: 2006-04-07
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: applies view transformations
%  arguments: whichMatrix: 'GL_MODELVIEW', 'GL_PROJECTION', or 'GL_TEXTURE'
%             whichTransform:  'glRotate', 'glTranslate', 'glScale',
%                              'glMultMatrix', 'glFrustum', 'glOrtho',
%                              'glLoadMatrix', 'glLoadIdentity', 'glPushMatrix',
%                              'glPopMatrix', 'glDepthRange', or 'glViewport'
%             whichParameters: function-specific; see OpenGL documentation
%             You can also specifiy one of GL_MODELVIEW, GL_PROJECTION, or
%             GL_TEXTURE and a return variable current matrix values. If
%             two outputs are specified, the result of the computation
%             will be returned.
%
%             This function is usually not called directly, but
%             called by mglVisualAngleCoordinates or
%             mglScreenCoordinates to set the transforms
function mglTransform(whichMatrix, whichTransform, varargin)

% Warn about work in progress, but try not to spam on every frame.
persistent mglTransformWIPWarning
if (nargin > 4) && isempty(mglTransformWIPWarning)
    mglTransformWIPWarning = true;
    fprintf("(mglTransform) v3 work in progress: only GL_MODELVIEW, glScale, glTranslate, and glLoadIdentity are supported so far.\n")
end

if ~strcmp('GL_MODELVIEW', whichMatrix)
    return;
end

% This is a rough placeholder for work in progress
% The Metal app should own this state, not Matlab.
global mgl

switch whichTransform
    case 'glScale'
        xyz = varargin{1};
        newMatrix = eye(4);
        newMatrix([1,6,11]) = xyz;
        mgl.currentMatrix = mgl.currentMatrix * newMatrix;
    case 'glTranslate'
        xyz = varargin{1};
        newMatrix = eye(4);
        newMatrix([4,8,12]) = xyz;
        mgl.currentMatrix = mgl.currentMatrix * newMatrix;
    case 'glLoadIdentity'
        mgl.currentMatrix = eye(4);
end

mgl.s = mglSocketWrite(mgl.s,uint16(mgl.command.xform));
mgl.s = mglSocketWrite(mgl.s,single(mgl.currentMatrix));
