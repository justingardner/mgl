% mglGetParam.m
%
%        $Id: mglMovie.m,v 1.1 2007/10/23 22:21:23 justin Exp $
%      usage: mglGetParam(paramName);
%         by: justin gardner
%       date: 12/30/08
%    purpose: Set MGL parameters
%
%mglGetParam('verbose',1);
function retval  = mglGetParam(paramName)

% default to returning empty
retval = [];

if (nargin ~= 1)
  help mglGetParam;
  return
end

global MGL

if isfield(MGL,paramName)
  retval = MGL.(paramName);
end

