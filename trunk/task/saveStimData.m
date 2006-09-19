% savestimdata.m
%
%        $Id$
%      usage: savestimdata.m()
%         by: justin gardner
%       date: 12/22/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
function retval = saveStimData(myscreen,task)

global gNumSaves;

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
while(isfile(sprintf('%s.mat',filename)))
  mydisp(sprintf('UHOH: There is already a file %s...',filename));
  gNumSaves = gNumSaves+1;
  thedate = [datestr(now,'yy') datestr(now,'mm') datestr(now,'dd')];
  filename = sprintf('%s_stim%02i',thedate,gNumSaves);
  disp(sprintf('Changing to %s',filename));
end

% ask user if they want to save
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

%make the string for also saving the stimulus structures
getStimuliCommand = '';
stimuliNames = '';
for stimulusNum = 1:length(myscreen.stimulusNames)
  getStimuliCommand = sprintf('%sglobal %s;',getStimuliCommand,myscreen.stimulusNames{stimulusNum});
  stimuliNames = sprintf('%s %s',stimuliNames,myscreen.stimulusNames{stimulusNum});
end

if (strcmp(lower(response),'n'))
  % user aborts, decrement save number
  gNumSaves = gNumSaves - 1;
  return;
elseif (strcmp(response,'y'))
  % user accepts, save data
  mydisp(sprintf('Saving %s...',filename));
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
  % and save it
  mydisp(sprintf('Saving %s...',filename));
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
  if (str2num(first(version)) < 7)
    eval(sprintf('save %s myscreen task %s',response,stimuliNames));
  else
    eval(sprintf('save %s myscreen task %s -V6',response,stimuliNames));
  end
  mydisp(sprintf('done.\n'));
end