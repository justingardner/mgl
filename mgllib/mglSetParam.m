% mglSetParam.m
%
%        $Id: mglMovie.m,v 1.1 2007/10/23 22:21:23 justin Exp $
%      usage: mglSetParam('paramName',paramValue,<makePersistent>);
%         by: justin gardner
%       date: 12/30/08
%    purpose: Set MGL parameters, if perisistent is set to 1, then
%             the parameter will be saved in a file .mglParams.mat
%             in the users home directory.
%             If persistent is set to 2, then the parameter will
%             be save into the file /Users/Shared/.mglParams.mat
%             and be saved for all users
%
%mglSetParam('verbose',1);
function mglSetParam(paramName,paramValue,makePersistent)

if ~any(nargin == [2 3])
  help mglSetParam;
  return
end

global MGL
MGL.(paramName) = paramValue;

if (nargin >= 3) && (isequal(makePersistent,1) || isequal(makePersistent,2))
  persistentParams = [];
  % try to load the persistentParams from a file
  if isequal(makePersistent,1)
    % user file
    persistentParamsFilename = '~/.mglParams.mat';
  else
    % shared file
    persistentParamsFilename = '/Users/Shared/.mglParams.mat';
  end
  if isfile(persistentParamsFilename)
    load(persistentParamsFilename);
  end
  % now set the curent param
  persistentParams.(paramName) = paramValue;
  % now save it back
  eval(sprintf('save %s persistentParams',persistentParamsFilename));
  % if persistent then make sure that we give write permission to everyone
  if isequal(makePersistent,2)
    try 
      fileattrib(persistentParamsFilename,'+w');
    catch
      disp(sprintf('(mglSetParam) Unable to set permissions ond %s',persistentParamsFilename));
    end
  end
end

