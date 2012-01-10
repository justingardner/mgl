% mglRetinotopy.m
%
%        $Id$
%      usage: mglRetinotopy(varargin)
%         by: justin gardner
%       date: 04/06/07
%  copyright: (c) 2007 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Displays a retinotopy stimulus, there are many
%             parameters you can set, you can set as many
%             or as few as you like.
%
%             To display wedges
%             mglRetinotopy('wedges=1')
% 
%             To display rings
%             mglRetinotopy('rings=1')
%
%             To display bars, set bars
%             mglRetinotopy('bars=1');
%
%             The direction can be set to 1 or -1 (default=1)
%             mglRetinotopy('direction=-1')
%
%             The duty cycle (default = 0.25)
%             mglRetinotopy('dutyCycle=.15');
%             
%             THe number of cycles to run for (default = 10)
%             mglRetinotopy('numCycles=10');
%
%             The length in secs of a stimulus period 
%             mglRetinotopy('stimulusPeriod=24');
% 
%             The number of steps that the stimulus will move in
%             one period 
%             mglRetinotopy('stepsPerCycle',24);
%
%             If you want to synch to a volume acquisition at the
%             end of each cycle (to insure that your cycle length
%             is matched to the acquisition, but otherwise of 
%             a fixed number of seconds), set the following. This
%             will make the last step of the cycle wait for a backtick
%             to continue;
%             mglRetinotopy('synchToVolEachCycle=1');
%
%             Or instead of stimulusPeriod/stepsPerCycle one can
%             set the number of volumes per cycle and the
%             program will synch to backticks (default = 16) This
%             gives a 24 second cycle time with a TR=1.5 secs
%             mglRetinotopy('volumesPerCycle=16');
%
%             Eye calibration can be absent=0, at the beginning=-1
%             or at the end =1 (default = -1)
%             mglRetinotopy('doEyeCalib=1');
%
%             Start with an initial half cycle that will be thrown
%             out later (default = 1)
%             mglRetinotopy('initialHalfCycle=1');
%
%             Also, you can set wich displayName to use (see mglEditScreenParams)
%             mglRetinotopy('displayName=projector');
%
function myscreen = mglRetinotopyOffset(varargin)

% evaluate the arguments
eval(evalargs(varargin,0,0,{'wedges','rings','bars','barAngle','elementAngle','direction','dutyCycle','stepsPerCycle','stimulusPeriod','numCycles','doEyeCalib','initialHalfCycle','volumesPerCycle','displayName','easyFixTask','dispText','barWidth','barSweepExtent','elementSize','barStepsMatchElementSize','synchToVolEachCycle','blanks','fixedRandom','yOffset','xOffset','imageWidth','imageHeight'}));

global stimulus;

% default to wedges
stimulusType = 1;

% setup default arguments
if exist('wedges','var') && ~isempty(wedges),stimulusType = 1;,end
if exist('rings','var') && ~isempty(rings),stimulusType = 2;,end
if exist('bars','var') && ~isempty(bars),stimulusType = 3;,end
if ~exist('barAngle','var') || isempty(barAngle),barAngle=[0:45:359];end
if ieNotDefined('fixedRandom') stimulus.fixedRandom = 0;else stimulus.fixedRandom = fixedRandom;end
if ieNotDefined('blanks'),blanks = false;end
if ieNotDefined('direction'),direction = 1;end
if ieNotDefined('dutyCycle'),dutyCycle = 0.25;end
if ieNotDefined('stepsPerCycle'),stepsPerCycle = 24;end
if ieNotDefined('stimulusPeriod'),stimulusPeriod = 24;end
if ieNotDefined('numCycles'),numCycles = 10;end
if ieNotDefined('doEyeCalib'),doEyeCalib = -1;end
if ieNotDefined('initialHalfCycle') initialHalfCycle = 1;end
if ieNotDefined('displayName'),displayName = 'projector';end
if ieNotDefined('easyFixTask'),easyFixTask = 1;end
if ieNotDefined('dispText'),dispText = '';end
if ieNotDefined('barWidth'),barWidth = 3;end
if ieNotDefined('elementAngle'),elementAngle = 'parallel';end
if ieNotDefined('barSweepExtent'),barSweepExtent = 'min';end
if ieNotDefined('elementSize'),elementSize = [];end
if ieNotDefined('barStepsMatchElementSize'),barStepsMatchElementSize=true;end
if ieNotDefined('synchToVolEachCycle'),synchToVolEachCycle=false;end
% settings that are used to adjust the position on the screen
% the stimuli are shown in - for cases when the subject can
% not see the whole screen
if ieNotDefined('xOffset'),xOffset = 0;end
if ieNotDefined('yOffset'),yOffset = 0;end
if ieNotDefined('imageWidth'),imageWidth = [];end
if ieNotDefined('imageHeight'),imageHeight = [];end

% initalize the screen
myscreen.allowpause = 1;
myscreen.displayname = displayName;
myscreen.background = 'gray';
if isempty(stimulus.fixedRandom) || (stimulus.fixedRandom == 0)
  myscreen = initScreen(myscreen);
else
  % set randomization to always be the same
  myscreen = initScreen(myscreen,stimulus.fixedRandom);
end
% init the stimulus
myscreen = initStimulus('stimulus',myscreen);

% set the first task to be the fixation staircase task
global fixStimulus;
if ~easyFixTask
  % default values
  fixStimulus.diskSize = 0.5;
  fixStimulus.fixWidth = 1;
  fixStimulus.fixLineWidth = 3;
  fixStimulus.stimTime = 0.4;
  fixStimulus.responseTime = 1;
else
  % make cross bigger and task slower
  fixStimulus.diskSize = 0.5;
  fixStimulus.fixWidth = 1+1*easyFixTask;
  fixStimulus.fixLineWidth = 3+2*easyFixTask;
  fixStimulus.stimTime = 0.4+0.4*easyFixTask;
  fixStimulus.responseTime = 1+1*easyFixTask;
end
global fixStimulus
fixStimulus.pos = [xOffset yOffset];
[task{1} myscreen] = fixStairInitTask(myscreen);

% set the number and length of the stimulus cycles
stimulus.numCycles = numCycles;
% set whether to have an initial half cycle
stimulus.initialHalfCycle = initialHalfCycle;
% if we have defined volumesPerCycle then get timing in volumes
if ~ieNotDefined('volumesPerCycle')
  stimulus.volumesPerCycle = volumesPerCycle;
  stimulus.stepsPerCycle = stimulus.volumesPerCycle;
% otherwise do it in seconds
else
  stimulus.stimulusPeriod = stimulusPeriod;
  % this will control how many steps the stimulus makes per cycle
  stimulus.stepsPerCycle = stepsPerCycle;
end
% set the screen size settings
stimulus.xOffset = xOffset;
stimulus.yOffset = yOffset;
if isempty(imageWidth)
  stimulus.imageWidth = myscreen.imageWidth;
else
  stimulus.imageWidth = imageWidth;
end
if isempty(imageHeight)
  stimulus.imageHeight = myscreen.imageHeight;
else
  stimulus.imageHeight = imageHeight;
end
% set the parameters of the stimulus
% whether to display wedges or rings or bars
% 1 for wedges 2 for rings 3 for bars
stimulus.stimulusType = stimulusType;
% min/max radius is the size of the stimulus
stimulus.minRadius = 0.5;
stimulus.maxRadius = min(stimulus.imageWidth/2,stimulus.imageHeight/2);
%stimulus.maxRadius = stimulus.imageWidth;
% direction of stimulus
stimulus.direction = direction;
% the duty cycle of the stimulus.
% For wedges, this will control the wedge size (360*dutyCycle)
% For rings, will control the ring thickness
stimulus.dutyCycle = dutyCycle;
% angle size is the size in degrees of the
% elements of the wedge that slide against each other
stimulus.elementAngleSize = 5;
% radius is the radial length of these elements
stimulus.elementRadiusSize = 2;
% radial speed of elements moving each other
stimulus.elementRadialVelocity = 7.5;
% element size parameters for bars (non-radial pattern)
if isempty(elementSize)
  stimulus.elementWidth = 3;
  stimulus.elementHeight = 3;
else
  stimulus.elementWidth = elementSize;
  stimulus.elementHeight = elementSize;
end  
stimulus.elementVelocity = 6;
% bar parameters
stimulus.barWidth = barWidth;
% this forces the step size of the bar sweep to 
% match a multiple of half the element size. This
% is to try to make the underlying pattern beneath
% the bars show up with the same phase for each bar
% since each bar center will be placed either at the
% edge or in the middle of the elements
stimulus.barStepsMatchElementSize = barStepsMatchElementSize;
% the following gets used if you try to match the bar steps
% to the element size. If you set to moveBars it will offset
% the bars to match the underlying pattern, but this causes the
% bar sweeps to be asymmetrical (they start a little to one 
% side and end a little short). Alternatively set to 
% moveElemnts to move the elements relative to the bars. THis
% will keep the bar sweeps symmetric. If you don't want to
% do anything set to None.
stimulus.barElementAlignmentCorrection = 'moveElements';
% set the barSweepExtent this is the extent in degrees
% over which the bars move
stimulus.barSweepExtent = barSweepExtent;
% angle of the underlying elements. This can be set to
% the actual angle you want, or it can be 'orthogonal'
% or 'parallel' to be the angle orthogonal/parallel
% to the bar motion
stimulus.elementAngle = elementAngle;
% init the stimulus
stimulus = initRetinotopyStimulus(stimulus,myscreen);
stimulus.cycleTime = mglGetSecs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set our task to have a segment for each stimulus step
% and a trial for each cycle of the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task{2}{1}.waitForBacktick = 1;
% if we are given the parametr in cycles per volume, then
% make every segment very short and let the synchToVol capture 
% the volumes to move on to the next segment 
if ~ieNotDefined('volumesPerCycle')
  task{2}{1}.seglen(1:volumesPerCycle) = 1;
  task{2}{1}.timeInVols = 1;
  % this is set so that we can end
  task{2}{1}.fudgeLastVolume = 1;
% otherwise, we are given the stimulusPeriod and stepsPerCycle and
% we compute stuff in seconds
else
  numSegs = stimulus.stepsPerCycle;
  task{2}{1}.seglen(1:numSegs) = (stimulus.stimulusPeriod/stimulus.stepsPerCycle);
  % set the synchToVol to wait for a backtick at the end of the last cycle
  task{2}{1}.synchToVol(1:numSegs) = 0;
  if synchToVolEachCycle
    % in this case, keep time in seconds, but synch to the volume
    % at the end of each cycle to insure that we are still sycned
    % with scanner acquisition
    task{2}{1}.synchToVol(numSegs) = 1;
    % make the last segment a bit shorter so that it will be waiting 
    % for a backtick to synch
    task{2}{1}.seglen(numSegs) = 4*(stimulus.stimulusPeriod/stimulus.stepsPerCycle)/5;
    % so we can end at the end of the scan
    task{2}{1}.fudgeLastVolume = 1;
  end
end

% init the number of trials needed andd one for the initial half cycle.
% initial half cycle will be handled by jumping to the end of the trial
% after half the first cycle in startSegmentCallback
task{2}{1}.numTrials = stimulus.numCycles + stimulus.initialHalfCycle;

% now add a trace for saving information about the phase of the 
% stimulus mask. This can be used for reconstructing the stimulus 
% sequence for example to use to do a pRF analysis
[task{2}{1} myscreen] = addTraces(task{2}{1},myscreen,'maskPhase');
% add track for blank
[task{2}{1} myscreen] = addTraces(task{2}{1},myscreen,'blank');

% add a field for elementAngle if we are doing bars
if stimulus.stimulusType == 3
  task{2}{1}.randVars.calculated.elementAngle = nan;
  task{2}{1}.parameter.barAngle = barAngle;
  task{2}{1}.random = 0;
end

% make a variable to control when there will be a stimulus blank
task{2}{1}.randVars.blank = zeros(1,task{2}{1}.numTrials);
stimulus.blanks = blanks;
if stimulus.blanks 
  if stimulus.stimulusType == 3
    % for bars, simply add some -1 barAngles
    barAngleSeq = [-1 barAngle repmat(-1,1,stimulus.blanks)];
    barAngleSeq(2:end) = barAngleSeq(randperm(length(barAngleSeq)-1)+1);
    task{2}{1}.parameter.barAngle = barAngleSeq;
    task{2}{1}.numTrials = length(barAngleSeq);
  else
    % set stimulus.blanks number of trials to have an either 1 or 2
    % in them (for first or second half to be blank)
    blank(1:stimulus.numCycles) = 0;
    blank(1:stimulus.blanks) = ceil(2*rand(1,stimulus.blanks));
    % now randomize which trials those are, note that the first trial
    % can't be blank if initialHalfCycle is set
    if stimulus.initialHalfCycle
      task{2}{1}.randVars.blank(2:stimulus.numCycles+1) = blank(randperm(stimulus.numCycles));
    else
      task{2}{1}.randVars.blank(1:stimulus.numCycles) = blank(randperm(stimulus.numCycles));
    end    
  end
end

% init the task
[task{2}{1} myscreen] = initTask(task{2}{1},myscreen,@startSegmentCallback,@updateScreenCallback);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (doEyeCalib == -1)
  myscreen = eyeCalibDisp(myscreen,dispText);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main display loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
phaseNum = 1;
while (phaseNum <= length(task{2})) && ~myscreen.userHitEsc
  % update the retinotpy stimulus
  [task{2} myscreen phaseNum] = updateTask(task{2},myscreen,phaseNum);
  % update the fixation task
  [task{1} myscreen] = updateTask(task{1},myscreen,1);
  % flip screen
  myscreen = tickScreen(myscreen,task);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (doEyeCalib == 1)
  myscreen.eyecalib.prompt = 0;
  myscreen = eyeCalibDisp(myscreen);
end

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task, myscreen)

global stimulus;

% debugging
if task.thistrial.thisseg == 1
  if stimulus.stimulusType == 3
    disp(sprintf('%i: barAngle: %i',task.trialnum,task.thistrial.barAngle));
  end
end

if task.thistrial.thisseg == 1
    disp(sprintf('%i: %f last cycle length',task.trialnum,mglGetSecs(stimulus.cycleTime)));
    stimulus.cycleTime = mglGetSecs;
end
% check for blank stimulus type with bars
if (stimulus.stimulusType == 3)
  if task.thistrial.barAngle == -1
    % first half cycle show blank
    if (task.thistrial.thisseg < round(stimulus.stepsPerCycle/2)) 
      stimulus.blank = 1;
      return;
    % second half jump to next trial
    else
      if stimulus.direction == 1,stimulus.currentMask = 0;else stimulus.currentMask = 1;end
      task = jumpSegment(task,inf);
      return
    end
  end
end

% for bar stimulus, on the first segment, we need to set up the directions
if (stimulus.stimulusType == 3) && (task.thistrial.thisseg == 1)
  % get the element angle for bar stimuli
  % if element angle is a string, then
  if isstr(stimulus.elementAngle) 
    % if orthogonal, set to to orthogonal to bar angle
    if strcmp(stimulus.elementAngle,'orthogonal')
      task.thistrial.elementAngle = task.thistrial.barAngle-90;
    else
      % otherwise the same as the bar angle
      task.thistrial.elementAngle = task.thistrial.barAngle;
    end
  else
    task.thistrial.elementAngle = stimulus.elementAngle;
  end

  % now make a rotation matrix for the background angle
  c = cos(pi*task.thistrial.elementAngle/180);
  s = sin(pi*task.thistrial.elementAngle/180);
  stimulus.elementRotMatrix = [c s;-s c];

  % now make a rotation matrix for the bar angle we want to present
  c = cos(pi*task.thistrial.barAngle/180);
  s = sin(pi*task.thistrial.barAngle/180);
  stimulus.maskBarRotMatrix = [c s;-s c];
end

% update the mask number each trial
stimulus.currentMask = stimulus.currentMask+stimulus.direction;
if stimulus.stimulusType == 1
  stimulus.currentMask = 1+mod(stimulus.currentMask-1,stimulus.wedgeN);
else
  stimulus.currentMask = 1+mod(stimulus.currentMask-1,stimulus.ringN);
end
%disp(sprintf('%i:%i',task.trialnum,stimulus.currentMask));

% check to see if this is a blank interval
stimulus.blank = 0;
if task.thistrial.blank
  if (task.thistrial.blank==1) && (task.thistrial.thisseg < round(stimulus.stepsPerCycle/2)) 
    stimulus.blank = 1;
  elseif (task.thistrial.blank==2) && (task.thistrial.thisseg >= round(stimulus.stepsPerCycle/2)) 
    stimulus.blank = 1;
  end
end

% save the blank status
myscreen = writeTrace(stimulus.blank,task.blankTrace,myscreen);

% save the mask phase in the traces so that we can 
% later reconstruct the mask for pRF processing
myscreen = writeTrace(stimulus.currentMask,task.maskPhaseTrace,myscreen);

% handle first cycle being only one half
if stimulus.initialHalfCycle && (task.trialnum == 1) && (task.thistrial.thisseg >= round(stimulus.stepsPerCycle/2))
  disp(sprintf('(mglRetinotopy) Jumping after first half cycle'));
  task = jumpSegment(task,inf);
  return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = updateScreenCallback(task, myscreen)

global stimulus
if stimulus.blank,mglClearScreen;return,end
stimulus = updateRetinotopyStimulus(stimulus,myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the retinotopy stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = initRetinotopyStimulus(stimulus,myscreen)

% round to nearest quarter of a degree, this reduces
% some edge effects
stimulus.maxRadius = floor(stimulus.maxRadius/.25)*.25;
disp(sprintf('Stimulus radius = [%0.2f %0.2f] degrees',stimulus.minRadius,stimulus.maxRadius));
% calculate some parameters
% size of wedges
stimulus.wedgeAngle = 360*stimulus.dutyCycle;
% how much to step the wedge angle by
stimulus.wedgeStepSize = 360/stimulus.stepsPerCycle;
% Based on the duty cycle calculate the ringSize.
% Note that this is not just maxRadius-minRadius * dutyCycle
% because we start the rings off the inner edge and end
% them off the outer edge (that is the screen will be blank for
% a time, rathter than showing a ring). We also have to
% compensate in our dutyCycle for this, since the effective
% duty cycle is reduced by the time that we are offscreen
% that is for two periods
dutyCycle = stimulus.dutyCycle*stimulus.stepsPerCycle/(stimulus.stepsPerCycle-2);
stimulus.ringSize = (dutyCycle*(stimulus.maxRadius-stimulus.minRadius))/(1-dutyCycle);
% get the radii for the rings
minRadius = stimulus.minRadius-stimulus.ringSize;
maxRadius = stimulus.maxRadius+stimulus.ringSize;
% now we have the inner and outer ring radius that will be used
% add a little fudge factor so that we don't get any rings
% with only a small bit showing
epsilon = 0.1;
stimulus.ringRadiusMin = max(0,minRadius:(epsilon+stimulus.maxRadius-minRadius)/(stimulus.stepsPerCycle-1):stimulus.maxRadius+epsilon);
stimulus.ringRadiusMax = stimulus.minRadius:(maxRadius-stimulus.minRadius)/(stimulus.stepsPerCycle-1):maxRadius;

% set some parameters for bars
stimulus.barHeight = stimulus.imageWidth*1.5;
stimulus.barMaskWidth = stimulus.imageWidth*1.5;

% we only need to recompute the mglQuad points of the elements if something has
% changed in the stimulus. This is for the radial element pattern
if ~isfield(stimulus,'last') || ~isfield(stimulus,'x') || ...
  (stimulus.elementAngleSize ~= stimulus.last.elementAngleSize) || ...
  (stimulus.elementRadiusSize ~= stimulus.last.elementRadiusSize) || ...
  (stimulus.elementRadialVelocity ~= stimulus.last.elementRadialVelocity) || ...
  (stimulus.maxRadius ~= stimulus.last.maxRadius) || ...
  (stimulus.minRadius ~= stimulus.last.minRadius)
  % all the angles that the elements will be made up of
  allAngles = (0:stimulus.elementAngleSize:(360-stimulus.elementAngleSize));
  % all the phases. The phase refers to the radial position of the
  % black and white pattern (the pattern that is seen as moving
  % in the stimulus). There are two sets here since the wedges slide
  % against each other. That is every other sector will go in a 
  % different direction. 
  allPhases1 = 0:(stimulus.elementRadialVelocity/myscreen.framesPerSecond):(stimulus.elementRadiusSize*2);
  allPhases2 = fliplr(allPhases1);
  disppercent(-inf,'(mglRetinotopy) Calculating coordinates of elements in stimulus pattern');
  for phaseNum = 1:length(allPhases1)
    stimulus.x{phaseNum} = [];stimulus.y{phaseNum} = [];stimulus.c{phaseNum} = [];
    for angleNum = 1:length(allAngles)
      % get the angle
      angle = allAngles(angleNum);
      % choose which phase we are going to be
      if isodd(angleNum)
	thisMinRadius = stimulus.minRadius-allPhases1(phaseNum);
      else
	thisMinRadius = stimulus.minRadius-allPhases2(phaseNum);
      end
      % all the radiuses
      allRadius = thisMinRadius:stimulus.elementRadiusSize:stimulus.maxRadius;
      % now create all the quads for this wedge
      for radiusNum = 1:length(allRadius)
	radius = allRadius(radiusNum);
	if (radius+stimulus.elementRadiusSize) >= stimulus.minRadius
	  radius1 = max(radius,stimulus.minRadius);
	  radius2 = min(radius+stimulus.elementRadiusSize,stimulus.maxRadius);
	  % calculate in polar angle coordinates the corners of this quad
	  r = [radius1 radius1 radius2 radius2];
	  a = [angle angle+stimulus.elementAngleSize angle+stimulus.elementAngleSize angle];
	  % convert into rectilinear coordinates and save in array
	  stimulus.x{phaseNum}(:,end+1) = r.*cos(d2r(a));
	  stimulus.y{phaseNum}(:,end+1) = r.*sin(d2r(a));
	  % also calculate what color we ant
	  stimulus.c{phaseNum}(:,end+1) = [1 1 1]*(isodd(radiusNum+isodd(angleNum)));
	end
      end
    end
    disppercent(phaseNum/length(allPhases1));
  end
  disppercent(inf);
  stimulus.n = length(allPhases1);
  stimulus.phaseNum = 1;
else
  disp(sprintf('(mglRetinotopy) Using precomputed stimulus pattern'));
end

% we only need to recompute the mglQuad points of the elements if something has
% changed in the stimulus. This is for the rectilinear elements (i.e. for the bars)
if ~isfield(stimulus,'last') || ~isfield(stimulus,'x') || ...
  (stimulus.elementWidth ~= stimulus.last.elementWidth) || ...
  (stimulus.elementHeight ~= stimulus.last.elementHeight) || ...
  (stimulus.elementVelocity ~= stimulus.last.elementVelocity)
  maxDim = ceil(max(stimulus.imageWidth,stimulus.imageHeight)/stimulus.elementWidth)*stimulus.elementWidth;
  minRect = -maxDim/2-2*stimulus.elementWidth;
  maxRect = maxDim/2;
  % all the angles that the elements will be made up of
  allY = minRect:stimulus.elementHeight:maxRect;
  % all the phases. The phase refers to the radial position of the
  % black and white pattern (the pattern that is seen as moving
  % in the stimulus). There are two sets here since the wedges slide
  % against each other. That is every other sector will go in a 
  % different direction. 
  allPhases1 = 0:(stimulus.elementVelocity/myscreen.framesPerSecond):(stimulus.elementWidth*2);
  allPhases2 = fliplr(allPhases1);
  disppercent(-inf,'(mglRetinotopy) Calculating coordinates of elements in stimulus pattern for rectilinear patterns (i.e. ones for bars)');
  for phaseNum = 1:length(allPhases1)
    stimulus.xRect{phaseNum} = [];stimulus.yRect{phaseNum} = [];stimulus.cRect{phaseNum} = [];
    for yNum = 1:length(allY)
      % get the y
      y = allY(yNum)+stimulus.elementHeight/2;
      % choose which phase we are going to be
      if isodd(yNum)
	thisMinX = minRect-allPhases1(phaseNum);
      else
	thisMinX = minRect-allPhases2(phaseNum);
      end
      % all the X
      allX = thisMinX:stimulus.elementWidth:maxRect;
      % now create all the quads for this wedge
      for xNum = 1:length(allX)
	x = allX(xNum);
	% calculate element
	stimulus.xRect{phaseNum}(:,end+1) = [x x x+stimulus.elementWidth x+stimulus.elementWidth];
	stimulus.yRect{phaseNum}(:,end+1) = [y y+stimulus.elementHeight y+stimulus.elementHeight y];
	% also calculate what color we ant
	stimulus.cRect{phaseNum}(:,end+1) = [1 1 1]*(isodd(xNum+isodd(yNum)));
      end
    end
    disppercent(phaseNum/length(allPhases1));
  end
  disppercent(inf);
  stimulus.nRect = length(allPhases1);
  stimulus.phaseNumRect = 1;
  % later below when we are calculating the optimal placement of bars
  % over the elements we may wish to offset the location of the elements
  % we start off with no offset.
  stimulus.xRectOffset = 0;
else
  disp(sprintf('(mglRetinotopy) Using precomputed stimulus pattern'));
end


% remember these parameters, so that we can know whether we
% need to recompute
stimulus.last.elementRadiusSize = stimulus.elementRadiusSize;
stimulus.last.elementAngleSize = stimulus.elementAngleSize;
stimulus.last.elementRadialVelocity = stimulus.elementRadialVelocity;
stimulus.last.maxRadius = stimulus.maxRadius;
stimulus.last.minRadius = stimulus.minRadius;
stimulus.last.elementWidth = stimulus.elementWidth;
stimulus.last.elementHeight = stimulus.elementHeight;
stimulus.last.elementVelocity = stimulus.elementVelocity;

% new we calculate the masks that cover the stimulus so that we can
% have either rings or wedges, we start by making a set of wedge masks
angles = (0:stimulus.wedgeStepSize:(360-stimulus.wedgeStepSize))+90+stimulus.wedgeAngle/2;
% create masks for wedges
for angleNum = 1:length(angles)
  angle = angles(angleNum);
  % init the wedge mask values
  stimulus.maskWedgeX{angleNum} = [];
  stimulus.maskWedgeY{angleNum} = [];
  % create a polygon that spares the wedge that we want
  % start in the center, compute it in radial coordinates
  r = 0;a = 0;
  % and go around the angles except for the wedge we want
  for vertexAngle = angle:(angle+360-stimulus.wedgeAngle);
    r(end+1) = stimulus.maxRadius+1;
    a(end+1) = vertexAngle;
  end
  % and end up in the center
  r(end+1) = 0;
  a(end+1) = 0;
  % now convert to rectilinear
  stimulus.maskWedgeX{angleNum}(:,end+1) = r.*cos(d2r(a));
  stimulus.maskWedgeY{angleNum}(:,end+1) = r.*sin(d2r(a));
end
stimulus.wedgeN = length(angles);

% now we will make the masks for the rings. We will
% make an inner and outer set of ring masks so that we
% can cover up everything but one ring of the stimulus
for radiusNum = 1:length(stimulus.ringRadiusMin)
  % create the inner mask
  stimulus.maskInnerX{radiusNum} = [];
  stimulus.maskInnerY{radiusNum} = [];
  % compute in radial coordinates
  r = [0];a = [0];
  for angle = 0:stimulus.elementAngleSize:360
    r(end+1) = stimulus.ringRadiusMin(radiusNum);
    a(end+1) = angle;
  end
  r(end+1) = 0;a(end+1) = 0;
  % now convert to rectilinear
  stimulus.maskInnerX{radiusNum}(:,end+1) = r.*cos(d2r(a));
  stimulus.maskInnerY{radiusNum}(:,end+1) = r.*sin(d2r(a));
  % create the outer mask, this will be 
  % a set of quads that make a torus
  stimulus.maskOuterX{radiusNum} = [];
  stimulus.maskOuterY{radiusNum} = [];
  allAngles = 0:stimulus.elementAngleSize:360;
  for angleNum = 1:length(allAngles)
    angle = allAngles(angleNum);
    r = stimulus.ringRadiusMax(radiusNum);
    a = angle;
    r(end+1) = stimulus.maxRadius+1;
    a(end+1) = angle;
    r(end+1) = stimulus.maxRadius+1;
    a(end+1) = angle+stimulus.elementAngleSize;
    r(end+1) = stimulus.ringRadiusMax(radiusNum);
    a(end+1) = angle+stimulus.elementAngleSize;
    % convert to rectilinear
    stimulus.maskOuterX{radiusNum}(:,angleNum) = r.*cos(d2r(a));
    stimulus.maskOuterY{radiusNum}(:,angleNum) = r.*sin(d2r(a));
    stimulus.maskOuterC{radiusNum}(:,angleNum) = [0.5 0.5 0.5];
  end
end
stimulus.ringN = length(stimulus.ringRadiusMin);

% now make masks for bars
if stimulus.stimulusType == 3
  % get x and y of bar center (note that this is before we apply the
  % rotation to coordinates, so we are making the coordinates as if
  % we are going to make horizontally sweeping bars - we will later
  % rotate the coordinates around the center to get the other sweep angels

  % start by figuring out over what the extent of visual angle
  % that we want to sweep the bars over
  if isempty(stimulus.barSweepExtent),stimulus.barSweepExtent = 'max';end
  if isstr(stimulus.barSweepExtent)
    if strcmp(stimulus.barSweepExtent,'min')
      sweepExtent = min(stimulus.imageWidth,stimulus.imageHeight);
    elseif strcmp(stimulus.barSweepExtent,'max')
      barDirVec = abs(stimulus.maskBarRotMatrix*[1 0]');
      sweepExtent = max(barDirVec(1)*stimulus.imageWidth,barDirVec(2)*stimulus.imageHeight);
    else
      disp(sprintf('(mglRetinotopy) Unknown Bar sweep extent; %s',stimulus.barSweepExtent));
      keyboard
    end
  else
    sweepExtent = stimulus.barSweepExtent;
  end
  % calculate the stepSize that we will have with this sweepExtent
  stepSize = sweepExtent/(stimulus.stepsPerCycle-1);
  % now round that stepSize to the size of half an element
  % so that the bars all show at the same part of the underlying
  % checkerboard
  if stimulus.barStepsMatchElementSize
    % set the granularity - that is, stepSize will need
    % to be an integer multiple of stepSizeGranularity.
    % If this is just elementWidth then the stepSize
    % will never have only part of element in it.
    stepSizeGranularity = stimulus.elementWidth/4;
    % keep original step size for comparison, to
    % tell user what we are doing
    originalStepSize = stepSize;
    stepSize = round(stepSize/stepSizeGranularity)*stepSizeGranularity;
    % make sure stepSize is greater than 0
    stepSize = max(stepSize,stepSizeGranularity);
    % if the stepSize is not evenly divisible into the elementWidth
    % then we add an offset to the start position, so that the stimulus
    % is always centered on the element size
    barAndElementNeedAlignment = stepSize/stimulus.elementWidth;
    barAndElementNeedAlignment = (barAndElementNeedAlignment - floor(barAndElementNeedAlignment)) ~= 0;
    % tell user what is going on if the stepSize is greater than 10% of desired
    if (stepSize >= 1.05*originalStepSize) ||  (stepSize <= 0.95*originalStepSize) 
      disp(sprintf('(mglRetinotopy) Bar step size has been set to %0.2f (from ideal %0.2f) which changes the coverage',stepSize,originalStepSize));
      disp(sprintf('                of the bars from the desired barSweepExtent of %0.2f to %0.2f ',-sweepExtent/2,sweepExtent/2));
      disp(sprintf('                (see barCenter setting below). This is done to match the underlying'));
      disp(sprintf('                pattern better. If you want to have the bars exactly cover the '));
      disp(sprintf('                barSweepExtent, set barStepsMatchElementSize to false or set the'));
      disp(sprintf('                elementSize (%0.2fx%0.2f) such that the bar step size is an integer multiple',stimulus.elementWidth,stimulus.elementHeight));
      disp(sprintf('                of that elementSize'));
    end
  else
    barAndElementNeedAlignment = false;
  end
  % now create the steps
  stimulus.barCenter = [];
  if isodd(stimulus.stepsPerCycle)
    % for odd number of steps cover the center of the screen
    stimulus.barCenter(:,1) = -stepSize*(stimulus.stepsPerCycle-1)/2:stepSize:stepSize*(stimulus.stepsPerCycle-1)/2;
  else
    % for even number of steps, will be symmetric around the center
    stimulus.barCenter(:,1) = -stepSize*stimulus.stepsPerCycle/2+stepSize/2:stepSize:stepSize*stimulus.stepsPerCycle/2-stepSize/2;
  end
  stimulus.barCenter(:,2) = 0;
  % check to see if we need to align bars or elements to get a match (we want the element pattern to be
  % centered on bars)
  if barAndElementNeedAlignment
    adjustmentSize = min(abs(stimulus.barCenter(:,1)));
    switch (lower(stimulus.barElementAlignmentCorrection))
      case {'movebars'}
       stimulus.barCenter(:,1) = stimulus.barCenter(:,1)-adjustmentSize;
       % remove any offset on the elements
       for i = 1:length(stimulus.xRect)
	 stimulus.xRect{i} = stimulus.xRect{i}-stimulus.xRectOffset;
       end
       stimulus.xRectOffset = 0;
       disp(sprintf('(mglRetinotopy) Moving bar centers by %f to match to underlying elements. Check stimulus.barElementAlignmentCorrection if you want something different.',adjustmentSize));
     case {'moveelements'}
      for i = 1:length(stimulus.xRect)
	stimulus.xRect{i} = stimulus.xRect{i}-stimulus.xRectOffset+adjustmentSize;
      end
      stimulus.xRectOffset = adjustmentSize;
      disp(sprintf('(mglRetinotopy) Moving element centers by %f to match bar locations. Check stimulus.barElementAlignmentCorrection if you want something different.',adjustmentSize));
      case {'none'}
       % remove any offset on the elements
       for i = 1:length(stimulus.xRect)
	 stimulus.xRect{i} = stimulus.xRect{i}-stimulus.xRectOffset;
       end
       stimulus.xRectOffset = 0;
       disp(sprintf('(mglRetinotopy) Detected misalignment of bar and elements center, but not doing any adjustment, if you want to adjust the bar location set stimulus.barElementAlignmentCorrection to moveBars. If you want to adjust the elements to match then set to moveElements'));
    end
  end

  % display the bar centers
  disp(sprintf('(mglRetinotopy) barCenter: %s',num2str(stimulus.barCenter(:,1)','%0.02f ')));

  % now make the left hand bar mask - remember we are making the inverse
  % of the bar so we need to mask out everything to the left and to the
  % right of the bar.
  stimulus.maskBarLeft(1,:) = [-stimulus.barWidth/2 -stimulus.barHeight/2]';
  stimulus.maskBarLeft(2,:) = [-stimulus.barWidth/2-stimulus.barMaskWidth -stimulus.barHeight/2]';
  stimulus.maskBarLeft(3,:) = [-stimulus.barWidth/2-stimulus.barMaskWidth stimulus.barHeight/2]';
  stimulus.maskBarLeft(4,:) = [-stimulus.barWidth/2 stimulus.barHeight/2]';
  % now make the right hand bar mask
  stimulus.maskBarRight(1,:) = [stimulus.barWidth/2 -stimulus.barHeight/2]';
  stimulus.maskBarRight(2,:) = [stimulus.barWidth/2+stimulus.barMaskWidth -stimulus.barHeight/2]';
  stimulus.maskBarRight(3,:) = [stimulus.barWidth/2+stimulus.barMaskWidth stimulus.barHeight/2]';
  stimulus.maskBarRight(4,:) = [stimulus.barWidth/2 stimulus.barHeight/2]';
end

% set the current mask that will be displayed
if stimulus.direction == 1
  stimulus.currentMask = 0;
else
  stimulus.currentMask = 1;
end

% if we are supposed to start halfway through
if stimulus.initialHalfCycle
  stimulus.currentMask = stimulus.currentMask+round(stimulus.stepsPerCycle/2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to draw retinotopy stimulus to screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = updateRetinotopyStimulus(stimulus,myscreen)

if stimulus.stimulusType == 3
  % update the phase of the sliding wedges
  stimulus.phaseNumRect = 1+mod(stimulus.phaseNumRect,stimulus.nRect);

  % draw the whole stimulus pattern, rotate to the element angle
  x = stimulus.xRect{stimulus.phaseNumRect};
  y = stimulus.yRect{stimulus.phaseNumRect};
  coords(1:2,:) = stimulus.elementRotMatrix*[x(1,:);y(1,:)];
  coords(3:4,:) = stimulus.elementRotMatrix*[x(2,:);y(2,:)];
  coords(5:6,:) = stimulus.elementRotMatrix*[x(3,:);y(3,:)];
  coords(7:8,:) = stimulus.elementRotMatrix*[x(4,:);y(4,:)];
  mglQuad(coords(1:2:8,:)+stimulus.xOffset,coords(2:2:8,:)+stimulus.yOffset,stimulus.cRect{stimulus.phaseNumRect},1);

  % compute the center of the bar
  barCenter = repmat(stimulus.barCenter(stimulus.currentMask,:),size(stimulus.maskBarLeft,1),1);
  % compute the left and right masks (covering up everything except the bar)
  % by shifting by the barCenter and rotating the coordinates for the angle we want
  maskBarLeft = stimulus.maskBarRotMatrix*(barCenter+stimulus.maskBarLeft)';
  maskBarRight = stimulus.maskBarRotMatrix*(barCenter+stimulus.maskBarRight)';

  % draw the bar masks
  mglPolygon(maskBarLeft(1,:)+stimulus.xOffset,maskBarLeft(2,:)+stimulus.yOffset,0.5);
  mglPolygon(maskBarRight(1,:)+stimulus.xOffset,maskBarRight(2,:)+stimulus.yOffset,0.5);
else
  % update the phase of the sliding wedges
  stimulus.phaseNum = 1+mod(stimulus.phaseNum,stimulus.n);
  % draw the whole stimulus pattern
  mglQuad(stimulus.x{stimulus.phaseNum}+stimulus.xOffset,stimulus.y{stimulus.phaseNum}+stimulus.yOffset,stimulus.c{stimulus.phaseNum},1);
  
  % mask out to get a wedge
  if stimulus.stimulusType == 1
    mglPolygon(stimulus.maskWedgeX{stimulus.currentMask}+stimulus.xOffset,stimulus.maskWedgeY{stimulus.currentMask}+stimulus.yOffset,0.5);
    % or mask out to get a ring
  else
    mglPolygon(stimulus.maskInnerX{stimulus.currentMask}+stimulus.xOffset,stimulus.maskInnerY{stimulus.currentMask}+stimulus.yOffset,0.5);
    mglQuad(stimulus.maskOuterX{stimulus.currentMask}+stimulus.xOffset,stimulus.maskOuterY{stimulus.currentMask}+stimulus.yOffset,stimulus.maskOuterC{stimulus.currentMask});
  end
end

% evalargs.m
%
%      usage: evalargs(varargin,<alwaysUseNextArg>,<verbose>,<validVarnameList>)
%         by: justin gardner
%       date: 12/13/05
%    purpose: passed in varargin, returns a string
%             that once evaluated sets the variables
%             called for. Thus, allows arguments like:
%
%             fun('var1','var2=3','var3',[3 4 5]);
%             will set var1=1, var2=3 and var3=[3 4 5];
%
%             should be run in the folling way:
%
%             function fun(varargin)
%             eval(evalargs(varargin));
%
%             if alwaysUseNextArg is set, then instead of
%             interpreting
%             fun('var1','str')
%               var1=1 str=1
%             will do
%               var1='str'
%
%             when eval is called, you can have it print
%             out of a list of what is being set by setting the
%             verbose argument to 1.
%
%             validVarnameList is a cell array of names that will
%             be checked against to see if the variables that are
%             being set are valid variable names, e.g.
%
%             eval(evalargs(varargin,[],[],{'test1','test2'}));
%             will print out a warning if anything other than test1 and test2 are set
function evalstr = evalargs(args,alwaysUseNextArg,verbose,validVarnameList)

if ~any(nargin == [1 2 3 4])
  evalstr = '';
  help evalargs;
  return
end

% default to always using next argument
if ieNotDefined('alwaysUseNextArg'),alwaysUseNextArg=1;end
if ieNotDefined('verbose'),verbose=0;end

% get function name
st = dbstack;
funname = st(end).name;

% only check the variable names if we are given a list of names
if ieNotDefined('validVarnameList')
  checkValidVarnameList = 0;
else
  checkValidVarnameList = 1;
end

% start the eval string
evalstr = '';
% check arguments in
skipnext = 0;
for i = 1:length(args)
  % skip if called for
  if skipnext
    skipnext = 0;
    continue
  end
  % evaluate anything that has an equal sign in it
  if isstr(args{i}) && ~isempty(strfind(args{i},'='))
    % if the argument is a numeric, than just set it
    if ((exist(args{i}(strfind(args{i},'=')+1:end)) ~= 2) && ...
	~isempty(mrStr2num(args{i}(strfind(args{i},'=')+1:end))))
      evalstr = sprintf('%s%s;',evalstr,args{i});
    % check for empty i.e. 'varname='
    elseif (length(strfind(args{i},'=')) == 1) && (strfind(args{i},'=') == length(args{i}))
      evalstr = sprintf('%s%s[];',evalstr,args{i});
    % same for a quoted string
    elseif args{i}(strfind(args{i},'=')+1)==''''
      evalstr = sprintf('%s%s;',evalstr,args{i});
    % otherwise, we got a unquoted string, so we need to set the quotes
    else      
      evalstr = sprintf('%s%s''%s'';',evalstr,args{i}(1:strfind(args{i},'=')),args{i}(strfind(args{i},'=')+1:end));
    end
    % any quote needs to be two single quotes
    args{i}(strfind(args{i},''''))='"';
    % if verbose display setting
    if verbose
      evalstr = sprintf('%sdisp(sprintf(''setting: %s''));,',evalstr,args{i});
    end
    % check against validVarnameList
    if checkValidVarnameList && ~any(strcmp(args{i}(1:strfind(args{i},'=')-1),validVarnameList))
      disp(sprintf('(evalargs) Variable %s for function %s is not known',args{i}(1:strfind(args{i},'=')-1),funname));
      keyboard
    end
  % if it is not evaluated then either it means to set the variable
  % or to set the variable to the next argument, we determine this
  % by whether the next argument is a string or not. If it is not
  % a string then it means to set the variable to that argument
  elseif isstr(args{i})
    if (length(args) >= (i+1)) && (~isstr(args{i+1}) || alwaysUseNextArg)
      % set the variable to the next argument
      if ~isstr(args{i+1})
	evalstr = sprintf('%s%s=varargin{%i};',evalstr,args{i},i+1);
        % if verbose display setting
	if verbose
	  evalstr = sprintf('%sdisp(sprintf(''setting: %s=varargin{%i}''));,',evalstr,args{i},i+1);
	end
	if checkValidVarnameList && ~any(strcmp(args{i},validVarnameList))
	  disp(sprintf('(evalargs) Variable %s for function %s is not known',args{i},funname));
	  keyboard
	end
      else
	evalstr = sprintf('%s%s=''%s'';',evalstr,args{i},args{i+1});
        % if verbose display setting
	if verbose
	  evalstr = sprintf('%sdisp(sprintf(''setting: %s=''''%s''''''));,',evalstr,args{i},args{i+1});
	end
        % check against validVarnameList
	if checkValidVarnameList && ~any(strcmp(args{i},validVarnameList))
	  disp(sprintf('(evalargs) Variable %s for function %s is not known',args{i},funname));
	  keyboard
	end
      end
      skipnext = 1;
    else
      % just set the variable to one, since the next argument
      % does not contain a non string
      evalstr = sprintf('%s%s=1;',evalstr,args{i});
      % if verbose display setting
      if verbose
	evalstr = sprintf('%sdisp(sprintf(''setting: %s=1''));,',evalstr,args{i});
      end
      % check against validVarnameList
      if checkValidVarnameList && ~any(strcmp(args{i},validVarnameList))
	disp(sprintf('(evalargs) Variable %s for function %s is not known',args{i},funname));
	keyboard
      end
    end
  else
    % skip anythin we don't know about
    if ~skipnext
    else
      skipnext = 0;
    end
  end
end

evalstr = sprintf('%s',evalstr);


% mystr2num
%
%      usage: num = mystr2num(str)
%         by: justin gardner
%       date: 07/17/07
%    purpose: returns number or empty if string is not a number
%             matlab's str2num is *very* annoying since it
%             evaluates strings, so that if your string happens to
%             have, say a function name in it then that function
%             will be called, instead of just returning []
%
function retval = mystr2num(str)

% check arguments
if ~any(nargin == [1])
  help mystr2num
  return
end

% remove from the string any nan/inf for testing
% since these are valid strings to have.
teststr = fixBadChars(str,{{'nan',''},{'inf',''}});

% check if the string is a valid function or if it has
% any characters in it
if any(exist(teststr) == [2 3 5]) || any(regexp(teststr,'[a-zA-Z]')) 
  % then return empty
  retval = [];
else
  retval = str2num(str);
end

% fixBadChars.m
%
%      usage: str = fixBadChars(str)
%         by: justin gardner
%       date: 04/20/07
%    purpose: takes a string and replaces bad characters not
%    allowed in variable names like space or * with variable name acceptable characters
%
function str = fixBadChars(str,fixList)

% check arguments
if ~any(nargin == [1 2])
  help fixBadChars
  return
end

% this is the list of what characters will map to what
if ieNotDefined('fixList')
  fixList = {{'-','_'},{' ','_'},{'*','star'},{'+','plus'},{'%','percent'},{'[',''},{']',''},{'(',''},{')',''},{'/','_div_'},{'=','_eq_'},{'^','_pow_'},{'.','_period_'},{':','_'},{'&','_and_'},{'!','_bang_'},{'#','_hash_'},{'$','_dollar_'},{'{',''},{'}',''},{'|','_bar_'},{'\','_backslash_'},{';','_'},{'?','_question_'},{',','_comma_'},{'<','_less_'},{'>','_greater_'},{'~','_tilde_'},{'`','_backtick_'}};
  userDefinedFixList = 0;
else
  fixList = cellArray(fixList,2);
  userDefinedFixList = 1;
end

% now swap any occurrences of these characters
for i = 1:length(fixList)
  % look for where we have a bad character
  swaplocs = strfind(str,fixList{i}{1});
  % if any found replace them
  if ~isempty(swaplocs)
    newstr = '';
    swaplocs = [-length(fixList{i}{1})+1 swaplocs];
    for j = 2:length(swaplocs)
      newstr = sprintf('%s%s%s',newstr,str((swaplocs(j-1)+length(fixList{i}{1})):swaplocs(j)-1),fixList{i}{2});
    end
    str = sprintf('%s%s',newstr,str((swaplocs(end)+length(fixList{i}{1})):end));
  end
end

% check for non character at beginning
if ~userDefinedFixList
  if ~isempty(regexp(str,'^[^a-zA-Z]'))
    str = sprintf('x%s',str);
  end
end

%%%%%%%%%%%%%%%
%%   isodd   %%
%%%%%%%%%%%%%%%
function retval = isodd(num)

if (nargin ~= 1)
  help isodd
  return
end


retval =  ~(floor(num/2)*2 == num);


%%%%%%%%%%%%%
%%   d2r   %%
%%%%%%%%%%%%%
% convert degrees to radians
%
% usage: radians = d2r(degrees);
function radians = d2r(angle)

radians = (angle/360)*2*pi;

% cellArray.m
%
%      usage: var = cellArray(var,<numLevels>)
%         by: justin gardner
%       date: 04/05/07
%    purpose: when passed a single structure it returns it as a
%    cell array of length 1, if var is already a cell array just
%    passes it back. numLevels controls how many levels of
%    cell array you want, usually this would be one, but
%    if you wanted to make sure you have a cell array of cell
%    arrays then set it to two.
%  
% 
% e.g.:
% c = cellArray('this')
%
function var = cellArray(var,numLevels)

% check arguments
if ~any(nargin == [1 2])
  help cellArray
  return
end

if ieNotDefined('numLevels'),numLevels = 1;,end

% make the variable name
varName = 'var';

for i = 1:numLevels
  % for each level make sure we have a cell array
  % if not, make it into a cell array
  if ~iscell(eval(varName))
    tmp = var;
    clear var;
    var{1} = tmp;
  end
  % test the next level
  varName = sprintf('%s{1}',varName);
end



