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
%             mglRetinotopy('wedges')
% 
%             To display rings
%             mglRetinotopy('rings')
% 
%             The direction can be set to 1 or -1
%             mglRetinotopy('direction=-1')
%
%             The duty cycle
%             mglRetinotopy('dutyCycle=.15');
%             
%             THe number of cycles to run for
%             mglRetinotopy('numCycles=10');
%
%             The length in secs of a stimulus period
%             mglRetinotopy('stimulusPeriod=36');
% 
%             The number of steps that the stimulus will move in
%             one period
%             mglRetinotopy('stepsPerCycle',24');
%
%             Or instead of stimulusPeriod/stepsPerCycle one can
%             set the number of volumes per cycle and the
%             program will synch to backticks
%             mglRetinotopy('volumesPerCycle=24');
%
%             Eye calibration can be absent=0, at the beginning=-1
%             or at the end =1
%             mglRetinotopy('doEyeCalib=1');

function myscreen = mglRetinotopy(varargin)

% evaluate the arguments
eval(evalargs(varargin));

% setup default arguments
if exist('wedges') && wedges,wedgesOrRings = 1;,end
if exist('rings') && rings,wedgesOrRings = 0;,end
if ieNotDefined('wedgesOrRings'),wedgesOrRings = 1;end
if ieNotDefined('direction'),direction = 1;end
if ieNotDefined('dutyCycle'),dutyCycle = 0.25;end
if ieNotDefined('stepsPerCycle'),stepsPerCycle = 24;end
if ieNotDefined('stimulusPeriod'),stimulusPeriod = 24;end
if ieNotDefined('numCycles'),numCycles = 10;end
if ieNotDefined('doEyeCalib'),doEyeCalib = -1;end
if ieNotDefined('initialHalfCycle'),initialHalfCycle = 1;end

% initalize the screen
myscreen.autoCloseScreen = 0;
myscreen.allowpause = 1;
myscreen.displayname = 'projector';
myscreen.background = 'gray';
myscreen = initScreen(myscreen);

% set the first task to be the fixation staircase task
global fixStimulus;
fixStimulus.diskSize = 0.5;
[task{1} myscreen] = fixStairInitTask(myscreen);

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);

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
% set the parameters of the stimulus
% whether to display wedges or rings
% 1 for wedges/ 0 for rings
stimulus.wedgesOrRings = wedgesOrRings;
% min/max radius is the size of the stimulus
stimulus.minRadius = 0.5;
stimulus.maxRadius = min(myscreen.imageWidth/2,myscreen.imageHeight/2);
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
% init the stimulus
stimulus = initWedges(stimulus,myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set our task to have a segment for each stimulus step
% and a trial for each cycle of the stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
task{2}{1}.waitForBacktick = 1;
% if we are given the parametr in cycles per volume, then
% make every segment very short and let the synchToVol capture 
% the volumes to move on to the next segment 
if ~ieNotDefined('volumesPerCycle')
  task{2}{1}.seglen = 0.01*ones(1,stimulus.volumesPerCycle);
  task{2}{1}.synchToVol = ones(1,stimulus.volumesPerCycle);
% otherwise, we are given the stimulusPeriod and stepsPerCycle and
% we compute stuff in seconds
else
  task{2}{1}.seglen = (stimulus.stimulusPeriod/stimulus.stepsPerCycle)*ones(1,stimulus.stepsPerCycle);
end

task{2}{1} = initTask(task{2}{1},myscreen,@startSegmentCallback,@updateScreenCallback);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (doEyeCalib == -1)
  myscreen = eyeCalibDisp(myscreen);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main display loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
phaseNum = 1;
while (phaseNum <= length(task{2})) && ~myscreen.userHitEsc
  % update the dots
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

% update the mask number each trial
stimulus.currentMask = stimulus.currentMask+stimulus.direction;
if stimulus.wedgesOrRings
  stimulus.currentMask = 1+mod(stimulus.currentMask-1,stimulus.wedgeN);
else
  stimulus.currentMask = 1+mod(stimulus.currentMask-1,stimulus.ringN);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called to draw the stimulus each frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = updateScreenCallback(task, myscreen)

global stimulus
stimulus = updateWedges(stimulus,myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to init the dot stimulus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = initWedges(stimulus,myscreen)

% calculate some parameters
% size of wedges
stimulus.wedgeAngle = 360*stimulus.dutyCycle;
% how much to step the wedge angle by
stimulus.wedgeStepSize = 360/stimulus.stepsPerCycle;
% Based on the duty cycle calculate the ring cycle.
% Note that this is not just maxRadius-minRadius * dutyCycle
% because we start the rings off the inner edge and end
% them off the outer edge (that is the screen will be blank for
% a time, rathter than showing a rawp.
stimulus.ringSize = (stimulus.dutyCycle*(stimulus.maxRadius-stimulus.minRadius))/(1-2*stimulus.dutyCycle);
% get the radii for the rings
minRadius = stimulus.minRadius-stimulus.ringSize;
maxRadius = stimulus.maxRadius+stimulus.ringSize;
% now we have the inner and outer ring radius that will be used
% add a little fudge factor so that we don't get any rings
% with only a small bit showing
epsilon = .1;
stimulus.ringRadiusMin = max(0,minRadius:(epsilon+stimulus.maxRadius-minRadius)/(stimulus.stepsPerCycle-1):stimulus.maxRadius+epsilon);
stimulus.ringRadiusMax = stimulus.minRadius:(maxRadius-stimulus.minRadius)/(stimulus.stepsPerCycle-1):maxRadius;

% we only need to recompute the mglQuad points of the elements if something has
% changed in the stimulus
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
% remember these parameters, so that we can know whether we
% need to recompute
stimulus.last.elementRadiusSize = stimulus.elementRadiusSize;
stimulus.last.elementAngleSize = stimulus.elementAngleSize;
stimulus.last.elementRadialVelocity = stimulus.elementRadialVelocity;
stimulus.last.maxRadius = stimulus.maxRadius;
stimulus.last.minRadius = stimulus.minRadius;

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
  
% set the current mask that will be displayed
if stimulus.direction == 1
  stimulus.currentMask = 0;
else
  stimulus.currentMask = 2;
end

% if we are supposed to start halfway through
if stimulus.initialHalfCycle
  stimulus.currentMask = stimulus.currentMask+round(stimulus.stepsPerCycle/2);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to draw wedges to screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = updateWedges(stimulus,myscreen)

% update the phase of the sliding wedges
stimulus.phaseNum = 1+mod(stimulus.phaseNum,stimulus.n);
% draw the whole stimulus pattern
mglQuad(stimulus.x{stimulus.phaseNum},stimulus.y{stimulus.phaseNum},stimulus.c{stimulus.phaseNum},1);

% mask out to get a wedge
if stimulus.wedgesOrRings
  mglPolygon(stimulus.maskWedgeX{stimulus.currentMask},stimulus.maskWedgeY{stimulus.currentMask},[0.5 0.5 0.5]);
% or mask out to get a ring
else
  mglPolygon(stimulus.maskInnerX{stimulus.currentMask},stimulus.maskInnerY{stimulus.currentMask},[0.5 0.5 0.5]);
  mglQuad(stimulus.maskOuterX{stimulus.currentMask},stimulus.maskOuterY{stimulus.currentMask},stimulus.maskOuterC{stimulus.currentMask});
end

