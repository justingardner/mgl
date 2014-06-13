% getLastStimfile.m
%
%        $Id:$ 
%      usage: stimfile = getLastStimfile(myscreen,<verbose=1>,<stimfileNum=-1>)
%         by: justin gardner
%       date: 06/08/11
%    purpose: retrieves the latest stimfile from the data directory. This is useful
%             for when you want to create a stimulus program which continues a staircase
%             from one run to the other and you need the data from the last run
%             to start the current run. If there is no existing stimfile, then returns []
%
%             myscreen should be a properly initialized (initScreen) myscreen variable.
%               if a string then it can be the path of where to find the stimfiles.
%             verbose (default = 1) prints information about stimfiles
%             stimfileNum (default = -1) which stimfile to return. The default is -1
%                which means the last stimfile. -k would be the kth last stimfile. A
%                positive value means the kth stimfile (e.g. 2 would be the 2nd stimfile
%                in the directory). A value of inf means to return all stimfiles.
%
function [s nStimfiles] = getLastStimfile(msc,varargin)

% check arguments
if nargin < 1
  help getLastStimfile
  return
end

s = {};

% parse input information about where data directory is
datadir = [];
if isstr(msc)
  datadir = msc;
elseif isstruct(msc) && isfield(msc,'datadir')
  datadir = msc.datadir;
else
  disp(sprintf('(getLastStimfile) Unknown input argument'));
  help getLastStimfile;
  return
end

% parse arguments
verbose = [];
stimfileNum = [];
getArgs(varargin,{'verbose=1','stimfileNum=-1'});

% now check datadirectory
if ~isdir(datadir)
  disp(sprintf('(getLastStimfile) Could not find data directory: %s',datadir));
  return
end

% load list of stimfiles
dirlist = dir(fullfile(datadir,'*stim*.mat'));
nStimfiles = length(dirlist);
disp(sprintf('(getLastStimfile) Found %i stimfiles in: %s',nStimfiles,datadir));

if nStimfiles == 0
  disp(sprintf('(getLastStimfile) No existing stimfiles found in %s',datadir));
  return
end

% inf means to return all stimfiles
if isinf(stimfileNum)
  stimfileNum = 1:nStimfiles;
end

% now get stimfile number to return
for i = 1:length(stimfileNum)
  if stimfileNum(i) < 0
    % stimfile num less than 0
    if abs(stimfileNum(i))<=nStimfiles
      stimfileNum(i) = nStimfiles+stimfileNum(i)+1;
    else
      disp(sprintf('(getLastStimfile) No matching stimfile %i',stimfileNum(i)));
      stimfileNum(i) = 0;
    end
  elseif stimfileNum(i) > 0
    % make sure we are in range
    if stimfileNum(i) > nStimfiles
      disp(sprintf('(getLastStimfile) No matching stimfile %i',stimfileNum(i)));
      stimfileNum(i) = 0;
    end
  end
end
    
% display all data in directory
for i = 1:length(dirlist)
  x = load(fullfile(datadir,dirlist(i).name));
  % see how many trials
  x.task = cellArray(x.task,2);
  for iTask = 1:length(x.task)
    trialnum(iTask) = 0;
    for iPhase = 1:length(x.task{iTask})
      trialnum(iTask) = trialnum(iTask) + x.task{iTask}{iPhase}.trialnum;
    end
  end
  % see whether we need to return this stimfile
  if isempty(stimfileNum) 
    s{end+1} = x;
    verboseStr = '*';
  elseif any(stimfileNum == i)
    % put into correct location in array
    for sLoc = find(stimfileNum==i)
      s{sLoc} = x;
    end
    verboseStr = '*';
  else
    verboseStr = ' ';
  end
  
  % display string
  if verbose
    disp(sprintf('%s%s: Date %s Length: %s trials: %s',verboseStr,dirlist(i).name,x.myscreen.starttime,dispTimeDiff(x.myscreen.endtime,x.myscreen.starttime),num2str(trialnum)));
  end
end

% return a simple struct instead of a cell array when possible
if length(s) == 1,s = s{1};end

%%%%%%%%%%%%%%%%%%%%%%
%    dispTimeDiff    %
%%%%%%%%%%%%%%%%%%%%%%
function retval = dispTimeDiff(time1,time2)

% check arguments
if ~any(nargin == [1 2])
  help dispTimeDiff
  return
end

% convert to time number
if isstr(time1),time1 = datenum(time1);end
if isstr(time2),time2 = datenum(time2);end

% convert to seconds
time1 = time1*24*60*60;
time2 = time2*24*60*60;

retval = disptime(time1-time2);

%%%%%%%%%%%%%%%%%%
%    disptime    %
%%%%%%%%%%%%%%%%%%
function retval = disptime(t,format)

hours = floor(t/(60*60));
minutes = floor((t-hours*60*60)/60);
seconds = floor(t-hours*60*60-minutes*60);

if (nargin == 1) || isequal(format,1)
  if hours > 0
    retval = sprintf('%02i hours %02i min %02i secs',hours,minutes,seconds);
  else
    retval = sprintf('%02i min %02i secs',minutes,seconds);
  end
else
  retval = sprintf('%02i:%02i:%02i',hours,minutes,seconds);
end  
