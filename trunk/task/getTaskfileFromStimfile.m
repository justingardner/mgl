% getTaskfileFromStimfile.m
%
%        $Id:$ 
%      usage: getTaskfileFromStimfile(v,scanNum,groupName)
%         by: justin gardner
%       date: 11/20/13
%    purpose: extracts the task file that was run from a stimfile and saves in the local diretory
%
%             v = newView;
%             getTaskfileFromStimfile(v,4,'Raw');
%
function retval = getTaskfileFromStimfile(varargin)

% check arguments
if nargin < 1
  help getTaskfileFromStimfile
  return
end

stimfiles = [];
% check that we have the view
if isview(varargin{1})
  v = varargin{1};
  % get scan and group
  if nargin >= 2
    scanNum = varargin{2};
    if ~isnumeric(scanNum)
      disp(sprintf('(getTaskfileFromStimfile) Must specify a numeric scan number'));
      help getTaskfileFromStimfile;
      return
    end
  else
    % default to scan 1
    scanNum = 1;
  end
  % get group
  if nargin >= 3
    groupNum = varargin{3};
    v = viewSet(v,'curGroup',groupNum);
  end
  if length(scanNum == 1)
    % now get stimfiles
    stimfiles = viewGet(v,'stimfile',scanNum);
  else
    % for multiple scans, call recursively
    for iScan = 1:length(scanNum)
      getTaskfileFromStimfile(v,scanNum(iScan));
    end
    return
  end
end

% check for empty stimfile
if isempty(stimfiles)
  disp(sprintf('(getTaskfileFromStimfile) Empty stimfile'));
  return
end

for iStimfile = 1:length(stimfiles)
  % get task
  if ~isfield(stimfiles{iStimfile},'task')
    disp(sprintf('(getTaskfileFromStimfile) Missing task variable in stimfile'));
    continue
  end
  task = stimfiles{iStimfile}.task;
  for iTask = 1:length(task)
    taskFilename = task{iTask}{1}.taskFilename;
    if askuser(sprintf('(getTaskfileFromStimfile) Retrieve task file %s',taskFilename));
      saveName = setext(taskFilename,'m');
      % file name bonk
      if isfile(saveName)
	% ask for overwrite
	if ~askuser(sprintf('(getTaskfileFromStimfile) Overwrite file %s in current directory',saveName));
	  saveName = input(sprintf('(getTaskfileFromStimfile) Enter name to save as and hit return (or just return to skip): ',taskFilename),'s');
	end
      end
      if ~isempty(saveName)
	saveName = setext(saveName,'m');
	% save file
	f = fopen(saveName,'w');
	fprintf(f,'%s',task{iTask}{1}.taskFileListing);
	fclose(f);
	disp(sprintf('(getTaskfileFromStimfile) Saved %s',saveName));
      end
    end
  end
end
