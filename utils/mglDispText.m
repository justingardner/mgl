% mglDispText.m
%
%      usage: mglDispText(<whichScreen>,<defaultText>)
%         by: justin gardner
%       date: 05/16/06
%    purpose: display text to screen (useful for communicating
%             w/subject). 
% 
%
function mglDispText(whichScreen,defaultText)

% check arguments
if ~any(nargin == [0 1 2])
  help disptext
  return
end

if nargin == 0,whichScreen = [];end
if nargin < 2,defaultText = [];end
  
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
textWidth = abcTexture.imageWidth;
textWidthDevice = textWidth*mglGetParam('xPixelsToDevice');
deviceRect = mglGetParam('deviceRect');

% get the maximum number of lines we can display and max number of characters
maxlines = floor(mglGetParam('screenHeight')/textHeight)-1;
maxStrLen = floor((deviceRect(3)-deviceRect(1))/(textWidthDevice/52));

% default text
if ~isempty(defaultText)
  defaultTextTex = mglText(defaultText);
  mglBltTexture(defaultTextTex,[deviceRect(1) deviceRect(4)-textHeightDevice],-1,1);
  mglLines2(deviceRect(1),deviceRect(4)-textHeightDevice,deviceRect(3),deviceRect(4)-textHeightDevice,2,[1 1 1 ]);
%  mglLines2(deviceRect(1),deviceRect(4)-2*textHeightDevice,deviceRect(3),deviceRect(4)-2*textHeightDevice,2,[1 1 1 ]);
  mglFlush;
end

% some init values
str = 'start';textnum = 1;

minDist = 4;
% loop to display text
while 1
  % ask the user what they want to display
  str = input('Text to display (type end to end, type clear to clear screen): ','s');
  % clear the screen
  if strcmp(str,'clear')
    if exist('textTexture')
      for i = 1:length(textTexture)
	mglDeleteTexture(textTexture(i));
      end
      clear textTexture;
    end
    textnum = 1;
    mglClearScreen;
    if ~isempty(defaultText)
      mglBltTexture(defaultTextTex,[deviceRect(1) deviceRect(4)-textHeightDevice],-1,1);
      mglLines2(deviceRect(1),deviceRect(4)-textHeightDevice,deviceRect(3),deviceRect(4)-textHeightDevice,2,[1 1 1 ]);
    end
    % or draw some more text
  elseif strcmp(str,'end')
    break;
  else
    while(length(str)>0)
      if length(str) > maxStrLen
	% default break loc is at maxStrLen
	breakLoc = maxStrLen;
	thisStr = sprintf('%s-',str(1:breakLoc));
	% but look for a better place to break string
	breakLocs = regexp(str,'[\W]');
	if ~isempty(breakLocs)
	  distFromBreakLoc = breakLocs-maxStrLen;
          if any(abs(distFromBreakLoc) < minDist)
	    [minDist breakLocIndex] = min(abs(distFromBreakLoc));
	    breakLoc = breakLocs(breakLocIndex(1));
	    if breakLoc < length(str)
	      thisStr = sprintf('%s',str(1:breakLoc));
	    else
	      breakLoc = maxStrLen;
	    end
	  end
	end
	str = str(breakLoc+1:end);
      else
	thisStr = str;
	str = '';
      end
      % convert text to texture
      textTexture(textnum) = mglText(thisStr);
      % get the next line of text
      textnum = mod(textnum,maxlines)+1;
    end
    % clear screen
    mglClearScreen;
    if isempty(defaultText)
      % set vertical offset
      voffset = textHeightDevice;
    else
      % draw default text
      mglBltTexture(defaultTextTex,[deviceRect(1) deviceRect(4)-textHeightDevice],-1,1);
      mglLines2(deviceRect(1),deviceRect(4)-textHeightDevice,deviceRect(3),deviceRect(4)-textHeightDevice,2,[1 1 1 ]);
      voffset = textHeightDevice*2;
    end
    % now go through and draw all text lines in memory
    for i = 1:min(length(textTexture),maxlines)
      mglBltTexture(textTexture(i),[deviceRect(1) deviceRect(4)-voffset],-1,1);
      voffset = voffset+textHeightDevice;
    end
  end
  % and flush screen
  mglFlush;
end

msc = endScreen(msc);
		    


