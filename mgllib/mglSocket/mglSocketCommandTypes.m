% mglSocketCommandTypes: Access commands and data types shared with mglMetal.
%
%        $Id$
%      usage: [commandCodes, dataTypes] = mglSocketCommandTypes()
%         by: justin gardner and ben heasly
%       date: 12/26/2019
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Get a Matlab view of command codes and matrix data types that
%             MGL and the mglMetal app both support and agree on.
%      usage: [commandCodes, dataTypes] = mglSocketCommandTypes()
%
%             Returns a struct of uint command codes shared between MGL
%             here on the Matlab side, and the mglMetal app.  Matlab code
%             should access command codes by field name from this struct,
%             and not hard-code the numeric values.
%
%             These command names and codes come from a C header file
%             which is the source of truth: mglCommandTypes.h.
%
%             Mex-functions here in Matlab include this header, and so
%             does the mglMetal app.  Changes to command codes or names
%             should go through the header and not be duplicated/maintained
%             on both ends.
%
%             Also returns a struct describing Matlab numeric data types
%             that MGL and mglMetal support, and the size in bytes of
%             array elements of each type.  We might never need this
%             directly in Matlab, but it's part of the shared header
%             contract, so I figure we should make it visible to Matlab
%             code.
%
%             This function doesn't actually open or use any sockets.  It
%             just exposes build-time constants to Matlab code.
%
% % For example:
% [commandCodes, dataTypes] = mglSocketCommandTypes()
%