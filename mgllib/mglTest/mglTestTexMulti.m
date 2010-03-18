% mglTestTexMulti.m
%
%        $Id: mglTestTexMulti.m 380 2008-12-31 04:39:55Z justin $
%      usage: mglTestTexMulti(screenNum)
%         by: justin gardner
%       date: 04/11/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: 
%
function retval = mglTestTexMulti(screenNumber)

% check arguments
if ~any(nargin == [0 1])
  help textest
  return
end
if exist('screenNumber')~=1,screenNumber = [];,end

% use mgl
mgl = 1;
% display multiple gratings at once
multi = 1;

% set up mgl window
if mgl
  mglOpen(screenNumber);
  mglClearScreen;
  mglScreenCoordinates;
  frameRate = mglGetParam('frameRate');
else
  myscreen = initscreen;
  frameRate = 60;
end


% size of textures in pixels
if multi
  xsize = 128;%mglGetParam('screenWidth');
  ysize = 128;%mglGetParam('screenHeight');
else
  xsize = 1024;
  ysize = 512;
end
numtexs = 1;

% get x and y
x = -2:4/(xsize-1):2;
y = -2:4/(ysize-1):2;

% turn into grid
[xMesh,yMesh] = meshgrid(x,y);

nsteps = 30;
%disppercent(-inf,'Creating gratings');
for i = 1:nsteps;
  %disppercent(i/nsteps);
  phase = i*2*pi/nsteps;
  angle = d2r(45);
  f=0.8*2*pi; 
  a=cos(angle)*f;
  b=sin(angle)*f;
  % compute grating
  m = sin(a*xMesh+b*yMesh+phase);
  m = round(255*(m+1)/2);
  if mgl
    tex(i) = mglCreateTexture(m);
  else
    tex(i) = Screen('MakeTexture', myscreen.screenNumber,m);
  end
end
%disppercent(inf);

% run through once
for i = 1:nsteps
  if mgl
    mglBltTexture(tex(i),[0 0]);
    mglFlush;
  else
    disprect = SetRect(0,0,xsize,ysize);
    Screen('DrawTexture', myscreen.w,tex(i),[],disprect);
  end
end

numsec = 5;
if multi==0
  starttime = mglGetSecs;
  for i = 1:frameRate*numsec
    if mgl
      mglBltTexture(tex(mod(i,nsteps)+1),[0 0]);
    else
      Screen('DrawTexture', myscreen.w,tex(mod(i,nsteps)+1),[],SetRect(0,0,0+xsize-1,0+ysize-1));
    end
    if mgl,mglFlush,else,Screen('flip',myscreen.w);,end
  end
  endtime = mglGetSecs;
else
  starttime = mglGetSecs;
  for i = 1:frameRate*numsec
    for j = 0:2.2:6.6
      for k = 0:2.2:4.4
	top = [round(j*xsize) round(k*ysize)];
	if j==k
	  thisPhase = mod(i,nsteps)+1;
	else
	  thisPhase = nsteps-mod(i,nsteps);
	end
	if mgl
	  mglBltTexture(tex(thisPhase),top,-1,-1);
	  mglBltTexture(tex(thisPhase),[top]+[round(xsize*1.1) 0],-1,-1);
	  mglBltTexture(tex(thisPhase),top+[round(xsize*1.1) round(ysize*1.1)],-1,-1);
	  mglBltTexture(tex(thisPhase),top+[0 round(ysize*1.1)],-1,-1);    
	else
	  Screen('DrawTexture', myscreen.w,tex(thisPhase),[],SetRect(top(1),top(2),top(1)+xsize-1,top(2)+ysize-1));
	  top(1) = top(1)+round(xsize*1.1);
	  Screen('DrawTexture', myscreen.w,tex(thisPhase),[],SetRect(top(1),top(2),top(1)+xsize-1,top(2)+ysize-1));
	  top(2) = top(2)+round(ysize*1.1);
	  Screen('DrawTexture', myscreen.w,tex(thisPhase),[],SetRect(top(1),top(2),top(1)+xsize-1,top(2)+ysize-1));
	  top(1) = top(1)-round(xsize*1.1);
	  Screen('DrawTexture', myscreen.w,tex(thisPhase),[],SetRect(top(1),top(2),top(1)+xsize-1,top(2)+ysize-1));
	end
      end
    end
    if mgl,mglFlush,else,Screen('flip',myscreen.w);,end
  end
  endtime = mglGetSecs;
end  

% check how long it ran for
disp(sprintf('Ran for: %0.8f sec Intended: %0.8f sec',endtime-starttime,numsec));
disp(sprintf('Difference from intended: %0.8f ms',1000*((endtime-starttime)-numsec)));
disp(sprintf('Number of frames lost: %i/%i (%0.2f%%)',round(((endtime-starttime)-numsec)*frameRate),numsec*frameRate,100*(((endtime-starttime)-numsec)*frameRate)/(frameRate*numsec)));


if mgl
  mglClose;
else
  Screen('closeall');
end

function r=d2r(d)
r=d/180*pi;
