% savestimdata.m
%
%        $Id$
%      usage: savestimdata.m(myscreen,task,<forceSave>)
%         by: justin gardner
%       date: 12/22/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: saves the myscreen/task/stimulus. This will normally obey settings
%             from mglEditScreenParams on whether to save the stim file (or ask
%             the user whether to save). If you set forceSave=1, then it will
%             save the stim file regardless of what the settings are.
%
function myscreen = saveStimData(myscreen,task,forceSave)

% default not to override file save settings from myscreen/mglEditScreenParams
if nargin<3,forceSave = false;end

global gNumSaves;
myscreen.stimfile = '';
% update the numsaves variable
if (isempty(gNumSaves))
  gNumSaves = 1;
else
  gNumSaves = gNumSaves+1;
end

% convert task handles to strings
task = removeTaskFunctionHandles(task);

% get filename
thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
filename = sprintf('%s_stim%02i',thedate,gNumSaves);

% make sure we don't have an existing file in the directory
% that would get overwritten
changedName = 0;
while(isfile(fullfile(myscreen.datadir,sprintf('%s.mat',filename))))
  gNumSaves = gNumSaves+1;
  thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
  filename = sprintf('%s_stim%02i',thedate,gNumSaves);
  changedName = 1;
end
% display name if it changes
if changedName
  disp(sprintf('(saveStimData) Changed output file to %s',filename));
end

% add path to filename
filename = fullfile(myscreen.datadir,filename);

% ask user if they want to save
if forceSave
  response = 'y';
else
  if (myscreen.saveData == -1)
    % ask whether to save
    response = '';
    while ~strcmp(response,'y') && ~strcmp(response,'n')
      response = input(sprintf('Save data %s? (y/n) ',filename),'s');
    end
  elseif (myscreen.saveData == 0)
    % don't save
    response = 'n';
  else
    % if we have exceeded the number of volumes expected for 
    % a run (set in initscreen), then save automatically,
    % otherwise ask whether to save
    if (myscreen.volnum > myscreen.saveData)
      response = 'y';
    else
      response = '';
      while ~strcmp(response,'y') && ~strcmp(response,'n')
	response = input(sprintf('Save data %s? (y/n) ',filename),'s');
      end
    end
  end
end

%make the string for also saving the stimulus structures
getStimuliCommand = '';
stimuliNames = '';
for stimulusNum = 1:length(myscreen.stimulusNames)
  getStimuliCommand = sprintf('%sglobal %s;',getStimuliCommand,myscreen.stimulusNames{stimulusNum});
  stimuliNames = sprintf('%s %s',stimuliNames,myscreen.stimulusNames{stimulusNum});
end
eval(getStimuliCommand);

if (strcmp(lower(response),'n'))
  % user aborts, decrement save number
  gNumSaves = gNumSaves - 1;
  return;
else
  % we're going to save the data
  if (strcmp(response,'y'))
    % user accepts, save data
    mydisp(sprintf('Saving %s...',filename));
    myscreen.stimfile = filename;
    if (str2num(first(version)) < 7)
      eval(sprintf('save %s myscreen task %s',filename,stimuliNames));
    else
      eval(sprintf('save %s myscreen task %s -V6',filename,stimuliNames));
    end    
    mydisp(sprintf('done.\n'));
  elseif (~isempty(str2num(response)) && (sigfig(str2num(response)) == 0))
    % user has input a new number for sequence
    gNumSaves = str2num(response);
    % get filename
    filename = sprintf('%s_stim%02i',thedate,gNumSaves);
    filename = fullfile(myscreen.datadir,filename);
    % and save it
    mydisp(sprintf('Saving %s...',filename));
    myscreen.stimfile = filename;
    if (str2num(first(version)) < 7)
      eval(sprintf('save %s myscreen task %s',filename,stimuliNames));
    else
      eval(sprintf('save %s myscreen task %s -V6',filename,stimuliNames));
    end
    mydisp(sprintf('done.\n'));
  else
    gNumSaves = gNumSaves - 1;
    % user has input a filename
    mydisp(sprintf('Saving %s...',response));
    myscreen.stimfile = filename;
    if (str2num(first(version)) < 7)
      eval(sprintf('save %s myscreen task %s',response,stimuliNames));
    else
      eval(sprintf('save %s myscreen task %s -V6',response,stimuliNames));
    end
    mydisp(sprintf('done.\n'));
  end
  % always save eyedata if were saving data
  if myscreen.eyetracker.init && isfield(myscreen.eyetracker.callback,'saveEyeData')
    if myscreen.eyetracker.savedata
      [task, myscreen] = feval(myscreen.eyetracker.callback.saveEyeData,task,myscreen);
    end
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% returns first element of input array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = first(x)

if (isempty(x))
  retval = [];
else
  retval = x(1);
end


