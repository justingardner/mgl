% initASLEyeTracker.m
%
%        $Id: initASLEyeTracker.m 203 2007-03-19 15:41:00Z justin $
%      usage: initASLEyeTracker.m()
%         by: justin gardner, eric dewitt
%       date: 02/24/05
%  copyright: (c) 2006 Justin Gardner; 2009 Eric DeWitt (GPL see mgl/COPYING)
%
function myscreen = initASLEyeTracker(myscreen, bkcolor, configuration)
    
    global gNumSaves;
    
    if ~exist('configuration', 'var')
        configuration = 12;
    end
    
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
    myscreen.eyetracker.prompt = 1;

    % default dummy callbacks
    myscreen.eyetracker.callback.getPosition    = @aslDefaultCallback;
    myscreen.eyetracker.callback.nextTask       = @aslDefaultCallback;
    myscreen.eyetracker.callback.startBlock     = @aslDefaultCallback;
    myscreen.eyetracker.callback.startTrial     = @aslDefaultCallback;
    myscreen.eyetracker.callback.endTrial       = @aslDefaultCallback;
    myscreen.eyetracker.callback.startSegment   = @aslDefaultCallback;
    myscreen.eyetracker.callback.saveEyeData    = @aslDefaultCallback;
    myscreen.eyetracker.callback.endTracking    = @aslDefaultCallback;

    % default paramaters for eye calibration

    switch configuration
        case {9}
            myscreen.eyetracker.x = [5 0 -5 5 0 -5 5 0 -5];
            myscreen.eyetracker.y = [5 5 5 0 0 0 -5 -5 -5];
            myscreen.eyetracker.n = length(myscreen.eyetracker.x);
            myscreen.eyetracker.waittime = inf;
        case {12}
            myscreen.eyetracker.x = [0 0 -5 0  0 0 5 0 0 0 3.5 0 -3.5 0  3.5 0 -3.5 0];
            myscreen.eyetracker.y = [0 0  0 0 -5 0 0 0 5 0 3.5 0 -3.5 0 -3.5 0  3.5 0];
            myscreen.eyetracker.n = length(myscreen.eyetracker.x);
            myscreen.eyetracker.size = [0.2 0.2];
            myscreen.eyetracker.color = [1 1 0];
            myscreen.eyetracker.waittime = 1;
    end
    
    %% very important, all future code should check this
    myscreen.eyetracker.init = 1;
    
end