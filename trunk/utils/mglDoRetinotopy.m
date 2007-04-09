% mglDoRetinotopy.m
%
%        $Id$
%      usage: mglDoRetinotopy()
%         by: justin gardner
%       date: 04/09/07
%    purpose: 
%
function retval = mglDoRetinotopy()

% check arguments
if ~any(nargin == [0])
  help mglDoRetinotopy
  return
end

if ~exist('mrParamsDialog')
  disp(sprintf('(mglDoRetinotopy) You must have mrTools in your path to run this'));
  return
end

scanNames = {'CW wedges','CCW wedges','Expanding rings','Contracting rings'};
% Parameters that can be set when running retinotopy
paramsInfo = {...
    {'numCycles',10,'Number of cycles of the stimulus per scan (usually 10)','incdec=[-1 1]','minmax=[1 inf]',},...
    {'initialHalfCycle',1,'Run an initial half cycle of stimulus to stabilize response (in the analysis you will junk these frames)','type=checkbox'},...
    {'volumesPerCycle',24,'minmax=[0 inf]','incdec=[-1 1]','Number of volumes per stimulus cycle'},...
    {'dutyCycle',0.25,'minmax=[0 1]','The duty cycle is the percent of time that any given area of the visual field will have the stimulus on for--for wedges it controls the size of the wedge and for rings the width of the rings'},...
    {'eyeCalibAtEnd',1,'Runs a quick eye calibration at end of scan (should be set if you are running with eyetracker)','type=checkbox'},...
    {'numScans',10,'incdec=[-1 1]','minmax=[1 inf]','The scans will progress in the order CW wedges, CCW wedges, expanding then contracting and cycle back. Usually run 10 scans so that you get 3 repeats of wedges and 2 of rings'},...
    {'startType',scanNames,'Which stimulus type to start with. Usually CW wedges. Change if you need to start from a different scan'},...
	     };

% get the parameters from the user
params = mrParamsDialog(paramsInfo);

% return if use rr hit cancel
if isempty(params)
  return
end

% order of stimulus
stimulusType = {'wedges' 'wedges' 'rings' 'rings'};
stimulusDir =  [-1 1 1 -1];
params.startType = find(strcmp(params.startType,scanNames));

scanNum = params.startType;
while scanNum <= (params.startType+params.numScans-1)
  % get which scan we are doing
  scanTypeNum = mod(scanNum-1,4)+1;
  
  % display what we are doing
  disp(sprintf('================================================'));
  disp(sprintf('Running scan %s (%i/%i)',scanNames{scanTypeNum},scanNum-params.startType+1,params.numScans));
  disp(sprintf('To STOP scan hold down ESC until you get a restart dialog box popping up'));
  disp(sprintf('================================================'));

  % run the desired retinotopy
  myscreen = mglRetinotopy(stimulusType{scanTypeNum},sprintf('direction=%i',stimulusDir(scanTypeNum)),sprintf('numCycles=%i',params.numCycles),sprintf('volumesPerCycle=%i',params.volumesPerCycle),sprintf('doEyeCalib=%i',params.eyeCalibAtEnd),sprintf('dutyCycle=%f',params.dutyCycle));

  % if user is holding down escape then we need to ask them what to do.
  if (mglGetKeys(myscreen.keyboard.esc))
    nextOptions = {sprintf('Rescan %s',scanNames{scanTypeNum}),sprintf('Start scanning %s',scanNames{mod(scanTypeNum,4)+1}),'Quit'};
    whatNext=mrParamsDialog({{'whatNext',nextOptions}},'Scan paused. What do you want to do?');
    if isempty(whatNext),return,end
    nextOptions = find(strcmp(whatNext.whatNext,nextOptions));
    if nextOptions == 1
      continue
    elseif nextOptions == 3
      mglClose;
      return
    end
  end
  scanNum = scanNum+1;
end


mglClose;