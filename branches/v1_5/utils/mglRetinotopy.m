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
%             mglRetinotopy('stimulusPeriod=36');
% 
%             The number of steps that the stimulus will move in
%             one period 
%             mglRetinotopy('stepsPerCycle',24');
%
%             Or instead of stimulusPeriod/stepsPerCycle one can
%             set the number of volumes per cycle and the
%             program will synch to backticks (default = 24)
%             mglRetinotopy('volumesPerCycle=24');
%
%             Eye calibration can be absent=0, at the beginning=-1
%             or at the end =1 (default = -1)
%             mglRetinotopy('doEyeCalib=1');
%
%             Start with an initial half cycle that will be thrown
%             out later (default = 1)
%             mglRetinotopy('initialHalfCycle=1');

function myscreen = mglRetinotopy(varargin)

% evaluate the arguments
eval(evalargs(varargin,0));

% setup default arguments
if exist('wedges','var') && ~isempty(wedges),wedgesOrRings = 1;,end
if exist('rings','var') && ~isempty(rings),wedgesOrRings = 0;,end
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
  task{2}{1}.seglen = 1;
  task{2}{1}.timeInVols = 1;
  % this is set so that we can end
  task{2}{1}.fudgeLastVolume = 1;
% otherwise, we are given the stimulusPeriod and stepsPerCycle and
% we compute stuff in seconds
else
  task{2}{1}.seglen = (stimulus.stimulusPeriod/stimulus.stepsPerCycle);
end

task{2}{1}.numTrials = stimulus.numCycles*stimulus.stepsPerCycle + stimulus.initialHalfCycle*round(stimulus.stepsPerCycle/2);
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
  stimulus.currentMask = 1;
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

% evalargs.m
%
%      usage: evalargs(varargin,<alwaysUseNextArg>)
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
%             when eval is called, this will print out
%             what the variables are being set to. If
%             you want it to run quietly, do:
%             eval(evalargs({'gVerbose=0','var1',...}));
function evalstr = evalargs(args,alwaysUseNextArg)

if ~any(nargin == [1 2])
  help evalargs;
  return
end

if ~exist('alwaysUseNextArg','var'),alwaysUseNextArg=1;end

evalstr = 'global gVerbose;oldgVerbose=gVerbose;gVerbose=1;';
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
	~isempty(mystr2num(args{i}(strfind(args{i},'=')+1:end))))
      evalstr = sprintf('%s%s;',evalstr,args{i});
    % same for a quoted string
    elseif args{i}(strfind(args{i},'=')+1)==''''
      evalstr = sprintf('%s%s;',evalstr,args{i});
    % otherwise, we got a unquoted string, so we need to set the quotes
    else      
      evalstr = sprintf('%s%s''%s'';',evalstr,args{i}(1:strfind(args{i},'=')),args{i}(strfind(args{i},'=')+1:end));
    end
    % any quote needs to be two single quotes
    args{i}(strfind(args{i},''''))='"';
    evalstr = sprintf('%sif gVerbose,disp(sprintf(''setting: %s''));,end,',evalstr,args{i});
  % if it is not evaluated then either it means to set the variable
  % or to set the variable to the next argument, we determine this
  % by whether the next argument is a string or not. If it is not
  % a string then it means to set the variable to that argument
  elseif isstr(args{i})
    if (length(args) >= (i+1)) && (~isstr(args{i+1}) || alwaysUseNextArg)
      % set the variable to the next argument
      if ~isstr(args{i+1})
	evalstr = sprintf('%s%s=varargin{%i};',evalstr,args{i},i+1);
	evalstr = sprintf('%sif gVerbose,disp(sprintf(''setting: %s=varargin{%i}''));,end,',evalstr,args{i},i+1);
      else
	evalstr = sprintf('%s%s=''%s'';',evalstr,args{i},args{i+1});
	evalstr = sprintf('%sif gVerbose,disp(sprintf(''setting: %s=''''%s''''''));,end,',evalstr,args{i},args{i+1});
      end
      skipnext = 1;
    else
      % just set the variable to one, since the next argument
      % does not contain a non string
      evalstr = sprintf('%s%s=1;',evalstr,args{i});
      evalstr = sprintf('%sif gVerbose,disp(sprintf(''setting: %s=1''));,end,',evalstr,args{i});
    end
  else
    % skip anythin we don't know about
    if ~skipnext
    else
      skipnext = 0;
    end
  end
end

evalstr = sprintf('%sgVerbose=oldgVerbose;',evalstr);


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



