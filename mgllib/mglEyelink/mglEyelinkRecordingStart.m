function mglEyelinkRecordingStart(varargin)
% mglEyelinkOpen - Opens a connection to an SR Resarch Eyelink eyetracker
%
%     program: mglEyelinkRecordingStart.m
%          by: eric dewitt
%        date: 04/03/06
%  copyright: (c) 2009,2006 Eric DeWitt, Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%     purpose: open a link connection to an SR Research Eylink
%
%       Usage: mglEyelinkRecordingStart(<recordingState>)
%
%              Pass in either a vector for recording state: e.g. [1 0 0 0] where
%              the elements are [file-sample file-event link-sample link-event]
%              or up to four string arguments that set the recording state
%
%              mglEyelinkRecordingStart('file-sample','file-event',
%                                       'link-sample','link-event');
%
%               'edf-sample' and 'edf-event' are equivilant to 'file-*'

if ~any(nargin == 1:4)
    help mglEyelinkRecordingStart
    return;
end

recordingState = [0 0 0 0];
if nargin == 1 && isvector(varargin{1}) && length(varargin{1}) == 4
    recordingState = varargin{1};
else
    for nArg = 1:nargin
        if ischar(varargin{nArg})
            switch lower(varargin{nArg})
                case {'edf-sample', 'file-sample'}
                    recordingState = recordingState | [1 0 0 0];
                case {'edf-event', 'file-event'}
                    recordingState = recordingState | [0 1 0 0];
                case 'link-sample'
                    recordingState = recordingState | [0 0 1 0];
                case 'link-event'
                    recordingState = recordingState | [0 0 0 1];
                otherwise
                    error('(mglEyelinkRecordingStart) Incorrect arguments.');
            end
        else
            error('(mglEyelinkRecordingStart) Incorrect arguments.');
        end
    end
end
retval = mglPrivateEyelinkRecordingStart(recordingState);
if retval == -1
  if ~askuser('(mglEyelinkRecordingStart) Eyelink failed to start. Do you want to continue')
    keyboard
  end
end

% askuser.m
%
%      usage: askuser(question,<toall>,<useDialog>)
%         by: justin gardner
%       date: 02/08/06
%    purpose: ask the user a yes/no question. Question is a string or a cell arry of strings with the question. This
%             function will return 1 for yes and 0 for no. If toall is set to 1, then
%             'Yes to all' will be an option, which if selected will return inf
%
function r = askuser(question,toall,useDialog)

% check arguments
if ~any(nargin == [1 2 3])
  help askuser
  return
end

if ieNotDefined('toall'),toall = 0;,end
if ieNotDefined('useDialog'),useDialog=0;end

% if explicitly set to useDialog then use dialog, otherwise
% check verbose setting
if useDialog
  verbose = 1;
else
  verbose = mrGetPref('verbose');
  if strcmp(verbose,'Yes'),verbose = 1;else,verbose = 0;end
end

r = [];

question=cellstr(question); %convert question into a cell array
  

while isempty(r)
  % ask the question
  if ~verbose
    % not verbose, use text question
    %fprintf('\n');
    for iLine = 1:length(question)-1
      fprintf([question{iLine} '\n']);
    end
    if toall
      % ask the question (with option for all)
      r = input([question{end} ' (y/n or a for Yes to all)? '],'s');
    else
      % ask question (without option for all)
      r = input([question{end} ' (y/n)? '],'s');
    end
  else
    if toall
      % verbose, use dialog
      r = questdlg(question,'','Yes','No','All','Yes');
      r = lower(r(1));
    else
      r = questdlg(question,'','Yes','No','Yes');
      r = lower(r(1));
    end
  end
  % make sure we got a valid answer
  if (lower(r) == 'n')
    r = 0;
  elseif (lower(r) == 'y')
    r = 1;
  elseif (lower(r) == 'a') & toall
    r = inf;
  else
    r =[];
  end
end



