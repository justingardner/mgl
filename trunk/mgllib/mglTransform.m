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

