% mglEyelinkEDFRead.m
%
%      usage: mglEyelinkEDFRead(filename,<verbose>)
%         by: justin gardner
%       date: 04/04/10
%    purpose: Function to read EyeLink eye-tracker files into matlab
%
function retval = mglEyelinkEDFRead(filename,verbose)

% default return argument
retval = [];

% check arguments
if ~any(nargin == [1 2])
  help mglEyelinkEDFRead
  return
end

% default arguments
if nargin < 2,verbose = 1;end

% check for compiled file
if exist('mglPrivateEyelinkEDFRead')~=3
  disp(sprintf('(mglEyelinkEDFRead) You must compile the eyelink files: mglMake(''Eyelink'')'));
  return
end

[p,n,e] = fileparts(filename);
if isempty(e)
    filename = fullfile(p, [n '.edf']);
end
if isfile(filename)
  % mglPrivateEleyinkReadEDF returns a structre
  retval = mglPrivateEyelinkEDFRead(filename,verbose);
  if isempty(retval),return,end
else
  disp(sprintf('(mglEyelinkEDFRead) Could not open file %s',filename));
end

%% let's parse some additional info
% this could be parsed to provide information about the calibration quality
retval.cal = char(strtrim({retval.messages(strmatch('!CAL',{retval.messages.message})).message}));
% mode
retval.mode = strtrim(retval.messages(strmatch('!MODE',{retval.messages.message})).message);
[t,m] = strtok(retval.mode); % should be !MODE
[t,m] = strtok(m); % should be RECORD
if ~strcmp(t,'RECORD')
    warning('mglEyelinkEDFRead:UnknownMode', 'Unknown mode encountered in edf file.');
end
[retval.trackmode,m] = strtok(m); % will be CR or P? (pupil only)
[t,m] = strtok(m); % sample rate
% this is the true sample rate.
retval.samplerate = str2num(t);
[t,m] = strtok(m); % filer mode
retval.filter = str2num(t);
[t,m] = strtok(m); % number of eyes
retval.numeye = str2num(t);
[t,m] = strtok(m); % which eye
if retval.numeye == 2
    retval.whicheye = 'Both';
    disp(sprintf('(mglEyelinkEDFRead) !!! Both eyes were recorded. Setting gaze variable to left eye !!!'));
    retval.gaze = retval.gazeLeft;
elseif strcmp(t,'R')
    retval.whicheye = 'Right';
    retval.gaze = retval.gazeRight;
    % remove left and right gaze
    retval = rmfield(retval,'gazeLeft');
    retval = rmfield(retval,'gazeRight');
else
    retval.whicheye = 'Left';
    retval.gaze = retval.gazeLeft;
    % remove left and right gaze
    retval = rmfield(retval,'gazeLeft');
    retval = rmfield(retval,'gazeRight');
end
return

% TEST CODE
d = mglEyelinkEDFRead('10043009.edf');
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
    disp(sprintf('(mglEyelinkEDFRead) Discrepancy for trial %i and recorded time is: %f',trialNum,trialStartTimeDiscrepancy(trialNum)));
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

