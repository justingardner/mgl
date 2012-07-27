% editStimfile.m
%
%        $Id:$ 
%      usage: editStimfile(stimFilename)
%         by: justin gardner
%       date: 07/27/12
%    purpose: GUI to view and edit stimfiles
%
function retval = editStimfile(stimFilename,varargin)

% check arguments
if nargin < 1
  help editStimfile
  return
end

% get arguments
getArgs(varargin,{'scanNum=[]','groupNum=[]','carFilename=[]'});

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
  [stimFilename carFilename] = getFilenamesFromView(stimFilename,scanNum,groupNum);
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
    gEditStimfile.stimfile{iFile} = stimfile;
  end
  % make short name
  gEditStimfile.stimFilenameShort{iFile} = stripext(getLastDir(gEditStimfile.stimFilename{iFile}));
  % make description
  makeDispStr(iFile);
end

% set up params dialog
paramsInfo = {};
paramsInfo{end+1} = {'stimFilename',gEditStimfile.stimFilenameShort,'callback',@editStimfileParamsCallback,'Name of the stimfile being displayed'};
paramsInfo{end+1} = {'volnum',1,'callback',@editStimfileParamsCallback,'incdec=[-1 1]','minmax=[1 inf]','Current selected volume - shown in red'};
paramsInfo{end+1} = {'remove',1,'type=pushbutton','buttonString=Delete volume','callback',@editStimfileDeleteVolume,'Remove the current selected volume'};

% open figure
gEditStimfile.fig = mlrSmartfig('editStimfile');

% display the stimfile
editStimfileUpdateDisp(gEditStimfile);

% open control dialog
mrParamsDialog(paramsInfo,'Edit Stimfile');

% close figure
close(gEditStimfile.fig);

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

% delete the volume
gEditStimfile.stimfile{gEditStimfile.index}.myscreen = deleteVolume(msc,gEditStimfile.volnum);

% recreate the display string
makeDispStr(gEditStimfile.index);

% redraw
editStimfileUpdateDisp(gEditStimfile);

%%%%%%%%%%%%%%%%%%%%%%
%    deleteVolume    %
%%%%%%%%%%%%%%%%%%%%%%
function msc = deleteVolume(msc,volnum);

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileParamsCallback    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function editStimfileParamsCallback(params)

global gEditStimfile;

% set the index
gEditStimfile.index = find(strcmp(params.stimFilename,gEditStimfile.stimFilenameShort));

% set the volnum
gEditStimfile.volnum = params.volnum;

% redraw
editStimfileUpdateDisp(gEditStimfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    editStimfileUpdateDisp    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function editStimfileUpdateDisp(g)

msc = g.stimfile{g.index}.myscreen;

% clear the fig
clf(g.fig);
a = gca(g.fig);

% plot the traces
plot(a,msc.time,msc.traces(1,:),'k-');
hold(a,'on');

% get the event
event = getVolEvent(msc,g.volnum);
if ~isempty(event)
  plot(a,[event.time event.time],[0 1],'r-');
end

% label the axis
xlabel(a,'Time (sec)');
ylabel(a,'Volume trace');
title(a,g.dispstr{g.index},'Interpreter','none');
zoom on

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
