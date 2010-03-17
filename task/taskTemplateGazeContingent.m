% taskTemplate.m
%
%        $Id: taskTemplate.m 217 2007-04-04 16:54:42Z justin $
%      usage: taskTemplate
%         by: justin gardner
%       date: 09/07/06
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use the task structure
%
function myscreen = taskTemplate

  % check arguments
  if ~any(nargin == [0])
    help taskTemplate
    return
  end

  % initalize the screen
  myscreen.screenParams{1} = {mglGetHostName,[],2,1280,1024,57,[31 23],60,1,0,'',1.8,'',[0 0]};

  % background
  myscreen.background = 0.2;

  % initialize the screen
  myscreen = initScreen(myscreen);


  % this specifies whether to save data or not
  myscreen.eyetracker.savedata = false;

  % this says what data to collect:
  % (file-samples file-events link-samples ~link-events)
  myscreen.eyetracker.data = [1 1 1 0]; % don't need link events

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % run the eye calibration
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  myscreen = initEyeTracker(myscreen, 'Eyelink');
  myscreen = calibrateEyeTracker(myscreen);

  task{1}.waitForBacktick = 1;
  % fix: the task defined here has two segments, one that
  % is 3 seconds long followed by another that is 
  % 6-9 seconds (randomized in steps of 1.5 seconds)
  % change this to what you want for your trial
  task{1}.segmin = [5 3];
  task{1}.segmax = [5 6];
  task{1}.segquant = [0 1.5];
  % fix: enter the parameter of your choice
  task{1}.parameter.myParameter = [0 30 90];
  task{1}.random = 1;

  % initialize the task
  for phaseNum = 1:length(task)
    [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@stimStartSegmentCallback,@stimDrawStimulusCallback);
  end

  % init the stimulus
  global stimulus;
  myscreen = initStimulus('stimulus',myscreen);

  % fix: you will change the function myInitStimulus
  % to initialize the stimulus for your experiment.
  stimulus = myInitStimulus(stimulus,myscreen);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Main display loop
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  phaseNum = 1;
  while (phaseNum <= length(task)) && ~myscreen.userHitEsc
    % update the task
    [task myscreen phaseNum] = updateTask(task,myscreen,phaseNum);
    % flip screen
    myscreen = tickScreen(myscreen,task);
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
  % if (task.thistrial.thisseg == 1)
  %   mglFixationCross(1,1,[0 1 1]);
  % else
  %   mglFixationCross(1,1,[1 1 1]);
  % end

  mglBltTexture(stimulus.texture,[0,0], 'center', 'center')
  mglGluAnnulus(myscreen.eyetracker.eyepos(1),myscreen.eyetracker.eyepos(2),5,30, [1 1 1]*myscreen.background);
  % mglFixationCross(1, 1, [0.6 0.6 0.6], myscreen.eyetracker.eyepos);
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen)

  mglTextSet('Helvetica',48,[0 0.5 1 1],0,0,0,0,0,0,0);
  stimulus.texture = mglText('Please read this line of text');

  % fix: add stuff to initalize your stimulus
  stimulus.init = 1;

end

