% getLastStimfile.m
%
%        $Id:$ 
%      usage: stimfile = getLastStimfile(myscreen,<verbose=1>,<stimfileNum=-1>,<onlyToday=false>)
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
%             onlyToday (default false). If set to true, will return only stimfiles from
%                today. If set to a date, will return only files from that day. For
%                example: onlyToday=140608 (will return only files from 06/08/2014
%                or, you can format in anything datestr can parse: onlyToday='06/08/2014'
%                if a negative integer e.g. ('onlyToday',-3), then specifies to use stimfiles
%                that many days back (e.g. 3 days ago)
%                if a positive integer specifies to use stimfiles only within
%                the last number of days. e.g. ('onlyToday',7) would only retrieve
%                stimfiles from the last week
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
getArgs(varargin,{'verbose=1','stimfileNum=-1','onlyToday',false});

% convert onlyToday argument into a date number
if isstr(onlyToday)
  try
    % see if it is a yymmdd format
    if (length(onlyToday)==6) && (length(regexp(onlyToday,'[0-9]'))==6)
      onlyToday = datenum(onlyToday,'yymmdd');
    else
      onlyToday = datenum(onlyToday);
    end
  catch
    disp(sprintf('(getLastStimfile) !!! Ignoring unrecognized data format for onlyToday: %s !!!',onlyToday));
    onlyToday = false;
  end
elseif isnumeric(onlyToday) 
  % if numeric and negative, means to get the date that many days back
  if onlyToday<0
    nowvec = datevec(now);
    nowvec = nowvec(1:3);
    onlyToday = datenum(nowvec+[0 0 onlyToday]);
  % if positive means to get all stimfiles within the number of days specified
  elseif onlyToday>0
    nowvec = datevec(now);
    nowvec = nowvec(1:3);
    datenums = [];
    for daysBack = -onlyToday:1:0
      datenums(end+1) = datenum(nowvec+[0 0 daysBack]);
    end
    onlyToday = datenums;
  end
elseif onlyToday
  onlyToday = now;
end

    
% now check datadirectory
if ~isdir(datadir)
  disp(sprintf('(getLastStimfile) Could not find data directory: %s',datadir));
  return
end

% load list of stimfiles
if onlyToday
  dirlist = [];
  % go through all dates
  for iDate = 1:length(onlyToday)
    % lookup directory
    thisDirlist = dir(fullfile(datadir,sprintf('%s_stim*.mat',datestr(onlyToday(iDate),'yymmdd'))));
    % if not empty
    if ~isempty(thisDirlist)
      % concatenate to existing list
      if isempty(dirlist)
	dirlist = thisDirlist;
      else
	dirlist(end+1:end+length(thisDirlist)) = thisDirlist;
      end
    end
  end
else
  dirlist = dir(fullfile(datadir,'*stim*.mat'));
end

% count them
nStimfiles = length(dirlist);

% if none exist, then return
if nStimfiles == 0
  disp(sprintf('(getLastStimfile) No existing stimfiles found in %s',datadir));
  return
end

% otherwise display how many we foun
if verbose
  disp(sprintf('(getLastStimfile) Found %i stimfiles in: %s',nStimfiles,datadir));
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
  % load stimfile
  stimfiles{i} = load(fullfile(datadir,dirlist(i).name));
end

% sort the stimfiles by end time
% get the endtime as a datenum for all elements of the array
endtime = cellfun(@(x) datenum(x.myscreen.endtime),stimfiles);
% sort
[dummy,sortIndex] = sort(endtime);
% and reorder the array
stimfiles = {stimfiles{sortIndex}};

for i = 1:length(stimfiles)
  % see how many trials
  stimfiles{i}.task = cellArray(stimfiles{i}.task,2);
  for iTask = 1:length(stimfiles{i}.task)
    trialnum(iTask) = 0;
    for iPhase = 1:length(stimfiles{i}.task{iTask})
      trialnum(iTask) = trialnum(iTask) + stimfiles{i}.task{iTask}{iPhase}.trialnum;
    end
  end
  % see whether we need to return this stimfile
  if isempty(stimfileNum) 
    s{end+1} = stimfiles{i};
    verboseStr = '*';
  elseif any(stimfileNum == i)
    % put into correct location in array
    for sLoc = find(stimfileNum==i)
      s{sLoc} = stimfiles{i};
    end
    verboseStr = '*';
  else
    verboseStr = ' ';
  end
  
  % display string
  if verbose
    disp(sprintf('%s%s: Date %s Length: %s trials: %s',verboseStr,dirlist(i).name,stimfiles{i}.myscreen.starttime,dispTimeDiff(stimfiles{i}.myscreen.endtime,stimfiles{i}.myscreen.starttime),num2str(trialnum)));
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
