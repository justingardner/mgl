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
mglPrivateEyelinkRecordingStart(recordingState);
