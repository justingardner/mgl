% mglDispVisualAngleDiscrepancy.m
%
%        $Id:$ 
%      usage:mglDispVisualAngleDiscrepancy()
%         by: justin gardner
%       date: 03/29/10
%    purpose: Display the discrepancy between what you ask for and what you
%             get in terms of visual angle based on current settings
%             of mglVisualAngleCoordinates. Make sure to call after you
%             run mglVisualAngleCoordinates. Note that there is a discrepancy
%             because we are essentially approximating the flat screen of the
%             monitor display with a curved surface to compute visual angles.
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%mglClose;
%mglDispVisualAngleDiscrepancy;
function retval = mglDispVisualAngleDiscrepancy()

if ~isequal(mglGetParam('deviceCoords'),'visualAngle')
  disp('(mglDispVisualAngleDiscrepancy) Screen is not in visual angle coordinates');
  return
end

xPix2deg = mglGetParam('xPixelsToDevice');
yPix2deg = mglGetParam('yPixelsToDevice');
d = mglGetParam('devicePhysicalDistance');
physicalSize = mglGetParam('devicePhysicalSize');
screenWidth = mglGetParam('screenWidth');
screenHeight = mglGetParam('screenHeight');

figure;
dispMonitor1D(xPix2deg,d,physicalSize(1),screenWidth,'width',[2 2 1 2]);
dispMonitor1D(yPix2deg,d,physicalSize(2),screenHeight,'height',[2 2 3 4]);

%%%%%%%%%%%%%%%%%%%%%%%
%    dispMonitor1D    %
%%%%%%%%%%%%%%%%%%%%%%%
function [pos2deg deg2pos discrep desired] = dispMonitor1D(pix2deg,d,physicalSize,pixelSize,dimstr,sDims)

if ~isnan(sDims)
  subplot(sDims(1),sDims(2),sDims(3));
end

% compute the deg2pos scaling factor. 
pix2cm = physicalSize/pixelSize;
pos2deg = pix2deg/pix2cm;
deg2pos = 1/pos2deg;

% calculate the maximum possible visual angle achievable
thetaMax = pix2deg*pixelSize/2;

% plot actual position we would draw
desired = [];discrep = [];
for phi = -thetaMax:thetaMax/32:thetaMax
  % draw only a few points
  if any(round(phi*100) == round((-thetaMax:thetaMax/4:thetaMax)*100))
    if ~isnan(sDims)
      % this is what we want
      plot([0 d],[0 d*tan(d2r(phi))],'k.:');
      hold on
      % this is what we would draw
      plot([0 d],[0 phi*deg2pos],'r.:');
    end
  end
  
  % calculate what we actually get in terms of
  % visual angle
  a = r2d(atan(phi*deg2pos/d));

  % calculate the discrepancy between what we anted and what we displayd
  desired(end+1) = phi;
  discrep(end+1) = phi-a;
end

% just compute
if isnan(sDims),return,end

% draw circle from eye position
x = [];y= [];
for i = -90:90
  x(end+1) = d*cos(d2r(i));
  y(end+1) = d*sin(d2r(i));
end
plot(x,y,'k-');
hold on

% plot the size of the monitor
vline(d);
hline(physicalSize/2);
hline(-physicalSize/2);
plot([d d],[-physicalSize/2 physicalSize/2],'k-');

% set the axis
xaxis(0,d+3);
yaxis(-9*physicalSize/16,9*physicalSize/16);

legend('actual','desired','Location','NorthWest');
xlabel('Distance from eye to display (cm)');
ylabel('Postion on display (cm)');
title(sprintf('Display %s %0.1fcm, distance %0.1fcm, %i pixels',dimstr,physicalSize,d,pixelSize));

subplot(sDims(1),sDims(2),sDims(4));
plot(desired,discrep);
hold on
vline(0);
hline(0);
xaxis(min(desired),max(desired));

xlabel('Desired visual angle (deg)');
ylabel('Difference between desired and actual (deg)');
title(sprintf('%s: %0.1f pixels = 1 deg',dimstr,1/pix2deg));


% convert radians to degrees
%
% usage: degrees = r2d(radians);
function degrees = r2d(angle)

degrees = (angle/(2*pi))*360;

% if larger than 360 degrees then subtract
% 360 degrees
while (sum(degrees>360))
  degrees = degrees - (degrees>360)*360;
end

% if less than 360 degreees then add 
% 360 degrees
while (sum(degrees<-360))
  degrees = degrees + (degrees<-360)*360;
end

% convert degrees to radians
%
% usage: radians = d2r(degrees);
function radians = d2r(angle)

radians = (angle/360)*2*pi;
