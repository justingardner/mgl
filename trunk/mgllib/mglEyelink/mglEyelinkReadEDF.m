% mglEyelinkReadEDF.m
%
%      usage: mglEyelinkReadEDF(filename,<verbose>)
%         by: justin gardner
%       date: 04/04/10
%    purpose: Function to read EyeLink eye-tracker files into matlab
%
function retval = mglEyelinkReadEDF(filename,verbose)

% default return argument
retval = [];

% check arguments
if ~any(nargin == [1 2])
  help mglEyelinkReadEDF
  return
end

% default arguments
if nargin < 2,verbose = 1;end

[p,n,e] = fileparts(filename);
if isempty(e)
    filename = fullfile(p, [n '.edf']);
end
if isfile(filename)
  % mglPrivateEleyinkReadEDF returns two matrices. The first
  % is the eye data with rows time, gaze x, gaze y, pupil, whichEye
  % The second contains Mgl messages which has rows:
  % time, segmentNum, trialNum, blockNum, phaseNum, taskID
  [retval.d retval.m] = mglPrivateEyelinkReadEDF(filename,verbose);
else
  disp(sprintf('(mglEyelinkReadEDF) Could not open file %s',filename));
end

return

% TEST CODE
d = mglEyelinkReadEDF('10043009.edf');
load 100430_stim09;
e = getTaskParameters(myscreen,task);


% get start time of each trial
timeLine = 1;
segmentNumLine = 2;
trialNumLine = 3;
blockNumLine = 4;
phaseNumLIne = 5;
taskIDLine = 6;
gazeXLine = 2;
gazeYLine = 3;

taskID = 1;

% get trial start times and end times
trialStartTime = d.m(timeLine,find((d.m(taskIDLine,:) == taskID) & (d.m(segmentNumLine,:) == 1)));
trialEndTime = [trialStartTime(2:end) d.d(timeLine,end)];

% get number of trials
numTrials = length(trialStartTime);

% get the index of each trial start
for trialNum = 1:numTrials
  % find closest matching time
  [trialStartTimeDiscrepancy(trialNum) trialStartIndex(trialNum)] = min(abs(d.d(timeLine,:) - trialStartTime(trialNum)));
  if (trialStartTimeDiscrepancy(trialNum) > 1)
    disp(sprintf('(mglEyelinkReadEDF) Discrepancy for trial %i and recorded time is: %f',trialNum,trialStartTimeDiscrepancy(trialNum)));
  end
end

% and the index of each trial en
trialEndIndex = [trialStartIndex(2:end) size(d.d,2)];

% get the maximum trial length. If only one trial, then
% the maximum is till the end of the data file. 
maxTrialLen = max(diff(trialStartIndex));
if isempty(maxTrialLen)
  maxTrialLen = d.d(timeLine,end)-trialStartTime(end);
end

% get the triallen
trialLen = min(trialEndIndex-trialStartIndex,maxTrialLen);

% create data arrays
d.xGaze = nan(numTrials,maxTrialLen);
d.yGaze = nan(numTrials,maxTrialLen);

% now break into trials
for trialNum = 1:length(trialStartTime)
  d.xGaze(trialNum,1:trialLen(trialNum)) = d.d(gazeXLine,trialStartIndex(trialNum):trialStartIndex(trialNum)+trialLen(trialNum)-1);
  d.yGaze(trialNum,1:trialLen(trialNum)) = d.d(gazeYLine,trialStartIndex(trialNum):trialStartIndex(trialNum)+trialLen(trialNum)-1);
end

% convert to degrees
d.xGaze = myscreen.imageWidth*(d.xGaze-myscreen.screenWidth/2)/myscreen.screenWidth;
d.yGaze = myscreen.imageHeight*(d.yGaze-myscreen.screenHeight/2)/myscreen.screenHeight;

fixTime = 1:500;
sacTime = 800:1200;

x = median(d.xGaze(:,fixTime)');
y = median(d.yGaze(:,fixTime)');

xSac = median(d.xGaze(:,sacTime)');
ySac = median(d.yGaze(:,sacTime)');

plot(x,y,'k.');
hold on
targetAngles = unique(e.parameter.targetAngle);
targetRadiuses = unique(e.parameter.targetRadius);
symbols = 'os*dphxv^<>';
for iRadius = 1:length(targetRadiuses)
  for iAngles = 1:length(targetAngles)
    trials = (e.parameter.targetAngle == targetAngles(iAngles)) & (e.parameter.targetRadius == targetRadiuses(iRadius));
    c = getSmoothColor(iAngles,length(targetAngles),'hsv');
    plot(xSac(trials),ySac(trials),symbols(iRadius),'Color',c,'MarkerFaceColor',c,'MarkerEdgeColor',c);
  end
end


for i = 1:361
  cx(i) = cos(pi*i/180);
  cy(i) = sin(pi*i/180);
end
plot(cx*8,cy*8,'k-');
plot(cx*12,cy*12,'k-');
hline(0);vline(0);
plot([-15 15],[-15 15],'k:');
plot([-15 15],[15 -15],'k:');
xaxis(-15,15);
yaxis(-15,15);
axis square
xlabel('H. eyepos (deg)');
ylabel('V. eyepos (deg)');

