% endTask.m
%
%        $Id$
%      usage: myscreen = endTask(myscreen,task)
%         by: justin gardner
%       date: 09/18/06
%    purpose: packages all variables into myscreen
%             and reports any thrown errors
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%
function myscreen = endTask(myscreen,task)
    
    % check arguments
    if ~any(nargin == [2])
        help endTask
        return
    end
    
    % quit keyboard listener
    mglListener('quit');
    
    % compute traces and save data
    myscreen = endScreen(myscreen);
    % This funciton will check for existing stim files and update the save
    % number appropriately. This should ensure that the eyelink data will always
    % matched, as the stim and eyelink will have the same file number.
    saveStimData(myscreen,task);
    
    if myscreen.eyetracker.init
        feval(myscreen.eyetracker.callback.endTracking,task,myscreen);
    end
    
    
    mydisp(sprintf('End task\n'));
    % we are done
    myscreen.task = task;
    % package up stimuli
    myscreen.stimuli = '';
    for stimulusNum = 1:length(myscreen.stimulusNames)
        eval(sprintf('global %s;',myscreen.stimulusNames{stimulusNum}));
        eval(sprintf('myscreen.stimuli{end+1} = %s;',myscreen.stimulusNames{stimulusNum}));
    end
    
    % switch back to current directory
    if isfield(myscreen,'pwd') && isdir(myscreen.pwd)
        cd(myscreen.pwd);
    end

end

