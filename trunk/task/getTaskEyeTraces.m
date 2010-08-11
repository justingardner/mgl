% getTaskEyeTraces.m
%
%        $Id:$ 
%      usage: e = getTaskEyeTraces(stimfileName,<taskNum=1>,<phaseNum=1>,<dispFig=1>)
%         by: justin gardner
%       date: 06/23/10
%    purpose: get the eye traces for a task. Pass in a stimfile name and the taskNum and phaseNum
%             you want. The eye traces will be returned in e.eye with units of degrees of visual angle
%
%    e = getTaskEyeTraces('100616_stim01','taskNum=1','phaseNum=1');
%
function e = getTaskEyeTraces(stimfileName,varargin)

e = [];

% check arguments
if nargin == 0
  help getTaskEyeTraces
  return
end

% trace numbers from mglEyelinkReadEDF
gazeXTraceNum = 1;
gazeYTraceNum = 2;
pupilTraceNum = 3;

timeTraceNum = 5;
mglTimeTraceNum = 1;
segmentNumTraceNum = 2;
trialNumTraceNum = 3;
taskIDTraceNum = 6;

taskNum=[];phaseNum=[];
getArgs(varargin,{'taskNum=1','phaseNum=1','dispFig=1'});

% if we are passed in the name of a file then assume it is a stimfile and load it through
% getTaskParameters
if isstr(stimfileName)
  [e stimfile] = getTaskParameters(stimfileName);
  if isempty(e)
    return
  end
  % make sure e/task are the correct form of cell array
  e = cellArray(e);
  stimfile.task = cellArray(stimfile.task,2);
else
  disp(sprintf('(getTaskEyeTraces) Must pass in stimfile name'));
  return
end

% get the correct task and phase
e = e{taskNum}(phaseNum);
taskID = stimfile.task{taskNum}{phaseNum}.taskID;

% check eye tracker type
eyeTrackerType = stimfile.myscreen.eyeTrackerType;
if ~isequal(eyeTrackerType,'Eyelink')
  disp(sprintf('(getTaskEyeTraces) Loading of eye tracker type %s not implemented',eyeTrackerType));
  return
else
  eyeTrackerFileExt = 'edf';
end

% get the filename
if isfield(stimfile.myscreen.eyetracker,'datafilename')
  eyeTrackerFilename = stimfile.myscreen.eyetracker.datafilename;
else
  disp(sprintf('(getTaskEyeTraces) No associated eyetracker datafilename found in myscreen'));
  return
end

% check for file, should be in myscreen directory
eyeTrackerFilename = fullfile(stimfile.stimfilePath,sprintf('%s.%s',eyeTrackerFilename,eyeTrackerFileExt));
if ~isfile(eyeTrackerFilename)
  disp(sprintf('(getTaskEyeTraces) Could not find eye tracker file %s',eyeTrackerFilename));
  return
end

% load the file
disppercent(-inf,sprintf('(getTaskEyeTraces) Opening edf file %s',eyeTrackerFilename));
edf = mglEyelinkReadEDF(eyeTrackerFilename,0);
disppercent(inf);

% get all the messages that match our taskID
edf.m = edf.m(:,edf.m(taskIDTraceNum,:) == taskID);
% get the number of trials
edf.nTrials = max(edf.m(trialNumTraceNum,:));

% now process each trial
disppercent(-inf,sprintf('(getTaskEyeTraces) Extracting trial by trial data for %i trials',edf.nTrials));
% get the start times
for i = 1:edf.nTrials
  % get start tiem
  thisTrialMessages = find(edf.m(trialNumTraceNum,:)==i);
  % find the segment 0 message
  segmentZeroMessage = thisTrialMessages(find(edf.m(segmentNumTraceNum,thisTrialMessages)==0));
  segmentZeroTime = edf.m(mglTimeTraceNum,segmentZeroMessage);
  % call this the startTime
  if ~isempty(segmentZeroTime)
    startTime(i) = segmentZeroTime;
  else
    startTime(i) = nan;
  end
end
% get the end times
endTime(1:length(startTime)-1) = startTime(2:end);
% make the end time of the last trial, at most as long as the longest trial so far
maxTrialLen = max(endTime-startTime(1:end-1));
endTime(end+1) = min(max(edf.d(timeTraceNum,:)),startTime(end)+maxTrialLen);

% now get time between samples
timeBetweenSamples = median(diff(edf.d(timeTraceNum,:)));

% figure out how large to make data array
e.eye.hPos = nan(edf.nTrials,ceil(maxTrialLen/timeBetweenSamples));
e.eye.vPos = nan(edf.nTrials,ceil(maxTrialLen/timeBetweenSamples));
e.eye.pupil = nan(edf.nTrials,ceil(maxTrialLen/timeBetweenSamples));

% put in time in seconds
e.eye.time = (0:(size(e.eye.hPos,2)-1))*timeBetweenSamples/1000;

% go through each trial and populate traces
for iTrial = 1:edf.nTrials
  disppercent(iTrial/edf.nTrials);
  % the times for this trial
  thisTrialTimes = startTime(iTrial):timeBetweenSamples:endTime(iTrial);
  % get data for hPos, vPos and pupil traces form edf data 
  e.eye.hPos(iTrial,1:length(thisTrialTimes)) = interp1(edf.d(timeTraceNum,:),edf.d(gazeXTraceNum,:),thisTrialTimes,'linear',nan);
  e.eye.vPos(iTrial,1:length(thisTrialTimes)) = interp1(edf.d(timeTraceNum,:),edf.d(gazeYTraceNum,:),thisTrialTimes,'linear',nan);
  e.eye.pupil(iTrial,1:length(thisTrialTimes)) = interp1(edf.d(timeTraceNum,:),edf.d(pupilTraceNum,:),thisTrialTimes,'linear',nan);
end
disppercent(inf);

% convert to device coordinates
w = stimfile.myscreen.screenWidth;
h = stimfile.myscreen.screenHeight;
xPix2Deg = stimfile.myscreen.imageWidth/w;
yPix2Deg = stimfile.myscreen.imageHeight/h;

e.eye.hPos = (e.eye.hPos-(w/2))*xPix2Deg;
e.eye.vPos = ((h/2)-e.eye.vPos)*yPix2Deg;

% keep stimfile
e.stimfile = stimfile;
e.stimfile.taskNum = taskNum;
e.stimfile.phaseNum = phaseNum;

if dispFig
  displayEyeTraces(e);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%    displayEyeTraces    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function displayEyeTraces(e)

% get all combination of parameters
[stimvol names trialNums] = getStimvolFromVarname('_every_',e.stimfile.myscreen,e.stimfile.task,e.stimfile.taskNum,e.stimfile.phaseNum);

figure;

% display trial by trial.
for iTrialType = 1:length(trialNums)
  % get color
  c = getSmoothColor(iTrialType,length(trialNums),'hsv');
  % display horizontal eye trace
  subplot(2,3,1:2);
  plot(e.eye.time,e.eye.hPos(trialNums{iTrialType},:)','Color',c);
  hold on
  % display vertical eye trace
  subplot(2,3,4:5);
  plot(e.eye.time,e.eye.vPos(trialNums{iTrialType},:)','Color',c);
  hold on
  % display as an x/y plot the median eye trace for this condition
  subplot(2,3,[3 6]);
  hPos = nanmedian(e.eye.hPos(trialNums{iTrialType},:));
  vPos = nanmedian(e.eye.vPos(trialNums{iTrialType},:));
  plot(hPos,vPos,'.','Color',c);
  hold on
end

% figure trimmings
hMin = -15;hMax = 15;
vMin = -15;vMax = 15;
subplot(2,3,1:2);
yaxis(hMin,hMax);
xaxis(0,max(e.eye.time));
xlabel('Time (sec)');
ylabel('H. eyepos (deg)');
subplot(2,3,4:5);
yaxis(vMin,vMax);
xaxis(0,max(e.eye.time));
xlabel('Time (sec)');
ylabel('V. eyepos (deg)');
subplot(2,3,[3 6]);
xaxis(hMin,hMax);
yaxis(vMin,vMax);
xlabel('H. eyepos (deg)');
ylabel('V. eyepos (deg)');
title('Median eye position by trial type');
axis square

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    getInterpolatedEyepos    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hPos vPos pupil] = getInterpolatedEye(edf,time)

hPos = nan;vPos = nan;pupil = nan;
sampleNum = find(edf.d(5,:)==time);
if ~isempty(sampleNum)
  hPos(iTrial,k) = edf.d(1,sampleNum);
  vPos(iTrial,k) = edf.d(2,sampleNum);
  pupil(iTrial,k) = edf.d(3,sampleNum);
else
  disp(sprintf('(getTaskEyeTraces) Missing sample %i form trial %i',iSampleTime,iTrial));
end
