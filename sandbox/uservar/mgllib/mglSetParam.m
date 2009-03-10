% mglSetParam.m
%
%        $Id: mglMovie.m,v 1.1 2007/10/23 22:21:23 justin Exp $
%      usage: mglSetParam('paramName',paramValue);
%         by: justin gardner
%       date: 12/30/08
%    purpose: Set MGL parameters
%
%mglSetParam('verbose',1);
function mglSetParam(paramName,paramValue)

if (nargin ~= 2)
  help mglSetParam;
  return
end

global MGL
MGL.(paramName) = paramValue;


