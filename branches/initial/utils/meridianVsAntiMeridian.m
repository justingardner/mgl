screenSize=[43.2 43.2*6/8]./100;
screenDist=1.5;
debug=0;
if (debug)
  mglOpenDisplay('displayNumber',0,'nosplash',1);
else
  mglOpenDisplay('nosplash',1);
end
mglVisualAngleCoordinates(screenDist,screenSize);

DC=0.8;
blockLength=12; % seconds - 8 TR's
TR=1.5;
stimDuration=[blockLength DC blockLength/TR];
nCycles=10;
nAntiMeridians=0;
if (~exist('polarOffset','var'))
  polarOffset=0; % for upper vertical meridian
%polarOffset=90; % for horizontal meridian
end

uM.wedgeRadialCoords=3;
uM.wedgePolarCoords=90+polarOffset;
uM.wedgeRadialWidths=6;
uM.wedgePolarWidths=21;
uM.minEccentricity=0.3;
uM.maxEccentricity=6;
uM.wrapEccentricity=[0 6];
uM.checkSizes=[0.5 7];
uM.slidingSpeed=0.10;
uM.stimDuration=stimDuration;

if (nAntiMeridians==3)
  mess='UVM vs LVM + HM';
  auM.wedgeRadialCoords=repmat(3,3,1);
  auM.wedgePolarCoords=[180 270 0]+polarOffset;
  auM.wedgeRadialWidths=6;
  auM.wedgePolarWidths=21;
  auM.minEccentricity=0.3;
  auM.maxEccentricity=6;
  auM.wrapEccentricity=[0 6];
  auM.checkSizes=repmat([0.5 7],3,1);
  auM.slidingSpeed=0.10;
  auM.stimDuration=stimDuration;
elseif (nAntiMeridians==0)
  mess='UVM vs blank';
  auM=uM;
  auM.stimDuration(2)=0;
  if (polarOffset==90)
    mess='HM vs blank';
    uM.wedgeRadialCoords=[3;3];
    uM.wedgePolarCoords=[0;180];
    uM.checkSizes=repmat([0.5 7],2,1);
  end
elseif (nAntiMeridians==1)
  mess='UVM vs LVM';
  auM.wedgeRadialCoords=3;
  auM.wedgePolarCoords=270+polarOffset;
  auM.wedgeRadialWidths=6;
  auM.wedgePolarWidths=21;
  auM.minEccentricity=0.3;
  auM.maxEccentricity=6;
  auM.wrapEccentricity=[0 6];
  auM.checkSizes=[0.5 7];
  auM.slidingSpeed=0.1;
  auM.stimDuration=stimDuration;
end

tSummed=0;
disp(mess)
disp('READY! WAITING FOR BACKTICK...DON''T PRESS ANY KEY')
mglClearScreen([0.5 0.5 0.5]);
mglStrokeText(mess,3,0,-0.5,0.5,2);
mglFlush;
pause
t0=GetSecs;

tSummed=tSummed+drawSlidingWedges( auM.stimDuration, ...
				   auM.wedgeRadialCoords, auM.wedgePolarCoords, ...
				   auM.wedgeRadialWidths, auM.wedgePolarWidths, ...
				   auM.minEccentricity, auM.maxEccentricity, auM.wrapEccentricity, auM.checkSizes,...
				   [],[],auM.slidingSpeed);
for n=1:nCycles
  tSummed=tSummed+drawSlidingWedges( uM.stimDuration, ...
				     uM.wedgeRadialCoords, uM.wedgePolarCoords, ...
				     uM.wedgeRadialWidths, uM.wedgePolarWidths, ...
				     uM.minEccentricity, uM.maxEccentricity, uM.wrapEccentricity, uM.checkSizes,...
				     [],[],uM.slidingSpeed);
  
  tSummed=tSummed+drawSlidingWedges( auM.stimDuration, ...
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
