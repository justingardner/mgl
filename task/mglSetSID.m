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
%             To add a subject
%             mglSetSID('add');
%            
%             To edit a subject
%             mglSetSID('s001','edit');
%             You will need to enter the password for the databse.
%
%             To clear the current SID:
%             mglSetSID([]);
%
%             To list all subjects:
%             mglSetSID('list');
%
%             Or list subjects added after a certain date
%             mglSetSID('list','listStartDate=Jan 1, 2015')
%
%             To remove a subject
%             mglSetSID('s999','remove');
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
%             If you are not connected to the SID database (i.e. running
%             on a laptop with no internet access), then you can set an
%             SID without validating through the database:
%          
%             mglSetSID(15,'force=1');
%
%             IF you want to keep a "private" SID database - e.g.
%             you are running psychophysics only and have a lot
%             of subjects that will not get used in other experiments
%             then you can set subjects into a private database
%             (which is stored centrally and validated the same as
%             the regular subjet IDs). In which case, you can
%             set private. 
%
%             mglSetSID('add','private=myown');
%             When you add, you will be asked to 
%             set a postfix which is a letter string that gets
%             appended to the subject id to distinguish it from
%             other subjectIDs. For example, if postfix=x then
%             subject ids will be of the form s001x
%
%             Note that when someone looks up a subjet name
%             it will not search private SIDs unless you set
%             private. If you want to search all without
%             caring about which private  database they are in
%             then set private to _all_:
% 
%             mglSetSID('somebody','private=_all_');
%             mglSetSID('somebody','edit','private=_all_');
%
%             You can make a backup of the current database by doing
%             mglSetSID('backup')
%
%             You can merge information from an old backup with the current
%             databse as follows - note it will ask you for confirmation
%             before saving and also make a backup
%             mglSetSID('merge');
%
%             To list a backup you can do the following which will bring up
%             a drop-down listbox of backups to choose from:
%             mglSetSID('list','listBackup');
%
function retval = mglSetSID(sid,varargin)

% check arguments
if nargin < 1
  help mglSetSID
  return
end

% get arguments
force = false;
edit  = false;
remove = false;
private = [];
listBackup = false;
listStartDate = [];
if (nargin > 1) && mglIsMrToolsLoaded
  getArgs(varargin,{'force=0','edit=0','private=[]','remove=0','listStartDate=[]','listBackup=0'});
end

% FIX, FIX, FIX
% set private sid
% Check private database against all database for name/dob match
% set for number of digits

% required fields. This is a list with:
% fieldnames, defaultValue, description string, t/f is encrypted field
% note that unencrypted fields should not contain personal identifiers
% ALso, that since unencrypted fields go only into a .mat file
% and not an encrypted csv file they can be any matlab structure
% and not just a string
global requiredFields;
requiredFields = {{'sid','','Unique identifier for subejct',1},...
		  {'firstName','','First name of subject',1},...
		  {'lastName','','last name of subject',1},...
		  {'gender',{'F','M','Non-binary','Decline'},'Gender of subject',1},...
		  {'dob','date','Date of birth for subject',1},...
		  {'experimenter','','Name of experimenter entering this SID into database',1},...
		  {'dateAdded',datestr(now),'Date that this entry was added to the sid database',1},...
		  {'private',[],'Whether this sid is in a private listing - in which case this will be set to a string identifying the private database',0}...
		 };

% race and ethnic categories from NIH
%http://grants.nih.gov/grants/guide/notice-files/NOT-OD-01-053.html
global ethnicCategories;
ethnicCategories = {'Decline','Hispanic or Latino','Not Hispanic or Latino'};
ethnicCategoriesHelp = 'Ethnicity as specified by NIH requirements. You are not required to specify any ethnicity if you do not wish to';
global racialCategories;
racialCategories = {'Decline','American Indian or Alaska Native','Asian','Black or African American','Native Hawaiian or Other Pacific Islander','White'};
racialCategoriesHelp = 'Race as specified by NIH requirements. You may enter more than one. You are not required to specify any race if you do not wish to';

% set race/ethnicity fields if asked for
% setting this to always set race and ethnicity
%if mglGetParam('sidRaceEthnicity')
if 1
  requiredFields = {requiredFields{:},...
		    {'ethnicity',ethnicCategories,ethnicCategoriesHelp,1},...
		    {'race',racialCategories,racialCategoriesHelp,1},...
		    {'otherRace1',racialCategories,racialCategoriesHelp,1},...
		    {'otherRace2',racialCategories,racialCategoriesHelp,1},...
		    {'otherRace3',racialCategories,racialCategoriesHelp,1},...
		    {'otherRace4',racialCategories,racialCategoriesHelp,1},...
		   };
end

% set what the maximum SID can be
global gMaxSID;
gMaxSID = 999;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% is empty then set sid to empty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(sid)
  setSID([],force,private)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% is a number, so format correctly and set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif (isnumeric(sid) && (length(sid) == 1))
  sid = num2sid(sid);
  if ~isempty(sid)
    % either edit, remove or set
    if edit,editSID(sid,private); elseif remove,removeSID(sid,private); else setSID(sid,force,private);end
  end
elseif (isstr(sid)  && (length(sid) >= 4) && (sid(1) == 's') && ~isempty(sid(2:end)))
  % if person passed in an explicit sid, then
  % allow looking up in private as well
  if isempty(private),private = '_all_';end
  % either edit or set
  if edit,editSID(sid,private);  elseif remove,removeSID(sid,private); else setSID(sid,force,private);end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if it is an edit command
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif isequal(sid,'edit')
  disp(sprintf('(mglSetSID) Edit feature disabled - possibly busted - and sucks anyway'));
  % something wrong with the ethnicity fields do not seem to be in the right column
  %editSIDDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add an entry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif isequal(sid,'add')
  addSID(private);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list all entries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif isequal(sid,'list')
  listSID(private,listStartDate,listBackup);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% merge with a backup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif isequal(sid,'merge')
  mergeSID(private,listStartDate);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make a backup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif isequal(sid,'backup')
  backupSID(private,listStartDate);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% see if it is a subject name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif (isstr(sid))
  % lookup name
  sid = name2sid(sid,private);
  if ~isempty(sid)
    % either edit or set
    if edit,editSID(sid,private); else setSID(sid,force,private);end
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% not valid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
  disp(sprintf('(mglSetSID) SID should either be a number [-1 or 1-%i] or a valid string snnn',gMaxSID));
end

%%%%%%%%%%%%%%%%%
%    editSID    %
%%%%%%%%%%%%%%%%%
function editSID(sid,private)

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get the lock
if ~getLock return, end

% load existing database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase),releaseLock;return;,end

% if private is set, then make sure sid has the correct postfix
if ~isempty(private) && ~strcmp(lower(private),'_all_') && ~isempty(regexp(sid(end),'\d'))
  postfix = getPostfix(sidDatabase,private,true);
  sid = sprintf('%s%s',sid,postfix);
end
  
% find the sid
rownum = find(strcmp(sid,sidDatabase.sid));
if isempty(rownum)
  disp(sprintf('(mglSetSID:editSID) Could not find %s in database',sid));
  return
end

% get the fields we have
columnNames = fieldnames(sidDatabase);
global requiredFields;

% make an input for each field 
paramsInfo = {};
for iField = 1:length(requiredFields)
  fieldName = requiredFields{iField}{1};
  if isfield(sidDatabase,fieldName)
    % see if the field has set choices
    if iscell(requiredFields{iField}{2})
      % if so, then put current setting at top of list
      fieldDefault = putOnTopOfList(sidDatabase.(fieldName){rownum},requiredFields{iField}{2});
    else
      % just put string there
      fieldDefault = sidDatabase.(fieldName){rownum};
    end
  else
    fieldDefault = requiredFields{iField}{2};
  end
  % get help
  fieldHelp = requiredFields{iField}{3};
  % cell array deafults mean to put up a set of choices
  % like for race or gender categories. Except in the case
  % of log which contains a cell array of usage info
  if any(strcmp(fieldName,{'sid','private'}))
    paramsInfo{end+1} = {fieldName,fieldDefault,fieldHelp,'editable=0'};
  elseif iscell(fieldDefault)
    paramsInfo{end+1} = {fieldName,fieldDefault,'type=popupmenu',fieldHelp};
  % date needs to be checked against age limits and formatted properly
  elseif strcmp(requiredFields{iField}{2},'date')
    paramsInfo{end+1} = {fieldName,fieldDefault,'type=string',fieldHelp,'callback',@validateDate,'callbackArg',fieldName};
  % experimenter gets as default the current user name
  elseif strcmp(fieldName,'experimenter')
    paramsInfo{end+1} = {fieldName,getusername,'type=string',fieldHelp};
  % otherwise, everything but sid gets put up as a string
  elseif ~strcmp(fieldName,'sid') && ~strcmp(fieldName,'log')
    paramsInfo{end+1} = {fieldName,fieldDefault,'type=string',fieldHelp};
  end
end

% button to display log
paramsInfo{end+1} = {'log',0,'type=pushbutton','buttonString=Display Log','callback=mglTaskLog','callbackArg',sid,'Display a log listing everytime the subject was run'};

% bring up dialog box
params = mrParamsDialog(paramsInfo);

% save the database
if ~isempty(params)
  % add the subject to the database
  for iField = 1:length(requiredFields)
    % everything except log gets value from params
    if ~any(strcmp(requiredFields{iField}{1},{'log','sid'}))
      sidDatabase.(requiredFields{iField}{1}){rownum} = params.(requiredFields{iField}{1});
    end
  end
  % set the dateAdded
  sidDatabase.dateAdded{end+1} = datestr(now);
  keyboard
  % save it back
  saveSIDDatabase(sidDatabase);
  % release lock
  releaseLock(true);
else
  % release lock
  releaseLock;
end

%%%%%%%%%%%%%%%%%%%
%    removeSID    %
%%%%%%%%%%%%%%%%%%%
function removeSID(sid,private)

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get the lock
if ~getLock return, end

% load existing database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase),releaseLock;return;,end

% if private is set, then make sure sid has the correct postfix
if ~isempty(private) && ~strcmp(lower(private),'_all_') && ~isempty(regexp(sid(end),'\d'))
  postfix = getPostfix(sidDatabase,private,true);
  sid = sprintf('%s%s',sid,postfix);
end
  
% find the sid
rownum = find(strcmp(sid,sidDatabase.sid));
if isempty(rownum)
  disp(sprintf('(mglSetSID:editSID) Could not find %s in database',sid));
  return
end

% display SID and confirm
dispSID(sidDatabase,rownum);
if askuser('(mglSetSID) Remove above SID? This cannot be undone.')
  % remove subject from database
  % get column names
  columnNames = fieldnames(sidDatabase);
  for iCol = 1:length(columnNames)
    sidDatabase.(columnNames{iCol}) = {sidDatabase.(columnNames{iCol}){1:rownum-1} sidDatabase.(columnNames{iCol}){rownum+1:end}};
  end
  % save the database back back
  saveSIDDatabase(sidDatabase);
  % release lock
  releaseLock(true);
else
  % release lock
  releaseLock;
end


%%%%%%%%%%%%%%%%
%    setSID    %
%%%%%%%%%%%%%%%%
function setSID(sidStr,force,private)

% clear sid
if isempty(sidStr)
  disp(sprintf('(mglSetSID) Clearing SID'));
  mglSetParam('sid',[]);
  mglSetParam('sidValidUntil',[]);
  return;
end
  
% if this is not test and not forced, then try to validate
if ~force
  % test sid is special (you can always just set it)
  if ~strcmp(lower(sidStr),'test')
    % otherwise, get database name
    sidDatabaseSID = mlrReplaceTilde(setext(mglGetParam('sidDatabaseFilename'),'mat',0));
    if ~mglIsFile(sidDatabaseSID)
      disp(sprintf('(mglSetSID) Could not find SID file %s, so cannot validate',sidDatabaseSID));
    else
      % load it
      sid = load(sidDatabaseSID);
      % check sid
      if isfield(sid,'sid')
	% see if there is a private setting
	if isfield(sid,'private')
	  if isempty(private) 
	    % means to take all non-private sid (i.e. ones in
	    % which private is set to empty
	    sid.sid = {sid.sid{cellfun(@isempty,sid.private)}};
	  elseif ~isequal(lower(private),'_all_')
	    % only take sids that match the private setting
	    sid.sid = {sid.sid{strcmp(private,sid.private)}};
	    % add correct postfix if missing
	    if ~isempty(regexp(sidStr(end),'\d')) && (length(sid.sid) >= 1)
	      [sidBegin sidEnd] = regexp(sid.sid{1},'s\d+');
	      postfix = sid.sid{1}(sidEnd+1:end);
	      sidStr = sprintf('%s%s',sidStr,postfix);
	    end
	  end
	end
	% how look for match
	if isempty(find(strcmp(lower(sidStr),lower(sid.sid))))
	  disp(sprintf('(mglSetSID) SID %s is not in database. Must be added with mglSetSID(''edit'') before you can set it',sidStr));
	  setSID([]);
	  return
	end
      end
    end
  end
end

% display what we are doing
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
function [sid firstName lastName] = lookupSID(sidstr,private)

% defaults
sid = [];
firstName = [];
lastName = [];
privateMatch = [];

% load sid database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase),return,end

% case insensitive
sidstr = lower(sidstr);
rownum = [];
% lookup matching row
for iRow = 1:size(sidDatabase.sid,2)
  if ~isempty(strfind(lower(sidDatabase.firstName{iRow}),sidstr)) || ~isempty(strfind(lower(sidDatabase.lastName{iRow}),sidstr))
    rownum(end+1) = iRow;
  end
end
  
if ~isempty(rownum)
  % return matches
  for i = 1:length(rownum)
    sid{i} = sidDatabase.sid{rownum(i)};
    firstName{i} = sidDatabase.firstName{rownum(i)};
    lastName{i} = sidDatabase.lastName{rownum(i)};
    privateMatch{i} = sidDatabase.private{rownum(i)};
  end

  % return only ones with a private match
  if isempty(private)
    match = find(cellfun(@isempty,privateMatch));
  elseif strcmp(lower(private),'_all_')
    match = 1:length(privateMatch);
  else
    match = find(strcmp(private,privateMatch));
  end
  sid = {sid{match}};
  firstName = {firstName{match}};
  lastName = {lastName{match}};
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    [Database    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function sidDatabase = loadSIDDatabase(sidDatabaseFilename)

global ethnicCategories;
global racialCategories;
global columnNames;
sidDatabase = [];

% need mrTools
if ~mglIsMrToolsLoaded,return,end

if nargin < 1
  % get filename for SID database
  sidDatabaseFilename = mlrReplaceTilde(mglGetParam('sidDatabaseFilename'));
  if isempty(sidDatabaseFilename)
    disp(sprintf('(mglSetSID) !!! Can not load SID Database because filename has not been set: use mglSetParam(''sidDatabaseFilename'',''filename''); !!!'));
    return
  end
end

% decrypt file name
sidDatabaseDecrypt = setext(sidDatabaseFilename,'csv',0);

% get list of required fields
global requiredFields;

% check if data base exists
if ~mglIsFile(sidDatabaseFilename)
  if askuser(sprintf('(mglSetSID) Could not find SID Database file %s, create one from scratch?',sidDatabaseFilename))
    for iField = 1:length(requiredFields)
      % check if default is a cell
      if iscell(reqiredFields{iField}{2})
	% then use first element in cell
	sidDatabase.(requiredFields{iField}{1}) = requiredFields{iField}{2}{1};
      else
	sidDatabase.(requiredFields{iField}{1}) = requiredFields{iField}{2};
      end
    end
    % set column names
    columnNames = fieldnames(sidDatabase);
  end
  return
end

% load unencrypted part of database that does not contain
% any personal identifiers
sidDatabaseFilenameUnencrypted = mlrReplaceTilde(setext(mglGetParam('sidDatabaseFilename'),'mat',0));
if ~mglIsFile(sidDatabaseFilenameUnencrypted)
  disp(sprintf('(mglSetSID) !!! Could not find unencrypted dataabase that contains info devoid of personal identifiers. Will try to load from encrypted database'));
else
  unencrypted = load(sidDatabaseFilenameUnencrypted);
end

% try to unencrypt file using openssl des3
disp(sprintf('(mglSetSID) Loading SID database, enter password'));
status = system(sprintf('openssl des3 -d -md md5 -in %s -out %s',sidDatabaseFilename,sidDatabaseDecrypt));

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

% try to merge unencrypted and encrypted information
% first check that sid information is the same in both files
if isfield(unencrypted,'sid') && isfield(sidDatabase,'sid') && isequal(unencrypted.sid,sidDatabase.sid)
  % ok, we have matching information so, merge the date
  unencryptedFieldnames = fieldnames(unencrypted);
  for iField = 1:length(unencryptedFieldnames)
    % copy fields
    sidDatabase.(unencryptedFieldnames{iField}) = unencrypted.(unencryptedFieldnames{iField});
  end
else
  disp(sprintf('(mglSetSID) !!! Unencrypted database file %s does not have matching information with sidDatabase file %s, so ignoring unencrypted file !!!',sidDatabaseFilenameUnencrypted,sidDatabaseFilename));
end

% set column names
columnNames = fieldnames(sidDatabase);

% check format
checkFields = {'sid','lastName','firstName'};
if ~isempty(setxor(intersect(columnNames,checkFields),checkFields))
  disp(sprintf('(mglSetSID) Bad table format for file %s',sidDatabaseFilename));
  sidDatabase = [];
end

% add any missing fields
if ~isempty(sidDatabase)
  nSID = length(sidDatabase.sid);
  % check if all the special fields exists
  for iField = 1:length(requiredFields)
    % if a field does not exist then set it to its default value
    if ~isfield(sidDatabase,requiredFields{iField}{1})
      % set to default value for all subjects
      sidDatabase.(requiredFields{iField}{1}) = cell(1,length(sidDatabase.sid));
      sidDatabase.(requiredFields{iField}{1})(:) = {requiredFields{iField}{2}};
    else
      % if it does exist, make sure that it has an entry for each sid
      if length(sidDatabase.(requiredFields{iField}{1})) < nSID
      	for i = length(sidDatabase.(requiredFields{iField}{1}))+1:nSID
      	  sidDatabase.(requiredFields{iField}{1}){i} = requiredFields{iField}{2};
      	end
      end
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    saveSIDDatabase    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function saveSIDDatabase(sidDatabase,sidDatabaseFilename)

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get filename for SID s
if nargin < 2
  sidDatabaseFilename = mlrReplaceTilde(mglGetParam('sidDatabaseFilename'));
  if isempty(sidDatabaseFilename)
    disp(sprintf('(mglSetSID) Can not look up sid because filename has not been set: use mglSetParam(''sidDatabaseFilename'',''filename'');'));
    return
  end
  % ask to create
  askToCreateNew = true;
else
  % don't ask to create
  askToCreateNew = false;
end

% check if data base exists
if ~mglIsFile(sidDatabaseFilename)
  if askToCreateNew
    disp(sprintf('(mglSetSID) Could not find SID database file %s',sidDatabaseFilename));
    if (~askuser(sprintf('(mglSetSID) Create SID database file: %s',sidDatabaseFilename)))
      return
    end
  end
end

% check to see if any fields need to be stripped and put
% into unencrypted mat file instead of csv file
global requiredFields
unencrypted.sid = sidDatabase.sid;
for iField = 1:length(requiredFields)
  % check to see if the 4th argumnet, which is whether the
  % field should be encrypted or not is set to 0
  if requiredFields{iField}{4} == 0
    % now copy over that unencrypted to the variable unencrypted
    % which will get saved as an unecrypted mat file below
    unencrypted.(requiredFields{iField}{1}) = sidDatabase.(requiredFields{iField}{1});
    % and remove it from the sidDatabase which will get
    % saved as an encrypted csv file
    sidDatabase = rmfield(sidDatabase,requiredFields{iField}{1});
  end
  % also, build up an easy to access list of requiredField names
  % which is used for the check below for any fields that exist
  % that are not required
  requiredFieldNames{iField} = requiredFields{iField}{1};
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
save(sidDatabaseSID,'-struct','unencrypted');

%%%%%%%%%%%%%%%
%    addSID   %
%%%%%%%%%%%%%%%
function addSID(private)

global gMaxSID;

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get the lock
if ~getLock return,end

% open the SID database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase),return,end

% get postfix
if ~isempty(private)
  postfix = getPostfix(sidDatabase,private);
  if isempty(postfix)
    disp(sprintf('(mglSetSID:addSID) No postfix for private SID: %s. Aborting',private));
    return
  end
else
  postfix = [];
end

% get the set of unused sids
sidUsed = [];
for iSID = 1:length(sidDatabase.sid)
  if isequal(sidDatabase.private{iSID},private)
    sidUsed(iSID) = sid2num(sidDatabase.sid{iSID});
  end
end

global requiredFields;

% set up the dialog
paramsInfo = {};
paramsInfo{end+1} = {'sid',validateNewSID(sidUsed,1),'incdec=[-1 1]','minmax',[0 gMaxSID],'Set the SID that you want to add','callback',@validateNewSID,'callbackArg',sidUsed};

% make an input for each field 
for iField = 1:length(requiredFields)
  fieldName = requiredFields{iField}{1};
  fieldDefault = requiredFields{iField}{2};
  fieldHelp = requiredFields{iField}{3};
  % cell array deafults mean to put up a set of choices
  % like for race or gender categories. Except in the case
  % of log which contains a cell array of usage info
  if strcmp(fieldName,'private')
    paramsInfo{end+1} = {fieldName,private,fieldHelp,'editable=0'};
  elseif iscell(fieldDefault) && ~strcmp(fieldName,'log')
    paramsInfo{end+1} = {fieldName,fieldDefault,'type=popupmenu',fieldHelp};
  % date needs to be checked against age limits and formatted properly
  elseif strcmp(fieldDefault,'date')
    paramsInfo{end+1} = {fieldName,'','type=string',fieldHelp,'callback',@validateDate,'callbackArg',fieldName};
  % experimenter gets as default the current user name
  elseif strcmp(fieldName,'experimenter')
    paramsInfo{end+1} = {fieldName,getusername,'type=string',fieldHelp};
  % otherwise, everything but sid gets put up as a string
  elseif ~strcmp(fieldName,'sid') && ~strcmp(fieldName,'log')
    paramsInfo{end+1} = {fieldName,fieldDefault,'type=string',fieldHelp};
  end
end

% get validated user input
validated = false;
% some fields that don't need to be validated
validationSkip = {'private'};

while ~validated
  % bring up dialog box
  params = mrParamsDialog(paramsInfo);

  % assume validated, check below for empty fields
  validated = true;
  
  % if user hit cancel then dont worry about validating
  if ~isempty(params)
    missingFields = 'Missing required field(s):';
    % check required fields
    for iRequired = 1:length(requiredFields)
      if ~any(strcmp(requiredFields{iRequired},validationSkip))
	% check if required field is not set
	if isempty(params.(requiredFields{iRequired}{1}))
	  % make string to report which fields are missing
	  missingFields = sprintf('%s %s',missingFields,requiredFields{iRequired}{1});
          % not validated.
	  validated = false;
	  % reset paramsInfo, so that the dialog box comes up again with 
	  % what the user already put in.
	  fields = fieldnames(params);
	  for iField = 1:length(fields)
	    for jField = 1:length(paramsInfo)
	      % look for matching parameter in paramsInfo
	      if isequal(paramsInfo{jField}{1},fields{iField})
		if iscell(paramsInfo{jField}{2})
		  % put value set by user on top of list
		  paramsInfo{jField}{2} = putOnTopOfList(params.(fields{iField}),paramsInfo{jField}{2});
		else
		  % then set with value set by user
		  paramsInfo{jField}{2} = params.(fields{iField});
		end
	      end
	    end
	  end
	end
      end
    end
  end
  if ~validated
    warndlg(missingFields,'Missing fields','modal');
  end
end

% save the database
if ~isempty(params)
  % check for repeat by first/last name
  firstIdx = cellfun(@(x) strcmp(x,params.firstName),sidDatabase.firstName);
  lastIdx = cellfun(@(x) strcmp(x,params.lastName),sidDatabase.lastName);
  idx = firstIdx .* lastIdx;
  if any(idx)
    sid = sidDatabase.sid{logical(idx)};
    warndlg(sprintf('Subject %s %s is already in the database with subject ID %s',params.firstName,params.lastName,sid));
    releaseLock(true);
    return
  end
    
  % add the subject to the database
  for iField = 1:length(requiredFields)
    % convert sid, which is a number into a sid string
    if strcmp(requiredFields{iField}{1},'sid')
      sidDatabase.sid{end+1} = num2sid(params.sid,postfix);
    % everything except log gets value from params
    elseif ~strcmp(requiredFields{iField}{1},'log')
      sidDatabase.(requiredFields{iField}{1}){end+1} = params.(requiredFields{iField}{1});
    % log starts out empty
    elseif strcmp(requiredFields{iField}{1},'log')
      sidDatabase.log = {};
    end
  end
  % set the dateAdded
  sidDatabase.dateAdded{end+1} = datestr(now);
  % save it back
  saveSIDDatabase(sidDatabase);
  % release lock
  releaseLock(true);
else
  % release lock
  releaseLock;
end

%%%%%%%%%%%%%%%%
%    backupSID   %
%%%%%%%%%%%%%%%%
function backupSID(private,listStartDate)

global gMaxSID;

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get the lock
if ~getLock return,end

% get database path
sidDatabasePath = fileparts(mlrReplaceTilde(mglGetParam('sidDatabaseFilename')));
if ~isdir(sidDatabasePath)
  disp(sprintf('(mglSetSID) Could not find datbase path: %s',sidDatabasePath));
  releaseLock;
  return
end

sidDatabaseFilename = getLastDir(mlrReplaceTilde(mglGetParam('sidDatabaseFilename')));
% open the SID database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase)
  releaseLock;
  return
end
disp(sprintf('(mglSetSID:backup) Found %i subject listings in current database',length(sidDatabase.sid)));

% get backup name
backupName = sprintf('backup%s',datestr(now,'YYYYMMDD'));
backupNameStem = sprintf('backup%s',datestr(now,'YYYYMMDD'));iBackup = 1;
% look for one that is not taken already
while isdir(fullfile(sidDatabasePath,backupName))
  backupName = sprintf('%s_%i',backupNameStem,iBackup);
end

if askuser(sprintf('(mglSetSID:backup) Make backup: %s',fullfile(sidDatabasePath,backupName)))
  % make the directory
  mkdir(fullfile(sidDatabasePath,backupName));

  % save the backup
  backupName = fullfile(sidDatabasePath,backupName,sidDatabaseFilename);
  dispHeader(sprintf('(mglSetSID) Saving backup: %s',backupName));
  saveSIDDatabase(sidDatabase,backupName);
end

% now check for fields that need to be updated
% release lock
releaseLock;

%%%%%%%%%%%%%%%%%%%%%%%
%    getBackupName    %
%%%%%%%%%%%%%%%%%%%%%%%
function [backupName sidDatabasePath sidDatabaseFilename] = getBackupName

% default return arguments
backupName = [];
sidDatabasePath = [];
sidDatabseFilename = [];

% get database path
sidDatabasePath = fileparts(mlrReplaceTilde(mglGetParam('sidDatabaseFilename')));
if ~isdir(sidDatabasePath)
  disp(sprintf('(mglSetSID) Could not find datbase path: %s',sidDatabasePath));
  return
end
sidDatabaseFilename = getLastDir(mlrReplaceTilde(mglGetParam('sidDatabaseFilename')));

% look for all backups
backupDir = dir(fullfile(sidDatabasePath,'backup*'));

% make sure they all have datbases in them
backupNames = {};
for iDir = 1:length(backupDir)
  if isfile(fullfile(sidDatabasePath,backupDir(iDir).name,sidDatabaseFilename))
    backupNames{end+1} = backupDir(iDir).name;
  else
    disp(sprintf('(mglSetSID) Backup dir: %s does not have file: %s',backupDir(iDir).name,sidDatabaseFilename));
  end
end

% check for empty
if isempty(backupNames)
  disp(sprintf('(mglSetSID) No backups found in: %s',sidDatabasePath));
  return
end

% put them in reverse chronological order
backupNames = fliplr(sort(backupNames));

% give user option to chose
paramsInfo = {{'backupDir',backupNames}};
params = mrParamsDialog(paramsInfo);
if isempty(params)
  return
end

% return the chosen backup dir
backupName = params.backupDir;


%%%%%%%%%%%%%%%%
%    mergeSID   %
%%%%%%%%%%%%%%%%
function mergeSID(private,listStartDate)

global gMaxSID;

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get the lock
if ~getLock return,end

% get the backup name
[backupName sidDatabasePath sidDatabaseFilename] = getBackupName;

% try to load the backup
backupDatabase = loadSIDDatabase(fullfile(sidDatabasePath,backupName,sidDatabaseFilename));
if isempty(backupDatabase)
  releaseLock;
  return
end
disp(sprintf('(mglSetSID:merge) Found %i subject listings in backup: %s',length(backupDatabase.sid),backupName));

% open the SID database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase)
  releaseLock;
  return
end
disp(sprintf('(mglSetSID:merge) Found %i subject listings in current database',length(sidDatabase.sid)));

% check to see if they are equal
if isequal(backupDatabase,sidDatabase)
  disp(sprintf('(mglSetSID:merge) Backup %s is identical to current database. Nothing to do',backupName));
  releaseLock;
  return
end

% if not, go through each one of the backup database information and
% see if it is in the current databse and if so whether it has new fields
backupFields = fieldnames(backupDatabase);backupFields = setdiff(backupFields,'sid');
sidFields = fieldnames(sidDatabase);sidFields = setdiff(sidFields,'sid');
somethingToDo = false;
for iSID = 1:length(backupDatabase.sid)
  % look it up
  s.currentSID(iSID) = find(strcmp(backupDatabase.sid{iSID},sidDatabase.sid));
  % if not there then we will propose to add
  if isempty(s.currentSID(iSID))
    s.newSID(iSID) = true;
    somethingToDo = true;
  else
    % if it is there, see if it has any information that
    % is in conflict or filled in that the old one does not
    s.newSID(iSID) = false;
    for iField = 1:length(backupFields)
      % see if the field is non-existent or empty in the current database
      if ~isfield(sidDatabase,backupFields{iField})
	% does not exist in current
	s.(backupFields{iField})(iSID) = 1;
	somethingToDo = true;
      elseif isempty(sidDatabase.(backupFields{iField}){s.currentSID(iSID)})
	% is empty in current, and also empty in backup
	if isempty(backupDatabase.(backupFields{iField}){iSID})
	  s.(backupFields{iField})(iSID) = 0;
	else
	  % not empty in backup, so offer to copy
	  s.(backupFields{iField})(iSID) = 1;
	  somethingToDo = true;p
	end
      elseif ~isequal(sidDatabase.(backupFields{iField}){s.currentSID(iSID)},backupDatabase.(backupFields{iField}){iSID})
	% is different in current
	s.(backupFields{iField})(iSID) = 2;
	somethingToDo = true;
      else
	% otherwise the same
	s.(backupFields{iField})(iSID) = 0;
      end
    end
  end
end

% check to see if we have anything to do
if ~somethingToDo
  disp(sprintf('(mglSetSID:merge) Backup %s has no information that is not in current database.',backupName));
  releaseLock;
  return
end

% keep original database for printing out
originalDatabase = sidDatabase;

% now print out all the new subjects ask to merge
if any(s.newSID)
  % get the list
  newSID = find(s.newSID);
  dispHeader;
  dispHeader(sprintf('SIDs found in %s that are not in current',backupName));
  dispHeader;
  % display them
  for iSID = 1:length(newSID)
    dispSID(backupDatabase,newSID(iSID));
  end
  if askuser('(mglSetSID) Add the above to the current SID database (you will have another chance to confirm this before it actually gets saved)')
    for iSID = 1:length(newSID)
      % add the SID
      sidDatabase.sid{end+1} = backupDatabase.sid{newSID(iSID)};
      for iField = 1:length(sidFields)
	% if the field exists in the backupDatabase
	if isfield(backupDatabase,sidFields{iField})
	  % then copy it
	  sidDatabase.(sidFields{iField}){end+1} = backupDatabase.(sidFields{iField}){newSID(iSID)};
	else
	  % otherwise set it to empty
	  sidDatabase.(sidFields{iField}){end+1} = [];
	end
      end
    end
  end
end
  
% now look at each field and see if there is something to update  
for iField = 1:length(backupFields)
  % get which subjects need to be updated
  updateSID = find(s.(backupFields{iField}));
  if ~isempty(updateSID)
    dispHeader;
    dispHeader(sprintf('(mglSetSID:merge) Field %s is different in backup',backupFields{iField}));
    dispHeader;
    for iSID = 1:length(updateSID)
      % display the SID
      dispSID(backupDatabase,updateSID(iSID));
      % display the change
      if isfield(sidDatabase,backupFields{iField})
	% if it is a field that exist in the current database
	disp(sprintf('Change from: %s to: %s',sidDatabase.(backupFields{iField}){s.currentSID(updateSID(iSID))},backupDatabase.(backupFields{iField}){updateSID(iSID)}));
      else	
	% if it is completely new
	disp(sprintf('Make into: %s',backupDatabase.(backupFields{iField}){updateSID(iSID)}));
      end
    end
    % see if the user wants to do the above changes
    if askuser('(mglSetSID) Make above changes to current SID database (you will have another chance to confirm this before it actually gets saved)')
      for iSID = 1:length(updateSID)
	sidDatabase.(backupFields{iField}){s.currentSID(updateSID(iSID))} = backupDatabase.(backupFields{iField}){updateSID(iSID)};
      end
    end
  end
end

% now ask for a final confirmation, first show original database
dispHeader
dispHeader('(mglSetSID:merge) Original SID database');
dispHeader;
for iSID = 1:length(originalDatabase.sid)
  dispSID(originalDatabase,iSID);
end

% now show proposed new database
dispHeader
dispHeader('(mglSetSID:merge) Proposed merged SID database');
dispHeader;
for iSID = 1:length(sidDatabase.sid)
  dispSID(sidDatabase,iSID);
end
dispHeader('(mglSetSID:merge) Original and proposed merged database are above');
if ~askuser('(mglSetSID:merge) Confirm changes (If you say yes this will save changes and a backup of the original will be made)');
  releaseLock;
  return
end

% ok first make a backup
backupName = sprintf('backup%s',datestr(now,'YYYYMMDD'));
backupNameStem = sprintf('backup%s',datestr(now,'YYYYMMDD'));iBackup = 1;
% look for one that is not taken already
while isdir(fullfile(sidDatabasePath,backupName))
  backupName = sprintf('%s_%i',backupNameStem,iBackup);
end

% make the directory
mkdir(fullfile(sidDatabasePath,backupName));

% save the backup
backupName = fullfile(sidDatabasePath,backupName,sidDatabaseFilename);
dispHeader(sprintf('(mglSetSID) Saving backup: %s',backupName));
saveSIDDatabase(sidDatabase,backupName);

% save the updated version
dispHeader(sprintf('(mglSetSID) Saving merged database: %s',fullfile(sidDatabasePath,sidDatabaseFilename)));
saveSIDDatabase(sidDatabase);

% now check for fields that need to be updated
% release lock
releaseLock;

%%%%%%%%%%%%%%%%
%    listSID   %
%%%%%%%%%%%%%%%%
function listSID(private,listStartDate,listBackup)

global gMaxSID;

% check for mrTools
if ~mglIsMrToolsLoaded,return,end

% get the lock
if ~getLock return,end

if listBackup
  % get the backup name
  [backupName sidDatabasePath sidDatabaseFilename] = getBackupName;
  if isempty(backupName)
    releaseLock;
    return
  end
  backupFullFilename = fullfile(sidDatabasePath,backupName,sidDatabaseFilename);

  % print name
  dispHeader(sprintf('(mglSetSID) Loading: %s',backupFullFilename));

  % load the backup database
  sidDatabase = loadSIDDatabase(backupFullFilename);
else
  % open the SID database
  sidDatabase = loadSIDDatabase;
end

% release lock
releaseLock;

% check for problem opening database
if isempty(sidDatabase),return,end

% select out database entries that match listStartYear parameter
if ~isempty(listStartDate)
  % display what we are doing
  disp(sprintf('(mglSetSID) Removing entries that were entered before: %s',listStartDate));
  dispHeader('drop list');
  % cycle through looking at dates
  keepList = [];
  for iSID = 1:length(sidDatabase.sid)
    if datenum(sidDatabase.dateAdded{iSID})>datenum(listStartDate)
      % keep this one
      keepList(end+1) = iSID;
    else
      % display that we are dropping the following sid
      dispSID(sidDatabase,iSID);
    end
  end
  % check for empty
  if isempty(keepList)
    disp(sprintf('(mglSetSID) No matching entries'));
    return
  end
  % now just keep the ones in the keepList
  allFields = fieldnames(sidDatabase);
  for iField = 1:length(allFields)
    % subset all fields that have more than one entry 
    % i.e. ones that are per-subject
    if length(sidDatabase.(allFields{iField})) > 1
      sidDatabase.(allFields{iField}) = {sidDatabase.(allFields{iField}){keepList}};
    end
  end
  dispHeader(sprintf('List of entries since: %s',listStartDate));
end
% get postfix
if ~isempty(private)
  postfix = getPostfix(sidDatabase,private);
  if isempty(postfix)
    disp(sprintf('(mglSetSID:addSID) No postfix for private SID: %s. Aborting',private));
    return
  end
else
  postfix = [];
end

% display all entries
for iSID = 1:length(sidDatabase.sid)
  dispSID(sidDatabase,iSID);
end

% compute statistics

% number of subjects
stats.n = length(sidDatabase.sid);

% number of male and female
stats.f = sum(strcmp('f',lower(sidDatabase.gender)));
stats.m = sum(strcmp('m',lower(sidDatabase.gender)));
stats.nonbinary = sum(strcmp('non-binary',lower(sidDatabase.gender)));

% ethnicity
stats.ethnicity = unique(lower(sidDatabase.ethnicity));
for iEthnicity = 1:length(stats.ethnicity)
  stats.ethnicityN(iEthnicity) = sum(strcmp(stats.ethnicity{iEthnicity},lower(sidDatabase.ethnicity)));
end

% race
stats.race = unique(lower({sidDatabase.race{:} sidDatabase.otherRace1{:} sidDatabase.otherRace2{:} sidDatabase.otherRace3{:} sidDatabase.otherRace4{:}}));
for iRace = 1:length(stats.race)
  stats.raceN(iRace) = sum(strcmp(stats.race{iRace},lower(sidDatabase.race)));
  stats.otherRace1N(iRace) = sum(strcmp(stats.race{iRace},lower(sidDatabase.otherRace1)));
  stats.otherRace2N(iRace) = sum(strcmp(stats.race{iRace},lower(sidDatabase.otherRace2)));
  stats.otherRace3N(iRace) = sum(strcmp(stats.race{iRace},lower(sidDatabase.otherRace3)));
  stats.otherRace4N(iRace) = sum(strcmp(stats.race{iRace},lower(sidDatabase.otherRace4)));
end

% count number of declines
declineRace = strcmp('n/a',lower(sidDatabase.race)) | strcmp('decline',lower(sidDatabase.race));
declineRace1 = strcmp('n/a',lower(sidDatabase.otherRace1)) | strcmp('decline',lower(sidDatabase.otherRace1));
declineRace2 = strcmp('n/a',lower(sidDatabase.otherRace2)) | strcmp('decline',lower(sidDatabase.otherRace2));
declineRace3 = strcmp('n/a',lower(sidDatabase.otherRace3)) | strcmp('decline',lower(sidDatabase.otherRace3));
declineRace4 = strcmp('n/a',lower(sidDatabase.otherRace4)) | strcmp('decline',lower(sidDatabase.otherRace4));
stats.raceDeclineTotal = sum(declineRace & declineRace1 & declineRace2 & declineRace4);

% count races across all fields
stats.raceTotal = stats.raceN + stats.otherRace1N + stats.otherRace2N + stats.otherRace3N + stats.otherRace4N;


% get age in years
for iSID = 1:stats.n
  if ~isempty(sidDatabase.dob{iSID})
    age = datevec(datenum(now)-datenum(sidDatabase.dob{iSID}));
    stats.age(iSID) = age(1);
    if stats.age(iSID) > 120
      stats.age(iSID) = nan;
    end
  else
    stats.age(iSID) = nan;
  end
end

% missing sttast
missingStats.f = 15;
missingStats.m = 15;
missingStats.race{1} = 'asian';
missingStats.n(1) = 70;
missingStats.race{2} = 'american indian or alaska native';
missingStats.n(2) = 2;
missingStats.race{3} = 'black or african american';
missingStats.n(3) = 14;
missingStats.race{4} = 'decline';
missingStats.n(4) = 28;
missingStats.race{5} = 'native hawaiian or other pacific islander';
missingStats.n(5) = 1;
missingStats.race{6} = 'white';
missingStats.n(6) = 104;
missingStats.ethnicity{1} = 'hispanic or latino';
missingStats.nEthnicity(1) = 31;

% cycle through the races in missing stats
naIndex = strcmp('n/a',lower(stats.race));
for iRace = 1:length(missingStats.race)
  % if there is a match
  raceMatch = find(strcmp(missingStats.race{iRace},stats.race));
  if ~isempty(raceMatch)
    % then add the count to that count
    stats.raceN(raceMatch) = stats.raceN(raceMatch) + missingStats.n(iRace);
  else
    % add the race category
    stats.race{end+1} = missingStats.race{iRace};
    stats.raceN(end+1) = missingStats.n(iRace);
  end
  % add decrement the count from n/a
  stats.raceN(naIndex) = stats.raceN(naIndex) - missingStats.n(iRace);
  stats.raceDeclineTotal = stats.raceDeclineTotal - missingStats.n(iRace);
end
% add the hispanic or latino count
naIndex = strcmp('n/a',lower(stats.ethnicity));
for iEthnicity = 1:length(missingStats.ethnicity)
  % if there is a match
  ethnicityMatch = find(strcmp(missingStats.ethnicity{iEthnicity},stats.ethnicity));
  if ~isempty(ethnicityMatch)
    % then add the count to that count
    stats.ethnicityN(ethnicityMatch) = stats.ethnicityN(ethnciityMatch) + missingStats.nEthnicity(iEthnicity);
  else
    % add the ethnicity category (not tested)
    stats.ethnicity{end+1} = missingStats.ethnicity{iEthnicity};
    stats.ethnicityN(end+1) = missingStats.nEthnicity(iEthnicity);
  end
  % add decrement the count from n/a
  stats.ethnicityN(naIndex) = stats.ethnicityN(naIndex) - missingStats.n(iEthnicity);
end
% add gender and total n
stats.n = stats.n + missingStats.f + missingStats.m;
stats.f = stats.f + missingStats.f;
stats.m = stats.m + missingStats.m;

% display statistics
dispHeader('Gender');
disp(sprintf('Total n: %i',stats.n));
disp(sprintf('Female: %i (%0.2f%%)',stats.f,100*stats.f/stats.n));
disp(sprintf('Male: %i (%0.2f%%)',stats.m,100*stats.m/stats.n));
disp(sprintf('Non-binary: %i (%0.2f%%)',stats.nonbinary,100*stats.nonbinary/stats.n));
disp(sprintf('Decline: %i (%0.2f%%)',stats.n-(stats.m+stats.f),100*(stats.n-(stats.m+stats.f))/stats.n));
dispHeader('Ethnicity');
for iEthnicity = 1:length(stats.ethnicity)
  disp(sprintf('%s: %i (%0.2f%%)',stats.ethnicity{iEthnicity},stats.ethnicityN(iEthnicity),100*stats.ethnicityN(iEthnicity)/stats.n));
end
dispHeader('Race totals');
disp(sprintf('Decline or n/a: %i (%0.2f%%)',stats.raceDeclineTotal, 100*stats.raceDeclineTotal/stats.n));
for iRace = 1:length(stats.race)
  if ~any(strcmp(lower(stats.race{iRace}),{'n/a','decline'}))
    disp(sprintf('%s: %i (%0.2f%%)',stats.race{iRace},stats.raceN(iRace),100*stats.raceN(iRace)/stats.n));
  end
end

%%%%%%%%%%%%%%%%%
%    dispSID    %
%%%%%%%%%%%%%%%%%
function dispSID(sidDatabase,iSID)

% get the fields we have
columnNames = fieldnames(sidDatabase);

% initialize display string
dispStr = '';
for iVal = 1:length(columnNames)
  % get the value of the field
  fieldVal = sidDatabase.(columnNames{iVal}){iSID};
  if ~isstr(fieldVal),fieldVal = '';end
  % some fields are long, so give them two tabs
  if any(strcmp(columnNames{iVal},{'firstName','lastName'}))
    if length(fieldVal) >= 8
      dispStr = sprintf('%s%s\t',dispStr,fieldVal);
    else
      dispStr = sprintf('%s%s\t\t',dispStr,fieldVal);
    end
  else
    dispStr = sprintf('%s%s\t',dispStr,fieldVal);
  end
end
disp(dispStr);

%%%%%%%%%%%%%%%%%%%%
%    getPostfix    %
%%%%%%%%%%%%%%%%%%%%
function postfix = getPostfix(sidDatabase,private,matchOnly)

postfix = [];
if isempty(private),return,end
if nargin<3,matchOnly = false;end
% look for this private marker in the datbase
privateMatch = find(strcmp(lower(private),sidDatabase.private));

% if there is a match, then return existing postfix
% the postfix is the letters after the number in subject
% ID. e.g. s0001x (postfix = x) It can be a more than one
% letter code
if ~isempty(privateMatch)
  % get the postfix
  [issid postfixPos] = regexp(sidDatabase.sid{privateMatch(1)},'s\d+');
  if issid && (postfixPos < length(sidDatabase.sid{privateMatch(1)}))
    % if valid, then set it.
    postfix = sidDatabase.sid{privateMatch(1)}(postfixPos+1:end);
  end
  return
end
if matchOnly,return,end

% not found, first get all the postfixes
% so that we can validate whether one
% is existing or not
existingPostfix = {};
for iSID = 1:length(sidDatabase.sid)
  [issid postfixPos] = regexp(sidDatabase.sid{iSID},'s\d+');
  if issid && (postfixPos < length(sidDatabase.sid{iSID}))
    existingPostfix{end+1} = sidDatabase.sid{iSID}(postfixPos+1:end);
  end
end
existingPostfix = unique(existingPostfix);

% generate all possible postfixs of one letter
possiblePostfix = {};
for iLetter = 'a':'z'
  possiblePostfix{end+1} = iLetter;
end
% only offer postfix that has not been used already
possiblePostfix = setdiff(possiblePostfix,existingPostfix);

% try to put the first letter at the top of the list
if ismember(lower(private(1)),possiblePostfix)
  % if the first letter of the private string
  % is available, put it on the top of the list
  possiblePostfix = putOnTopOfList(lower(private(1)),possiblePostfix);
else
  % if not, then add the first letter + every letter of the alphabet
  for iLetter = 'a':'z'
    possiblePostfix{end+1} = sprintf('%s%s',lower(private(1)),iLetter);
  end
  % only offer postfix that has not been used already
  possiblePostfix = setdiff(possiblePostfix,existingPostfix);
  if ismember(lower(private(1:2)),possiblePostfix)
    possiblePostfix = putOnTopOfList(lower(private(1:2)),possiblePostfix);
  end
end

paramsInfo{1} = {'postfix',possiblePostfix,'type=popupmenu',sprintf('Choose the subjectID postfix for the private sid database: %s. This is the character that will go after s001 to distinguish it form other subject IDs. For example, s001x',private)};
params = mrParamsDialog(paramsInfo,sprintf('Choose postfix for %s',private));
if ~isempty(params),postfix = params.postfix;end

%%%%%%%%%%%%%%%%%%%%%%
%    validateDate    %
%%%%%%%%%%%%%%%%%%%%%%
function val = validateDate(fieldName,params)

% validate date
try
  d = datevec(datenum(params.(fieldName)));
  val = sprintf('%i/%i/%i',d(2),d(3),d(1));
  % check to see if the subject is under 18
  if ~checkAgeLimit(val),val = '';end
catch
  disp(sprintf('(mglSetSID:validateDate) Invalid date: %s',params.(fieldName)));
  val = '';
end
% set validated date back
params.(fieldName) = val;
mrParamsSet(params);

%%%%%%%%%%%%%%%%%%%%%%%%
%    validateNewSID    %
%%%%%%%%%%%%%%%%%%%%%%%%
function val = validateNewSID(sidUsed,params)

global gMaxSID;

% set sid to the proposed new sid
if isstruct(params)
  sid = params.sid;
else
  sid = params;
end

% make an array of all possible SIDs starting with the
% one in params. Check if they are in sidUsed and
% select the first one in the list that is not in used
possibleSID = [sid:gMaxSID 1:sid];
isAlreadyUsed = ismember(possibleSID,sidUsed);
val = possibleSID(first(find(~isAlreadyUsed)));

% reset the mrParamsDialog with the new value
if isstruct(params)
  params.sid = val;
  mrParamsSet(params);
end
%%%%%%%%%%%%%%%%%
%    sid2num    %
%%%%%%%%%%%%%%%%%
function [num postfix] = sid2num(sid)

num = [];
% we are looking for something
% that looks like sxxxx with a possible character
% at end, e.g. s0001a = subjectID num of 1
for i = 2:length(sid)
  % keep looking for digits
  if isempty(regexp(sid(i),'\d'))
    % found non-digit, so go back one
    i = i - 1;
    % and break loop
    break
  end
end
% get the number
if i <=length(sid)
  num = str2num(sid(2:i));
end
% get any postfix string
postfix = sid(i+1:end);

%%%%%%%%%%%%%%%%%
%    num2sid    %
%%%%%%%%%%%%%%%%%
function sid = num2sid(sid,postfix)

if nargin < 2,postfix = '';end

global gMaxSID;
if ((sid>=1)&&(sid<=gMaxSID))
  sid = sprintf('s%03i%s',round(sid),postfix);
elseif (sid == -1)
  sid = 'test';
else
  disp(sprintf('(mglSetSID) Numeric SID should be 1-%i for actual subejct ID or -1 for a test',gMaxSID));
  sid = [];
end

%%%%%%%%%%%%%%%%%%
%    name2sid    %
%%%%%%%%%%%%%%%%%%
function sid = name2sid(sid,private)

% check if it is test
if strcmp(lower(sid),'test')
  sid = 'test';
  return
end

% lookup name
sidstr = sid;
[sid firstName lastName] = lookupSID(sidstr,private);
% found it
if length(sid) == 1
  % if only one, display and set
  disp(sprintf('(mglSetSID) Found subject: %s %s (%s)',firstName{1},lastName{1},sid{1}));
  sid = sid{1};
elseif length(sid) > 1
  % multiple matches, display them all and let subject select
  disp(sprintf('(mglSetSID) Found multiple matches for %s',sidstr));
  for i = 1:length(sid)
    disp(sprintf('%i: %s %s: %s',i,firstName{i},lastName{i},sid{i}));
  end
  c = getnum(sprintf('(mglSetSID) Choose which subject (0 to cancel): ',0:length(sid)));
  % return that
  if (c > 0)
    sid = sid{c};
  else
    sid = [];
  end
else
  disp(sprintf('(mglSetSID) !!! Could not find unique SID for: %s !!!\nSID not set.',sidstr));
  sid = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%
%    editSIDDatabase    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function editSIDDatabase

% get the lock
if ~getLock return, end

% load existing database
sidDatabase = loadSIDDatabase;
if isempty(sidDatabase),releaseLock;return;,end

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
    % set default values for things that will not show up in edit table
    % not that this needs to be fixed if we add more fields beyond
    % experimenter and log - but actually hoping to deprecate this
    % whole edit thing
    if strcmp(columnNames{iCol},'experimenter')
      sidDatabase.(columnNames{iCol}){end+1} = getusername;
    else
      sidDatabase.(columnNames{iCol}){end+1} = '';
    end
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
global numColumns;
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

% save the database
if ~isempty(sidDatabase)
  saveSIDDatabase(sidDatabase);
  % release lock
  releaseLock(true);
else
  % release lock
  releaseLock;
end

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
  fieldNum = find(strcmp(requiredFields{iField}{1},columnNames));
  % check if that field is empty
  if ~isempty(fieldNum) && (size(data,2)>=fieldNum) && isempty(data{rownum,fieldNum})
    tf = false;
    invalidFieldNum = fieldNum;
    invalidFieldName = requiredFields{iField}{1};
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

%%%%%%%%%%%%%%%%%%%%%%%
%    checkAgeLimit    %
%%%%%%%%%%%%%%%%%%%%%%%
function tf = checkAgeLimit(fieldVal)

tf = true;

% get age limit. Default to 18
ageLimit = mglGetParam('sidAgeLimit');
if isempty(ageLimit),ageLimit=18;end

% age - accounting for birthday happening on same as today
age = datevec(datenum(floor(now)+1)-datenum(fieldVal));
if age(1) < ageLimit
  tf = false;
  warndlg(sprintf('!!! Subject born on %s is %i years old which is less than %i years old. Using this subject in an experiment is a protocol violation !!!',fieldVal,age(1),ageLimit),'Age Violation','modal');
end

%%%%%%%%%%%%%%%%%%%%%
%    editSIDcell    %
%%%%%%%%%%%%%%%%%%%%%
function editSIDcell(src, eventdata)

% check formatting of field
[tf fieldVal] = validateField(eventdata.NewData,eventdata.Indices(2));

% check if there is an age limit
global columnNames;
if strcmp(columnNames{eventdata.Indices(2)},'dob')
  tf = checkAgeLimit(fieldVal);
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
    % set all other fields in row to default
    global requiredFields;
    global numColumns;
    rowNum = eventdata.Indices(1);
    for iField = 1:length(requiredFields)
      columnNum = find(strcmp(requiredFields{iField}{1},columnNames));
      % see if it should be filled with a default value
      if ~isempty(columnNum) && (columnNum <= numColumns) && isempty(d{rowNum,columnNum})
	if strcmp(requiredFields{iField}{1},'dateAdded')
	  d{rowNum,columnNum} = datestr(now);
	elseif strcmp(requiredFields{iField}{1},'dob')
	  d{rowNum,columnNum} = '';
	elseif iscell(requiredFields{iField}{2})
	  d{rowNum,columnNum} = requiredFields{iField}{2}{1};
	else
	  d{rowNum,columnNum} = requiredFields{iField}{2};
	end
      end
    end
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

if isequal(fieldVal,nan),fieldVal = '';end

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
      sprintf('(mglSetSID) Missing field: %s for %s',fieldName,data{iRow,1});
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
sidDatabaseLockFilename = mlrReplaceTilde(setext(mglGetParam('sidDatabaseFilename'),'lock',0));

% see if it exists
if mglIsFile(sidDatabaseLockFilename)
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
  else
    tf = false;
    return
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
sidDatabaseLockFilename = mlrReplaceTilde(setext(mglGetParam('sidDatabaseFilename'),'lock',0));

% check if lock is there
if ~mglIsFile(sidDatabaseLockFilename)
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
    % check to see if field exists
    if isfield(t,fields{iField}) && (length(t.(fields{iField})) >= iRow)
      % if it does get it
      fieldVal = t.(fields{iField}){iRow};
    else
      fieldVal = 'N/A';
    end
    % check if field has not been set
    if iscell(fieldVal)
      fieldVal = 'N/A';
    end
    if (iField==1)
      fprintf(f,'%s',fieldVal);
    else
      fprintf(f,',%s',fieldVal);
    end
  end
  fprintf(f,'\n');
end

% close file
fclose(f);


