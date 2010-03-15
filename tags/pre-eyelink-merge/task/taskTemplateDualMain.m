function myscreen = taskTemplateDualMain
% function myscreen = taskTemplateDualMain
%
% 2007May04 SO
% Sample code to show how to run dual tasks
% The main task is just two stimuli shown with a variable
% delay in between. The subject will discriminate orientation.
% The subsidiary task is an RSVP task at fixation


% initalize the screen
myscreen = initScreen;

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);
myInitStimulus 

% Task will just show a stimulus at a set of contrasts
task{1}{1}.segmin =      [0.2 1 0.2 1 2];
task{1}{1}.segmax =      [0.2 3 0.2 1 2];
task{1}{1}.getResponse = [0.0 0 0.0 1 0];
task{1}{1}.numTrials = 5;
task{1}{1}.randVars.uniform.or1 = 1:180;
task{1}{1}.randVars.uniform.deltaOR = [-5 5]; % second orientation is + or - 5 degrees

% initialize the task
[task{1}{1} myscreen] = initTask(task{1}{1},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);

% set the subsidiary task
[task{2} myscreen] = taskTemplateDualSubsidiary(myscreen);

%%%%%%%%%%%%%%%%%%%%%
% Main display loop %
%%%%%%%%%%%%%%%%%%%%%
phaseNum = 1;
while (phaseNum <= length(task{1})) && ~myscreen.userHitEsc
  % update both tasks
  [task{1} myscreen phaseNum] = updateTask(task{1},myscreen,phaseNum);
  [task{2} myscreen] = updateTask(task{2},myscreen,1);
  % flip screen
  myscreen = tickScreen(myscreen,task);
end

% if we got here, we are at the end of the experiment
myscreen = endTask(myscreen,task);



                 % **********************  SUBFUNCTIONS *************************** %

                 %                   START SEGMENT CALLBACK                         %
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                 %     function that gets called at the start of each segment       %
                 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		 
function [task myscreen] = startSegmentCallback(task, myscreen)

global stimulus;

if task.thistrial.thisseg == 1 % Show first stimulus; set the orientation
  stimulus.OR1 = task.thistrial.or1;
  
elseif task.thistrial.thisseg == 2 % variable delay
  
  stimulus.startSubsidiary = 1;% START THE SUBSIDIARY TASK
  
elseif task.thistrial.thisseg == 3 % show second stimulus; set the orientation
  
  stimulus.OR2 = task.thistrial.or1 + task.thistrial.deltaOR;
  stimulus.endSubsidiary = 1;   % END THE SUBSIDIARY TASK
  
end 


                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   %     function that gets called to draw the stimulus each frame    %
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)
global stimulus

mglClearScreen(0.5);

if task.thistrial.thisseg == 1 % show first stimulus
  
  mglBltTexture(stimulus.texture,[0 0],0,0,stimulus.OR1);  
  mglFixationCross(0.2,8,[0 0 0],[0 0]);  
  mglFixationCross(0.2,2,[1 1 1],[0 0]);
  
elseif task.thistrial.thisseg == 3 % show second stimulus

  mglBltTexture(stimulus.texture,[0 0],0,0,stimulus.OR2);
  mglFixationCross(0.2,8,[0 0 0],[0 0]);  
  mglFixationCross(0.2,2,[1 1 1],[0 0]);
  
elseif task.thistrial.thisseg == 4 % cue response
  % put up a fixation cross, red to cue
  mglFixationCross(0.2,8,[1 0 0],[0 0]);  
  
elseif task.thistrial.thisseg == 5 % ITI
  % keep up the fixation cross for ITI
  mglFixationCross(0.2,8,[0 0 0],[0 0]);  
  mglFixationCross(0.2,2,[1 1 1],[0 0]);
    
end % going through segments


                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   %                function that gets subject  response              %
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task, myscreen)

global stimulus;

% make sure the response is a 1 or a 2
if(or(task.thistrial.whichButton == 1,task.thistrial.whichButton == 2))

  % see if we got a correct or incorrect answer
  if task.thistrial.whichButton == 0.1*(task.thistrial.deltaOR+15) % 1 for CCW, 2 for CW
    % play the correct sound
    mglPlaySound('Glass');
  else
    % play the incorrect sound
    mglPlaySound('Basso');
  end  

% move on to the next segment once you get a response
task = jumpsegment(task);

end


                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     %          function to make the stimulus             %
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function myInitStimulus
global stimulus

stimulus.init = 1;

stimulus.count = 0;

% make the stimulus:
% calculate an annulus envelope (annulus is in the alpha channel)
maskOut = 255*(mglMakeGaussian(6,6,3,3)>exp(-1/2));
maskIn = 255*(mglMakeGaussian(6,6,1,1)>exp(-1/2));
annulus = maskOut - maskIn;

% put a grating in the annulus
tempGrating = 100*(mglMakeGrating(6,6,2.5,0,0));
grating(:,:,1) = 128 + tempGrating;
grating(:,:,2) = grating(:,:,1);
grating(:,:,3) = grating(:,:,1);
grating(:,:,4) = annulus;
  
stimulus.texture = mglCreateTexture(grating);

clear tempGrating


   %******************************************
   % also initialize the subsidiary task stimuli
   %******************************************
stimulus.startSubsidiary= 0;
stimulus.endSubsidiary = 0;
   
% I like to put FIX in the name to differentiate them from the main task

stimulus.FIXnumXs = 8; % how many segments to display an X
stimulus.FIXshowXseg = []; % initialize, because will save a record of when X's were shown

% make the letter textures to be drawn:
mglTextSet('Geneva',18);
% geneva gothic
[discard, temp] = mglText('X');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{1} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('N');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{2} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('Y');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{3} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('Z');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{4} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('K');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{5} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('A');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{6} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('R');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{7} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('S');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{8} = mglCreateTexture(tempLetter);
clear discard tempLetter

[discard, temp] = mglText('V');
tempLetter = 128*ones(size(temp));
tempLetter(temp>0) = 0;
stimulus.FIXletter{9} = mglCreateTexture(tempLetter);
clear discard tempLetter

