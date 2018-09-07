% addCalculatedVar.m
%
%      usage: addCalculatedVar(varname,varval,stimfileName)
%         by: justin gardner
%       date: 08/06/10
%    purpose: add a computed variable to a stimfile
% 
%       e.g.: addCalculatedVar('newvar',[1 3 4 5 6 2 8 10],'100728_stim01');
%             To specify taskNum (default=1) and phaseNum (default=1)
%             addCalculatedVar('newvar',[1 3 4 5 6 2 8 10','100728_stim01','taskNum=2','phaseNum=2');
%   
%             You may also want to specify all possible values a variable can take (useful if in
%             each particular stimfile you won't necessarily encounter each value the variable can take);
%             addCalculatedVar('newvar',[1 3 4 5 6 2 8 10],'100727_stim01','taskNum=2','phaseNum=2','allval',1:10);
%             
%             To not make backups - set backup=0
%             addCalculatedVar('newvar',[1 3 4 5 6 2 8 10],'100728_stim01','backup=0');
%             To always make backups (i.e. make a unique backup each time the file is changed)
%             addCalculatedVar('newvar',[1 3 4 5 6 2 8 10],'100728_stim01','backup=2');
%
function retval = addCalculatedVar(varname,varval,stimfile,varargin)

% check arguments
if any(nargin < 3)
  help addCalculatedVar
  return
end

taskNum=[];
phaseNum=[];
force=[];
allval=[];
backup = [];
getArgs(varargin,{'taskNum=1','phaseNum=1','force=0','allval=[]','backup=1'});

stimfile = setext(stimfile,'mat');
if ~mglIsFile(stimfile)
  disp(sprintf('(addCalculatedVar) Could not find stimfile %s',stimfile));
  return
end

% load and valideate
s = load(stimfile);
if ~isfield(s,'myscreen') || ~isfield(s,'task')
  disp(sprintf('(addCalculatedVar) File %s is not a stimfile - missing myscreen or task',stimfile));
  return
end

% make sure task is a cell array
s.task = cellArray(s.task,2);

% add default fields if they do not yet exist
if ~isfield(s.task{taskNum}{phaseNum}.randVars,'names_')
  s.task{taskNum}{phaseNum}.randVars.names_ = {};
  s.task{taskNum}{phaseNum}.randVars.varlen_ = [];
end

% check whether variable already exist
if any(strcmp(varname,s.task{taskNum}{phaseNum}.randVars.names_))
  if force
    disp(sprintf('(addCalculatedVar) Variable %s already exists in task. Overwriting (this will still keep an original copy of stimfile)',varname));
  else
    if ~askuser(sprintf('(addCalculatedVar) Variable %s already exists in task. Overwrite existing value (this will still keep an original copy of stimfile)',varname))
      return
    end
  end
end

% get number of trials
e = getTaskParameters(s.myscreen,s.task);
nTrials = e{taskNum}(phaseNum).nTrials;

% check number of trials
if length(varval) ~= nTrials
  if force
    disp(sprintf('(addComuptedVar) Passed in variable values has %i trials, but structure in %s has %i trials',length(varval),stimfile,nTrials));
  else
    if ~askuser(sprintf('(addComuptedVar) Passed in variable values has %i trials, but structure in %s has %i trials, continue?',length(varval),stimfile,nTrials))
      return
    end
  end
end

if backup
    % now make sure there is an original backup
    originalBackup = sprintf('%s_original.mat',stripext(stimfile));
    if mglIsFile(originalBackup)
      if backup >= 2
	originalBackup = sprintf('%s_backup_%s.mat',stripext(stimfile),datestr(now,'ddmmyyyy_HHMMSS'));
	disp(sprintf('(adCalculatedVar) Original backup already exists, saving as %s',originalBackup));
      else
	disp(sprintf('(adCalculatedVar) Original backup %s already exists, skipping making new backup (set backup=2 if you want multiple backups)',originalBackup));
      end
    end
    if mglIsFile(originalBackup)
      disp(sprintf('(adCalculatedVar) %s already exists',originalBackup));
    else
      % save
      eval(sprintf('save %s -struct s',originalBackup));
    end
end

% set the new variable
s.task{taskNum}{phaseNum}.randVars.n_ = s.task{taskNum}{phaseNum}.randVars.n_+1;
s.task{taskNum}{phaseNum}.randVars.names_{end+1} = varname;
s.task{taskNum}{phaseNum}.randVars.varlen_(end+1) = length(varval);
s.task{taskNum}{phaseNum}.randVars.(varname) = varval;

% add it to calculated
if isempty(allval)
  s.task{taskNum}{phaseNum}.randVars.calculated.(varname) = unique(varval);
else
  s.task{taskNum}{phaseNum}.randVars.calculated.(varname) = allval;
end
  

% and save
disp(sprintf('(addCalculatedVar) Saving variable %s into %s for taskNum=%i phaseNum=%i',varname,stimfile,taskNum,phaseNum));
eval(sprintf('save %s -struct s',stimfile));


