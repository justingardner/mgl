% mglCameraPostProcess.m
%
%      usage: mglCameraPostProcess(stimfilename)
%         by: justin gardner
%       date: 10/29/19
%    purpose: Post-processing of camera files to task. This will load images up,
%             align the images to task times and then save out as a lossless compressed AVI file
%
%             Works with stimfile and stimulus structure that is returned from wmface
%             Requires a cameraInfo field in stimulus that containes the camera images per trial
%
function retval = mglCameraPostProcess(stimfilename,varargin)

% check arguments
if nargin < 1
  help mglCameraPostProcess
  return
end

% get arguments
getArgs(varargin,{'dispTiming=1','videoFormat=Archival','savePath=[]'});

% load the stimfile
s = loadStimfile(stimfilename);
if isempty(s),return,end

% check savePath
if ~isempty(savePath)
  if ~isdir(savePath)
    if askuser(sprintf('(mglCameraPostProcess) Directory %s does not exist. Ok to create',savePath));
      mkdir(savePath);
    else
      return
    end
  end
end

% get task parameters
e = getTaskParameters(s.myscreen,s.task);
[e.camera e.exptName] = alignCameraImages(s.myscreen,s.task,s.stimulus,dispTiming,videoFormat,savePath);
e.s = s;
if isempty(e.exptName),e.exptName = 'e';end

% save the e structure
save(fullfile(savePath,e.exptName),'e');

%%%%%%%%%%%%%%%%%%%%%%
%    loadStimfile    %
%%%%%%%%%%%%%%%%%%%%%%
function s = loadStimfile(stimfilename);

s = [];

% load the stimfile
if ~isfile(stimfilename)
  disp(sprintf('(mglCameraPostProcess:loadStimfile) Could not open stimfile: %s',stimfilename));
  return
end

% otherwise load the stimfile
s = load(stimfilename);

% check file
if ~isfield(s,'myscreen') || ~isfield(s,'task') 
  disp(sprintf('(mglCameraPostProcess:loadStimfile) File is not a stimfile: %s',stimfilename));
  s = [];
  return;
end

% check for stimulus
if ~isfield(s,'stimulus')
  disp(sprintf('(mglCameraPostProcess:loadStimfile) Stimfile is missing stimulus structure: %s',stimfilename));
  s = [];
  return
end

% check for camera images
if ~isfield(s.stimulus,'cameraImages')
  disp(sprintf('(mglCameraPostProcess:loadStimfile) Stimulus structure is missing cameraImages: %s',stimfilename));
  s = [];
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    alignCameraImages    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [retval exptName] = alignCameraImages(myscreen,task,stimulus,dispTiming,videoFormat,savePath)

% default return argument
retval = [];
exptName = '';

% get camera images
c = stimulus.cameraImages;

% get segmentTimes
segmentTrace = find(strcmp(myscreen.traceNames,'segmentTime'));
segmentEvents = find(myscreen.events.tracenum == segmentTrace);
segmentNums = myscreen.events.data(segmentEvents);
segmentTimes = myscreen.events.time(segmentEvents);

% find start time for each trial
trialStartEvents = find(segmentNums==1);
trialStartEvents = trialStartEvents(1:end);

if dispTiming
  % display timing
  startTime = segmentTimes(1);
  segmentTimes = segmentTimes - segmentTimes(1);
  for i = 1:length(c)
    c{i}.t = c{i}.t-startTime;
  end
  mlrSmartfig('mglCameraPostProcess');
  vline(segmentTimes,'r-');hold on
  vline(segmentTimes(trialStartEvents),'g-');
  for i = 1:length(c)
    vline(c{i}.t);
  end
  zoom on
  xlabel('Time from start of experiment (s)');
  mylegend({'Start of trial','Segment','Camera Image capture'},{'g', 'r','k'});
end

% show what we are doing
disppercent(-inf,'(mglCameraPostProcessing:alignCameraImages) Aligning camera images');

% cycle through each camera trial that we have
for iTrial = 1:length(c)
  % set output structure
  retval(iTrial).nImages = size(c{iTrial}.im,3);
  retval(iTrial).seg = nan(1,retval(iTrial).nImages);

  % get the events for this trial
  startTime = segmentTimes(trialStartEvents(iTrial));

  % figure out which semgent each image happened in
  % get max segment (note that we calculate here since sometimes the
  % last trial may have missing segments)
  maxSegment = max(segmentNums(trialStartEvents(iTrial):end));
  for iSegment = 1:(maxSegment-1)
    % get this segments time
    thisSegTime = segmentTimes(trialStartEvents(iTrial)+iSegment);
    % set all the images to have this segment if they match
    retval(iTrial).seg((c{iTrial}.t >= startTime) & (c{iTrial}.t < thisSegTime)) = iSegment;
    % update startTime
    startTime = thisSegTime;
  end

  % get valid images
  validImages = find(~isnan(retval(iTrial).seg));

  % update info based on these valid images
  retval(iTrial).nImages = length(validImages);
  retval(iTrial).seg = retval(iTrial).seg(validImages);
  retval(iTrial).t = c{iTrial}.t(validImages)-segmentTimes(trialStartEvents(iTrial));
  retval(iTrial).exposureTimes = c{iTrial}.exposureTimes(validImages);

  % only copy over images that are within the trial
  if ~isempty(c{iTrial}.im)
    retval(iTrial).im = c{iTrial}.im(:,:,validImages);
  end
  % if there is a filename, then load and process
  if ~isempty(c{iTrial}.filename)
    % load the data
    d = mglCameraLoadData(c{iTrial}.filename);
    % check for data
    if ~isempty(d)
      % try to open video file
      [originalSavePath saveName] = fileparts(c{iTrial}.filename);
      % set the savePath if it was not passed in
      if isempty(savePath),savePath = originalSavePath;end
      % start the video writer
      v = VideoWriter(fullfile(savePath,saveName),videoFormat);
      % open it
      open(v);
      % write valid images
      writeVideo(v,reshape(d(:,:,validImages),c{iTrial}.size(1),c{iTrial}.size(2),1,c{iTrial}.size(3)));
      % close video writer
      close(v);
      % change filename to this one
      c{iTrial}.filename = fullfile(v.Path,v.Filename);
      % grab the exptName from the filename
      bracketLoc = regexp(v.Filename,'\]','once');
      if ~isempty(bracketLoc)
	exptName = v.Filename(2:bracketLoc-1);
      end
    else
      c{iTrial}.filename = '';
    end
  end
  % pull out filepath / filename / ext
  [retval(iTrial).filepath retval(iTrial).filename ext] = fileparts(c{iTrial}.filename);
  retval(iTrial).filename = setext(retval(iTrial).filename,ext);

  % update disppercent
  disppercent(iTrial/length(c));
end
disppercent(inf);
