% mglSetScreenParams.m
%
%        $Id:$ 
%      usage: mglSetScreenParams()
%         by: justin gardner
%       date: 07/17/09
%    purpose: 
%
function retval = mglSetScreenParams(saveScreenParams)

% check arguments
if ~any(nargin == [1])
  help mglSetScreenParams
  return
end

% get then name of the screen params filename
screenParamsFilename = mglGetParam('screenParamsFilename');
if isempty(screenParamsFilename)
  screenParamsFilename = fullfile(mglGetParam('taskdir'),'mglScreenParams');
end

% make sure we have a .mat extension 
[pathstr name] = fileparts(screenParamsFilename);
screenParamsFilename = sprintf('%s.mat',fullfile(pathstr,name));

% check for file
if ~isfile(screenParamsFilename)
  disp(sprintf('(mglEditScreenParams) UHOH: Could not find screenParams file %s',screenParamsFilename));
  screenParams = {};
else
  % load the file
  screenParams = load(screenParamsFilename);
end

% check to make sure it has the right field
if isfield(screenParams,'screenParams')
  screenParams = screenParams.screenParams;
elseif ~isempty(screenParams)
  disp(sprintf('(mglEditScreenParams) UHOH: File %s does not contain screenParams',screenParamsFilename));
  screenParams = {};
end

if isempty(screenParams),return,end

% save a backup of the old one
backupFilename = sprintf('%sBackup',stripext(screenParamsFilename));
system(sprintf('rm -f %s',backupFilename));
eval(sprintf('save %s screenParams',backupFilename));

% save the new one
screenParams = saveScreenParams;
eval(sprintf('save %s screenParams',screenParamsFilename));


