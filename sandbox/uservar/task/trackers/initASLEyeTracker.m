% eyeCalib9.m
%
%        $Id: eyeCalib9.m 203 2007-03-19 15:41:00Z justin $
%      usage: eyeCalib9.m()
%         by: justin gardner, eric dewitt
%       date: 02/24/05
%  copyright: (c) 2006 Justin Gardner; 2009 Eric DeWitt (GPL see mgl/COPYING)
%
function myscreen = eyeCalib9(myscreen, bkcolor)

    if ~exist('bkcolor','var'),
        bkcolor = 'gray',
    end

    % init the screen
    myscreen.background = bkcolor;
    % now create an output for the tracker
    % with the tracknum shift up 8 bits
    if (isempty(gNumSaves))
        tracknum = 1;
    else
        tracknum = gNumSaves+1;
    end
    
    myscreen.fishcamp = bitshift(tracknum,1);

    % default paramaters for eye calibration
    myscreen.eyetracker.x = [5 0 -5 5 0 -5 5 0 -5];
    myscreen.eyetracker.y = [5 5 5 0 0 0 -5 -5 -5];
    myscreen.eyetracker.n = length(myscreen.eyetracker.x);
    myscreen.eyetracker.waittime = inf;
    
    %% very important, all future code should check this
    myscreen.eyetracker.init = 1;
end