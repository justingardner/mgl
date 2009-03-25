function mglEyelinkRecordingStart(varargin)
%
%
% accepts either vector or text for recording types

    if ~any(nargin==[0:4])
        error('(mglEyelinkRecordingStart) Incorrect arguments.');
    end
    
    recordingState = [0 0 0 0];
    if isvector(varargin(nArg)) && nargin == 1 && ...
        length(varargin(nArg)) == 4
        recordingState == varargin(nArg);
    else
        for nArg = 1:nargin
            if ischar(varargin(nArg))
                switch lower(varargin(nArg))
                    case {'edf-sample', 'file-sample'}
                        recordingState = recordingState | [1 0 0 0];
                    case {'edf-event', 'file-event'}
                        recordingState = recordingState | [0 1 0 0];
                    case {'link-sample', 'link-sample'}
                        recordingState = recordingState | [0 0 1 0];
                    case {'link-event', 'link-event'}
                        recordingState = recordingState | [0 0 0 1];
                    otherwise
                        error('(mglEyelinkRecordingStart) Incorrect arguments.');
                end
            else
                error('(mglEyelinkRecordingStart) Incorrect arguments.');
            end
        else
            error('(mglEyelinkRecordingStart) Incorrect arguments.');
        end
    end
end