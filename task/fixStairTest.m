% fixStairtest.m
%
%        $Id: testExperiment.m 247 2007-06-14 15:13:51Z justin $
%      usage: fixStairTest(<difficulty>)
%         by: justin gardner
%       date: 09/08/26
%  copyright: (c) 2009 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Shows the fixation staircase task alone. Difficulty of 0 is normal
%             difficulty of 1 is easy
%             difficulty of 2 is very very easy
%
%
function myscreen = fixStairTest(difficulty)

% check arguments
if ~any(nargin == [0 1])
  help fixStairTest
  return
end

% default difficulty
if nargin == 0, difficulty = 2;end

% set fixStimulus properties to control difficulty
global fixStimulus;
if difficulty == 0
  % default values
  fixStimulus.diskSize = 0.5;
  fixStimulus.fixWidth = 0.95;
  fixStimulus.fixLineWidth = 3;
  fixStimulus.stimTime = 0.4;
  fixStimulus.responseTime = 1;
  fixStimulus.trainingMode = 0;
elseif difficulty == 1
  % make cross bigger and task slower
  fixStimulus.diskSize = 1;
  fixStimulus.fixWidth = 2;
  fixStimulus.fixLineWidth = 8;
  fixStimulus.stimTime = 0.8;
  fixStimulus.responseTime = 2;
  fixStimulus.trainingMode = 1;
elseif difficulty == 2
  % make cross realy really big and task very very slow
  fixStimulus.diskSize = 5;
  fixStimulus.fixWidth = 10;
  fixStimulus.fixLineWidth = 8;
  fixStimulus.stimTime = 2;
  fixStimulus.interTime = 1;
  fixStimulus.responseTime = 5;
  fixStimulus.trainingMode = 1;
else
  disp('(fixStairTest) unknown difficulty level');
end

% initalize the screen
myscreen = initScreen;

% set the first task to be the fixation staircase task
[task{1} myscreen] = fixStairInitTask(myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main display loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while ~myscreen.userHitEsc
  % update the fixation task
  [task{1} myscreen] = updateTask(task{1},myscreen,1);
  % flip screen
  myscreen = tickScreen(myscreen,task);
end

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

% clear the fixStimulus since we don't need to keep parameters across experimetns
clear global fixStimulus