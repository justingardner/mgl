% mglDispText.m
%
%      usage: mglDispText(<whichScreen>,<defaultText>,<centeredText>)
%         by: justin gardner
%       date: 05/16/06
%    purpose: display text to screen (useful for communicating w/subject). 
%
%             all arguments are optional.
%             whichScreen: (screen to open, if [], then default screen opens). If screen
%               is already open, will leave screen open and clear
%             defaultText: A string containing default text that will always appear at the
%               top of the screen
%             centeredText: Set to false if you want to have a left/top aligned text display
%                otherwise defaults to true in which case each text is shown centered near
%                the top of the display
% 
%
function mglDispText(whichScreen,defaultText,centeredText)

% check arguments
if ~any(nargin == [0 1 2 3])
  help disptext
  return
end

if nargin == 0,whichScreen = [];end
if nargin < 2,defaultText = [];end
if nargin < 3, centeredText = true;end

% open the screen, if one is not open
if mglGetParam('displayNumber') == -1
  msc = initScreen(whichScreen);
else
  mglClearScreen;
  mglFlush;
  msc = [];
end
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

minDist = 8;
% loop to display text
while 1
  % ask the user what they want to display
  str = input('Text to display (type end to end, type clear to clear screen, ruok to ask if ok): ','s');
  % clear the screen
  if strcmp(str,'ruok')
    str = sprintf('Are you ok?\nHit button once for ok. Twice for NOT ok.');
  end  
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
  elseif strcmp(str,'end')
    break;
  else
    % or draw some more text
    while(length(str)>0)
      if length(str) > maxStrLen
	% default break loc is at maxStrLen
	breakLoc = maxStrLen;
	thisStr = sprintf('%s-',str(1:breakLoc));
	% but look for a better place to break string
	newlinebreak = find(sprintf('\n') == str);
	if ~isempty(newlinebreak)
	  thisStr = str(1:newlinebreak(1)-1);
	  str = str(newlinebreak(1)+1:end);
	else
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
	end
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
      if centeredText
	mglBltTexture(textTexture(i),[deviceRect(1)+(deviceRect(3)-deviceRect(1))/2 deviceRect(2)+3*(deviceRect(4)-deviceRect(2))/4-voffset],0,0);
	voffset = voffset+textHeightDevice;
      else
	mglBltTexture(textTexture(i),[deviceRect(1) deviceRect(4)-voffset],-1,1);
	voffset = voffset+textHeightDevice;
      end
    end
  end
  % and flush screen
  mglFlush;
  if centeredText
    if exist('textTexture')
      for i = 1:length(textTexture)
	mglDeleteTexture(textTexture(i));
      end
      clear textTexture;
    end
    textnum = 1;
  end
end

if ~isempty(msc)
  msc = endScreen(msc);
else
  mglClearScreen;
  mglFlush;
end
		    


