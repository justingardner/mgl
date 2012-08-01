% editStimfile.m
%
%        $Id:$ 
%      usage: editStimfile(stimFilename)
%         by: justin gardner
%       date: 07/27/12
%    purpose: GUI to view and edit stimfiles
%
%      usage: To view all stimfiles in the Raw group
%             v = newView;
%             editStimfile(v,'group=Raw');
%
%             Or a specific scan and group
%             v = newView;
%             editStimfile(v,'scanNum=3','groupNum=Concatenation');
% 
%             To view a specific stimfile
%             editStimfile('120731_stim01');
%
%
function retval = editStimfile(stimFilename,varargin)

% check arguments
if nargin < 1
  help editStimfile
  return
end

% get arguments
getArgs(varargin,{'scanNum=[]','groupNum=[]','carFilename=[]','group=[]'});

% check for mrParamsDialog function
if exist('mrParamsDialog') ~= 2
  disp(sprintf('(editStimfile) You need to install mrTools functions to use this. You can download just the whole package or just the utilities functions: see http://gru.brain.riken.jp/doku.php/mgl/gettingStarted'));
  return
end

% check for isView
hasMrTools = false;
if exist('isview') == 2,hasMrTools = true;end

% if passed in argument is a view, then we get the stimfile from the view
if hasMrTools && isview(stimFilename)
  v = stimFilename;
  % if group, then try to load all stimfiles for group
  if ~isempty(group)
    % check for group
    groupNum = viewGet(v,'groupNum',group);
    if isempty(groupNum),disp(sprintf('(editStimfile) Could not find group %s',group));return;end
    % get nScans for group
    v = viewSet(v,'curGroup',groupNum);
    nScans = viewGet(v,'nScans');
    % load each scan's info
    stimFilename = {};carFilename = {};
    for iScan = 1:nScans
      [thisStimFilename thisCarFilename] = getFilenamesFromView(v,iScan,groupNum);
      stimFilename = {stimFilename{:} thisStimFilename{:}};
      carFilename = {carFilename{:} thisCarFilename{:}};
    end
  else
    [stimFilename carFilename] = getFilenamesFromView(v,scanNum,groupNum);
  end
end  

% make stimFilename into a string
stimFilename = cellArray(stimFilename);

% check carFilename
if ~isempty(carFilename)
  carFilename = cellArray(carFilename);
  if length(carFilename) ~= length(stimFilename)
    disp(sprintf('(editStimfile) Length of carFilename list does not match length of stimFilename'));
    carFilename = [];
  end
end

% make a global to carry stimfiles
global gEditStimfile;
gEditStimfile = [];

% set up global
gEditStimfile.n = length(stimFilename);
gEditStimfile.index = 1;
gEditStimfile.volnum = 1;
gEditStimfile.stimFilename = stimFilename;
gEditStimfile.carFilename = carFilename;

% load files
editStimfileLoadFiles;

% set up params dialog
paramsInfo = {};
paramsInfo{end+1} = {'stimFilename',gEditStimfile.stimFilenameShort,'callback',@editStimfileParamsCallback,'Name of the stimfile being displayed'};
if ~isempty(gEditStimfile.carFilename)
  paramsInfo{end+1} = {'carFilename',gEditStimfile.carFilenameShort{1},'editable=0'};
end  
paramsInfo{end+1} = {'volnum',1,'callback',@editStimfileParamsCallback,'incdec=[-1 1]','minmax=[1 inf]','Current selected volume - shown in red'};
paramsInfo{end+1} = {'remove',1,'type=pushbutton','buttonString=Delete volume','callback',@editStimfileDeleteVolume,'Remove the current selected volume'};
paramsInfo{end+1} = {'export',1,'type=pushbutton','buttonString=Export to base workspace','callback',@editStimfileExport,'Export the stimfile structure to the workspace as the variable stimfile'};
paramsInfo{end+1} = {'save',1,'type=pushbutton','buttonString=Save stimfile','callback',@editStimfileSave,'Save the stimfile'};

% open figure
gEditStimfile.fig = mlrSmartfig('editStimfile');

% display the stimfile
editStimfileUpdateDisp(gEditStimfile);

% open control dialog
mrParamsDialog(paramsInfo,'Edit Stimfile');

% close figure
close(gEditStimfile.fig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileExport    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dummy = editStimfileExport

% dummy return variable
dummy = 1;

% get global
global gEditStimfile;

% get stimfile and associated info
stimfile = gEditStimfile.stimfile{gEditStimfile.index};
stimfile.filename = gEditStimfile.stimFilename{gEditStimfile.index};
if ~isempty(gEditStimfile.carFilename)
  stimfile.car = gEditStimfile.car{gEditStimfile.index};
end

% assign in matlab workspace
assignin('base','stimfile',stimfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileSave    %
%%%%%%%%%%%%%%%%%%%%%%%%%%
function dummy = editStimfileSave

% dummy return variable
dummy = 1;

% get global
global gEditStimfile;

filenameShort = gEditStimfile.stimFilenameShort{gEditStimfile.index};
filename = gEditStimfile.stimFilename{gEditStimfile.index};
stimfile = gEditStimfile.stimfile{gEditStimfile.index};

% see if user wants to overwrite
if ~askuser(sprintf('(editStimfile) Make backup of original and save this version as %s',filenameShort),false,true);
  return
end

% first copy old file to make a backup - with a timestamp
backupName = sprintf('%s_backup_%s.mat',filenameShort,datestr(now,'YYYY_mm_DD_HH_MM_SS'));
backupName = fullfile(getpath(filename),backupName);

if isfile(filename)
  disp(sprintf('(editStimfile) Making backup of %s to %s',getLastDir(filename),getLastDir(backupName)));
  movefile(filename,backupName);
else
  disp(sprintf('(editStimfile) Could not find original %s to make backup of',filename));
end

% save the new stimfile
disp(sprintf('(editStimfile) Saving %s',filename));
save(filename,'-struct','stimfile');


%%%%%%%%%%%%%%%%%%%%%
%    makeDispStr    %
%%%%%%%%%%%%%%%%%%%%%
function dispstr = makeDispStr(iFile)

global gEditStimfile;
msc = gEditStimfile.stimfile{iFile}.myscreen;

% get average TR
tr = getedges(msc.traces(1,:),0.5);
tr = median(diff(msc.time(tr.rising)));

% set the str
gEditStimfile.dispstr{iFile} = sprintf('%s nVols: %i (%s -> %s) tr=%0.3f',gEditStimfile.stimFilenameShort{iFile},msc.volnum,msc.starttime,msc.endtime,tr);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileDeleteVolume    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function val = editStimfileDeleteVolume

val = 1;
global gEditStimfile;
msc = gEditStimfile.stimfile{gEditStimfile.index}.myscreen;
extra = gEditStimfile.extra{gEditStimfile.index};

% delete the volume
[gEditStimfile.stimfile{gEditStimfile.index}.myscreen gEditStimfile.extra{gEditStimfile.index}] = deleteVolume(msc,extra,gEditStimfile.volnum);

% recreate the display string
makeDispStr(gEditStimfile.index);

% redraw
editStimfileUpdateDisp(gEditStimfile);

%%%%%%%%%%%%%%%%%%%%%%
%    deleteVolume    %
%%%%%%%%%%%%%%%%%%%%%%
function [msc extra] = deleteVolume(msc,extra,volnum);

% get the event
event = getVolEvent(msc,volnum);

% see if it exists
if isempty(event)
  disp(sprintf('(editStimfile:deleteVolume) Volume %i does not exist',volnum));
  return
end

% now go and delete that event
eventNums = [1:event.num-1 event.num+1:msc.events.n];
eventFields = fieldnames(msc.events);
for iField = 1:length(eventFields)
  if length(msc.events.(eventFields{iField})) == msc.events.n
    msc.events.(eventFields{iField}) = msc.events.(eventFields{iField})(eventNums);
  end
end
msc.events.n = length(eventNums);

% fix the volume numbers for all events that happened after the removed one
msc.events.volnum(event.num:end) = msc.events.volnum(event.num:end)-1;

% remove a volume
msc.volnum = msc.volnum-1;

% remake traces
msc = makeTraces(msc);

% get first volume, so that we can rest the time of myscreen to be 0 at first acq
triggers = getedges(msc.traces(1,:),0.5);
firstTriggerTime = msc.time(triggers.rising(1));
lastTriggerTime = msc.time(triggers.rising(end));
extra.time = msc.time-firstTriggerTime;
extra.firstTriggerTime = firstTriggerTime;
extra.lastTriggerTime = lastTriggerTime;
extra.scanEndTime = lastTriggerTime-firstTriggerTime+median(diff(msc.time(triggers.rising)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileParamsCallback    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function editStimfileParamsCallback(params)

global gEditStimfile;

% set the index
gEditStimfile.index = find(strcmp(params.stimFilename,gEditStimfile.stimFilenameShort));

% if we have carfiles, then update the carfile name
if ~isempty(gEditStimfile.carFilename)
  params.carFilename = gEditStimfile.carFilenameShort{gEditStimfile.index};
  mrParamsSet(params);
end

% set the volnum
gEditStimfile.volnum = params.volnum;

% redraw
editStimfileUpdateDisp(gEditStimfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileUpdateDisp    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function editStimfileUpdateDisp(g)

% how many rows of plots to draw
numRows = 1;

% shortcut to myscreen
msc = g.stimfile{g.index}.myscreen;
extra = g.extra{g.index};

% see if we are going to draw car as well
if ~isempty(g.carFilename)
  numRows = numRows + 5;
end

% clear the fig
clf(g.fig);
a = subplot(numRows,1,1,'Parent',g.fig);

% plot the traces
plot(a,extra.time,msc.traces(1,:),'k-');
hold(a,'on');

% get the event
event = getVolEvent(msc,g.volnum);
if ~isempty(event)
  plot(a,[event.time event.time]-extra.firstTriggerTime,[0 1],'r-');
end

% set the axis limits
axis(a,[extra.minTime extra.maxTime -0.1 1.1]);

% label the axis
xlabel(a,'Time (sec)');
ylabel(a,'Volume trace');
title(a,g.dispstr{g.index},'Interpreter','none');
h = zoom(g.fig);
set(h,'Enable','on');
set(h,'Motion','horizontal');
set(h,'ActionPostCallback',@zoomCallback);

% draw car file if we have one
if ~isempty(g.carFilename)
  % shortcut
  car = g.car{g.index};
  % plot the stim trigger
  a = subplot(numRows,1,2,'Parent',g.fig);
  cla(a);
  plot(a,car.time,car.channels(car.trigChannel,:));
  aLim = axis(a);
  axis(a,[extra.minTime extra.maxTime aLim(3) aLim(4)]);
  ylabel(a,'ADC');
  title(a,g.carTrigDispstr{g.index});
  % plot the acq trigger
  a = subplot(numRows,1,3,'Parent',g.fig);
  cla(a);
  plot(a,car.acqTime,car.acq,'r-')
  aLim = axis(a);
  axis(a,[extra.minTime extra.maxTime -0.1 1.1]);
  ylabel(a,'Digio');
  title(a,g.carAcqDispstr{g.index});
  % plot the buttons
  a = subplot(numRows,1,4,'Parent',g.fig);
  cla(a);
  plot(a,car.time,car.channels(car.button1Channel,:),'r-');
  hold(a,'on');
  plot(a,car.time,car.channels(car.button2Channel,:),'k-');
  aLim = axis(a);
  axis(a,[extra.minTime extra.maxTime aLim(3) aLim(4)]);
  ylabel(a,'ADC');
  title(a,sprintf('Button1: %i Button2: %i',car.button1Channel,car.button2Channel));
  % plot respiration
  a = subplot(numRows,1,5,'Parent',g.fig);
  cla(a);
  plot(a,car.time,car.resp,'b-');
  hold(a,'on');
  aLim = axis(a);
  axis(a,[extra.minTime extra.maxTime aLim(3) aLim(4)]);
  ylabel(a,'ADC');
  title(a,g.carRespirDispstr{g.index});
  % plot cardio
  a = subplot(numRows,1,6,'Parent',g.fig);
  cla(a);
  plot(a,car.time,car.cardio,'r-');
  hold(a,'on');
  aLim = axis(a);
  axis(a,[extra.minTime extra.maxTime aLim(3) aLim(4)]);
  xlabel(a,'Time (sec)');
  ylabel(a,'ADC');
  title(a,g.carCardioDispstr{g.index});
  
end

%%%%%%%%%%%%%%%%%%%%%
%    getEventNum    %
%%%%%%%%%%%%%%%%%%%%%
function event = getVolEvent(msc,volnum)

event = [];
volnumEvents = find(msc.events.tracenum==1);
if (volnum >= 1) && (volnum <= length(volnumEvents))
  event.num = volnumEvents(volnum);
  event.time = msc.events.time(event.num)-msc.events.time(1);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    getFilenamesFromView    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [stimFilename carFilename] = getFilenamesFromView(v,scanNum,groupNum)

% set group
if ~isempty(groupNum)
  v = viewSet(v,'curGroup',groupNum);
end

% set scan
if ~isempty(scanNum)
  v = viewSet(v,'curScan',scanNum);
end

% get the stimfilename
stimFilename = viewGet(v,'stimFilename');

% get the fidFilenames
fidFilenames = viewGet(v,'fidFilename');

% look for car files
for iFid = 1:length(fidFilenames)
  d = dir(fidFilenames{iFid});
  carFilename{iFid} = '';
  for iDir = 1:length(d)
    if strcmp(lower(getext(d(iDir).name)),'car')
      carFilename{iFid} = fullfile(fidFilenames{iFid},d(iDir).name);
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileLoadFiles    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function editStimfileLoadFiles

global gEditStimfile

% read the stimFiles
for iFile = 1:gEditStimfile.n
  filename = setext(gEditStimfile.stimFilename{iFile},'mat');
  if ~isfile(filename)
    disp(sprintf('(editStimfile) Could not find stimfile: %s',filename));
    return
  else
    stimfile = load(filename);
    if ~isfield(stimfile,'myscreen')
      disp(sprintf('(editStimfile) Stimfile %s is missing myscreen variable',filename));
      return
    end

    % make traces
    stimfile.myscreen = makeTraces(stimfile.myscreen);
    
    % get first volume, so that we can rest the time of myscreen to be 0 at first acq
    triggers = getedges(stimfile.myscreen.traces(1,:),0.5);
    firstTriggerTime = stimfile.myscreen.time(triggers.rising(1));
    lastTriggerTime = stimfile.myscreen.time(triggers.rising(end));
    extra.time = stimfile.myscreen.time-firstTriggerTime;
    extra.firstTriggerTime = firstTriggerTime;
    extra.lastTriggerTime = lastTriggerTime;
    extra.scanEndTime = lastTriggerTime-firstTriggerTime+median(diff(stimfile.myscreen.time(triggers.rising)));

    % get min and max time
    extra.minTime = min(extra.time);
    extra.maxTime = max(extra.time);
    
    % put stimfile in global
    gEditStimfile.stimfile{iFile} = stimfile;
    gEditStimfile.extra{iFile} = extra;
  end

  % make short name
  gEditStimfile.stimFilenameShort{iFile} = stripext(getLastDir(gEditStimfile.stimFilename{iFile}));
  
  % make description
  makeDispStr(iFile);
  
  if ~isempty(gEditStimfile.carFilename)
    % try to load matching carfile
    filename = setext(gEditStimfile.carFilename{iFile},'car');
    
    if ~isfile(filename)
      disp(sprintf('(editStimfile) Could not find carfile: %s',filename));
      % can't load, set all carFilename to empty and give up loading
      gEditStimfile.carFilename = [];
    else
      
      % read car
      car = readcar(filename);
      
      % set what channels are what
      car.trigChannel = 14;
      car.button1Channel = 4;
      car.button2Channel = 5;
      
      % get the trigger pulses
      triggers = car.channels(car.trigChannel,:);
      triggers = getedges(triggers,min(triggers)+(max(triggers)-min(triggers))/2);
      firstTrigger = min(setdiff([triggers.rising triggers.falling],1));

      % now create a time vector with 0 being the time of the first trigger
      channelSamplePeriod = 0.01;
      car.time = 0:channelSamplePeriod:channelSamplePeriod*(size(car.channels,2)-1);
      car.time = car.time-firstTrigger*channelSamplePeriod+channelSamplePeriod;

      % do the same for acq channel
      acqSamplePeriod = 0.001;
      car.acqTime = 0:acqSamplePeriod:acqSamplePeriod*(length(car.acq)-1);
      car.acqTime = car.acqTime-firstTrigger*channelSamplePeriod;

      % and get number of acqs
      acqTriggers = getedges(car.acq,0.5);
      
      % reset min and max time
      gEditStimfile.extra{iFile}.minTime = min(gEditStimfile.extra{iFile}.minTime,min(car.time));
      gEditStimfile.extra{iFile}.maxTime = max(gEditStimfile.extra{iFile}.maxTime,max(car.time));

      % read bit files
      bit = readbit(getpath(filename),0);
      if ~isempty(bit)
	% get heartrate
	bit.heartrate = nan;
	if ~isempty(bit.cardio)
	  bit.heartrate = 60*sum(bit.cardio)/extra.scanEndTime;
	end
	% get respiration rate
	bit.respirrate = nan;
	if ~isempty(bit.cardio)
	  bit.respirrate = 60*sum(bit.respir)/extra.scanEndTime;
	end
	% save in car
	car.bit = bit;
      else
	car.bit.acq = [];
	car.bit.cardio = [];
	car.bit.respir = [];
      end
      
      % make display string
      cardir = dir(car.filename);
      gEditStimfile.carTrigDispstr{iFile} = sprintf('%s nAcq: %i (End: %s) channel: %i',getLastDir(car.filename),length(triggers.rising)+length(triggers.falling),cardir.date,car.trigChannel);
      gEditStimfile.carAcqDispstr{iFile} = sprintf('Acq (%i)',acqTriggers.n);
      if ~isempty(car.bit)
	gEditStimfile.carCardioDispstr{iFile} = sprintf('Cardio (heart rate: %0.1f beats/min)',car.bit.heartrate);
      else
	gEditStimfile.carCardioDispstr{iFile} = sprintf('Cardio');
      end	
      if ~isempty(car.bit)
	gEditStimfile.carRespirDispstr{iFile} = sprintf('Respir (respiration rate: %0.1f breaths/min, %0.2f sec/breath)',car.bit.respirrate,60/car.bit.respirrate);
      else
	gEditStimfile.carRespirDispstr{iFile} = sprintf('Respir');
      end	
      
      % save in global 
      gEditStimfile.car{iFile} = car;
      
      % set short name
      gEditStimfile.carFilenameShort{iFile} = getLastDir(gEditStimfile.carFilename{iFile});
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%
%    zoomCallback    %
%%%%%%%%%%%%%%%%%%%%%%
function zoomCallback(obj,event_obj)

% get all the figures children
allAxes = get(obj,'Children');

% get the current zoom for the zoomed axis
for i = 1:length(allAxes)
  if isequal(event_obj.Axes,allAxes(i))
    zoomedAxis = axis(allAxes(i));
  end
end

% just set all of the x-values the same
for i = 1:length(allAxes)
  thisAxis = axis(allAxes(i));
  axis(allAxes(i),[zoomedAxis(1) zoomedAxis(2) thisAxis(3) thisAxis(4)]);
end

