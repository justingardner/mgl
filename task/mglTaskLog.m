% mglTaskLog.m
%
%        $Id:$ 
%      usage: mglTaskLog(myscreen)
%         by: justin gardner
%       date: 05/01/14
%    purpose: Writes log of all experiments that have been done on computer
%             Can also display the log:
%             mglTaskLog;
%
%             or display the log for a particular year:
%             mglTaskLog(2014);
%
%             To display a verbose listing:
%             mglTaskLog(2014,true);
%
%             The log will be stored in dir specified by mglGetParam('logpath');
%             If logpath is not set then this will default to ~/data/log
%
%             If you set:
%             mglSetParam('writeTaskLog',1,2);
% 
%             Then this function will be called in endTask to save a log
%             entry for every user of the computer.
%
function mglTaskLog(var,verbose)

% check arguments
if ~any(nargin == [0 1 2])
  help mglTaskLog
  return
end

% display the log with 0 arguments
if nargin == 0
  mglDispLog;
elseif (nargin >= 1) && isnumeric(var)
  % display log
  if nargin == 1
    mglDispLog(var,false);
  else
    mglDispLog(var,verbose);
  end
% if struct then write the log
elseif isstruct(var)
  mglWriteLog(var);
end


%%%%%%%%%%%%%%%%%%%%%
%    mglWriteLog    %
%%%%%%%%%%%%%%%%%%%%%
function mglWriteLog(myscreen)

% collect information for writing into log
if isfield(myscreen,'stimfile')
  stimfile = myscreen.stimfile;
else
  stimfile = [];
end
if isempty(stimfile),stimfile = 'NA';end
username = getusername;
datenow = datestr(now,'mm/dd/yyyy');
timenow = datestr(now);
if isfield(myscreen,'endtime') && isfield(myscreen,'starttime')
  stimlen = dispTimeDiff(datenum(myscreen.endtime),datenum(myscreen.starttime));
else
  stimlen = 'NA';
end
if isfield(myscreen,'SID')
  sid = myscreen.SID;
else
  sid = 'NA';
end
if isempty(sid),sid = 'NA';end
thisdatevec = datevec(now);
year = thisdatevec(1);
month = thisdatevec(2);

% get directory where log is saved
logpath = mglGetParam('logpath');
if isempty(logpath),logpath = '~/data/log';end

% check for directory
[logpath logdir] = fileparts(logpath);
if ~isdir(logpath)
  disp(sprintf('(mglWriteLog) !!! Could not find log path %s. Unable to save log !!!',logpath));
  return
end
topdir = pwd;

% check for directory under logpath
if ~isdir(fullfile(logpath,logdir))
  % try to make it
  cd(logpath);
  mkdir(logdir);
  if ~isdir(fullfile(logpath,logdir))
    disp(sprintf('(mglWriteLog) !!! Could not find log path %s. Unable to save log !!!',fullfile(logpath,logdir)));
    cd(topdir);
    return
  end
end

% ok, we have a logpath
logpath = fullfile(logpath,logdir);

% check for existence of a file for this year
logfilename = fullfile(logpath,sprintf('mgllog%i.csv',year));
if isfile(logfilename)
  % load the log
  log = readtable(logfilename);
else
  % create a new log
  log = table;
end

% add a new entry into table
tableCols = {'date','username','time','sid','stimfile','stimlen'};
newEntry = cell2table({datenow,username,timenow,sid,stimfile,stimlen});
newEntry.Properties.VariableNames = tableCols;
log = [log;newEntry];

% write table back
writetable(log,logfilename);
fileattrib(logfilename,'+w');
disp(sprintf('(mglWriteLog) Wrote log entry: %s %s %s %s %s %s',datenow,username,timenow,sid,stimfile,stimlen));

%%%%%%%%%%%%%%%%%%%%%
%    getusername    %
%%%%%%%%%%%%%%%%%%%%%
function username = getusername()

[retval username] = system('whoami');
% sometimes there is more than one line (errors from csh startup)
% so need to strip those off
username = strread(username,'%s','delimiter','\n');
username = username{end};
if (retval == 0)
  % get it again
  [retval username2] = system('whoami');
  username2 = strread(username2,'%s','delimiter','\n');
  username2 = username2{end};
  if (retval == 0)
    % find the matching last characers
    % this is necessary, because matlab's system command
    % picks up stray key strokes being written into
    % the terminal but puts those at the beginning of
    % what is returned by stysem. so we run the
    % command twice and find the matching end part of
    % the string to get the username
    minlen = min(length(username),length(username2));
    for k = 0:minlen
      if (k < minlen)
	if username(length(username)-k) ~= username2(length(username2)-k)
	  break
	end
      end
    end
    if (k > 0)
      username = username(length(username)-k+1:length(username));
      username = lower(username);
      username = username(find((username <= 'z') & (username >= 'a')));
    else
      username = 'unknown';
    end
  else
    username = 'unknown';
  end
else
  username = 'unknown';
end


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

%%%%%%%%%%%%%%%%%%%%
%    mglDispLog    %
%%%%%%%%%%%%%%%%%%%%
function mglDispLog(year,verbose)

if ~mglIsMrToolsLoaded
  disp(sprintf('(mgltaskLog) Could not display log because mrTools is not loaded'));
  return
end

% set to this year if not passed in
if (nargin<1) || isempty(year)
  thisdatevec = datevec(now);
  year = thisdatevec(1);
end  
if nargin<2
  verbose = false;
end

% get directory where log is saved
logpath = mglGetParam('logpath');
if isempty(logpath),logpath = '~/data/log';end

% make sure directory exists
if ~isdir(logpath)
  disp(sprintf('(mglDispLog) Could not find log directory: %s',logpath));
  return
end

% check for existence of a file for this year
logfilename = fullfile(logpath,setext(sprintf('mgllog%i',year),'csv'));
if isfile(logfilename)
  % load the log
  log = readtable(logfilename);
else
  disp(sprintf('(mglDispLog) Could not find log: %s',logfilename));
  return
end

% if verbose, just display and be done with it
if verbose
  disp(log);
  return
end

% init variables
thisdate = [];thisusername = [];thissid = [];thisstimfile= {};thismonth = [];
numRows = size(log,1);

% cycle through each row
for iRow = 1:numRows
  % check to see if this row has the same date/username/sid as last row
  if ~isequal(thisdate,log.date{iRow}) || ~isequal(thisusername,log.username{iRow}) || ~isequal(thissid,log.sid{iRow})
    % get this month
    thisdatevec = datevec(log.date{iRow});
    lastmonth = thismonth;
    thismonth = thisdatevec(2);
    % if this is the first month, then display it
    if isempty(thismonth) 
      dispHeader(sprintf('%i/%i',thismonth,year));
    end
    % display line
    if ~isempty(thisdate)
      disp(sprintf('%s %s (sid: %s, n=%i)',thisdate,thisusername,thissid,length(thisstimfile)));
    end
    % if this is the first month, then display it
    if ~isempty(thismonth) && ~isequal(thismonth,lastmonth) 
      dispHeader(sprintf('%i/%i',thismonth,year));
    end
    % get the new entry
    thisdate = log.date{iRow};
    thisusername = log.username{iRow};
    thissid = log.sid{iRow};
    thisstimfile = {log.stimfile{iRow}};
  else
    % add the current stimfile
    thisstimfile{end+1} = log.stimfile{iRow};
  end
end
disp(sprintf('%s %s (sid: %s, n=%i)',thisdate,thisusername,thissid,length(thisstimfile)));


