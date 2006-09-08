function motionStims2(numtrials)
%  motionStims2(numsec)

global MGL

clear MGL
MGL=mglOpenDisplay('screensize',[640 480],...
			  'framerate',60,...
			  'devicePhysicalSize',[31 23],...
			  'devicePhysicalDistance',57,...
			  'deviceRect','degrees',...
			  'displayNumber',-1, ...
			  'verbose',1,'nosplash',1);
adaptStimParams.nPoints=1500;
adaptStimParams.coherentMotionType='boundary';
adaptStimParams.incoherentMotionType='random';%'movshon';%'random';%'brownian';
adaptStimParams.brownianComponent=0.05;
adaptStimParams.coherence=1;
adaptStimParams.direction=-pi/4+[0 pi];
adaptStimParams.speed=2;
adaptStimParams.lifetime=30;
adaptStimParams.pointSize=2;
adaptStimParams.pointColor=[1 1 1];
adaptStimParams.spatial.orientation=pi/2;
adaptStimParams.spatial.frequency=0.75/2;
adaptStimParams.spatial.phase=pi/3;
adaptStimParams.spatial.origin=[0 0];
adaptStimParams.annulus=[1.5 10];
adaptStimParams.bgColor=[0 0 0];
testStimParams=adaptStimParams;
isiStimParams=adaptStimParams;
isiStimParams.coherentMotionType='translating';
responseStimParams=isiStimParams;
% initialize function
[coords,direction,lifetime]=dotMotionFrame([],[],[],adaptStimParams);
fixStimParams=[0.3 1 0 1 0];
textParams=[0.3, 0.3, 1, 1, 0, 0];

elapsed_time=7.2;
mglStrokeText( 'Waiting for backtick...', -5, 0,0.5,0.5,2, [1 0 0], 0 );
mglFlush
pause
globalStartTime=GetSecs;
for i = 1:numtrials
  
  
  frameStartFun=[];
  frameStartFunArg=[];
  frameEndFun=[];
  frameEndArg=[];

  if (rand>0.5)
    if (testStimParams.spatial.orientation==0)
      testStimParams.spatial.orientation=pi/2;
    else
      testStimParams.spatial.orientation=0;
    end
  end

  stimRandFreq=2; % 4Hz
  respTime=1.2-(elapsed_time-7.2)
  
  [elapsed_time,coords]=motionAdaptationTrial( adaptStimParams, 4, ...
					       isiStimParams, 1, testStimParams, 1, responseStimParams, respTime, ...
					       fixStimParams, textParams, stimRandFreq, coords, ...
					       frameStartFun, ...
					       frameStartFunArg, ...
					       frameEndFun, ...
					       frameEndArg );

end
globalEndTime=GetSecs-globalStartTime;
mglClose;
disp(['Time elapsed: ' num2str(globalEndTime)])
