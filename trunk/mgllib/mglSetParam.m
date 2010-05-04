% mglSetParam.m
%
%        $Id: mglMovie.m,v 1.1 2007/10/23 22:21:23 justin Exp $
%      usage: mglSetParam('paramName',paramValue,<makePersistent>);
%         by: justin gardner
%       date: 12/30/08
%    purpose: Set MGL parameters, if perisistent is set to 1, then
%             the parameter will be saved in a file .mglParams.mat
%             in the users home directory.
%
%mglSetParam('verbose',1);
function mglSetParam(paramName,paramValue,makePersistent)

if ~any(nargin == [2 3])
  help mglSetParam;
  return
end

global MGL
MGL.(paramName) = paramValue;

if (nargin >= 3) && isequal(makePersistent,1)
  persistentParams = [];
  % try to load the persistentParams from a file
  persistentParamsFilename = '~/.mglParams.mat';
  if isfile(persistentParamsFilename)
    load(persistentParamsFilename);
  end
  % now set the curent param
  persistentParams.(paramName) = paramValue;
  % now save it back
  eval(sprintf('save %s persistentParams',persistentParamsFilename));
end

