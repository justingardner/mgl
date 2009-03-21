function [myscreen] = initEyeTracker(myscreen, varargin)
% initEyeTracker - initializes a the myscreen and tracker for use
%
%

% initEyeTracker.m
%
%        $Id: initEyeTracker.m 203 2007-03-19 15:41:00Z justin $
%      usage: myscreen = initEyeTracker(myscreen, [tracker])
%         by: eric dewitt
%       date: 2009-03-10
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%             (c) Copyright 2009 Eric DeWitt. All Rights Reserved. 
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

    initializer = [];
    if nargin<1
        help initEyeTracker;
    elseif nargin >= 2
        myscreen.eyeTrackerType = varargin{1};
    elseif ~isfield(myscreen, 'eyeTrackerType')
        fprintf(2, '(initEyeTracker) No eye-tracker specified in myscreen.\n');
    end
    initializer = sprintf('init%sEyeTracker', myscreen.eyeTrackerType);
    
    %% handle optional arguments for specific trackers
    if nargin > 2
        varargin = varargin{2:end};
        if ~iscell(varargin)
            varargin = {varargin};
        end
    end
    
    %% check to see if we have a valid eyetracker (that we know about)
    if isempty(initializer)
        fprintf(2,'(initEyeTracker) No tracker specified, proceeding without eyetracker\n');
    else
        if exist(initializer)
            if nargin>2
                eval(sprintf('myscreen = %s(myscreen, varargin{:});', initializer));
            else
                eval(sprintf('myscreen = %s(myscreen);', initializer));
            end
        else
            fprintf(2, '(initEyeTracker) Unknown eye-tracker specified.\n');
        end
    end
    if ~myscreen.eyetracker.init
        error('Attempt to initialize eye tracker failed.');
    end
    
end