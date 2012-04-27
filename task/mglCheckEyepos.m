% mglCheckEyepos.m
%
%        $Id:$ 
%      usage: mglCheckEyepos(stimfilenames,<taskNum=1>,<phaseNum=1>,<parameter=varname>,<segNum=1>)
%         by: justin gardner
%       date: 04/26/12
%    purpose: generic function to check eye position
%       e.g.: mglCheckEyepos({'120418_stim01','120418_stim02','120418_stim03','120418_stim04'},'parameter=contrast','segNum=1')
%      
%             Stimfilenames can be a cell array of stimfiles
%             taskNum,phaseNum are optional for setting which task and phase to use
%             parameter can be set to the parameter from your stim program that
%               you want to check whether eyepos differs over.
%             segNum will specify which segment the summary stats will be computed for
%               note the display will still show the full trial traces
%  
%
function retval = mglCheckEyepos(stimfilenames,varargin)

% check arguments
if nargin < 1
  help mglCheckEyepos
  return
end

% check for mrUtilities
if exist('getArgs') ~= 2
  disp(sprintf('(mglCheckEyepos) Need to have mrUtilities installed.'))
  disp(sprintf('svn checkout http://cbi.nyu.edu/svn/mrTools/trunk/mrUtilities/MatlabUtilities mrUtilities'));
  return
end

% parse arguments
getArgs(varargin,{'taskNum=1','phaseNum=1','parameter=[]','segNum=1'});

% load the stimfiles, checking for errors
stimfilenames = cellArray(stimfilenames);
for i = 1:length(stimfilenames)
  e{i} = getTaskEyeTraces(stimfilenames{i},'taskNum',taskNum,'phaseNum',phaseNum);
  % check for empty
  if isempty(e{i}) || ~isfield(e{i},'eye'),return,end
  % get task variable names
  varnames = getTaskVarnames(e{i});
  % if parameter is empty, then use the first parameter we find
  if isempty(parameter)
    parameter = varnames{i};
  end
  % make sure the called for parameter exists
  if ~any(strcmp(parameter,varnames))
    disp(sprintf('(mglCheckEyepos) Parameter %s does not exist in %s',parameter,stimfilenames{i}));
    return
  end
  % get the trial-by-trial setting of the parameter
  parameterValues{i} = getVarFromParameters(parameter,e{1});
  % make sure it has the requested number of segments
  nSegs = length(e{i}.trials(1).segtime);
  if nSegs < segNum
    disp(sprintf('(mglCheckEyepos) Only %i segments found in %s',nSegs,stimfilenames{i}));
    return
  end
end

% get the uniqu parameter values
uniqueParameterValues = unique(cell2mat(parameterValues));

% now go through and sort eye position as a function of the parameter value
xPos = [];yPos = [];t = [];
for i = 1:length(e)
  for iTrial = 1:e{i}.nTrials
    % get this trials parameter value as an index
    trialType = find(parameterValues{i}(iTrial) == uniqueParameterValues);
    % get the xPos for this trial
    if isempty(xPos) || (length(xPos) < trialType) || isempty(xPos{trialType})
      xPos{trialType}(1,:) = e{i}.eye.xPos(iTrial,:);
      t = e{i}.eye.time;
    else
      % length is the minimum of the current trials length or
      % the trials already saved in variable.
      len = min(length(xPos{trialType}(1,:)),length(e{i}.eye.xPos(iTrial,:)));
      xPos{trialType}(end+1,1:len) = e{i}.eye.xPos(iTrial,1:len);
    end
    % get the yPos for this trial
    if isempty(yPos) || (length(yPos) < trialType) || isempty(yPos{trialType})
      yPos{trialType}(1,:) = e{i}.eye.yPos(iTrial,:);
      trialNum = 1;
    else
      yPos{trialType}(end+1,1:len) = e{i}.eye.yPos(iTrial,1:len);
      trialNum = size(yPos{trialType},1);
    end
    % get the segment start and stop time
    segStart{trialType}(trialNum) = e{i}.trials(iTrial).segtime(segNum)-e{i}.trialTime(iTrial);
    if segNum < length(e{i}.trials(iTrial).segtime)
      segEnd{trialType}(trialNum) = e{i}.trials(iTrial).segtime(segNum+1)-e{i}.trialTime(iTrial);
    else
      disp(sprintf('(mglCheckEyepos) Getting end time of last segment not implemented yet...'));
      keyboard
    end
  end
end

% calculate the median eye position during the segment
for iType = 1:length(uniqueParameterValues)
  % compute nTrials 
  nX{iType} = sum(~isnan(xPos{iType}));
  nY{iType} = sum(~isnan(yPos{iType}));
  % compute nanmedian of eye position
  for iTrial = 1:size(xPos{iType},1)
    % get time segment occurred
    segTime = find((t >= segStart{iType}(iTrial)) & (t <= segEnd{iType}(iTrial)));
    % get nanmedian x and y pos
    xPosSeg{iType}(iTrial) = nanmedian(xPos{iType}(iTrial,segTime));
    yPosSeg{iType}(iTrial) = nanmedian(yPos{iType}(iTrial,segTime));
    % get standard deviation in x and y
    xStdSeg{iType}(iTrial) = nanstd(xPos{iType}(iTrial,segTime));
    yStdSeg{iType}(iTrial) = nanstd(yPos{iType}(iTrial,segTime));
    % get standard deviation in r
    [phi r] = cart2pol(xPos{iType}(iTrial,segTime),yPos{iType}(iTrial,segTime));
    rStdSeg{iType}(iTrial) = nanstd(r);
    % this type variable is used for the call to anovan
    type{iType}(iTrial) = iType;
    % convert to polar
    [phiSeg{iType}(iTrial) rSeg{iType}(iTrial)] = cart2pol(xPosSeg{iType}(iTrial),yPosSeg{iType}(iTrial));
  end
end

% run anova on the seg pos
pX = anova1(cell2mat(xPosSeg)',cell2mat(type)','off');
pY = anova1(cell2mat(yPosSeg)',cell2mat(type)','off');

% display the p-values for anova
disp(sprintf('(mglCheckEyepos) Anova for segment %i effect of %s in x: %f deg',segNum,parameter,pX));
disp(sprintf('(mglCheckEyepos) Anova for segment %i effect of %s in y: %f deg',segNum,parameter,pY));

% do hotellings t2 test  for each pairwise comparison
pHotelling = [];
if exist('hotelling') == 2
  for iType = 1:(length(uniqueParameterValues)-1)
    for jType = iType+1:length(uniqueParameterValues)
      % calculate hotellings t2 test
      pHotelling(iType,jType) = hotelling(phiSeg{iType},phiSeg{jType},rSeg{iType},rSeg{jType});
      % display
      disp(sprintf('(mglCheckEyepos) Hotelling T2 test for %s in segment %i %f vs %f: %s',parameter,segNum,uniqueParameterValues(iType),uniqueParameterValues(jType),disppval(pHotelling(iType,jType))));
    end
  end
end

% display how well the observer fixated for the interval
disp(sprintf('(mglCheckEyepos) Average standard deviation during segment %i in x: %f deg',segNum,mean(cell2mat(xStdSeg))));
disp(sprintf('(mglCheckEyepos) Average standard deviation during segment %i in y: %f deg',segNum,mean(cell2mat(yStdSeg))));
disp(sprintf('(mglCheckEyepos) Average standard deviation during segment %i in r: %f deg',segNum,mean(cell2mat(rStdSeg))));
  

% plot the median/ste eye traces as a function of parameter value
mlrSmartfig('checkPos','reuse');clf;
for iType = 1:length(uniqueParameterValues)
  % get color to plot in
  c = getSmoothColor(iType,length(uniqueParameterValues),'hsv');
  % plot x
  subplot(3,1,1);
  plot(t,nanmedian(xPos{iType}),'Color',c);
  hold on
  plot(t,nanmedian(xPos{iType})+nanstd(xPos{iType})./sqrt(nX{iType}),':','Color',c);
  plot(t,nanmedian(xPos{iType})-nanstd(xPos{iType})./sqrt(nX{iType}),':','Color',c);
  % plot y
  subplot(3,1,2);
  plot(t,nanmedian(yPos{iType}),'Color',c)
  hold on
  plot(t,nanmedian(yPos{iType})+nanstd(yPos{iType})./sqrt(nY{iType}),':','Color',c);
  plot(t,nanmedian(yPos{iType})-nanstd(yPos{iType})./sqrt(nY{iType}),':','Color',c);
  % plot number of trials
  subplot(3,1,3);
  plot(t,min(nX{iType},nY{iType}),'Color',c);
  hold on
  % get legend info
  legendName{iType} = sprintf('%s=%0.4f',parameter,uniqueParameterValues(iType));
  legendColor{iType} = {'k-' c};
end

subplot(3,1,1);
mylegend(legendName,legendColor);
xlabel('time');
ylabel('xPos (deg)');
subplot(3,1,2);
xlabel('time');
ylabel('yPos (deg)');
subplot(3,1,3);
xlabel('time');
ylabel('nTrials');

mlrSmartfig('checkPosSeg','reuse');clf;
for iType = 1:length(uniqueParameterValues)
  % get color to plot in
  c = getSmoothColor(iType,length(uniqueParameterValues),'hsv');
  % plot segment x and y
  plot(xPosSeg{iType},yPosSeg{iType},'.','Color',c);
  hold on
end
mylegend(legendName,legendColor);
title(sprintf('Median segment %i position\nANOVA x: %s, y: %s',segNum,disppval(pX),disppval(pY)));
xlabel('XPos (deg)');
ylabel('yPos (deg)');


