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
%             If an SID is set with mglSetSID, this will keep also
%             a subject specific tasklog which will keep every
%             task the subject has been run on. You can view
%             that log by doing:
% 
%             mglTaskLog('s001');
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
elseif (nargin >= 1) && (isnumeric(var) || isstr(var))
  if nargin == 1,verbose = false;end
  wiki = false;
  if isstr(var) && strcmp(var,'wiki'),wiki = true;end
  % display log
  mglDispLog(var,verbose,wiki);
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

% get directory where log is saved
logpath = mglGetParam('logpath');
if isempty(logpath),logpath = '~/data/log';end
logpath = mlrReplaceTilde(logpath);

% set logname to mgllog + year
thisdatevec = datevec(now);
year = thisdatevec(1);
month = thisdatevec(2);
logfilename = fullfile(logpath,sprintf('mgllog%i.csv',year));

% get the calling function name.
st = dbstack;
taskName = st(end).file;

% write the log
writeTaskLog(logpath,logfilename,'sid',sid,'stimfile',stimfile,'stimlen',stimlen,'task',taskName);

% now see if we also should keep a sid speicific log
% first make sure sid is still set
sid = mglGetSID;
if ~isempty(sid)
  % put the sid specific database into the sid directory
  sidpath = fileparts(mlrReplaceTilde(mglGetParam('sidDatabaseFilename')));
  if ~isempty(sidpath)
    % write the log
    writeTaskLog(sidpath,sprintf('%s.csv',sid),'task',taskName,'computer',myscreen.computer,'stimfile',stimfile);
  end
end

%%%%%%%%%%%%%%%%%%%%%%
%    writeTaskLog    %
%%%%%%%%%%%%%%%%%%%%%%
function writeTaskLog(logpath,logfilename,varargin);

% get username / date and time
username = getusername;
datenow = datestr(now,'mm/dd/yyyy');
timenow = datestr(now);

% check for directory
logdir = getLastDir(logpath);
logpath = fileparts(logpath);
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

% ok check for logifle
if mglIsFile(logfilename)
  % load the log
  log = myreadtable(logfilename);
else
  % create a new log
  log = [];
end

% figure out how many rows
if isempty(log)
  nRows = 0;
else
  nRows = length(log.date);
end

% add a new entry into table
tableCols = {'date','username','time'};
log.date{nRows+1} = datenow;
log.username{nRows+1} = username;
log.time{nRows+1} = timenow;

% set string to display at end
dispstr = sprintf('(mglWriteLog) Wrote log entry to %s: %s %s %s',logfilename,datenow,username,timenow);
% set the table cols and log values for all optional
% fields that are passed through varargin. 
for iField = 1:2:length(varargin)
  % set the table column
  tableCols{end+1} = varargin{iField};
  % and the actual value
  log.(varargin{iField}){nRows+1} = varargin{iField+1};
  % set display string
  dispstr = sprintf('%s %s=%s',dispstr,varargin{iField},varargin{iField+1});
end

% write table back
mywritetable(log,logfilename);
try
  fileattrib(logfilename,'+w');
catch
  disp(sprintf('(mglTaskLog) Could not set writeable attrib on file: %s',logfilename));
end

% display the entry that was made
disp(dispstr);

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
function logListing = mglDispLog(year,verbose,wiki)

logListing = '';

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
if nargin<3
  wiki = false;
end

% if year is a string, then it means to look up subject
if isstr(year) && ~isequal(year,'wiki')
  sid = year;
  % get logpath as where the sid database lives
  logpath = fileparts(mlrReplaceTilde(mglGetParam('sidDatabaseFilename')));
  % set logfilename to sid
  logfilename = fullfile(logpath,sprintf('%s.csv',sid));
elseif isequal(year,'wiki')
  % get directory where log is saved
  logpath = mglGetParam('logpath');
  if isempty(logpath),logpath = '~/data/log';end
  % serach for logs
  logdir = dir(logpath);
  for iDir = 1:length(logdir)
    if ~isempty(regexp(logdir(iDir).name,'mgllog\d\d\d\d.csv'))
      % extract year
      year = str2num(logdir(iDir).name(7:11));
      % set heading in wiki to year
      logListing = [logListing sprintf('===== %i =====\n',year)];
      % and get entries for that year
      logListing = [logListing mglDispLog(year,verbose,wiki)];
    end
  end
  % write the log listing to a local file
  localWiki = fullfile(logpath,'wiki.txt');
  fWiki = fopen(localWiki,'w+');
  if (fWiki == -1),disp(sprintf('(mglTaskLog) Could not open file %s',localWiki));return,end
  fprintf(fWiki,logListing);
  fclose(fWiki);
  % get the server name
  wikiServer = mglGetParam('mglTaskLogWikiServer');
  if isempty(wikiServer)
    disp(sprintf('(mglTaskLog) To save a wiki entry you must set the name of ther wiki server\ne.g. mglSetParam(''mglTaskLogWikiServer'',''gru@gru.stanford.edu'',2);'));
    return
  end
  % get the directory name
  wikiDir = mglGetParam('mglTaskLogWikiDir');
  if isempty(wikiDir)
    disp(sprintf('(mglTaskLog) To save a wiki entry you must set the name of the directory on the wiki server %s where the wiki page file will go\ne.g. mglSetParam(''mglTaskLogWikiDir'',''mglTaskLogWiki'',2);',wikiServer));
    return
  end
  % now copy wiki file to location on server
  commandStr = sprintf('scp %s %s:%s',localWiki,'gru@gru.stanford.edu',fullfile('mglTaskLogWiki',sprintf('%s.txt',strtok(mglGetHostName,'.'))));
  disp(commandStr);system(commandStr);
  return
else
  % get directory where log is saved
  logpath = mglGetParam('logpath');
  if isempty(logpath),logpath = '~/data/log';end
  % get log file name
  logfilename = fullfile(logpath,setext(sprintf('mgllog%i',year),'csv',0));
end

% make sure directory exists
if ~isdir(logpath)
  disp(sprintf('(mglDispLog) Could not find log directory: %s',logpath));
  return
end

% check for existence of the logfile
if mglIsFile(logfilename)
  % load the log
  log = myreadtable(logfilename);
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
logEntry = [];
thisMonth = [];lastMonth = [];
numRows = length(log.date);

% cycle through each row
for iRow = 1:numRows
  if isfield(log,'sid'),sid = log.sid{iRow};end
  % check to see if this row has the same date/username/sid as last row
  if isempty(logEntry) || ~isequal(logEntry.date,log.date{iRow}) || ~isequal(logEntry.username,log.username{iRow}) || ~isequal(logEntry.sid,sid)
    % get this month
    logDatevec = datevec(log.date{iRow});
    lastMonth = thisMonth;
    thisMonth = logDatevec(2);
    % if this is the first month, then display it
    if ~isempty(thisMonth) && ~isequal(thisMonth,lastMonth) 
      if wiki
	% for wiki, put an entry for each month
	logListing = [logListing sprintf('==== %i/%i ====\n',thisMonth,logDatevec(1))];
	% and start table
	logListing = [logListing sprintf('^ Date ^ SID ^ task ^\n')];
      else
	dispHeader(sprintf('%i/%i',thisMonth,logDatevec(1)));
      end
    end
    if ~isempty(logEntry)
      % since this is a new row, display last line of log
      logListing = [logListing dispLogLine(logEntry,wiki)];
    end
    % get the new entry
    logEntry.date = log.date{iRow};
    logEntry.username = log.username{iRow};
    logEntry.sid = sid;
    logEntry.stimfile = {log.stimfile{iRow}};
    % get task field if it exists
    if isfield(log,'task')
      if ~isempty(log.task{iRow})
	logEntry.task = {log.task{iRow}};
      else
	logEntry.task = {getTaskName(log.stimfile{iRow})};
      end
    end
    % get computer field if it exists
    if isfield(log,'computer')
      logEntry.computer = log.computer{iRow};
    end
  else
    % add the current stimfile
    logEntry.stimfile{end+1} = log.stimfile{iRow};
    % add task
    if isfield(log,'task')
      if ~isempty(log.task{iRow})
	logEntry.task{end+1} = log.task{iRow};
      else
	logEntry.task{end+1} = getTaskName(log.stimfile{iRow});
      end
    end
  end
end

% display a line of the log
logListing = [logListing dispLogLine(logEntry,wiki)];

%%%%%%%%%%%%%%%%%%%%%
%    getTaskName    %
%%%%%%%%%%%%%%%%%%%%%
function taskName = getTaskName(stimfileName)

taskName = [];
% try to load stimfile
if mglIsFile(stimfileName)
  s = load(stimfileName);
  % if there is a task variable
  % then go look for the last in 
  % the cell array of cell arrays for
  % taskFilename and put that into the task field
  if isfield(s,'task')
    if iscell(s.task)
      if iscell(s.task{end})
	if isfield(s.task{end}{end},'taskFilename')
	  taskName = s.task{end}{end}.taskFilename;
	end
      else
	if isfield(s.task{end},'taskFilename')
	  taskName = s.task{end}.taskFilename;
	end
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%
%    dispLogLine    %
%%%%%%%%%%%%%%%%%%%%%
function dispstr = dispLogLine(logEntry,wiki)

% fix up task fields - this may not have been set
% so if it was not then go look up in stimfile
% to figure out what task was
if ~isfield(logEntry,'task'),logEntry.task = {};end

% make sure empty tasks are strings so that unique does not fail
if iscell(logEntry.task)
  for i = 1:length(logEntry.task)
    if isempty(logEntry.task{i}),logEntry.task{i} = '';
    end
  end
end

% add the name of all unique tasks here
[taskNames ia ic] = unique(logEntry.task);
taskstr = '';
for iTask = 1:length(taskNames)
  taskstr = sprintf('%s%s (n=%i) ',taskstr,taskNames{iTask},sum(ic==iTask));
end

% for wiki entries only
if wiki
  dispstr = sprintf('| %s | %s | %s |\n',logEntry.date,logEntry.sid,taskstr);
  return
end

% start to create display string
dispstr = sprintf('%s',logEntry.date);

% display username/computer
if isfield(logEntry,'username')
  if isfield(logEntry,'computer')
    dispstr = sprintf('%s %s@%s',dispstr,logEntry.username,logEntry.computer);
  else
    dispstr = sprintf('%s %s',dispstr,logEntry.username);
  end
end

% display number of stimfiles
dispstr = sprintf('%s n=%i',dispstr,length(logEntry.stimfile));

% display sidID
dispstr = sprintf('%s %s',dispstr,logEntry.sid);

% add task string
dispstr = sprintf('%s: %s',dispstr,taskstr);

% display the string
disp(dispstr);

% add on new line
dispstr = sprintf('%s\n',dispstr);

%%%%%%%%%%%%%%%%%%%%
%    getLastDir    %
%%%%%%%%%%%%%%%%%%%%
function lastDir = getLastDir(pathStr,levels)

% check arguments
if ~any(nargin == [1 2])
  help getLastDir
  return
end

if ieNotDefined('levels'),levels = 1;end
if levels == 0,lastDir = '';return;end

% remove trailing fileseparator if it is there
if length(pathStr) && (pathStr(end) == filesep)
  pathStr = pathStr(1:end-1);
end

% get last dir
[pathStr lastDir ext] = fileparts(pathStr);

% paste back on extension
lastDir = [lastDir ext];

lastDir = fullfile(getLastDir(pathStr,levels-1),lastDir);

%%%%%%%%%%%%%%%%%%%%%
%    myreadtable    %
%%%%%%%%%%%%%%%%%%%%%
function t = myreadtable(filename)

t = [];
f = fopen(filename);
if (f==-1)
  disp(sprintf('(mglSetSID:myreadtable) Could not open file: %s',filename));
  return
end

% read variable names
varNamesLine = fgets(f);
varNames = {};
while ~isempty(varNamesLine)
  [varNames{end+1} varNamesLine] = strtok(varNamesLine,',');
  varNames{end} = strtrim(varNames{end});
end

% read the lines
l = fgets(f);
iLine = 1;
while ~isequal(l,-1)
  % read each entry in the line
  iEntry = 1;
  % try to read all fields
  cloc = strfind(l,',');
  if (length(cloc) ~= (length(varNames)-1))
    disp(sprintf('(mglSetSID) File: %s has a line with only %i comma delimited fields when %i is expected',filename,length(cloc),length(varNames)-1));
    fclose(f);
    return
  end
  cloc = [0 cloc length(l)];
  for iField = 1:length(varNames)
    t.(varNames{iField}){iLine} = l((cloc(iField)+1):(cloc(iField+1)-1));
    iEntry = iEntry+1;
  end
  % read another line
  l = fgets(f);
  iLine = iLine+1;
end

% close file
fclose(f);


%%%%%%%%%%%%%%%%%%%%%
%    mywritetable    %
%%%%%%%%%%%%%%%%%%%%%
function mywritetable(t,filename)

f = fopen(filename,'w');
if (f==-1)
  disp(sprintf('(mglSetSID) Could not open %s for writing',filename));
  return
end

% write the column names
fields = fieldnames(t);
for iField = 1:length(fields)
  if (iField==1)
    fprintf(f,'%s',fields{iField});
  else
    fprintf(f,',%s',fields{iField});
  end
end
fprintf(f,'\n');

% write out each row
for iRow = 1:length(t.(fields{1}))
  for iField = 1:length(fields)
    if (iField==1)
      fprintf(f,'%s',t.(fields{iField}){iRow});
    else
      fprintf(f,',%s',t.(fields{iField}){iRow});
    end
  end
  fprintf(f,'\n');
end

% close file
fclose(f);


% mlrReplaceTilde.m
%
%        $Id:$ 
%      usage: filename =  mlrReplaceTilde(filename)
%         by: justin gardner
%       date: 12/07/11
%    purpose: If filename starts with a tilde, will replace with
%             fully qualified path (e.g. ~/uhm will become /Users/justin/uhm)
%
function filename = mlrReplaceTilde(filename)

% check arguments
if ~any(nargin == [1])
  help mlrReplaceTilde
  return
end

if (length(filename) >= 1) && (filename(1) == '~')
  % get tilde dir
  if ispc
    tildeDir = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
  else
    tildeDir = getenv('HOME');
  end

  % apend tildeDir
  filename = fullfile(tildeDir,filename(2:end));
end

