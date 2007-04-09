% mglRetinotopy.m
%
%        $Id$
%      usage: mglRetinotopy
%         by: justin gardner
%       date: 04/06/07
%  copyright: (c) 2007 Justin Gardner (GPL see mgl/COPYING)
%    purpose: example program to show how to use the task structure
%
function myscreen = mglRetinotopy

% check arguments
if ~any(nargin == [0])
  help mglRetinotopy
  return
end

% initalize the screen
myscreen.autoCloseScreen = 1;
myscreen.allowpause = 1;
myscreen.displayname = 'projector';
myscreen.background = 'gray';
myscreen.screenNumber = 0;
myscreen = initScreen(myscreen);

% set the first task to be the fixation staircase task
[task{1} myscreen] = fixStairInitTask(myscreen);

% set our task to have trials for each location
task{2}{1}.waitForBacktick = 1;
task{2}{1}.seglen = 1;
task{2}{1}.numTrials = 24;

task{2}{1} = initTask(task{2}{1},myscreen,@startSegmentCallback,@updateScreenCallback);

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);

% set the parameters of the stimulus
% whether to display wedges or rings
stimulus.wedgesOrRings = 1;
% size of wedges
stimulus.wedgeAngle = 30;
% how much to step the wedge angle by
stimulus.wedgeStepSize = 15;
% ring min/max size
stimulus.ringRadiusMin = [1 2 3 4 5 6 7 8 9 10 11 12];
stimulus.ringRadiusMax = stimulus.ringRadiusMin+4;
% min/max radius is the size of the stimulus
stimulus.minRadius = 1;
stimulus.maxRadius = min(myscreen.imageWidth/2,myscreen.imageHeight/2);
% angle size is the size in degrees of the
% elements of the wedge that slide against each other
stimulus.angleSize = 5;
% radius is the radial length of these elements
stimulus.radiusSize = 2;
% radial speed of elements moving each other
stimulus.radialVelocity = 5;

% init the stimulus
stimulus = initWedges(stimulus,myscreen);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% run the eye calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
myscreen = eyeCalibDisp(myscreen);

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

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function that gets called at the start of each segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = startSegmentCallback(task, myscreen)

global stimulus;

stimulus.currentMask= 1+mod(stimulus.currentMask,stimulus.wedgeN);

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

% all the angles that the wedges will be made
allAngles = (0:stimulus.angleSize:(360-stimulus.angleSize));
% all the phases. The phase refers to the radial position of the
% black and white pattern (the pattern that is seen as moving
% in the stimulus). There are two sets here since the wedges slide
% against each other. That is every other sector will go in a 
% different direction. 
allPhases1 = 0:(stimulus.radialVelocity/myscreen.framesPerSecond):(stimulus.radiusSize*2);
allPhases2 = fliplr(allPhases1);
disppercent(-inf,'(mglRetinotopy) Calculating wedge coordinates');
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
    allRadius = thisMinRadius:stimulus.radiusSize:stimulus.maxRadius;
    % now create all the quads for this wedge
    for radiusNum = 1:length(allRadius)
      radius = allRadius(radiusNum);
      if (radius+stimulus.radiusSize) >= stimulus.minRadius
	radius1 = max(radius,stimulus.minRadius);
	radius2 = min(radius+stimulus.radiusSize,stimulus.maxRadius);
	% calculate in polar angle coordinates the corners of this quad
	r = [radius1 radius1 radius2 radius2];
	a = [angle angle+stimulus.angleSize angle+stimulus.angleSize angle];
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

% new we calculate the masks that cover the stimulus so that we can
% have either rings or wedges, we start by making a set of wedge masks
angles = (0:stimulus.wedgeStepSize:(360-stimulus.wedgeStepSize))+90+stimulus.wedgeAngle/2;
% create masks
for angleNum = 1:length(angles)
  angle = angles(angleNum);
  stimulus.maskX{angleNum} = [];
  stimulus.maskY{angleNum} = [];
  % create a polygon that spares the wedge that we want
  % start in the center
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
  stimulus.maskX{angleNum}(:,end+1) = r.*cos(d2r(a));
  stimulus.maskY{angleNum}(:,end+1) = r.*sin(d2r(a));
end
stimulus.wedgeN = length(angles);


% now we will make the masks for the rings. We will
% make an inner and outer set of ring masks so that we
% can isolate a single ring of the stimulus
% create ring masks
for radiusNum = 1:length(stimulus.ringRadiusMin)
  % create the inner mask
  stimulus.maskInnerX{radiusNum} = [];
  stimulus.maskInnerY{radiusNum} = [];
  r = [0];a = [0];
  for angle = 0:stimulus.angleSize:360
    r(end+1) = stimulus.ringRadiusMin(radiusNum);
    a(end+1) = angle;
  end
  r(end+1) = 0;a(end+1) = 0;
  % now convert to rectilinear
  stimulus.maskInnerX{radiusNum}(:,end+1) = r.*cos(d2r(a));
  stimulus.maskInnerY{radiusNum}(:,end+1) = r.*sin(d2r(a));
  % create the outer mask
  stimulus.maskOuterX{radiusNum} = [];
  stimulus.maskOuterY{radiusNum} = [];
  allAngles = 0:stimulus.angleSize:360;
  for angleNum = 1:length(allAngles)
    angle = allAngles(angleNum);
    r = stimulus.ringRadiusMax(radiusNum);
    a = angle;
    r(end+1) = stimulus.maxRadius+1;
    a(end+1) = angle;
    r(end+1) = stimulus.maxRadius+1;
    a(end+1) = angle+stimulus.angleSize;
    r(end+1) = stimulus.ringRadiusMax(radiusNum);
    a(end+1) = angle+stimulus.angleSize;
    % convert to rectilinear
    stimulus.maskOuterX{radiusNum}(:,angleNum) = r.*cos(d2r(a));
    stimulus.maskOuterY{radiusNum}(:,angleNum) = r.*sin(d2r(a));
    stimulus.maskOuterC{radiusNum}(:,angleNum) = [0.5 0.5 0.5];
  end
end
stimulus.ringN = length(stimulus.ringRadiusMin);
  
% set the mask to start with
stimulus.currentMask = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to update wedges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = updateWedges(stimulus,myscreen)

% update the phase of the sliding wedges
stimulus.phaseNum = 1+mod(stimulus.phaseNum,stimulus.n);
% draw the whole stimulus pattern
mglQuad(stimulus.x{stimulus.phaseNum},stimulus.y{stimulus.phaseNum},stimulus.c{stimulus.phaseNum},1);

% mask out to get a wedge
if stimulus.wedgesOrRings
  mglPolygon(stimulus.maskX{stimulus.currentMask},stimulus.maskY{stimulus.currentMask},[0.5 0.5 0.5]);
% or mask out to get a ring
else
  mglPolygon(stimulus.maskInnerX{stimulus.currentMask},stimulus.maskInnerY{stimulus.currentMask},[0.5 0.5 0.5]);
  mglQuad(stimulus.maskOuterX{stimulus.currentMask},stimulus.maskOuterY{stimulus.currentMask},stimulus.maskOuterC{stimulus.currentMask});
end



