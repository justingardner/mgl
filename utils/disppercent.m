% disppercent.m
%
%         by: justin gardner
%       date: 10/05/04
%      usage: disppercent(percentdone,message)
%    purpose: display percent done
%             Start by calling with a negative value:
%             disppercent(-inf,'Message to display');
%
%             Update by calling with percent done:
%             disppercent(0.5);
% 
%             Finish by calling with inf (elapsedTime is in seconds):
%             elapsedTime = disppercent(inf);
%
%             If you want to change the message before calling with inf:
%             disppercent(0.5,'New message to display');
% 
%             % this should print an updating disppercent
%             disppercent(-inf,'Testing disppercent');
%             for i = 1:100
%               pause(0.1);
%               disppercent(i/100);
%             end
%             disppercent(inf);
%
%             Also, if you have an inner loop within an outer loop, you
%             can call like the following:
%             n1 = 15;n2 = 10;
%             disppercent(-1/n1,'Testing disppercent'); % init with how much the outer loop increments
%             for i = 1:n1
%               for j = 1:n2
%                  pause(0.1);
%                  disppercent((i-1)/n1,j/n2);
%               end
%               disppercent(i/n1,sprintf('Made it through %i/%i iterations of outer loop',i,n1));
%             end
%             disppercent(inf);
%
%              To test call:
%
%             disppercent test
% 
%       e.g.:
%
%disppercent(-inf,'Doing stuff');for i =  1:30;pause(0.1);disppercent(i/30);end;elapsedTime = disppercent(inf);
function retval = disppercent(percentdone,mesg)

retval = nan;
% check command line arguments
if ((nargin ~= 1) && (nargin ~= 2))
  help disppercent;
  return
end

% global for disppercent
global gDisppercent;

% check for tput (system command that allows for updating text on
% terminals)
if ~isfield(gDisppercent,'hastput')
  [gDisppercent.hastput,~] = system('which tput');
  gDisppercent.hastput = ~gDisppercent.hastput;
end

% test disppercent
if (isequal(percentdone,'test'))
  testDisppercent;
  return
end


% if this is an init then remember time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (percentdone < 0)
  % global to turn off printing
  global gVerbose;
  gDisppercent.verbose = gVerbose;
  if ~gVerbose,return,end
  % set starting time
  gDisppercent.t0 = clock;
  % clear previous message and set to special startup message
  gDisppercent.mesg = '__startup__';
  % default to no message
  if (nargin < 2)
    % display message (saving cursor loc at end)
    dispNoNewline(true,'');
  else
    % display message (saving cursor loc at end)
    dispNoNewline(true,sprintf('%s: ',mesg));
  end    
  % display time 
  dispNoNewline(false,sprintf('00%%%% (00:00:00)'));
  if isinf(percentdone)
    gDisppercent.increment = 0;
  else
    gDisppercent.increment = abs(percentdone);
  end
    
% display total time at end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif (percentdone == inf)
  if ~gDisppercent.verbose,return,end
  % reprint message if necessary
  if (nargin == 2) && isstr(mesg)
    dispNoNewline(true,mesg);
  end
  % get elapsed time
  elapsedTime = etime(clock,gDisppercent.t0);
  % separate seconds and milliseconds
  numms = round(1000*(elapsedTime-floor(elapsedTime)));
  numsecs = floor(elapsedTime);
  % if over a minute then display minutes separately
  if numsecs>60
    nummin = floor(numsecs/60);
    numsecs = numsecs-nummin*60;
    % check if over an hour
    if nummin > 60
      numhours = floor(nummin/60);
      nummin = nummin-numhours*60;
      timestr = sprintf('%i hours %i min %i secs %i ms',numhours,nummin,numsecs,numms);
    else
      timestr = sprintf('%i min %i secs %i ms',nummin,numsecs,numms);
    end
  else
    timestr = sprintf('%i secs %i ms',numsecs,numms);
  end
  % display time string
  if gDisppercent.hastput
    dispNoNewline(false,sprintf('took %s\n',timestr));
  else
    fprintf(sprintf('took %s\n',timestr));
  end
  retval = elapsedTime;
% otherwise show update
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
  if ~gDisppercent.verbose,return,end
  
  % keep track of what increments percent done is being called in
  if (gDisppercent.increment == 0) & (percentdone > 0)
    gDisppercent.increment = percentdone;
  end
  % a negative value on percent done, simply means
  % how much each increment of percent done is.
  if percentdone < 0
    gDisppercent.increment = -percentdone;
    percentdone = 0;
  end
  % see if we should reprint message
  newmesg = '';
  if nargin == 2
    if isstr(mesg)
      newmesg = sprintf('%s: ',mesg);
      % otherwise if the second argument is a number,
      % it means we have a secondary value for percent done
      % i.e. the first number is the large increments and
      % the second number is what percentage of the large
      % increments has been done (useful for when you are
      % doing loops within loops).
    elseif isscalar(mesg)
      % make percent done into value computed by summing
      % percentdone with the increment passed in mesg.
      percentdone = percentdone + gDisppercent.increment*mesg;
    end
  end
      
  % avoid things that will end up dividing by 0
  if (percentdone >= 1)
    percentdone = .99;
  elseif (percentdone <= 0)
    percentdone = 0.01;
  end

  % display percent done and estimated time to end
  if ~isempty(newmesg)
    % always display if there is a new message
    dispNoNewline(true,newmesg);
    dispNoNewline(false,sprintf('%02i%%%% (%s)',floor(100*percentdone),disptime(etime(clock,gDisppercent.t0)*(1/percentdone - 1))));
  % display only if we have update by a percent or more
  elseif (gDisppercent.percentdone ~= floor(100*percentdone))
    dispNoNewline(false,sprintf('%02i%%%% (%s)',floor(100*percentdone),disptime(etime(clock,gDisppercent.t0)*(1/percentdone - 1))));
  end
end
% remember current percent done
gDisppercent.percentdone = floor(100*percentdone);


%%%%%%%%%%%%%%%%%%
%%   disptime   %%
%%%%%%%%%%%%%%%%%%
function retval = disptime(t)

hours = floor(t/(60*60));
minutes = floor((t-hours*60*60)/60);
seconds = floor(t-hours*60*60-minutes*60);

retval = sprintf('%02i:%02i:%02i',hours,minutes,seconds);

%%%%%%%%%%%%%%%%%%%%%%%%%
% Display w/out newline
%%%%%%%%%%%%%%%%%%%%%%%%%
function dispNoNewline(saveCursorLoc,str)

% get global
global gDisppercent;

% For systems without tput, just display the initial message
% and increment with a .
if ~gDisppercent.hastput
  if saveCursorLoc & isequal(gDisppercent.mesg,'__startup__')
    fprintf(str);
    gDisppercent.mesg = str;
  else
    fprintf('.');
  end
  return
end


if ~saveCursorLoc
  if gDisppercent.hastput
    % restore the cursor loc to overwrite what was written
    system('tput rc');
  end
else
  % move to the beginning of old message   
  if ~isequal(gDisppercent.mesg,'__startup__')
    if gDisppercent.hastput
      system('tput rc');
      system(sprintf('tput cub %i',length(gDisppercent.mesg)));
    end
  end
end

% print the string w/out the backspace
fprintf(str);

if saveCursorLoc
  if gDisppercent.hastput
    % save the cursor loc after printing
    system('tput sc');
  end
  % save the message
  gDisppercent.mesg = str;
end

%%%%%%%%%%%%%%%%%%%%%%%%%
% Display w/out newline
%%%%%%%%%%%%%%%%%%%%%%%%%
function testDisppercent
      
disppercent(-inf,'Testing disppercent');
for i = 1:100
  pause(0.001);
  disppercent(i/100);
end
disppercent(inf);

n1 = 15;n2 = 10;
disppercent(-1/n1,"Testing dual loop"); % init with how much the outer loop increments
for i = 1:n1
  for j = 1:n2
    pause(0.001);
    disppercent((i-1)/n1,j/n2);
  end
  disppercent(i/n1,sprintf('Made it through %i/%i iterations of outer loop',i,n1));
end
disppercent(inf);

