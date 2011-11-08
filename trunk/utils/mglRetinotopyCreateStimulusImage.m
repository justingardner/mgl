% mglRetinotopCreateStimulusImage.m
%
%        $Id:$ 
%      usage: mglRetinotopCreateStimulusImage()
%         by: justin gardner
%       date: 10/17/11
%    purpose: 
%
function maskImage = mglRetinotopyCreateStimulusImage(stimfile)

% check arguments
if ~any(nargin == [1])
  help mglRetinotopCreateStimulusImage
  return
end

% get the stimfile
s = getStimfile(stimfile);
if isempty(s),return,end
  
% make the traces
s.myscreen = makeTraces(s.myscreen);

% get task variables
e = getTaskParameters(s.myscreen,s.task{2});

% get some traces of things of interest
s.time = s.myscreen.time;
s.maskPhase = s.myscreen.traces(s.task{2}{1}.maskPhaseTrace,:);
s.blank = s.myscreen.traces(s.task{2}{1}.blankTrace,:);
s.vol = s.myscreen.traces(1,:);
s.trialVol = e.trialVolume;
s.blank = e.randVars.blank;
if s.stimulus.stimulusType == 3
  s.barAngle = e.parameter.barAngle;
  s.elementAngle = e.randVars.elementAngle;
end

% open the screen
screenWidth = 80;screenHeight = 60;
if mglGetParam('displayNumber') ~= -1,mglClose;end
mglSetParam('offscreenContext',1);
mglOpen(0,screenWidth,screenHeight);
mglVisualAngleCoordinates(s.myscreen.displayDistance,s.myscreen.displaySize);

timePoints = 0:1.5:252;
disppercent(-inf,'(mglRetinotopy) Computing mask images');
for iImage = 1:length(timePoints)
  maskImage(iImage,1:screenWidth,1:screenHeight) = createMaskImage(s,timePoints(iImage));
  disppercent(iImage/length(timePoints));
end
disppercent(inf);

% close screen
mglSetParam('offscreenContext',0);
mglClose;

%%%%%%%%%%%%%%%%%%%%%%%%%
%    createMaskImage    %
%%%%%%%%%%%%%%%%%%%%%%%%%
function maskImage = createMaskImage(s,t)

% find the beginning of the experiment
firstTimepoint = find(s.vol);
firstTimepoint = firstTimepoint(1);

% find the timepoint that corresponds to this time
thisTimepoint = s.time(firstTimepoint)+t;
thisTimepoint = find(thisTimepoint <= s.time);
thisTimepoint = thisTimepoint(1);

% get current volume number
thisVol = cumsum(s.vol);
thisVol = thisVol(thisTimepoint);

% get curent trial number
thisTrial = find(s.trialVol <= thisVol);
thisTrial = thisTrial(end);

% pull out stimulus variable
global stimulus;
stimulus = s.stimulus;

if isfield(s,'barAngle')
  % now make a rotation matrix for the background angle
  elementAngle = s.elementAngle(thisTrial);
  co = cos(pi*elementAngle/180);
  si = sin(pi*elementAngle/180);
  stimulus.elementRotMatrix = [co si;-si co];

  % now make a rotation matrix for the bar angle we want to present
  barAngle = s.barAngle(thisTrial);
  co = cos(pi*barAngle/180);
  si = sin(pi*barAngle/180);
  stimulus.maskBarRotMatrix = [co si;-si co];
  
  % see whether this is a blank
  if barAngle == -1,blank = true;else blank = false;end

  % clear screen
  mglClearScreen(1);
else
  % for rings and wedges see if it is a blank
  blank = s.blank(thisTrial);
  if blank
    disp(sprintf('(mglRetinotopy) Blank trials not yet coded here'));
    % this just needs to read the segment and decide which half
    % of the trial to balnk out
    keyboard
  end
  mglClearScreen(0.5);
  mglFillOval(0,0,[stimulus.maxRadius*2 stimulus.maxRadius*2],[1 1 1]);
end

% set the current mask
stimulus.currentMask = s.maskPhase(thisTimepoint);
if stimulus.currentMask == 0,blank = true;end

% updae bars only if this is not a blank frame
if ~blank
  updateWedges(stimulus,s.myscreen);
end

% flush
mglFlush;

% grab the screen
maskImage = mglFrameGrab;

% make into a black and white image
maskImage((maskImage > 0.51) | (maskImage < 0.49)) = 1;
maskImage((maskImage < 0.51) & (maskImage > 0.49)) = 0;
maskImage = maskImage(:,:,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to draw wedges to screen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stimulus = updateWedges(stimulus,myscreen)

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
%  mglQuad(coords(1:2:8,:),coords(2:2:8,:),stimulus.cRect{stimulus.phaseNumRect},1);

  % compute the center of the bar
  barCenter = repmat(stimulus.barCenter(stimulus.currentMask,:),size(stimulus.maskBarLeft,1),1);
  % compute the left and right masks (covering up everything except the bar)
  % by shifting by the barCenter and rotating the coordinates for the angle we want
  maskBarLeft = stimulus.maskBarRotMatrix*(barCenter+stimulus.maskBarLeft)';
  maskBarRight = stimulus.maskBarRotMatrix*(barCenter+stimulus.maskBarRight)';

  % draw the bar masks
  mglPolygon(maskBarLeft(1,:),maskBarLeft(2,:),0.5);
  mglPolygon(maskBarRight(1,:),maskBarRight(2,:),0.5);
else
  % update the phase of the sliding wedges
  stimulus.phaseNum = 1+mod(stimulus.phaseNum,stimulus.n);
  % draw the whole stimulus pattern
%  mglQuad(stimulus.x{stimulus.phaseNum},stimulus.y{stimulus.phaseNum},stimulus.c{stimulus.phaseNum},1);
  
  % mask out to get a wedge
  if stimulus.stimulusType == 1
    mglPolygon(stimulus.maskWedgeX{stimulus.currentMask},stimulus.maskWedgeY{stimulus.currentMask},0.5);
    % or mask out to get a ring
  else
    mglPolygon(stimulus.maskInnerX{stimulus.currentMask},stimulus.maskInnerY{stimulus.currentMask},0.5);
    mglQuad(stimulus.maskOuterX{stimulus.currentMask},stimulus.maskOuterY{stimulus.currentMask},stimulus.maskOuterC{stimulus.currentMask});
  end
end


%%%%%%%%%%%%%%%%%%%%%
%    getStimfile    %
%%%%%%%%%%%%%%%%%%%%%
function s = getStimfile(stimfile)

s = [];

% load stimfile
if isstr(stimfile)
  stimfile = setext(stimfile,'mat');
  if ~isfile(stimfile)
    disp(sprintf('(mglRetinotopy) Could not open stimfile: %s',stimfile));
    return
  end
  s = load(stimfile);
elseif isstruct(stimfile)
  % see if this is a myscreen
  if isfield(stimfile,'imageWidth')
    % check for task field
    if isfield(stimfile,'task')
      s.task = stimfile.task;
      stimfile = rmfield(stimfile,'task');
    end
    % check for stimulus field
    if isfield(stimfile,'stimulus')
      s.stimulus = stimfile.stimulus;
      stimfile = rmfield(stimfile,'stimulus');
    end
    % set myscreen field
    s.myscreen = stimfile;
  elseif isfield(stimfile,'myscreen')
    s.myscreen = stimfile.myscreen;
    if isfield(stimfile,'task')
      s.task = stimfile.task;
    end
    if isfield(stimfile,'stimulus')
      s.stimulus = stimfile.stimulus;
    end
  end
end

% check fields
checkFields = {'myscreen','task','stimulus'};
for i = 1:length(checkFields)
  if ~isfield(s,checkFields{i})
    disp(sprintf('(mglRetinotopy) !!! Missing %s !!!',checkFields{i}));
    s = [];
    return
  end
end
