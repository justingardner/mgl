screenSize=[43.2 43.2*6/8]./100;
screenDist=1.5;
debug=0;
if (debug)
  mglOpenDisplay('displayNumber',0,'nosplash',1);
else
  mglOpenDisplay('nosplash',1);
end
mglVisualAngleCoordinates(screenDist,screenSize);

DC=0.7;
blockLength=12; % seconds - 8 TR's
TR=1.5;
stimDuration=[blockLength DC blockLength/TR];
nCycles=10;

uM.wedgeRadialCoords=3;
uM.wedgePolarCoords=90;
uM.wedgeRadialWidths=6;
uM.wedgePolarWidths=30;
uM.minEccentricity=0.3;
uM.maxEccentricity=6;
uM.wrapEccentricity=[0 6];
uM.checkSizes=[0.5 7.5];
uM.slidingSpeed=0.05;

auM.wedgeRadialCoords=3;
auM.wedgePolarCoords=270;
auM.wedgeRadialWidths=6;
auM.wedgePolarWidths=330;
auM.minEccentricity=0.3;
auM.maxEccentricity=6;
auM.wrapEccentricity=[0 6];
auM.checkSizes=[0.5 7.5];
auM.slidingSpeed=0.15;

tSummed=0;
disp('READY! WAITING FOR BACKTICK...DON''T PRESS ANY KEY')
mglClearScreen([0.5 0.5 0.5]);
mglStrokeText('GET READY',2,0,-0.5,0.5,2);
mglFlush;
pause
t0=GetSecs;

tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				   auM.wedgeRadialCoords, auM.wedgePolarCoords, ...
				   auM.wedgeRadialWidths, auM.wedgePolarWidths, ...
				   auM.minEccentricity, auM.maxEccentricity, auM.wrapEccentricity, auM.checkSizes,...
				   [],[],auM.slidingSpeed);
for n=1:nCycles
  tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				     uM.wedgeRadialCoords, uM.wedgePolarCoords, ...
				     uM.wedgeRadialWidths, uM.wedgePolarWidths, ...
				     uM.minEccentricity, uM.maxEccentricity, uM.wrapEccentricity, uM.checkSizes,...
				     [],[],uM.slidingSpeed);
  
  tSummed=tSummed+drawSlidingWedges( stimDuration, ...
				     auM.wedgeRadialCoords, auM.wedgePolarCoords, ...
				     auM.wedgeRadialWidths, auM.wedgePolarWidths, ...
				     auM.minEccentricity, auM.maxEccentricity, auM.wrapEccentricity, auM.checkSizes,...
				     [],[],auM.slidingSpeed);
end
tTotal=GetSecs-t0;
pause(1)
mglClose;
tSummed
tTotal
