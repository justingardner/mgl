% mglSetSID.m
%
%        $Id:$ 
%      usage: mglSetSID()
%         by: justin gardner
%       date: 04/20/14
%    purpose: Sets the subject ID which is used by initScreen
%             and mglTaskLog. Subject ID is then retrieved with
%             mglGetSID
%
%             To set a known SID:
%             mglSetSID('s001');
%             mglSetSID(1);
%
%             To lookup a name in the SID database:
%             mglSetSID('justin');
%             You will need to enter the password for the databse.
%
%             To edit the database:
%             mglSetSID('edit');
%             You will need to enter the password for the databse.
%
%             To clear the current SID:
%             mglSetSID([]);
%
%             The SID database is saved in file specified by:
%             mglGetParam('sidDatabaseFilename');
%
%             After setting an SID, the SID will be valid for:
%             mglGetParam('sidValidIntervalInHours');
%             If not set, this defaults to 1 hour. This is
%             so that you can run multiple experiments without
%             having to reset the mglSetSID - but if you are gone for
%             some time and someone else comes to run an experiment
%             they will need to reset the SID. Note that running
%             mglGetSID will reset the valid timer.
% 
%             If you set:
%             mglSetParam('mustSetSID',1,2);
% 
%             Then every user of the computer will have to set an SID
%             before initScreen will allow them to run a subject.
%
%             If you need to have race/ethnicity info in sid database
%             then set the following.
%
%             mglSetParam('sidRaceEthnicity',true,2)
%     
function retval = mglSetSID(sid)

% check arguments
if ~any(nargin == [1])
  help mglSetSID
  return
end

% race and ethnic categories from NIH
%http://grants.nih.gov/grants/guide/notice-files/NOT-OD-01-053.html
global ethnicCategories;
global racialCategories;
ethnicCategories = {'Decline','Hispanic or Latino','Not Hispanic or Latino'};
racialCategories = {'Decline','American Indian or Alaska Native','Asian','Black or African American','Native Hawaiian or Other Pacific Islander','White'};

% required fields
global requiredFields;
requiredFields = {'sid','firstName','lastName','gender','dob'};
if mglGetParam('sidRaceEthnicity')
  requiredFields = {requiredFields{:} 'ethnicity','race'};
end
		    
% if passed in one argument and it is a number
if (nargin == 1)
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % is empty then set sid to empty
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if isempty(sid)
    setSID([])
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % is a number, so format correctly and set
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  elseif (isnumeric(sid) && (length(sid) == 1))
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
    sidDatabase = loadSIDDatabase;
    if isempty(sidDatabase),releaseLock;return;,end
    % edit the database
    sidDatabase = editSIDDatabase(sidDatabase);
    % save the database
    if ~isempty(sidDatabase)
      saveSIDDatabase(sidDatabase);
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
    % check if it is test
    if strcmp(lower(sid),'test')
      setSID('test');
      return
    end
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

% clear sid
if isempty(sidStr)
  disp(sprintf('(mglSetSID) Clearing SID'));
  mglSetParam('sid',[]);
  mglSetParam('sidValidUntil',[]);
  return;
end
  
disp(sprintf('(mglSetSID) Setting SID: %s',sidStr));

% if this is not test, then try to validate
if ~strcmp(lower(sidStr),'test')
  sidDatabaseSID = setext(mglGetParam('sidDatabaseFilename'),'mat',0);
  if ~isfile(sidDatabaseSID)
    disp(sprintf('(mglSetSID) Could not find SID file %s, so cannot validate',sidDatabaseSID));
  else
    sid = load(sidDatabaseSID);
    if isfield(sid,'sid')
      if isempty(find(strcmp(lower(sidStr),lower(sid.sid))))
	disp(sprintf('(mglSetSID) SID %s is not in database. Must be added with mglSetSID(''edit'') before you can set it',sidStr));
	setSID([]);
	return
      end
    end
  end
end

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
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase),return,end

% case insensitive
sidstr = lower(sidstr);
rownum = [];
% lookup matching row
for iRow = 1:size(sidDatabase.sid,2)
  if ~isempty(findstr(sidstr,lower(sidDatabase.firstName{iRow}))) || ~isempty(findstr(sidstr,lower(sidDatabase.lastName{iRow})))
    rownum(end+1) = iRow;
  end
end
  
if ~isempty(rownum)
  % return matches
  for i = 1:length(rownum)
    sid{i} = sidDatabase.sid{rownum(i)};
    firstName{i} = sidDatabase.firstName{rownum(i)};
    lastName{i} = sidDatabase.lastName{rownum(i)};
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    loadSIDDatabase    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function sidDatabase = loadSIDDatabase

global ethnicCategories;
global racialCategories;
global columnNames;
sidDatabase = [];

% need mrTools
if ~mglIsMrToolsLoaded,return,end

% get filename for SID database
sidDatabaseFilename = mglGetParam('sidDatabaseFilename');
if isempty(sidDatabaseFilename)
  disp(sprintf('(mglSetSID) !!! Can not load SID Database because filename has not been set: use mglSetParam(''sidDatabaseFilename'',''filename''); !!!'));
  return
end

% decrypt file name
sidDatabaseDecrypt = setext(sidDatabaseFilename,'csv',0);

% check if data base exists
if ~isfile(sidDatabaseFilename)
  if askuser(sprintf('(mglSetSID) Could not find SID Database file %s, create one from scratch?',sidDatabaseFilename))
    % create a new table
    sidDatabase.sid = {};
    sidDatabase.firstName = {};
    sidDatabase.lastName = {};
    sidDatabase.gender = {};
    sidDatabase.dob = {};
    sidDatabase.dateAdded = {};
    sidDatabase.ethnicity = {};
    sidDatabase.race = {};
    for iRace = 3:length(racialCategories)
      sidDatabase.(sprintf('otherRace%i',iRace-2)) = {};
    end
    % set column names
    columnNames = fieldnames(sidDatabase);
  end
  return
end

% try to unencrypt file using openssl des3
disp(sprintf('(mglSetSID) Loading SID database, enter password'));
status = system(sprintf('openssl des3 -d -in %s -out %s',sidDatabaseFilename,sidDatabaseDecrypt));

% see if decrypt was successful
if isequal(status,1)
  delete(sidDatabaseDecrypt);
  disp(sprintf('(mglSetSID) Did not decrypt %s',sidDatabaseFilename));
  return
end

% if so, then load it and delete the decrypt file
sidDatabase = myreadtable(sidDatabaseDecrypt);
delete(sidDatabaseDecrypt);
if isempty(sidDatabase)
  disp(sprintf('(mglSetSID) Could not load SID database %s',sidDatabaseDecrypt));
  return
end

% set column names
columnNames = fieldnames(sidDatabase);

% check format
checkFields = {'sid','lastName','firstName'};
if ~isempty(setxor(intersect(columnNames,checkFields),checkFields))
  disp(sprintf('(mglSetSID) Bad table format for file %s',sidDatabaseFilename));
  sidDatabase = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    saveSIDDatabase    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function saveSIDDatabase(sidDatabase)

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get filename for SID s
sidDatabaseFilename = mglGetParam('sidDatabaseFilename');
if isempty(sidDatabaseFilename)
  disp(sprintf('(mglSetSID) Can not look up sid because filename has not been set: use mglSetParam(''sidDatabaseFilename'',''filename'');'));
  return
end

% check if data base exists
if ~isfile(sidDatabaseFilename)
  disp(sprintf('(mglSetSID) Could not find SID database file %s',sidDatabaseFilename));
  
  if (~askuser(sprintf('(mglSetSID) Create SID database file: %s',sidDatabaseFilename)))
    return
  end
end

% write sids to file
sidDatabaseDecrypt = setext(sidDatabaseFilename,'csv',0);
mywritetable(sidDatabase,sidDatabaseDecrypt);
tryToEncrypt = true;

disp(sprintf('(mglSetSID) Saving SID database, enter password'));
while tryToEncrypt
  % try to encrypt file using openssl des3
  status = system(sprintf('openssl des3 -salt -in %s -out %s',sidDatabaseDecrypt,sidDatabaseFilename));

  % see if encrypt was successful
  if isequal(status,1)
    if ~askuser(sprintf('(mglSetSID) Did not encrypt %s. Try again',sidDatabaseDecrypt));
      disp(sprintf('(mglSetSID) !!! WARNING file %s is not encyrpted !!!',sidDatabaseDecrypt));
      if askuser(sprintf('(mglSetSID) Remove unencrypted file %s and lose changes',sidDatabaseDecrypt))
	delete(sidDatabaseDecrypt);
      end
      tryToEncrypt = false;
    end
  else
    % file encrypted ok, so delete decrypted version
    delete(sidDatabaseDecrypt);
    tryToEncrypt = false;
  end
end

% write out SIDs
sidDatabaseSID = setext(sidDatabaseFilename,'mat',0);
sid = sidDatabase.sid;
save(sidDatabaseSID,'sid');

%%%%%%%%%%%%%%%%%%%%%%%%%
%    editSIDDatabase    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function sidDatabase = editSIDDatabase(sidDatabase)

% sort based on subject id
[vals sortorder] = sort(sidDatabase.sid);
fields = fieldnames(sidDatabase);
for iField = 1:length(fields);
  sidDatabase.(fields{iField}) = {sidDatabase.(fields{iField}){sortorder}};
end

% get the column names (set when table is loaded)
global columnNames;
nCols = length(columnNames);
nRows = length(sidDatabase.(columnNames{1}));

% validate enries
for iRow = 1:nRows
  for iCol = 1:nCols
    [tf fieldVal] = validateField(sidDatabase.(columnNames{iCol}){iRow},iCol);
    if tf
      sidDatabase.(columnNames{iCol}){iRow} = fieldVal;
    else
      sidDatabase.(columnNames{iCol}){iRow} = '';
    end
  end
end

% add 100 empty rows for editing
for i= 1:100
  for iCol = 1:nCols
    sidDatabase.(columnNames{iCol}){end+1} = '';
  end
end

% set column formats
colWidth = 50;
columnFormat = {'char','char','char',{'M','F'},'char','char'};
columnEditable = [true true true true true false];
columnWidth = {colWidth colWidth*2 colWidth*2 colWidth colWidth*1.5 colWidth*1.5};
if mglGetParam('sidRaceEthnicity')
  % add ethnic and racial categories
  global ethnicCategories;
  global racialCategories;
  columnFormat{end+1} = ethnicCategories;
  columnWidth{end+1} = colWidth*3;
  columnEditable(end+1) = true;
  for iRace = 2:length(racialCategories)
    columnFormat{end+1} = {'None' racialCategories{:}};
    columnWidth{end+1} = colWidth*3;
    columnEditable(end+1) = true;
  end
end
numColumns = length(columnFormat);

% table width
tableWidth = sum(cell2mat(columnWidth))+colWidth;

% bring up figure
f = mlrSmartfig('mglSetSID','reuse');clf;
set(f,'MenuBar','none');

% size figure
p = get(f,'Position');
if p(3) < (tableWidth+2*colWidth)
  p(3) = (tableWidth+2*colWidth);
  set(f,'Position',p);
end

% copy over fields into a display variable (so that we can hide
% ehtnicity/race when sidRaceEthnicity is set to false)
for iCol = 1:numColumns
  for iRow = 1:length(sidDatabase.sid)
    displayData{iRow,iCol} = sidDatabase.(columnNames{iCol}){iRow};
  end
end

% keep track of what row the user is editing so that we can validate each row entry
global gEditingRow;
gEditingRow = nan;

% add the table
global hTable;
hTable = uitable(f,'Data',displayData,'ColumnName',{columnNames{1:numColumns}},'ColumnEditable',true,'Position',[20 50 tableWidth 530],'CellEditCallback',@editSIDcell,'CellSelectionCallback',@selectSIDcell,'ColumnFormat',columnFormat,'ColumnWidth',columnWidth,'ColumnEditable',columnEditable);

% add ok,cancel buttons
uicontrol(f,'Style','pushbutton','Position',[130 20 90 20],'String','Cancel','Callback',@editSIDCancel);
uicontrol(f,'Style','pushbutton','Position',[230 20 90 20],'String','OK','Callback',@editSIDOK);

% wait for user to hit ok/cancel
uiwait

% this will get set to what the user hits
global gEditSID;
if gEditSID
  % grab data from table
  displayData = get(hTable,'data');  
  % put it back into table
  nRows = 0;vals = [];
  for iRow = 1:length(sidDatabase.sid)
    % only add if there is an SID field set
    if ~isempty(displayData{iRow,1})
      nRows = nRows + 1;
      for iCol = 1:length(columnNames)
	if iCol <= size(displayData,2)
	  % if it is in the displayed data, grab from there
	  [tf fieldVal] = validateField(displayData{iRow,iCol},iCol);
	else
	  % if it is in original grab from there (like when not showing
	  % ethnicity fields
	  [tf fieldVal] = validateField(sidDatabase.(columnNames{iCol}){iRow},iCol);
	end
	if tf
	  % if there is data, then add it
	  vals.(columnNames{iCol}){nRows,1} = fieldVal;
	else
	  vals.(columnNames{iCol}){nRows,1} = '';
	end
      end
      % see if there is a date
      if isempty(vals.dateAdded{nRows,1})
	% if not add the now date
	vals.dateAdded{nRows,1} = datestr(now);
      end
    end
  end
  % sort based on subject id
  sidDatabaseNew = vals;
  [vals sortorder] = sort(sidDatabaseNew.sid);
  fields = fieldnames(sidDatabaseNew);
  for iField = 1:length(fields);
    sidDatabaseNew.(fields{iField}) = {sidDatabaseNew.(fields{iField}){sortorder}};
  end
  % check if changed or not
  if ~isequal(sidDatabaseNew,sidDatabase)
    sidDatabase = sidDatabaseNew;
  else
    sidDatabase = [];
  end
else
  sidDatabase = [];
end

% close figure
close(f);
pause(0.1);

%%%%%%%%%%%%%%%%%%%%%
%    validateRow    %
%%%%%%%%%%%%%%%%%%%%%
function [tf invalidFieldNum invalidFieldName] = validateRow(data,rownum)

global requiredFields;
global columnNames;

% default values
tf = true;invalidFieldNum = [];invalidFieldName = [];

% check for missing row
if size(data,1) < rownum
  disp(sprintf('(mglSetSID:validateRow) No row %i to validate',rownum));
  return
end

% check all required fields
for iField = 1:length(requiredFields)
  fieldNum = find(strcmp(requiredFields{iField},columnNames));
  % check if that field is empty
  if ~isempty(fieldNum) && (size(data,2)>=fieldNum) && isempty(data{rownum,fieldNum})
    tf = false;
    invalidFieldNum = fieldNum;
    invalidFieldName = requiredFields{iField};
    return
  end
end

%%%%%%%%%%%%%%%%%%%%%%%
%    selectSIDcell    %
%%%%%%%%%%%%%%%%%%%%%%%
function selectSIDcell(src, eventdata)

global gEditingRow;

% check for bad selection data
if length(eventdata.Indices) < 1,return,end

% get row that the user has select
currentRow = eventdata.Indices(1);

% check if the user is editing a new row
if ~isnan(gEditingRow)
  if ~isequal(gEditingRow,currentRow)
    % validate the row the user just finished editing, if it has a subjectID set
    data = get(src,'data');
    if size(data,1) >= gEditingRow
      if ~isempty(data{gEditingRow,1})
	[tf fieldNum fieldName] = validateRow(get(src,'data'),gEditingRow);
	if ~tf
	  warndlg(sprintf('(mglSetSID) You must set field %s for %s',fieldName,data{gEditingRow,1}),'Missing Field','modal');
	  return
	end
      end
    end
  end
end
gEditingRow = currentRow;

%%%%%%%%%%%%%%%%%%%%%
%    editSIDcell    %
%%%%%%%%%%%%%%%%%%%%%
function editSIDcell(src, eventdata)

% check formatting of field
[tf fieldVal] = validateField(eventdata.NewData,eventdata.Indices(2));

% check if there is an age limit
global columnNames;
if strcmp(columnNames{eventdata.Indices(2)},'dob')
  ageLimit = mglGetParam('sidAgeLimit');
  if ~isempty(ageLimit)
    % age - accounting for birthday happening on same as today
    age = datevec(datenum(floor(now)+1)-datenum(fieldVal));
    if age(1) < ageLimit
      tf = false;
      warndlg(sprintf('Subject was born on %s (%i years old) is less than %i years old. Using this subject in an fMRI experiment could be a protocol violation.',fieldVal,age(1),ageLimit),'Age Violation','modal');
    end
  end
end

% check for duplicate SID
if strcmp(columnNames{eventdata.Indices(2)},'sid')
  % get all existing SID except the one just set
  d = get(src,'data');
  n = size(d,1);
  i = eventdata.Indices(1);
  sids = {d{[1:(i-1) (i+1):n],eventdata.Indices(2)}};
  % now see if there is a match
  if any(strcmp(fieldVal,sids))
    warndlg(sprintf('(mglSetSID) Duplicate SID: %s',fieldVal),'Duplicate SID','modal');
    tf = false;
  end
end

% check for duplicate name
if strcmp(columnNames{eventdata.Indices(2)},'firstName') || strcmp(columnNames{eventdata.Indices(2)},'lastName')
  % see if both firstName and lastName have been entered
  d = get(src,'data');
  n = size(d,1);
  i = eventdata.Indices(1);
  firstName = lower(d{i,find(strcmp('firstName',columnNames))});
  lastName = lower(d{i,find(strcmp('lastName',columnNames))});
  if ~isempty(firstName) && ~isempty(lastName)
    % now check if there is someone else in the database with the same name
    firstNames = lower({d{:,find(strcmp('firstName',columnNames))}});
    % see if there is any matches
    firstNameMatches = find(strcmp(firstName,firstNames));
    % see if there is also a lastName match
    lastNames = lower({d{:,find(strcmp('lastName',columnNames))}});
    lastNameMatches = find(strcmp(lastName,lastNames));
    % find where there is a match of both first name and last name, excluding this roww
    matchingRows = setdiff(intersect(firstNameMatches,lastNameMatches),i);
    % if this is different than this row, then it means there is a repeat
    if ~isempty(matchingRows)
      warndlg(sprintf('(mglSetSID) Subject %s %s has already been entered with SIDs: %s',firstName,lastName,d{matchingRows(1),find(strcmp('sid',columnNames))}),'Duplicate subject name','modal');
      % clear the whole row
      for fieldNum = 1:size(d,2)
	d{i,fieldNum} = '';
      end
      set(src,'data',d);
    end
  end
end

if ~tf
  % if field did not validate, then set it back to what it once was
  d = get(src,'data');
  d{eventdata.Indices(1),eventdata.Indices(2)} = eventdata.PreviousData;
  set(src,'data',d);
else
  % if it did validate, check if it changed, if so then replace it
  if ~isequal(eventdata.NewData,fieldVal)
    d = get(src,'data');
    d{eventdata.Indices(1),eventdata.Indices(2)} = fieldVal;
    set(src,'data',d);
  end
end

%%%%%%%%%%%%%%%%%%%
%    mglSetSID    %
%%%%%%%%%%%%%%%%%%%
function [tf fieldVal] = validateField(fieldVal,fieldNum)

tf = true;

% column names should be set when the table is loaded/created
global columnNames;
global ethnicCategories;
global racialCategories;

% subjectID
if fieldNum > length(columnNames)
  disp(sprintf('(mglSetSID:validateField) Field %i does not exist',fieldNum));
  tf = false;
  return
elseif isequal(columnNames{fieldNum},'sid')
  fieldVal = lower(fieldVal);
  % first column should be either sxxx or test
  if (length(fieldVal) < 1)
    disp(sprintf('(mglSetSID) Subject ID should be sXXX format or test'));
    tf = false;return
  % if begins with s, then extract number and reformat (to make uniform
  elseif strcmp(fieldVal(1),'s')
    num = str2num(fieldVal(2:end));
    if isempty(num)
      disp(sprintf('(mglSetSID) Subject ID should be sXXX format or test'));
      tf = false;return
    else
      fieldVal = sprintf('s%03i',num);
    end
  % if is just number, then convert to sxxx
  elseif ~strcmp(fieldVal,'test')
    num = str2num(fieldVal);
    if isempty(num)
      disp(sprintf('(mglSetSID) Subject ID should be sXXX format or test'));
      tf = false;return
    else
      fieldVal = sprintf('s%03i',num);
    end
  end
% DOB
elseif isequal(columnNames{fieldNum},'dob')
  try
    % convert to a date vector
    if ~isempty(fieldVal)
      dob = datevec(datenum(fieldVal));
      fieldVal = sprintf('%i/%i/%i',dob(2),dob(3),dob(1));
    else
      tf = false;
    end
  catch me
    tf = false;
  end
elseif isequal(columnNames{fieldNum},'ethnicity')
  if isnan(fieldVal)
    tf = false;
  else
    tf = ismember(fieldVal,ethnicCategories);
  end
elseif isequal(columnNames{fieldNum},'race')
  if isnan(fieldVal)
    tf = false;
  else
    tf = ismember(fieldVal,racialCategories);
  end   
elseif strncmp(columnNames{fieldNum},'otherRace',9)
  if isnan(fieldVal)
    tf = false;
  else
    tf = ismember(fieldVal,{'None',racialCategories{:}});
  end
end

if isnan(fieldVal),fieldVal = '';end

%%%%%%%%%%%%%%%%%%%
%    editSIDOK    %
%%%%%%%%%%%%%%%%%%%
function editSIDOK(src, eventdata)

% validate the row the user just finished editing
global hTable;
data = get(hTable,'data');
for iRow = 1:size(data,1)
  % for all rows with a non-empty SID
  if ~isempty(data{iRow,1})
    % validate
    [tf fieldNum fieldName] = validateRow(data,iRow);
    if ~tf
      warndlg(sprintf('(mglSetSID) You must set field %s for %s',fieldName,data{iRow,1}),'Missing Field','modal');
      return
    end
  end
end

% otherwise close dialog and let calling routine know that we need to save
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
sidDatabaseLockFilename = setext(mglGetParam('sidDatabaseFilename'),'lock',0);

% see if it exists
if isfile(sidDatabaseLockFilename)
  % try to load it
  [username locktime] = readlock(sidDatabaseLockFilename);
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
fLock = fopen(sidDatabaseLockFilename,'w');
if (fLock == -1)
  disp(sprintf('(mglSetSID) Could not open lock file: %s',sidDatabaseLockFilename));
  if askuser(sprintf('(mglSetSID) You may not have permissions to write the SID database. Ignore and try to edit sid database anyway?'))
    tf = true;
    return;
  end
end
% set the attributes of the lock file to allow write by anyone
try
  fileattrib(sidDatabaseLockFilename,'+w');
catch
  disp(sprintf('(mglSetSID) Could not set writeable attribute on: %s',sidDatabaseLockFilename));
end

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
sidDatabaseLockFilename = setext(mglGetParam('sidDatabaseFilename'),'lock',0);

% check if lock is there
if ~isfile(sidDatabaseLockFilename)
  disp(sprintf('(mglSetSID) Lock has already been removed'));
  return
end

% open lock file, just to check if we haven't got it stolen.
[username locktime] = readlock(sidDatabaseLockFilename);
if ~strcmp(username,getusername)
  if warnOnStolenLock
    disp(sprintf('(mglSetSID) !!! Warning, your lock was stolen by %s, they may overwrite your changes. !!!',username));
  end
else
  % remove the lock
  delete(sidDatabaseLockFilename);
  disp('(mglSetSID) Releasing lock file on SID database');
end

%%%%%%%%%%%%%%%%%%
%    readlock    %
%%%%%%%%%%%%%%%%%%
function [username locktime] = readlock(sidDatabaseLockFilename)

username = []; locktime = [];

% try to load it
fLock = fopen(sidDatabaseLockFilename);
if (fLock == -1) 
  disp(sprintf('(mglSetSID) Could not open lock file %s',sidDatabaseLockFilename));
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
for iRow = 1:length(t.sid)
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
