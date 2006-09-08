% Initialize
debug=1; % draws in window

% Display parameters for scanner LCD 
screenDist=1.5; 
screenSize=[43.2 43.2*6/8]./100; 

% Stimulus parameters: spatial
bgCol=[0.5 0.5 0.5];
maxEcc=6;
nPolygons=10;
% coordinates of polygon corners in radial dimension from centre of
% gaze. 6 deg near upper/lower edge of display
polygonRadialWidth=maxEcc/nPolygons;
polygonPolarWidth=5/180*pi; % 5 degrees
polygonRadialCoords=0:polygonRadialWidth:maxEcc;
nWedges=2*pi/polygonPolarWidth; % this may be modified to allow overlap
wedgeThetas=linspace(0,2*pi-polygonPolarWidth,nWedges);

% Stimulus parameters: temporal
radialShiftPerFrame=0.2; % degrees random shift per frame
wedgeRadialShift=(rand(nWedges,1)-0.5)*radialShiftPerFrame;
nStimCycles=10;
firstHalfCycle=1;
timePerCycle=24;

% On every cycle, display fixed sequence of stimuli
stimulusSequencePerCycle=[1 2]; % block alternation between two stimuli
%stimulusSequencePerCycle=[1:12]; % e.g. for phase encoded mapping

stimulusSequence=repmat(stimulusSequencePerCycle,1,nStimCycles);
if (firstHalfCycle)
  halfcycle=ceil(length(stimulusSequencePerCycle)/2);
  stimulusSequence=[stimulusSequencePerCycle(halfcycle:end) ...
		    stimulusSequence];
end

% Each stimulus is defined by a sequence of component indexes and
% type (wedge or ring)
stimulusComponentIndexes{1}=;
stimulusComponentTypes{1}='w';

% Each stimulus is shown for a fixed time (multiple of TR)
stimulusDuration=1.5;
% with a duty cycle (default 1) between ON and OFF (blank screen)
stimulusDutyCycle=1.0; % stimulus is on for full stimulus duration
% Total time per cycle is given by the number of stimuli per cycle


% open display
mglOpenDisplay('displayNumber',1-debug,'nosplash',1); %
mglVisualAngleCoordinates(screenDist,screenSize)

% wait for backtick. only tricky part
%pause

% loop:
nFrames=nWedges;
drawUpperMeridian=1;
drawAntiUpperMeridian=0;
drawNothing=0;

%  
%
%
%
%

for nc=firstCycle:nStimCycles % stimulus cycles (1 revolution)
% note: first (zero) cycle is optional and may be less than a 
% full cycle


for ns=stimuli % fix me
  
  % draw polygons
  mglClearScreen(bgCol);
  if (drawUpperMeridian) 
    wedges=nf:nf+10; % vector of wedge indices
  elseif (drawAntiUpperMeridian)
    %..
  elseif (drawNothing)
    % do nothing
  end
  if (~drawNothing)
    for nw=wedges
      % for each wedge: 
      % add random displacement, clamping inner and outer radius to 0 and maxEcc
      wedgeRadialShift(nw)=wedgeRadialShift(nw)+(rand-0.5)* ...
	  radialShiftPerFrame;
      if (wedgeRadialShift(nw)>polygonRadialWidth)
	wedgeRadialShift(nw)=wedgeRadialShift(nw)- ...
	    polygonRadialWidth;	
      elseif (wedgeRadialShift(nw)<-polygonRadialWidth)
	wedgeRadialShift(nw)=wedgeRadialShift(nw)-+ ...
	    polygonRadialWidth;
      end
      % calculate polygon polar coordinates
      radius=polygonRadialCoords+wedgeRadialShift(nw);
      radius(radius<0)=0;
      radius(1)=0;
      radius(radius>maxEcc)=maxEcc;
      radius(end)=maxEcc;
      theta=wedgeThetas(nw)*ones(size(radius));
      % calculate cartesian coordinates
      [ccwX,ccwY]=pol2cart(theta-polygonPolarWidth/2,radius);
      [cwX,cwY]=pol2cart(theta+polygonPolarWidth/2,radius);
      % draw each radial polygon in alternating colours
      for np=1:nPolygons
	currcol=ones(1,3)*xor(mod(np,2)>0,mod(nw,2)>0);
	v0=[ccwX(np) ccwY(np)];
	v1=[ccwX(np+1) ccwY(np+1)];
	v2=[cwX(np+1) cwY(np+1)];
	v3=[cwX(np) cwY(np)];
	mglQuad(v0,v1,v2,v3,currcol);
      end
    end
  end
  
  % flush
  mglFlush;
pause(0.01)
end

end % nCycles

mglClose;
