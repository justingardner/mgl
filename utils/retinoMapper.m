% 2x single wedge
% 2x double wedge
% 2x static merids
% 2x exp rings
clear all;
screenSize=[43.2 43.2*6/8]./100;
screenDist=1.5;
c=computer;
if (strcmp(c(1:3),'GLN'))
  mglOpenDisplay('displayNumber',-1,'nosplash',1);
elseif (strcmp(c(1:3),'MAC'))
  mglOpenDisplay('nosplash',1);
else
  disp('Unsupported system.');
end
mglVisualAngleCoordinates(screenDist,screenSize);

DC=0.8;
TR=1.6; %1.5
stimDuration=TR;
nCycles=10;
nMeridians=1;
startAngle=0; % change for ccw stim
cyclePeriod=16*TR;%24;
nStepsPerCycle=cyclePeriod/TR;
stepAngle=360/nStepsPerCycle;
stimType='w'; % 'w'  'r' 'm'

wedgeRadialCoords=3;
wedgePolarCoords=startAngle;
wedgeRadialWidths=6;
wedgePolarWidths=stepAngle;%21;
minEccentricity=0;
maxEccentricity=6;
wrapEccentricity=[0 6];
checkSizes=[0.5 7.5];
slidingSpeed=0.10;

switch (stimType)
  case 'm'
  % meridians
  stepAngle=90;
  nMeridians=2;
  mess='HM vs VM';
  stimDuration=[nStepsPerCycle/2*stimDuration 1 nStepsPerCycle/2]; 
 case 'w'
  mess='cw wedge';  
 case 'r'
  mess='exp ring';  
  wedgePolarWidths=360;
  wedgeRadialCoords=minEccentricity;
  stepAngle=maxEccentricity/nStepsPerCycle
  wedgeRadialWidths=3*stepAngle;
  checkSizes=[0.5 15];
end
if (nMeridians==2)
  wedgeRadialCoords=repmat(3,2,1);
  wedgePolarCoords=startAngle+[0 180];
  checkSizes=repmat([0.5 7.5],2,1);
end


tSummed=0;
disp('READY! WAITING FOR START KEY...')
mglClearScreen([0.5 0.5 0.5]);
mglStrokeText(mess,3,0,-0.5,0.5,2);
mglFlush;
pause
t0=GetSecs;

switch (stimType)
  case 'm'
  % first half cycle
  tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				     wedgeRadialCoords, wedgePolarCoords, ...
				     wedgeRadialWidths, wedgePolarWidths, ...
				     minEccentricity, maxEccentricity, wrapEccentricity, checkSizes,...
				     [],[],slidingSpeed);
  wedgePolarCoords=wedgePolarCoords+stepAngle;
  for nCyc=1:nCycles*2
    tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				       wedgeRadialCoords, wedgePolarCoords, ...
				       wedgeRadialWidths, wedgePolarWidths, ...
				       minEccentricity, maxEccentricity, wrapEccentricity, checkSizes,...
				       [],[],slidingSpeed);
    wedgePolarCoords=wedgePolarCoords+stepAngle;
  end
 case 'w'
  % first half cycle
  for nStep=1:nStepsPerCycle/2
    tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				       wedgeRadialCoords, wedgePolarCoords, ...
				       wedgeRadialWidths, wedgePolarWidths, ...
				       minEccentricity, maxEccentricity, wrapEccentricity, checkSizes,...
				       [],[],slidingSpeed);
    wedgePolarCoords=wedgePolarCoords+stepAngle;
  end  
  for nCyc=1:nCycles
    for nStep=1:nStepsPerCycle
      tSummed=tSummed+drawSlidingWedges( stimDuration, ...
					 wedgeRadialCoords, wedgePolarCoords, ...
					 wedgeRadialWidths, wedgePolarWidths, ...
					 minEccentricity, maxEccentricity, wrapEccentricity, checkSizes,...
					 [],[],slidingSpeed);
      wedgePolarCoords=wedgePolarCoords+stepAngle;
    end
  end
 case 'r'
  % first half cycle
  for nStep=1:nStepsPerCycle/2
    tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				       wedgeRadialCoords, wedgePolarCoords, ...
				       wedgeRadialWidths, wedgePolarWidths, ...
				       minEccentricity, maxEccentricity, wrapEccentricity, checkSizes,...
				       [],[],slidingSpeed);
    wedgeRadialCoords=wedgeRadialCoords+stepAngle;
    if (wedgeRadialCoords>maxEccentricity)
      wedgeRadialCoords=wedgeRadialCoords-maxEccentricity
    end
  end  
  for nCyc=1:nCycles
    for nStep=1:nStepsPerCycle
      tSummed=tSummed+drawSlidingWedges( stimDuration, ...
					 wedgeRadialCoords, wedgePolarCoords, ...
					 wedgeRadialWidths, wedgePolarWidths, ...
					 minEccentricity, maxEccentricity, wrapEccentricity, checkSizes,...
					 [],[],slidingSpeed);
      wedgeRadialCoords=wedgeRadialCoords+stepAngle;
      if (wedgeRadialCoords>maxEccentricity)
	wedgeRadialCoords=wedgeRadialCoords-maxEccentricity;
      end
    end
  end
end

tTotal=GetSecs-t0;
pause(1)
mglClose;
tSummed
tTotal
