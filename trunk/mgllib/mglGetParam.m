% mglGetParam.m
%
%        $Id: mglGetParam.m,v 1.1 2007/10/23 22:21:23 justin Exp $
%      usage: mglGetParam(paramName);
%         by: justin gardner
%       date: 12/30/08
%    purpose: Get MGL parameters
%
% verbose = mglGetParam('verbose');
function retval  = mglGetParam(paramName)

% default to returning empty
retval = [];

% get the global
global MGL

% load the permanent params if they haven't been loaded
if ~isfield(MGL,'persistentParamsLoaded')
  % set the field to say that we have tried to load the
  % persistentParams, after this we will no longer keep
  % trying to load the persistent params
  MGL.persistentParamsLoaded = 0;
  % filenames of persistent params file (one is local, one is shared)
  persistentParamsFilenames = {'~/.mglParams.mat','/Users/Shared/.mglParams.mat'};
  for i = 1:length(persistentParamsFilenames)
    persistentParamsFilename = persistentParamsFilenames{i};
    if isfile(persistentParamsFilename)
      load(persistentParamsFilename);
      if exist('persistentParams','var')
	persistentParamNames = fieldnames(persistentParams);
	for i = 1:length(persistentParamNames)
	  MGL.(persistentParamNames{i}) = persistentParams.(persistentParamNames{i});
	  % set to remember that we have succeeded
	  MGL.persistentParamsLoaded = 1;
	end
      end
    end
  end
end

if (nargin ~= 1)
  help mglGetParam;
  disp(sprintf('(mglGetParam) List of all mgl global parameters'));
  MGL
  return
end

% and grab the field if it exist
if isfield(MGL,paramName)
  retval = MGL.(paramName);
else
  % special case for displayNumber -- if none exists, return
  % -1 to signal that the display is closed
  if strcmp(paramName,'displayNumber')
    retval = -1;
  end
  % special case for soundNames, default to cell array
  if strcmp(paramName,'soundNames') || strcmp(paramName,'movieStructs')
    retval = {};
  end
  % special case for the location of mgllibDir
  if any(strcmp(lower(paramName),{'mgllibdir','mgllib'}))
    retval = fileparts(which('mglOpen'));
    if isempty(retval)
      disp(sprintf('(mglGetParam) Could not find mgllib directory'));
    end
  end
  % special case for the location of mglutilsDir
  if any(strcmp(lower(paramName),{'mgldigiodir','mgldigio','digio'}))
    retval = fileparts(which('mglDigIO'));
    if isempty(retval)
      disp(sprintf('(mglGetParam) Could not find mgl/utils directory'));
    end
  end
  % special case for the location of mglutilsDir
  if any(strcmp(lower(paramName),{'mglutilsdir','mglutils'}))
    retval = fileparts(which('mglDoRetinotopy'));
    if isempty(retval)
      disp(sprintf('(mglGetParam) Could not find mgl/utils directory'));
    end
  end
  % special case for the location of mgl/task dir
  if any(strcmp(lower(paramName),{'taskdir','task','mgltaskdir','mgltask'}))
    retval = fileparts(which('initTask'));
    if isempty(retval)
      disp(sprintf('(mglGetParam) Could not find mgl/task directory'));
    end
  end

end
