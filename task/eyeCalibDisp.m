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
  if myscreen.useMGL
    mglClearScreen(myscreen.background);
  else
    Screen('FillRect', myscreen.w, myscreen.background);
  end
end
myscreen = tickScreen(myscreen);

if (myscreen.eyecalib.prompt)
  % check for space key
  mydisp(sprintf('Hit SPACE to do eye calibration\n'));
  mydisp(sprintf('ENTER to skip eye calibration\n'));
  mydisp(sprintf('Esc aborts at any time\n'));
  mydisp(sprintf('-----------------------------\n'));

  while ~mglGetKeys(myscreen.keyboard.space)
    if mglGetKeys(myscreen.keyboard.esc)
      return
    end
    if mglGetKeys(myscreen.keyboard.return)
      % starting experiment, start the eye tracker
      myscreen.fishcamp = bitor(myscreen.fishcamp,1);
      fishcamp(1,myscreen.fishcamp);
      % reset fliptime
      myscreen.fliptime = inf;
      return
    end
  end
end

% make sure eye tracker is on and recording that this is an eyecalibration
myscreen.fishcamp = bitor(myscreen.fishcamp,bin2dec('101'));
fishcamp(1,myscreen.fishcamp);

for j = 1:myscreen.eyecalib.n
  mglClearScreen;
  mglGluDisk(myscreen.eyecalib.x(j),myscreen.eyecalib.y(j),myscreen.eyecalib.size/2,myscreen.eyecalib.color);
  mglFlush;
  startTime = GetSecs;
  if ~isinf(myscreen.eyecalib.waittime)
    while (myscreen.eyecalib.waittime > (GetSecs-startTime));
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
myscreen.fishcamp = bitand(hex2dec('FF01'),myscreen.fishcamp);
fishcamp(1,myscreen.fishcamp);
% reset fliptime
myscreen.fliptime = inf;


