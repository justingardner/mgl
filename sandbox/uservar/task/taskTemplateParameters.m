% taskTemplate.m
%
%        $Id$
%      usage: taskTemplate
%         by: justin gardner
%       date: 09/07/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use the task structure's
%             various parameter mechanisms
%

function myscreen = taskTemplate

    % check arguments
    if ~any(nargin == [0])
        help taskTemplate
        return
    end
    
    % initalize the screen
    myscreen.screenParams{1} = {'yoyodyne.cns.nyu.edu',[],2,1280,1024,57,[31 23],60,1,0,1.8,''};
    myscreen.screenParams{2} = ...
        {'sibeling.local',[],0,800,600,38.5,[17.5 13.5],60,1,1,1.8,'',[0 0]};
    myscreen = initScreen(myscreen);
    
    task{1}.waitForBacktick = 1;
    % fix: the task defined here has two segments, one that
    % is 3 seconds long followed by another that is 
    % 6-9 seconds (randomized in steps of 1.5 seconds)
    % change this to what you want for your trial
    task{1}.segmin =   [1 1   1];
    task{1}.segmax =   [1 1   1];
    task{1}.segquant = [0 1.5 0];
    % fix: enter the parameter of your choice
    task{1}.parameter.myParameter = [0 30 90];
    task{1}.parameter.myArrayParam = [1 2 3; 4 5 6];
    task{1}.random = 1;
    
    % task{1}.randVars.block.distract = [1 2 3 4];
    % task{1}.randVars.uniform.deltaOR = [-5 5]; % second orientation is + or - 5 degrees
    
    % task{1}.segmentVars.alpha = []; % a parameter that the task will fill in as we go
    % task{1}.taskVars.beta = 1:20;
    % 
    % task{1}.parameter.foo1.type = 'task'
    % task{1}.parameter.foo1.value = 1:10
    % task{1}.parameter.foo1.random = 'none'
    % task{1}.parameter.foo2.type = 'block'
    % task{1}.parameter.foo2.value = 1:10
    % task{1}.parameter.foo2.random = 'cross'
    % task{1}.parameter.foo2.type = 'block'
    % task{1}.parameter.foo2.value = 1:10
    % task{1}.parameter.foo2.random = 'uniform'
    % task{1}.parameter.foo3.type = 'segment'
    % task{1}.parameter.foo3.value = 1:10
    % task{1}.parameter.foo3.random = 'none'
    % task{1}.parameter.foo4.type = 'user'
    % task{1}.parameter.foo4.value = 1:10
    % task{1}.parameter.foo4.random = 'none'
    
    % initialize the task
    for phaseNum = 1:length(task)
        [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@stimStartSegmentCallback,@stimDrawStimulusCallback);
    end
    
    % init the stimulus
    global stimulus;
    myscreen = initStimulus('stimulus',myscreen);

    % fix: you will change the funciton myInitStimulus
    % to initialize the stimulus for your experiment.
    stimulus = myInitStimulus(stimulus,myscreen);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % run the eye calibration
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    myscreen = eyeCalibDisp(myscreen);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Main display loop
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    phaseNum = 1;
    while (phaseNum <= length(task)) && ~myscreen.userHitEsc
        % update the task
        [task myscreen phaseNum] = updateTask(task,myscreen,phaseNum);
        % flip screen
        myscreen = tickScreen(myscreen,task);
        keyboard
    end

    % if we got here, we are at the end of the experiment
    myscreen = endTask(myscreen,task);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = stimStartSegmentCallback(task, myscreen)

    global stimulus;

    % fix: do anything that needs to be done at the beginning
    % of a segment (like for example setting the stimulus correctly
    % according to the parameters etc).
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = stimDrawStimulusCallback(task, myscreen)

    global stimulus

    % fix: display your stimulus here, for this code we just display 
    % a fixation cross that changes color depending on the segment
    % we are on.

    mglClearScreen;
    if (task.thistrial.thisseg == 1)
        mglFixationCross(1,1,[0 1 1]);
    else
        mglFixationCross(1,1,[1 1 1]);
    end  

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen)

    % fix: add stuff to initalize your stimulus
    stimulus.init = 1;


end
