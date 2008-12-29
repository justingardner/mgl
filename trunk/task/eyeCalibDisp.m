% eyeCalibDisp.m
%
%        $Id$
%      usage: eyeCalibDisp()
%         by: justin gardner
%       date: 12/10/04
%  copyright: (c) 2006 Justin Gardner (GPL see mgl/COPYING)
%    purpose: eye calibration - MGL version
%             stimuli should be defined in visual angle coords
%
function myscreen = eyeCalibDisp(myscreen)

% set the screen background color
if (myscreen.background ~= 0)
  mglClearScreen(myscreen.background);
end
myscreen = tickScreen(myscreen);

if (myscreen.eyecalib.prompt)
  % check for space key
  disp(sprintf('-----------------------------'));
  disp(sprintf('Hit SPACE to do eye calibration'));
  disp(sprintf('ENTER to skip eye calibration'));
  disp(sprintf('Esc aborts at any time'));
  disp(sprintf('-----------------------------'));
  drawnow;
  while ~mglGetKeys(myscreen.keyboard.space)
    if mglGetKeys(myscreen.keyboard.esc)
      return
    end
    if mglGetKeys(myscreen.keyboard.return)
      % starting experiment, start the eye tracker
      writeDigPort(16,2);
      %myscreen.fishcamp = bitor(myscreen.fishcamp,1);
      %fishcamp(1,myscreen.fishcamp);
      % reset fliptime
      myscreen.fliptime = inf;
      return
    end
  end
end

% put fixation in center of screen to allow subject to get there in time
mglClearScreen;
mglGluDisk(0,0,myscreen.eyecalib.size/2,myscreen.eyecalib.color);
mglFlush;
if waitSecsEsc(2,myscreen) == -1,return,end

% make sure eye tracker is on and recording that this is an eyecalibration
%myscreen.fishcamp = bitor(myscreen.fishcamp,bin2dec('101'));
%fishcamp(1,myscreen.fishcamp);
writeDigPort(16,2);

for j = 1:myscreen.eyecalib.n
  mglClearScreen;
  mglGluDisk(myscreen.eyecalib.x(j),myscreen.eyecalib.y(j),myscreen.eyecalib.size/2,myscreen.eyecalib.color);
  mglFlush;
  if ((myscreen.eyecalib.x(j) ~= 0) || (myscreen.eyecalib.y(j) ~= 0))
    writeDigPort(48,2);
  else
    writeDigPort(16,2);
  end
  startTime = mglGetSecs;
  if ~isinf(myscreen.eyecalib.waittime)
    while (myscreen.eyecalib.waittime > (mglGetSecs-startTime));
      if mglGetKeys(myscreen.keyboard.esc)
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

function retval = waitSecsEsc(waitTime,myscreen)

retval = 1;
startTime = mglGetSecs;
while mglGetSecs(startTime) <= waitTime
  if mglGetKeys(myscreen.keyboard.esc)
    retval = -1;
    return
  end
end
