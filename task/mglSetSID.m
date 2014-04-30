% mglSetSID.m
%
%        $Id:$ 
%      usage: mglSetSID()
%         by: justin gardner
%       date: 04/20/14
%    purpose: Sets the subject ID which is used by initScreen
%             and mglTaskLog. Brings up an interface to set
%             a subject ID or look it up in a searchable encrypted
%             database
%
function retval = mglSetSID(sid)

% check arguments
if ~any(nargin == [0 1])
  help mglSetSID
  return
end

% if passed in one argument and it is a number
if (nargin == 1)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % is a number, so format correctly and set
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if (isnumeric(sid) && (length(sid) == 1))
    if ((sid>=1)&&(sid<=999))
      setSID(sprintf('s%03i',round(sid)));
    elseif (sid == -1)
      setSID('test');
    else
      disp(sprintf('(mglSetSID) Numeric SID should be 1-999 for actual subejct ID or -1 for a test'));
    end
  elseif (isstr(sid)  && (length(sid) == 4) && (sid(1) == 's') && ~isempty(sid(2:end)))
    % string is of form snnn 
    setSID(sid);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % check if it is an edit command
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  elseif isequal(sid,'edit')
    % get the lock
    if ~getLock return, end
    % load existing database
    sids = loadSIDs;
    if ~istable(sids),releaseLock;return;,end
    % edit the database
    sids = editSIDs(sids);
    % save the database
    if ~isempty(sids)
      saveSIDs(sids);
      % release lock
      releaseLock(true);
    else
      % release lock
      releaseLock;
    end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % see if it is a subject name
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  elseif (isstr(sid))
    % lookup name
    sidstr = sid;
    [sid firstName lastName] = lookupSID(sidstr);
    % found it
    if length(sid) == 1
      % if only one, display and set
      disp(sprintf('(mglSetSID) Found subject: %s %s (%s)',firstName{1},lastName{1},sid{1}));
      setSID(sid{1});
    elseif length(sid) > 1
      % multiple matches, display them all and let subject select
      disp(sprintf('(mglSetSID) Found multiple matches for %s',sidstr));
      for i = 1:length(sid)
	disp(sprintf('%i: %s %s: %s',i,firstName{i},lastName{i},sid{i}));
      end
      c = getnum(sprintf('(mglSetSID) Choose which subject (0 to cancel): ',0:length(sid)));
      % set it
      if (c > 0)
	mglSetSID(sid{c});
      end
    else
      disp(sprintf('(mglSetSID) !!! Could not find unique SID for: %s !!!\nSID not set.',sidstr));
    end
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % not valid
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  else
    disp(sprintf('(mglSetSID) SID should either be a number [-1 or 1-999] or a valid string snnn'));
  end
end


%%%%%%%%%%%%%%%%
%    setSID    %
%%%%%%%%%%%%%%%%
function setSID(sidStr)

disp(sprintf('(mglSetSID) Setting SID: %s',sidStr));

% set the subject id
mglSetParam('sid',sidStr);

% set how long this sid will be valid for. The idea here is that
% people can set the SID and run a few experiments and we should
% not have to keep asking them for the SID. So, we keep it valid
% for some time - after which initScreen will ask them to update
% the SID

% get default interval for which sid is valid
validInterval = mglGetParam('sidValidIntervalInHours');
if isempty(validInterval)
  validInterval = 1;
end

% set how long it is valid for
nowvec = datevec(now);
nowvec(4) = nowvec(4)+floor(validInterval);
nowvec(5) = round(nowvec(5)+(validInterval-floor(validInterval))*60);
validUntil = datenum(datestr(nowvec));

mglSetParam('sidValidUntil',validUntil);


%%%%%%%%%%%%%%%%%%%
%    lookupSID    %
%%%%%%%%%%%%%%%%%%%
function [sid firstName lastName] = lookupSID(sidstr)

% defaults
sid = [];
firstName = [];
lastName = [];

% load sid database
sids = loadSIDs;
% lookup matching row
rownum = find(strcmp(lower(sidstr),lower(sids.firstName)) | strcmp(lower(sidstr),lower(sids.lastName)));
if ~isempty(rownum)
  % return matches
  for i = 1:length(rownum)
    sid{i} = sids.sid{rownum(i)};
    firstName{i} = sids.firstName{rownum(i)};
    lastName{i} = sids.lastName{rownum(i)};
  end
end

%%%%%%%%%%%%%%%%%%
%    loadSIDs    %
%%%%%%%%%%%%%%%%%%
function sids = loadSIDs

sids = [];

% need mrTools
if ~mglIsMrToolsLoaded,return,end

% get filename for SID database
sidsFilename = mglGetParam('sids');
if isempty(sidsFilename)
  disp(sprintf('(mglSetSID) Can not look up sid because filename has not been set: use mglSetParam(''sids'',''filename'');'));
  return
end

% strip extensims
sidsFilename = stripext(sidsFilename);

% decrypt file name
sidsDecrypt = setext(sidsFilename,'csv');

% check if data base exists
if ~isfile(sidsFilename)
  if askuser(sprintf('(mglSetSID) Could not find sids file %s, create one from scratch?',sidsFilename))
    % create a new table
    sids = table;
    sids.sid = {};
    sids.firstName = {};
    sids.lastName = {};
  end
  return
end

% try to unencrypt file using openssl des3
disp(sprintf('(mglSetSID) Loading SID database, enter password'));
status = system(sprintf('openssl des3 -d -in %s -out %s',sidsFilename,sidsDecrypt));

% see if decrypt was successful
if isequal(status,1)
  delete(sidsDecrypt);
  disp(sprintf('(mglSetSID) Did not decrypt %s',sidsFilename));
  return
end

% if so, then load it and delete the decrypt file
sids = readtable(sidsDecrypt);
delete(sidsDecrypt);
if isempty(sids)
  disp(sprintf('(mglSetSID) Could not load SID database %s',sidsDecrypt));
  return
end
% check format
checkFields = {'sid','lastName','firstName'};
if ~istable(sids) || ~isempty(setxor(intersect(sids.Properties.VariableNames,checkFields),checkFields))
  disp(sprintf('(mglSetSID) Bad table format for file %s',sidsFilename));
  sids = [];
end

%%%%%%%%%%%%%%%%%%
%    saveSIDs    %
%%%%%%%%%%%%%%%%%%
function saveSIDs(sids)

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get filename for SID s
sidsFilename = mglGetParam('sids');
if isempty(sidsFilename)
  disp(sprintf('(mglSetSID) Can not look up sid because filename has not been set: use mglSetParam(''sids'',''filename'');'));
  return
end

% strip extensions
sidsFilename = stripext(sidsFilename);

% check if data base exists
if ~isfile(sidsFilename)
  disp(sprintf('(mglSetSID) Could not find sids file %s',sidsFilename));
  
  if (~askuser(sprintf('(mglSetSID) Create sids file: %s',sidsFilename)))
    return
  end
end

% write sids to file
sidsDecrypt = setext(sidsFilename,'csv');
writetable(sids,sidsDecrypt);
tryToEncrypt = true;

disp(sprintf('(mglSetSID) Saving SID database, enter password'));
while tryToEncrypt
  % try to encrypt file using openssl des3
  status = system(sprintf('openssl des3 -salt -in %s -out %s',sidsDecrypt,sidsFilename));

  % see if encrypt was successful
  if isequal(status,1)
    if ~askuser(sprintf('(mglSetSID) Did not encrypt %s. Try again',sidsDecrypt));
      disp(sprintf('(mglSetSID) !!! WARNING file %s is not encyrpted !!!',sidsDecrypt));
      if askuser(sprintf('(mglSetSID) Remove unencrypted file %s and lose changes',sidsDecrypt))
	delete(sidsDecrypt);
      end
      tryToEncrypt = false;
    end
  else
    % file encrypted ok, so delete decrypted version
    delete(sidsDecrypt);
    tryToEncrypt = false;
  end
end

%%%%%%%%%%%%%%%%%%
%    editSIDs    %
%%%%%%%%%%%%%%%%%%
function sids = editSIDs(sids)

% sort based on subject id
sids = sortrows(sids,'sid');

% get the column names
columnNames = sids.Properties.VariableNames;
nCols = width(sids);
nRows = length(sids.(columnNames{1}));

% get the existing data
d = {};
for i = 1:nCols
  for j = 1:length(sids.(columnNames{i}))
    d{j,i} = sids.(columnNames{i}){j};
  end
end

% add 100 empty rows for editing
for i= 1:100
  for j = 1:nCols
    d{nRows+i,j} = '';
  end
end

% bring up figure
f = mlrSmartfig('mglSetSID','reuse');clf;
set(f,'MenuBar','none');

% size figure
p = get(f,'Position');
p(3) = 340;p(4) = 600;
set(f,'Position',p);

% add the table
hTable = uitable(f,'Data',d,'ColumnName',columnNames,'ColumnEditable',true,'Position',[20 50 300 530],'CellEditCallback',@editSIDcell);

% add ok,cancel buttons
uicontrol(f,'Style','pushbutton','Position',[130 20 90 20],'String','Cancel','Callback',@editSIDCancel);
uicontrol(f,'Style','pushbutton','Position',[230 20 90 20],'String','OK','Callback',@editSIDOK);

% wait for user to hit ok/cancel
uiwait

% this will get set to what the user hits
global gEditSID;
if gEditSID
  % grab data from table
  d = get(hTable,'data');
  
  % put it back into table
  nRows = 0;vals = [];
  for iRow = 1:size(d,1)
    if ~isempty(d{iRow,1})
      nRows = nRows + 1;
      for iCol = 1:length(columnNames)
	% if there is data, then add it
	vals.(columnNames{iCol}){nRows,1} = d{iRow,iCol};
      end
    end
  end
  sidsnew = struct2table(vals);
  % sort based on subject id
  sidsnew = sortrows(sidsnew,'sid');
  % no change, then return empty
  if isequal(sidsnew,sids)
    sids = [];
  else
    sids = sidsnew;
  end
else
  sids = [];
end

% close figure
close(f);
pause(0.1);

%%%%%%%%%%%%%%%%%%%%%
%    editSIDcell    %
%%%%%%%%%%%%%%%%%%%%%
function editSIDcell(src, eventdata)

% get new setting
str = lower(eventdata.NewData);

% check formatting
if eventdata.Indices(2) == 1
  % first column should be either sxxx or test
  if (length(str) < 1)
    disp(sprintf('(mglSetSID) Subject ID should be sXXX format or test'));
    str = eventdata.PreviousData;
  % if begins with s, then extract number and reformat (to make uniform
  elseif strcmp(str(1),'s')
    num = str2num(str(2:end));
    if isempty(num)
      disp(sprintf('(mglSetSID) Subject ID should be sXXX format or test'));
      str = eventdata.PreviousData;
    else
      str = sprintf('s%03i',num);
    end
  % if is just number, then convert to sxxx
  elseif ~strcmp(str,'test')
    num = str2num(str);
    if isempty(num)
      disp(sprintf('(mglSetSID) Subject ID should be sXXX format or test'));
      str = eventdata.PreviousData;
    else
      str = sprintf('s%03i',num);
    end
  end
else
  if length(str) >= 1
    str = fixBadChars(str);
    str = sprintf('%s%s',upper(str(1)),lower(str(2:end)));
  end
end

% write back into data
d = get(src,'data');
d{eventdata.Indices(1),eventdata.Indices(2)} = str;
set(src,'data',d);

%%%%%%%%%%%%%%%%%%%
%    editSIDOK    %
%%%%%%%%%%%%%%%%%%%
function editSIDOK(src, eventdata)

global gEditSID;
gEditSID = true;
uiresume;

%%%%%%%%%%%%%%%%%%%%%%%
%    editSIDCancel    %
%%%%%%%%%%%%%%%%%%%%%%%
function editSIDCancel(src, eventdata)

global gEditSID;
gEditSID = false;
uiresume;

%%%%%%%%%%%%%%%%
%    getnum    %
%%%%%%%%%%%%%%%%
function r = getnum(str,range)

% check arguments
if ~any(nargin==[1 2])
  help getnum
  return
end

r = [];
% while we don't have a valid answer, keep asking
while(isempty(r))
  % get user input
  r = input(str,'s');
  % make sure it is a string
  if isstr(r)
    % convert to number
    r = str2num(r);
  else
    r = [];
  end
  % check if in range
  if ~isempty(r) && ~ieNotDefined('range')
    for i = 1:length(r)
      if ~any(r(i)==range)
	disp(sprintf('(getnum) %i is out of range',r(i)));
	r = [];
	break;
      end
    end
  end
end

%%%%%%%%%%%%%%%%%
%    getLock    %
%%%%%%%%%%%%%%%%%
function tf = getLock

tf = false;

% need mrTools
if ~mglIsMrToolsLoaded,return,end

% get the filename of the database lock
sidsLockFilename = setext(mglGetParam('sids'),'lock');

% see if it exists
if isfile(sidsLockFilename)
  % try to load it
  [username locktime] = readlock(sidsLockFilename);
  if isempty(username),return,end
  % see if it has been locked for greater than an hour (in which
  % case we spit out a message and ignore.
  locklen = datevec(now-locktime);
  disp(sprintf('(mglSetSID) SID database is locked by %s since %s',username,datestr(locktime)));
  if any(locklen(1:4)>0)
    disp(sprintf('(mglSetSID) Ignoring lock since it has been locked for greater than an hour'));
  else
    if ~askuser(sprintf('Do you want to ignore the lock (in which case if %s tries to save, you might lose your changes - or you might write over their changes)',username))
      return
    else
      disp(sprintf('(mglSetSID) Stealing lock from %s',username));
    end
  end
end

% create the lock
fLock = fopen(sidsLockFilename,'w');
if (fLock == -1)
  disp(sprintf('(mglSetSID) Could not open lock file: %s',sidsLockFilename));
  if askuser(sprintf('(mglSetSID) You may not have permissions to write the SID database. Ignore and try to edit sid database anyway?'))
    tf = true;
    return;
  end
end
% set the attributes of the lock file to allow write by anyone
fileattrib(sidsLockFilename,'+w');

% write into the sidsLock the user name and time stamp
fprintf(fLock,'%s %s\n',getusername,datestr(now));

% close it, we have the lock
fclose(fLock);

% display message return true
disp('(mglSetSID) Setting lock file on SID database');
tf = true;

%%%%%%%%%%%%%%%%%%%%%
%    releaseLock    %
%%%%%%%%%%%%%%%%%%%%%
function releaseLock(warnOnStolenLock)

if nargin < 1,warnOnStolenLock = false;end

% get the filename of the database lock
sidsLockFilename = setext(mglGetParam('sids'),'lock');

% check if lock is there
if ~isfile(sidsLockFilename)
  disp(sprintf('(mglSetSID) Lock has already been removed'));
  return
end

% open lock file, just to check if we haven't got it stolen.
[username locktime] = readlock(sidsLockFilename);
if ~strcmp(username,getusername)
  if warnOnStolenLock
    disp(sprintf('(mglSetSID) !!! Warning, your lock was stolen by %s, they may overwrite your changes. !!!',username));
  end
else
  % remove the lock
  delete(sidsLockFilename);
  disp('(mglSetSID) Releasing lock file on SID database');
end

%%%%%%%%%%%%%%%%%%
%    readlock    %
%%%%%%%%%%%%%%%%%%
function [username locktime] = readlock(sidsLockFilename)

username = []; locktime = [];

% try to load it
fLock = fopen(sidsLockFilename);
if (fLock == -1) 
  disp(sprintf('(mglSetSID) Could not open lock file %s',sidsLockFilename));
else
  % get info from lockfile
  lockline = fgetl(fLock);
  fclose(fLock);
  [username locktime] = strtok(lockline);
  locktime = datenum(locktime);
end

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
