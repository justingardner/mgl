function [coords,direction,lifetime]=dotMotionFrame(coords,direction,lifetime,stimParams,displayParams);
% [coords,direction,lifetime]=dotMotionFrame(coords,direction,lifetime,stimParams,displayParams);
%
%  Displaces input device coordinates coords corresponding to one motion frame
%  (single screen refresh) according to global parameters in
%  structs stimParams and displayParams and
%  pointwise parameters direction and lifetime.
%  If displayParams is not specified, will use parameters in
%  MGL variable
% 
% INPUTS:
% Per-point parameters:
%  coords:       starting (last) coordinates of points (2D) (Npoints x 2)
%  direction:    starting (last) angular direction of incoherently moving points (use [] to initialize).
%  lifetime:     remaining lifetime of points in frames at beginning of frame (use [] to initialize)
%
% Global parameters:
%  stimParams struct fields:
%  Obligatory:
%  .coherentMotionType:  one of {'expanding' 'contracting' 'translating' 'boundary' 'rotating'}
%  .incoherentMotionType:  one of {'random' 'brownian' 'movshon'}
%  .coherence:   fraction of dots moving coherently. The first (1-coherence) x Npoints will be moved incoherently.
%  .direction:   [dir1 dir2] (single argument OK)  direction of coherent motion(s)
%  .speed:       [speed1 speed2] (single argument OK) in device units/sec OR Npoints long vector 
%  .lifetime:    dot life time (Note: could make this a random variable)
%  .spatial.frequency:   only for 'boundary' motionType
%  .spatial.orientation: only for 'boundary' motionType
%  .spatial.phase:       only for 'boundary' motionType
%  .spatial.origin:      [xO yO] only for contracting, expanding, or rotating motionType
% 
%  displayParams struct fields:
%  Obligatory:
%  .screenSize:  [xSize ySize]
%  .frameRate:   Hz
%  Optional:
%  .deviceRect:  [minX minY maxX maxY]. Defaults to [-1 -1 1 1]
%
% OUTPUTS:
%  coords:       current coordinates of points (2D)
%  direction:    current direction of incoherently moving points 
%  lifetime:     remaining lifetime of points in frames at end of frame

global MGL
if (~exist('displayParams','var'))
  xrange=MGL.deviceRect(3)-MGL.deviceRect(1);
  yrange=MGL.deviceRect(4)-MGL.deviceRect(2);
  xoffs=MGL.deviceRect(1);
  yoffs=MGL.deviceRect(2);
  speed=stimParams.speed/MGL.frameRate;
elseif (isfield(displayParams,'deviceRect'))
  xrange=displayParams.deviceRect(3)-displayParams.deviceRect(1);
  yrange=displayParams.deviceRect(4)-displayParams.deviceRect(2);
  xoffs=displayParams.deviceRect(1);
  yoffs=displayParams.deviceRect(2);
  speed=stimParams.speed/displayParams.frameRate;
else
  xrange=2;
  yrange=2;
  xoffs=-1;
  yoffs=-1;
  speed=stimParams.speed;
end
if (isfield(stimParams,'annulus'))
  orad=2*stimParams.annulus(2);
  if (xrange>orad)
    xrange=orad;
    xoffs=-stimParams.annulus(2);
  end
  if (yrange>orad)
    yrange=orad;
    yoffs=-stimParams.annulus(2);
  end
end

Npoints=stimParams.nPoints;
if (isempty(coords))
  coords=[xrange*(2*rand(Npoints,1)-1) yrange*(2*rand(Npoints,1)-1)];
end
displacement=zeros(size(coords));

if (isempty(lifetime))
  lifetime=round(stimParams.lifetime*rand(Npoints,1));
end

if (isempty(direction))
  direction=2*pi*rand(Npoints,1);
end

outofrange=(coords(:,1)<xoffs | coords(:,1)>xrange | coords(:,2)<yoffs | coords(:,2)>yrange);
deadpoints=(lifetime<1 | outofrange);
Ndeadpoints=nnz(deadpoints);

if (Ndeadpoints>0)
  % reinitialize dead point coordinates
  coords(deadpoints,1)=xrange*rand(Ndeadpoints,1)+xoffs;
  coords(deadpoints,2)=yrange*rand(Ndeadpoints,1)+yoffs;
  % reinitialize dead point directions
  direction(deadpoints)=2*pi*rand(Ndeadpoints,1);
  % reinitialize dead point lifetimes
  lifetime(deadpoints)=stimParams.lifetime;

end

Nincohpoints=ceil((1-stimParams.coherence)*Npoints);
incohpoints=[1:Nincohpoints]';
cohpoints=[1+Nincohpoints:Npoints]';
Ncohpoints=length(cohpoints);
% check which type of motion
if (stimParams.coherence<1)
  % identify incoherently moving points
  % apply random motion
  switch stimParams.incoherentMotionType
    case 'random'
      % Moves every dot in current direction
      displacement(incohpoints,:)=speed.*[cos(direction(incohpoints)) sin(direction(incohpoints))];
    case 'brownian'
      % randomize direction, then displace
      if (isfield(stimParams,'brownianComponent'))
        direction(incohpoints)=direction(incohpoints)+stimParams.brownianComponent*2*pi*rand(Nincohpoints,1);
      else 
	direction(incohpoints)=2*pi*rand(Nincohpoints,1);
      end
      displacement(incohpoints,:)=speed.*[cos(direction(incohpoints)) sin(direction(incohpoints))];
    case 'movshon'
     % plonk down dots anywhere
     coords(incohpoints,:)=[xrange*rand(Nincohpoints,1)+xoffs, yrange*rand(Nincohpoints,1)+yoffs];
    otherwise 
     disp('Undefined incoherent motion type');
  end

end

if (stimParams.coherence>0)
  % apply coherent motion
  Ndirections=length(stimParams.direction);
  Npointsperdir=Ncohpoints/Ndirections;
  switch stimParams.coherentMotionType
   case 'expanding'
    % add outward displacement scaled by position from origin
    % Need to figure out how to keep dot density constant.
    displacement(cohpoints,:)=speed*...
	(coords(cohpoints,:)-repmat(stimParams.spatial.origin,Ncohpoints,1));
   case 'contracting'
    % add inward displacement scaled by position from origin
    displacement(cohpoints,:)=-speed*...
	(coords(cohpoints,:)-repmat(stimParams.spatial.origin,Ncohpoints,1));
   case 'translating'
    % add direction*speed to coherent points
    % if multiple directions, add each direction to corresponding fraction of dots     
    for n=1:Ndirections
      d=stimParams.direction(n);
      currcohpoints=cohpoints(1+floor((n-1)*Npointsperdir):floor(n*Npointsperdir));
      displacement(currcohpoints,:)=repmat(speed.*[cos(d) sin(d)],length(currcohpoints),1);
    end
   case 'boundary'
    % compute sine of points 
    % displace points with negative values with direction 1,
    % points with positive values with direction 2
    % compute sine of displaced points; reinitialize points with
    % changed value (boundary crossers)
    % boundary orientation is ccw; we change it for cw rotation
    boundaryOrient=2*pi-(stimParams.spatial.orientation-pi/2); 
    costheta=cos(boundaryOrient);
    sintheta=sin(boundaryOrient);
    pointsx=costheta*coords(cohpoints,1)-sintheta*coords(cohpoints,2);
    whichdir=1+(sin(pointsx*stimParams.spatial.frequency*2*pi+ ...
		    stimParams.spatial.phase)>0);
    displacement(cohpoints,1)=speed.* ...
	cos(stimParams.direction(whichdir))';    
    displacement(cohpoints,2)=speed.* ...
	sin(stimParams.direction(whichdir))';
    newcoords=coords(cohpoints,:)+displacement(cohpoints,:);
    pointsnewx=costheta*newcoords(:,1)-sintheta*newcoords(:,2); 
    whichdirnew=1+(sin(pointsnewx*stimParams.spatial.frequency*2*pi+ ...
		       stimParams.spatial.phase)>0);
    crossingpoints=(whichdir~=whichdirnew);
    Ncrossingpoints=nnz(crossingpoints);
    if  (Ncrossingpoints>0)      
      % move points to random locations on other side of strip:
      % calculate strip width 
      stripwidth=1/stimParams.spatial.frequency/2;
      % calculate movement across strip
      % move in cardinal direction that is most orthogonal to grating:
      % if stimulus is closer to horizontal, move in orthogonal
      % direction
      % equivalent to choosing smallest movement.
      hAng=pi-stimParams.spatial.orientation;
      vAng=stimParams.spatial.orientation-pi/2;      
      if (hAng>0)
	dispx=stripwidth/sin(hAng);
      else
	dispx=stripwidth;;
      end
      if (vAng>0)
	dispy=stripwidth/sin(vAng);
      else
	dispy=stripwidth;
      end
      if (dispx<=dispy)
	stripdisp=[dispx 0];
      else
	stripdisp=[0 dispy];
      end
      % move points in opposite direction of their movement by this displacement
      moveforward=(crossingpoints & whichdir==1);
      moveback=(crossingpoints & whichdir==2);
      pointsforward=cohpoints(moveforward);
      pointsback=cohpoints(moveback);
      % figure out which direction to move by choosing the smaller vector
      disp1=[cos(stimParams.direction(1)) sin(stimParams.direction(1))];
      disp2=[cos(stimParams.direction(2)) sin(stimParams.direction(2))];
      if (norm(disp1+stripdisp)<norm(disp1-stripdisp))
	forwardsign=1;
      else
	forwardsign=-1;
      end
      if (norm(disp2+stripdisp)<norm(disp2-stripdisp))
	backwardsign=1;
      else
	backwardsign=-1;
      end
      displacement(pointsforward,:)=displacement(pointsforward,:)+ ...
	  repmat(forwardsign*stripdisp,length(pointsforward),1);      
      displacement(pointsback,:)=displacement(pointsback,:)+ ...
	  repmat(backwardsign*stripdisp,length(pointsback),1);
      % calculate orthogonal movement:
%      disporth=[stripdisp(2) -stripdisp(1)];
 %     disporth=disporth./norm(disporth);
%      disporthforward=(2*rand(size(pointsforward))-1)*repmat(disporth,length(pointsforward),1);
%      disporthback=(2*rand(size(pointsback))-1)*repmat(disporth,length(pointsback),1);
      
      
      
    end
   case 'rotating'
    
   otherwise 
    disp('Undefined coherent motion type');
  end
  
  
end

% add displacement and update lifetime
coords=coords+displacement;
lifetime=lifetime-1;

% reinitialize dots beyond device rect


return

