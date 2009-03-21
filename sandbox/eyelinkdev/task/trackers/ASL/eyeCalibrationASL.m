% eyeCalibrationASL.m
%
%        $Id: eyeCalibDisp.m 486 2009-02-16 00:05:54Z dep $
%      usage: eyeCalibDisp()
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: eye calibration - mgl version
%             stimuli should be defined in visual angle coords
%

% TODO: make this function generic with respect to the eyetracker used
function myscreen = eyeCalibrationASL(myscreen)

    % set the screen background color
    if (myscreen.background ~= 0)
        mglClearScreen(myscreen.background);
    end
    myscreen = tickScreen(myscreen);

    if (myscreen.eyetracker.prompt)
        % check for space key
        disp(sprintf('-----------------------------'));
        disp(sprintf('Hit SPACE to do eye calibration'));
        disp(sprintf('ENTER to skip eye calibration'));
        disp(sprintf('Esc aborts at any time'));
        disp(sprintf('-----------------------------'));
        drawnow;
        keyCodes=[];
        while ~any(keyCodes==myscreen.keyboard.space)
            if any(keyCodes == myscreen.keyboard.esc)
                return
            end
            if any(keyCodes == myscreen.keyboard.return)
                % starting experiment, start the eye tracker
                writeDigPort(16,2);
                %myscreen.fishcamp = bitor(myscreen.fishcamp,1);
                %fishcamp(1,myscreen.fishcamp);
                % reset fliptime
                myscreen.fliptime = inf;
                return
            end
            [keyCodes keyTimes] = mglGetKeyEvent([],1);
        end
    end

    % put fixation in center of screen to allow subject to get there in time
    mglClearScreen;
    mglGluDisk(0,0,myscreen.eyetracker.size/2,myscreen.eyetracker.color);
    mglFlush;
    if waitSecsEsc(2,myscreen) == -1
        return
    end

    % make sure eye tracker is on and recording that this is an eyetrackerration
    %myscreen.fishcamp = bitor(myscreen.fishcamp,bin2dec('101'));
    %fishcamp(1,myscreen.fishcamp);
    writeDigPort(16,2);

    for j = 1:myscreen.eyetracker.n
        mglClearScreen;
        mglGluDisk(myscreen.eyetracker.x(j),myscreen.eyetracker.y(j),myscreen.eyetracker.size/2,myscreen.eyetracker.color);
        mglFlush;
        if ((myscreen.eyetracker.x(j) ~= 0) || (myscreen.eyetracker.y(j) ~= 0))
            writeDigPort(48,2);
        else
            writeDigPort(16,2);
        end
        startTime = mglGetSecs;
        if ~isinf(myscreen.eyetracker.waittime)
            while (myscreen.eyetracker.waittime > (mglGetSecs-startTime));
                [keyCodes keyTimes] = mglGetKeyEvent([],1);
                if any(keyCodes==myscreen.keyboard.esc)
                    mglClearScreen;mglFlush;
                    mglClearScreen;mglFlush;
                    return
                end
            end
        else
            input(sprintf('Hit ENTER to continue'));
        end
    end
    mglClearScreen;mglFlush;
    mglClearScreen;mglFlush;

    % turn off trace for eye calibration
    %myscreen.fishcamp = bitand(hex2dec('FF01'),myscreen.fishcamp);
    %fishcamp(1,myscreen.fishcamp);
    % reset fliptime
    myscreen.fliptime = inf;

    writeDigPort(16,2);
end

function retval = waitSecsEsc(waitTime,myscreen)

    retval = 1;
    startTime = mglGetSecs;
    while mglGetSecs(startTime) <= waitTime
        [keyCodes keyTimes] = mglGetKeyEvent([],1);
        if any(keyCodes==myscreen.keyboard.esc)
            retval = -1;
            return
        end
    end
end