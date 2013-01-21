% taskTemplateMovie.m
%
%        $Id: taskTemplate.m 835 2010-06-29 04:04:08Z justin $
%      usage: taskTemplate
%         by: justin gardner
%       date: 1/20/2013
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use the task structure
%             and display a movie clip with a fixation cross over it.
%
function myscreen = taskTemplateMovie

% check arguments
if ~any(nargin == [0])
  help taskTemplate
  return
end

% initalize the screen
mglSetParam('movieMode',1);
myscreen = initScreen;

% load the movies
global stimulus;
frameRate = 30;
stimulus = myInitStimulus(stimulus,myscreen,frameRate);

% set up task
task{1}.waitForBacktick = 0;
task{1}.seglen = [60/frameRate 3];
task{1}.getResponse = [0 1];
task{1}.parameter.movieNum = 1:stimulus.numMovies;
task{1}.random = 1;
task{1}.waitForBacktick = 1;

% initialize the task
for phaseNum = 1:length(task)
  [task{phaseNum} myscreen] = initTask(task{phaseNum},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);
end

% init the stimulus
myscreen = initStimulus('stimulus',myscreen);

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
end

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task, myscreen)

global stimulus;
% clear screen to transparent
mglClearScreen([0 0 0 0]);

% on first segment
if (task.thistrial.thisseg == 1)
  % show movie
  startMovie(task.thistrial.movieNum);
  % draw fixation cross in cyan
  mglFixationCross(1,1,[0 1 1]);
  mglFlush;
else
  % stop movie 
  stopMovie;
  % display fixation cross in white
  mglFixationCross(1,1,[1 1 1]);
  mglFlush;
end  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)

global stimulus
if task.thistrial.thisseg == 1
  stepMovie;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%    responseCallback    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task,myscreen)

global stimulus

% here, we just check whether this is the first time we got a response
% this trial and display what the subject's response was and the reaction time
if task.thistrial.gotResponse < 1
  disp(sprintf('Subject response: %i Reaction time: %0.2fs',task.thistrial.whichButton,task.thistrial.reactionTime));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = myInitStimulus(stimulus,myscreen,frameRate)

clear stimulus;

% remember the desired frame rate
stimulus.frameRate = frameRate;

% look for directory where movies live
moviePath = fullfile(fileparts(which('taskTemplate')),'taskTemplateMovies');
if ~isdir(moviePath)
  disp(sprintf('(taskTemplateMovie) Could not find movie dir %s',movieDir));
  mglClose;
  keyboard
end

% load names of files in movie directory
movieDir = dir(moviePath);
movieNames = {};

% see if any names end with the right extensions and keep a list of those
for i = 1:length(movieDir)
  [path name ext] = fileparts(movieDir(i).name);
  if any(strcmp({'.mp4','.mov'},ext))
    movieNames{end+1} = fullfile(moviePath,movieDir(i).name);
  end
end

% check to make sure we found some movie names
if length(movieNames) < 1
  disp(sprintf('(taskTemplateMovie) Could not find any movies in directory %s\n',moviePath));
  mglClose;
  keyboard
end

% go through each name
for iMovie = 1:length(movieNames)

  % display what we are doing
  mglClearScreen;
  mglTextDraw(sprintf('Loading movies (%i/%i)',iMovie,length(movieNames)),[0 0]);
  mglFlush;

  % load movie
  m = mglMovie(movieNames{iMovie});
  if ~isempty(m)
    stimulus.m(iMovie) = m;
  else
    mglClose;
    keyboard
  end

  % if first one, show and hide
  if iMovie == 1
    % get the current position and move offscreen
    originalPos = mglMovie(stimulus.m(iMovie),'getPosition');
    offscreenPos = originalPos;
    offscreenPos(1) = 100000;
    mglMovie(stimulus.m(1),'move',offscreenPos);
    % display and hide
    mglMovie(stimulus.m(1),'show');
    mglMovie(stimulus.m(1),'hide');
    % move back to original position
    mglMovie(stimulus.m(1),'move',originalPos);
  end

  % count the number of frames, remembering the current time for each frame
  % so that we can use that to step the movie
  mglMovie(stimulus.m(iMovie),'gotoBeginning');
  frameNum = 1;
  stimulus.frameTimes{iMovie}{frameNum} = mglMovie(stimulus.m(iMovie),'getCurrentTime');
  mglMovie(stimulus.m(iMovie),'stepForward');
  % the movie is over when we find a frame with the same time stamp as the last one
  while ~strcmp(stimulus.frameTimes{iMovie}{end},mglMovie(stimulus.m(iMovie),'getCurrentTime'))
    % step forward again
    frameNum = frameNum+1;
    stimulus.frameTimes{iMovie}{frameNum} = mglMovie(stimulus.m(iMovie),'getCurrentTime');
    mglMovie(stimulus.m(iMovie),'stepForward');
  end
  stimulus.numFrames(iMovie) = frameNum;

  % go back to beginning to get it ready to play again
  mglMovie(stimulus.m(iMovie),'setCurrentTime',stimulus.frameTimes{iMovie}{1});
  
  % display number of frames counted
  disp(sprintf('(taskTemplateMovie) Counted %i frames in movie %s',stimulus.numFrames(iMovie),movieNames{iMovie}));
end

stimulus.numMovies = length(movieNames);

% display what we are doing
mglClearScreen;mglFlush;
mglClearScreen;mglFlush;

%%%%%%%%%%%%%%%%%%%%
%    startMovie    %
%%%%%%%%%%%%%%%%%%%%
function startMovie(movieNum)

global stimulus;

% set the current movie number
stimulus.movieNum = movieNum;

% show the movie
mglMovie(stimulus.m(stimulus.movieNum),'show');

% debugging - display which frame is being drawn
mydisp(sprintf('Displaying frame: '));

% remember the start time
stimulus.movieStartTime = mglGetSecs;

%%%%%%%%%%%%%%%%%%%
%    stepMovie    %
%%%%%%%%%%%%%%%%%%%
function stepMovie

global stimulus;

% figure out which frame to show
frameNum = ceil(mglGetSecs(stimulus.movieStartTime)*stimulus.frameRate);
frameNum = min(frameNum,stimulus.numFrames(stimulus.movieNum));

% set the current time to that frame
mglMovie(stimulus.m(stimulus.movieNum),'setCurrentTime',stimulus.frameTimes{stimulus.movieNum}{frameNum});

% debugging - display which frame is being drawn
mydisp(sprintf('%i ',frameNum));

%%%%%%%%%%%%%%%%%%%
%    stopMovie    %
%%%%%%%%%%%%%%%%%%%
function stopMovie

global stimulus;

% hide the movie
mglMovie(stimulus.m(stimulus.movieNum),'hide');

% show how much time was taken
disp(sprintf('\nElapsed time: %f movie frameNum: %i',mglGetSecs(stimulus.movieStartTime),find(strcmp(stimulus.frameTimes{stimulus.movieNum},mglMovie(stimulus.m(stimulus.movieNum),'getCurrentTime')))));

% go back to beginning to get it ready to play again
mglMovie(stimulus.m(stimulus.movieNum),'setCurrentTime',stimulus.frameTimes{stimulus.movieNum}{1});

