function myscreen = taskTemplateContrast10bit
% function myscreen = sampleContrast10bit
%
% 2007May04 SO
% sample code to show how to reserve colors and reset the gamma table
% so as to show fine contrast levels

% initalize the screen
myscreen = initScreen;

% init the stimulus
global stimulus;
myscreen = initStimulus('stimulus',myscreen);
myInitStimulus 

% Task will just show a stimulus at a set of contrasts

task{1}.seglen = [1 0.5 1]; % have the fixation point change color
task{1}.numTrials = length(stimulus.contrasts);


% initialize the task
for phaseNum = 1:length(task{1})
  task{1} = initTask(task{1},myscreen,@startSegmentCallback,@screenUpdateCallback,@responseCallback);
end


%%%%%%%%%%%%%%%%%%%%%
% Main display loop %
%%%%%%%%%%%%%%%%%%%%%

phaseNum = 1;
while (phaseNum <= length(task)) && ~myscreen.userHitEsc
  % update the task
  [task myscreen phaseNum] = updateTask(task,myscreen,phaseNum);
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

% I will display the stimuli in the screenUpdate callback, but set the 
% parameters in this callback

if task.thistrial.thisseg == 1 % show stimulus in the first segment

  stimulus.count = stimulus.count +1;
  setGammaTable(stimulus.contrasts(stimulus.count)); % set the gamma table to the desired contrast
  
  stimulus.fixXcolor1 = stimulus.black; % the fixation cross defaults to be black and white
  stimulus.fixXcolor2 = stimulus.white;

elseif task.thistrial.thisseg == 2 %turn fixation point Green and Red to demonstrate the reserve colors
  
  stimulus.fixXcolor1 = stimulus.green; 
  stimulus.fixXcolor2 = stimulus.red;
  
elseif task.thistrial.thisseg == 3 % turn fixation back to B&W so can see stim contrast change more easily
  
  stimulus.fixXcolor1 = stimulus.black; % the fixation cross defaults to be black and white
  stimulus.fixXcolor2 = stimulus.white;
  
end


                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   %     function that gets called to draw the stimulus each frame    %
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = screenUpdateCallback(task, myscreen)
global stimulus
% for this example code, all this could be done in the startSegment callback, but in my real
% expt, I want to be able to update the screen rapidly so I do it in the screenUpdate callback

mglClearScreen(stimulus.grayColor); % this is a single number between 0 and 1

% display the fixation cross; the color is set in the startSegment callback
mglFixationCross(0.2,8,stimulus.fixXcolor1,[0 0]);  
mglFixationCross(0.2,2,stimulus.fixXcolor2,[0 0]);

mglBltTexture(stimulus.texture,[0 0],0,0,0);    




                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                   %                function that gets subject  response              %
                   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [task myscreen] = responseCallback(task, myscreen)
global stimulus;


                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                     %          function to make the stimulus             %
                     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function myInitStimulus
global stimulus

stimulus.count = 0;
stimulus.contrasts = 0.251:-0.02:0.001; % run through some contrasts in order

% get the linearized gamma table
stimulus.linearizedGammaTable = mglGetGammaTable;

% reserved colors (save four colors, black, white, green and red)
stimulus.reservedColors = [0 0 0; 1 1 1; 0 .65 0; 1 0 0];
 
% for contrast need to calculated how many slots are left after reserve colors are taken
stimulus.nReservedColors=size(stimulus.reservedColors,1);          % how many colors you reserve
stimulus.minGratingColors = 2*floor(stimulus.nReservedColors/2)+1; % what slot the table starts at after the reserve colors
stimulus.maxGratingColors = 255;                                   % highest slot (always 255)
stimulus.nGratingColors = 256-(stimulus.minGratingColors);         % how many colors are left

% If you have an odd number of reserved colors, you will have an odd
% number of luminances, which means that  you can use the middle one to store 
% your background luminance so that it does not change between different cluts.
% However, if you have an even number of reserved colors you have an even number 
% of luminances and your background luminances will be slightly different 
% between cluts, which is bad.
% The following bit of code solves this problem by giving up one luminance value
% when you choose an even number of reserverd colors so to always have an odd 
% number of luminances:

stimulus.midGratingColors = stimulus.minGratingColors+floor(stimulus.nGratingColors/2); % what slot is now gray (if no reserved colors, = 128)
stimulus.deltaGratingColors = floor(stimulus.nGratingColors/2); % how many steps above and below the midlevel you can go after reserved the colors

% To set up reserved color values (these are indexes to the clut in OpenGL coordinates (0-1))
stimulus.black = [0 0 0];                                          % this accesses the first reserved space which is black
stimulus.white = [1/255 1/255 1/255];                              % this accesses the second reserved space which is white
stimulus.green = [2/255 2/255 2/255];                              % this accesses the third reserved space which is green
stimulus.red = [3/255 3/255 3/255];                                % this accesses the fourth reserved space which is red
stimulus.background = [ceil((255-stimulus.nReservedColors)/2)/255 ceil((255-stimulus.nReservedColors)/2)/255 ceil((255-stimulus.nReservedColors)/2)/255]; 
                                                                   % ^ this always accesses the middle of the range, which is gray
																   
stimulus.grayColor = stimulus.midGratingColors/255;% this is a single number for drawing the background using mglClearScreen

% calculate an annulus envelope (annulus is in the alpha channel)
% all envelopes for your stimuli can be sent to the alpha channels 
% instead of being numerically aprroximated in matlab (e.g., gaussian for gabors)
maskOut = 255*(makeGaussian(6,6,3,3)>exp(-1/2));
maskIn = 255*(makeGaussian(6,6,1,1)>exp(-1/2));
annulus = maskOut - maskIn;

% put a grating in the annulus
tempGrating = stimulus.deltaGratingColors*(makeGrating(6,6,2.5,0,0));
grating(:,:,1) = stimulus.midGratingColors + tempGrating;
grating(:,:,2) = grating(:,:,1);
grating(:,:,3) = grating(:,:,1);
grating(:,:,4) = annulus;
  
% load the stimulus in the video card buffer
stimulus.texture = mglCreateTexture(grating);

clear tempGrating


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function to create a gamma table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setGammaTable(maxContrast)

global stimulus;
 
% set the reserved colors
gammaTable(1:size(stimulus.reservedColors,1),1:size(stimulus.reservedColors,2))=stimulus.reservedColors;
 
% create the gamma table
cmax = 0.5+maxContrast/2;cmin = 0.5-maxContrast/2;
luminanceVals = cmin:((cmax-cmin)/(stimulus.nGratingColors-1)):cmax;

% now get the linearized range
redLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.redTable,luminanceVals,'linear');
greenLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.greenTable,luminanceVals,'linear');
blueLinearized = interp1(0:1/255:1,stimulus.linearizedGammaTable.blueTable,luminanceVals,'linear');
 
% set the gamma table
gammaTable((stimulus.minGratingColors+1):256,:)=[redLinearized;greenLinearized;blueLinearized]';
 
% set the gamma table 
% *this is the actual call to the mgl function that sets the clut*
mglSetGammaTable(gammaTable);

 
% remember what the current maximum contrast is that we can display
% use this in your code not to make mistakes and request a contrast
% that you cannot display
stimulus.currentMaxContrast = maxContrast;


