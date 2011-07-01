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
  disp(sprintf('(mglDoRetinotopy) You must have mrTools in your path to run the GUI for this function.\nSee here: http://gru.brain.riken.jp/doku.php/mgl/gettingStarted#initial_setup'));
  return
end

% here we decide the order of the stimuli, stimulusType controls whether it 
% will be a wedge or ring and stimulusDir is the direction. The scanNames
% gives the name that the user will see. If you make changes to stimulusType
% or stimulusDir make sure that you make the corresponding change in scanNames
stimulusType = {'wedges' 'wedges' 'rings' 'rings'};
stimulusDir =  [-1 1 1 -1];
scanNames = {'CW wedges','CCW wedges','Expanding rings','Contracting rings'};

% Parameters that can be set when running retinotopy
paramsInfo = {...
    {'numCycles',10,'Number of cycles of the stimulus per scan (usually 10)','incdec=[-1 1]','minmax=[1 inf]',},...
    {'initialHalfCycle',1,'Run an initial half cycle of stimulus to stabilize response. This will start the scan at midcycle. In the analysis you will need to junk one-half cycle worth of volumes.','type=checkbox'},...
    {'volumesPerCycle',16,'minmax=[0 inf]','incdec=[-1 1]','Number of volumes per stimulus cycle. For a 1.5 second TR we usually choose 16 so that the cycle length will be 24 seconds. You may want to adjust this appropriately if you are using a different TR (e.g. you may want to alway have the same length cycle in seconds)'},...
    {'dutyCycle',0.25,'minmax=[0 1]','The duty cycle is the percent of time that any given area of the visual field will have the stimulus on for. For wedges this controls the size of the wedge (e.g. a duty cycle of 0.25 creates a wedge of 90 degrees in size). For rings it controls the width of the ring.'},...
    {'eyeCalib',-1,'Set to 1 to runs a quick eye calibration at end of scan (should be set if you are running with eyetracker). Set to -1 for eye calibration at beginning of scan (you will need to hit space at the beginning of each scan to start the eye calibration sequence -- or hit return to skip the eye calibration sequence). Set to 0 for no eye calibration','type=numeric','incdec=[-1 1]','minmax=[-1 1]','round=1'},...
    {'easyFixTask',1,'Setting this greater than 0 will make the fixation task easier by making the cross bigger and the timing slower','type=numeric','incdec=[-1 1]','minmax=[0 inf]'},...
    {'dispText','Default','Choose what display text to show the subject before each scan (this will only display if you have eyeCalib set to -1.) If set to "Default" the text will read "Scan n: Ready for eye calibration". If you want to include the scan number in your custom text, then you can add a %i -- e.g. "Custom text scan %i"','type=string'},...
    {'numScans',16,'incdec=[-1 1]','minmax=[1 inf]','The scans will progress in the order CW wedges, CCW wedges, expanding rings then contracting rings and then repeat this cycle. Usually run 10 scans so that you get 3 repeats of wedges and 2 repeats of rings'},...
    {'startType',scanNames,'Which stimulus type to start with. Usually CW wedges. Change if you need to start from a different scan'},...
	     };

% get the parameters from the user
params = mrParamsDialog(paramsInfo,'mglDoRetinotopy');

% return if use rr hit cancel
if isempty(params)
  return
end

% order of stimulus
params.startType = find(strcmp(params.startType,scanNames));

scanNum = params.startType;
while scanNum <= (params.startType+params.numScans-1)
  % get which scan we are doing
  scanTypeNum = getScanTypeNum(scanNum);
  
  % display what we are doing
  disp(sprintf('================================================'));
  disp(sprintf('Running scan %s (%i/%i)',scanNames{scanTypeNum},scanNum-params.startType+1,params.numScans));
  disp(sprintf('To STOP scan hold down ESC until you get a restart dialog box popping up'));
  disp(sprintf('================================================'));

  % set up display text
  dispText = '';
  if strcmp(params.dispText,'Default')
    dispText = sprintf('Scan %i',scanNum);
    if params.eyeCalib == -1
      dispText = sprintf('Scan %i. Ready for eye calibration?',scanNum);
    end
  else
    wantScanNum = strfind(params.dispText,'%i');
    if length(wantScanNum) == 1
      dispText = sprintf(params.dispText,scanNum);
    else
      dispText = params.dispText;
    end
  end
    
    
  % run the desired retinotopy
  myscreen = mglRetinotopy(stimulusType{scanTypeNum}, 1, ...
			   sprintf('direction=%i',stimulusDir(scanTypeNum)), ...
			   sprintf('numCycles=%i',params.numCycles), ...
			   sprintf('volumesPerCycle=%i',params.volumesPerCycle), ...
			   sprintf('doEyeCalib=%i',params.eyeCalib), ...
			   sprintf('dutyCycle=%f',params.dutyCycle),...
			   sprintf('easyFixTask=%i',params.easyFixTask),...
			   sprintf('dispText=%s',dispText));
    


  % if user is holding down escape then we need to ask them what to do.
  if (mglGetKeys(myscreen.keyboard.esc))
    mglDisplayCursor(1);
    nextOptions = {};nextOptionScanNum = [];
    % get all the options on where to start
    nextOptions{1} = sprintf('Rescan %i:%s',scanNum-params.startType+1,scanNames{scanTypeNum});
    nextOptionScanNum(1) = scanNum;
    for i = params.startType:(params.startType+params.numScans-1)
      thisScanTypeNum = getScanTypeNum(i);
      if (i < (scanNum-params.startType+1))
	nextOptionScanNum(end+1) = i;
	nextOptions{end+1} = sprintf('Go back to %i:%s',i-params.startType+1,scanNames{thisScanTypeNum});
      elseif (i > (scanNum-params.startType+1))
	nextOptionScanNum(end+1) = i;
	nextOptions{end+1} = sprintf('Start scanning %i:%s',i-params.startType+1,scanNames{thisScanTypeNum});
      end
    end
    % put up dialog asking user what to do
    whatNext=mrParamsDialog({{'whatNext',nextOptions,'Choose which scan to do next. You can rescan the scan you just aborted, or start a new scan, or go back to a scan you have already done. The scans will continue in order from which every scan you selected. If you want to quit running retinotopy scans then hit cancel. Otherwise hit OK'},{'dispText',0,'type=pushbutton','buttonString=Display text to subject','callback',@runMglDispText,'Display text to the subject using mglDispText. When you are done click end and you will return to this menu'}},'mglDoRetinotopy');
    if isempty(whatNext),mglClose;return,end
    % set the scan number to what the user called for
    % actually to 1 minus that so that it will get updated properly
    scanNum = nextOptionScanNum(find(strcmp(whatNext.whatNext,nextOptions)))-1;
    mglDisplayCursor(0);
  end
  scanNum = scanNum+1;
end

mglClose;

%%%%%%%%%%%%%%%%%%%%%%%%
%%   getScanTypeNum   %%
%%%%%%%%%%%%%%%%%%%%%%%%
function scanType = getScanTypeNum(scanNum)

% first 8 scans we do all four types of scans
% but after that we just do polar angle wedges
if scanNum <= 8
  scanType = mod(scanNum-1,4)+1;
else
  scanType = mod(scanNum-1,2)+1;
end  

%%%%%%%%%%%%%%%%%%%%%%%%
%%   runMglDispText   %%
%%%%%%%%%%%%%%%%%%%%%%%%
function retval = runMglDispText

retval = 0;
disp(sprintf('*********************************************************************'));
disp(sprintf('Starting mglDispText. When you are done, type end and you can restart'));
disp(sprintf('the retinotopy stimulus from the dialog box.'));
disp(sprintf('*********************************************************************'));
mglDispText;

