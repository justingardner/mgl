% mglDispText.m
%
%      usage: mglDispText(whichScreen)
%         by: justin gardner
%       date: 05/16/06
%    purpose: display text to screen (useful for communicating
%             w/subject). 
% 
%
function retval = mglDispText(whichScreen)

% check arguments
if ~any(nargin == [0 1])
  help disptext
  return
end

if nargin == 0,whichScreen = [];end
  
% open the screen
msc = initScreen(whichScreen);
mglTextSet('Helvetica',64,[1 1 1],0,0,0,0,0,0,0);

% set flipping
if (exist('hFlip','var')==1) & (hFlip == 1),mglHFlip;,end
if (exist('vFlip','var')==1) & (vFlip == 1),mglVFlip;,end

% get the height of text
abcTexture = mglText(['A':'Z' 'a':'z']);
textHeight = abcTexture.imageHeight;
textHeightDevice = textHeight*mglGetParam('yPixelsToDevice');

% get the maximum number of lines we can display
maxlines = floor(mglGetParam('screenHeight')/textHeight)-1;

% some init values
str = 'start';textnum = 1;

% loop to display text
while ~isempty(str)
  % ask the user what they want to display
  str = input('Text to display (hit enter to end): ','s');
  % convert text to texture
  textTexture(textnum) = mglText(str);
  % set vertical offset
  voffset = textHeightDevice;
  % clear screen
  mglClearScreen;
  deviceRect = mglGetParam('deviceRect');
  % now go through and draw all text lines in memory
  for i = 1:min(length(textTexture),maxlines)
    mglBltTexture(textTexture(i),[deviceRect(1) deviceRect(4)-voffset],-1,-1);
    voffset = voffset+textHeightDevice;
  end
  % and flush screen
  mglFlush;
  % get the next line of text
  textnum = mod(textnum,maxlines)+1;
end

msc = endScreen(msc);
		    


