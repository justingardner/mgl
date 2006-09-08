function [elapsed_time,coords]=motionAdaptationTrial(adaptStimParams, adaptTime, ...
						  isiStimParams, isiTime, ...
						  testStimParams, testTime, ...
						  responseStimParams, ...
						  responseTime, ...
						  fixStimParams, ...
						  textParams, ...
						  stimRandFreq, ...
						  coords, ...
						  frameStartFunctionHandle, ...
						  frameStartFunctionArgs, ...
						  frameEndFunctionHandle, ...
						  frameEndFunctionArgs ...
						  );
%function elapsed_time=motionAdaptationTrial( nIncr, nDecr, speedStep,...
%					     adaptStimParams, adaptTime, ...
%					     isiStimParams, isiTime, ...
%					     testStimparams, testTime, ...
%					     responseStimParams, ...
%					     responseTime, ...
%					     fixStimParams, coords
%					     );
%
% Task: count speed decrements 

global MGL

start_time=GetSecs;
frameTime=1/MGL.frameRate;
elapsed_time=0;
randfreqtime=1/stimRandFreq;
trialTime=adaptTime+isiTime+testTime+responseTime;
isiCumTime=adaptTime+isiTime;
testCumTime=isiCumTime+testTime;
responseCumTime=testCumTime+responseTime;
direction=[];
lifetime=[];
if (~exist('frameStartFunctionHandle','var'))
  frameStartFunctionHandle=[];
end
if (~exist('frameEndFunctionHandle','var'))
  frameEndFunctionHandle=[];
end
if (~exist('frameStartFunctionArgs','var'))
  frameStartFunctionArgs=[];
end
if (~exist('frameEndFunctionArgs','var'))
  frameEndFunctionArgs=[];
end
if (length(textParams)>=6)
  textCol=textParams(4:6);
else
  textCol=[1 1 1];
end

randTime=elapsed_time;
currdirection=adaptStimParams.direction; % fix to account for empty adaptstim
currphase=rand*2*pi;
currLetter=1;
currFrame=0;
letters={'Z','L','N','T','X'};
nDrawnLetters=0;
while (elapsed_time<trialTime)
  currFrame=currFrame+1;
  % main loop:
  if (~isempty(frameStartFunctionHandle))
    if (isempty(frameStartFunctionArgs))
      feval(frameStartFunctionHandle);
    else
      feval(frameStartFunctionHandle,frameStartFunctionArgs);
    end
  end
  % set current direction and phase
  if (randTime>randfreqtime)
    if (currdirection(1)==pi/4)
      currdirection=-pi/4+[0 pi];
    else
      currdirection=pi/4+[0 pi];
    end
    currphase=rand*2*pi;
  end
  
  % set current speed
  
  % compute and draw dot stimulus
  if (elapsed_time<adaptTime & ~isempty(adaptStimParams))
    %    adaptStimParams.speed=currspeed;
    adaptStimParams.spatial.phase=currphase;
    adaptStimParams.direction=currdirection;
    [coords,direction,lifetime]=drawDots(coords,direction,lifetime,adaptStimParams );
  
  elseif (elapsed_time<isiCumTime & ~isempty(isiStimParams))
    isiStimParams.spatial.phase=currphase;
    isiStimParams.direction=currdirection;
    [coords,direction,lifetime]=drawDots(coords,direction,lifetime,isiStimParams );
  
  elseif (elapsed_time<testCumTime & ~isempty(testStimParams))
    testStimParams.spatial.phase=currphase;
    testStimParams.direction=currdirection;
    [coords,direction,lifetime]=drawDots(coords,direction,lifetime,testStimParams );
  
  elseif (elapsed_time<responseCumTime & ~isempty(responseStimParams))
    responseStimParams.spatial.phase=currphase;
    responseStimParams.direction=currdirection;
    [coords,direction,lifetime]=drawDots(coords,direction,lifetime,responseStimParams );
    % if required, check for response  
  end
    
  % draw fixation cross
  if (~isempty(fixStimParams))
    %mglFixationCross(fixStimParams);
    if (mod(currFrame,10)==0) 
      currLetter=currLetter+1;
      nDrawnLetters=nDrawnLetters+1;
      if (currLetter>4)
	if (currLetter>5 | rand<0.8)
	  currLetter=1;
	end
      end
    end
    if (elapsed_time>testCumTime)
      mglFixationCross(fixStimParams);
    else
      mglStrokeText( letters{currLetter}, 0, 0, textParams(1),textParams(2),textParams(3), textCol);
    end
  end
  
  if (~isempty(frameEndFunctionHandle))
    if (isempty(frameEndFunctionArgs))
      feval(frameEndFunctionHandle);
    else
      feval(frameEndFunctionHandle,frameEndFunctionArgs);
    end
  end
  % swap buffers
  mglFlush(MGL.displayNumber);
  % get time  
  time_per_frame=GetSecs-start_time-elapsed_time;
  % Hack to get around lack of synching on Linux
  while (time_per_frame<frameTime)
    time_per_frame=GetSecs-start_time-elapsed_time;
  end
  % end hack
  elapsed_time=elapsed_time+time_per_frame;
  if (randTime>randfreqtime)
    randTime=randTime-randfreqtime;
  end
  randTime=randTime+time_per_frame;
end
disp(nDrawnLetters)
return

function [coords,direction,lifetime]=drawDots(coords,direction, ...
					     lifetime,stimParams );
if (isempty(stimParams))
  return;
end

mglClearScreen(stimParams.bgColor);

[coords,direction,lifetime]=dotMotionFrame(coords,direction, ...
					   lifetime,stimParams );
% mask dots
if (isfield(stimParams,'annulus'))
  r2=sum(coords.^2,2);
  mask=find(r2>(stimParams.annulus(1)^2) & r2<(stimParams.annulus(2)^2));
  % plot dots
  mglPoints2(coords(mask,1),coords(mask,2),stimParams.pointSize, ...
	     stimParams.pointColor);
else
  mglPoints2(coords(:,1),coords(:,2)',stimParams.pointSize, ...
	     stimParams.pointColor);    
end
