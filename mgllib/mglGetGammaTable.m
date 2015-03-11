% mglGetGammaTable.m
%
%        $Id$
%      usage: mglGetGammaTable()
%         by: justin gardner
%       date: 05/27/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns what the gamma table is set to
%       e.g.:
%
%mglOpen
%gammaTable = mglGetGammaTable
function t = mglGetGammaTable

t = mglPrivateGetGammaTable;

% if we have an 8 bit display running and a 10 bit table, then 
% just return the 8 bit values that are being used
if length(t.redTable)>256 && (mglGetparam('bitDepth') == 32)
  keyboard
end