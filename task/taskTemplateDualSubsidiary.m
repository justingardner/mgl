function [task myscreen] = taskTemplateDualSubsidiary(myscreen)
% This is an example of an RSVP task at fixation
% I've taken out the parts where I keep track of 
% correct and incorrect responses, for the sake of 
% keeping the code simple.
%
% In this task, subjects must press a key
% when they see an 'X'


% show RSVP letters at 4 Hz
displayTime = 0.15*ones(1,16*4);
blinkTime = 0.10*ones(1,16*4);
combo = [displayTime; blinkTime];
segments = combo(:)';

task{1}.seglen = [inf segments]; % show letters at 4 Hz for 16 seconds
task{1}.getResponse = [0 ones(size(segments))];


% initialize the task
[task{1} myscreen] = initTask(task{1},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);


% But don't have a main loop, since this is just a subsidiary task
% which will be called by the main task

% **************SEGMENT CALLBACK:******************************
function [task myscreen] = startSegmentCallback(task, myscreen)
global stimulus;

if task.thistrial.thisseg == 1
% this segment just does the calculations, and then waits

  % set the randomization of letters:  
  temp = randperm(16)*4*2;
  stimulus.FIXshowXseg(:,end+1) = sort(temp(1:stimulus.FIXnumXs)); % choose which segments will show an X
  stimulus.FIXdisplaySet = ceil(rand(16*4,1)*8);            % divide the remaining segments among the other 8 characters
  stimulus.FIXshowNset = find(stimulus.FIXdisplaySet==1)*2; % multiply by 2 because have to skip the blanks (and the first segment)
  stimulus.FIXshowYset = find(stimulus.FIXdisplaySet==2)*2;
  stimulus.FIXshowZset = find(stimulus.FIXdisplaySet==3)*2;
  stimulus.FIXshowKset = find(stimulus.FIXdisplaySet==4)*2;
  stimulus.FIXshowAset = find(stimulus.FIXdisplaySet==5)*2;
  stimulus.FIXshowRset = find(stimulus.FIXdisplaySet==6)*2;
  stimulus.FIXshowSset = find(stimulus.FIXdisplaySet==7)*2;
  stimulus.FIXshowVset = find(stimulus.FIXdisplaySet==8)*2;

end

% **************************IN GET RESPONSE CALLBACK**********************************
function [task myscreen] = responseCallback(task, myscreen)
global stimulus;
% to keep things simple, I'm leaving this out

% ********************************screen update callback  ******************************

function [task myscreen] = screenUpdateCallback(task, myscreen)
global stimulus

% at every screen refresh, check the flags:
if stimulus.startSubsidiary == 1  % If the main task has set the start flag to 1
  stimulus.startSubsidiary = 0;   % reset it to 0
  task = jumpSegment(task);       % and start the subsidiary task by jumping to the next segment
end

if stimulus.endSubsidiary == 1      % if the main task has set the end flag to 1
  stimulus.endSubsidiary =0;        % reset it to 0
  task = jumpSegment(task,inf);   % and end the subsidiary task by jumping to the first segment of the next trial
end

if task.thistrial.thisseg>1       % once the task has started, clear the fixation area
  mglFillOval(0,0,[1 1],[0.5 0.5 0.5]); % instead of mglClearScreen
end

% once the task has started, start showing the letters
if any(task.thistrial.thisseg == stimulus.FIXshowXseg(:,end))
  mglBltTexture(stimulus.FIXletter{1},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowNset)
  mglBltTexture(stimulus.FIXletter{2},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowYset)
  mglBltTexture(stimulus.FIXletter{3},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowZset)
  mglBltTexture(stimulus.FIXletter{4},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowKset)
  mglBltTexture(stimulus.FIXletter{5},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowAset)
  mglBltTexture(stimulus.FIXletter{6},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowRset)
  mglBltTexture(stimulus.FIXletter{7},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowSset)
  mglBltTexture(stimulus.FIXletter{8},[0 0]);
elseif any(task.thistrial.thisseg == stimulus.FIXshowVset)
  mglBltTexture(stimulus.FIXletter{9},[0 0]);
end
