% mglGetGammaTable.m
%
%        $Id$
%      usage: mglGetGammaTable(fullTable)
%         by: justin gardner
%       date: 05/27/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: returns what the gamma table is set to.
%
%             t = mglGetGammaTable
%
%             If the gamma table has more entries than the bitDepth (usually
%             if the table is 10 bit but the bitDepth is set to 32 (8 bit)
%             then it will interpolate to 8 bits - this is for backwards
%             compatibility (mglSetGammaTable also interpolates an 8 bit
%             table to fill out a 10 bit table and this reverses that).
%             If you want the actual 10 bit table, then set fullTable = 1
%
%             mglGetGammaTable(true);
%
%mglOpen
%gammaTable = mglGetGammaTable
function t = mglGetGammaTable(fullTable)

t = mglPrivateGetGammaTable;

if nargin < 1,fullTable = false;end

% if we have an 8 bit display running and a 10 bit table, then 
% just return the 8 bit values that are being used
if ~fullTable && length(t.redTable)>256 && (mglGetParam('bitDepth') == 32)
  % what the table size is and what size we want to rever to
  tableSize = length(t.redTable);
  outputSize = 256;
  multiple = tableSize/outputSize;
  t.redTable = interp1((1:tableSize)-multiple/2,t.redTable,1:multiple:tableSize,'nearest','extrap');
  t.greenTable = interp1((1:tableSize)-multiple/2,t.greenTable,1:multiple:tableSize,'nearest','extrap');
  t.blueTable = interp1((1:tableSize)-multiple/2,t.blueTable,1:multiple:tableSize,'nearest','extrap');
end