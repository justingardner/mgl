% mglTestText.m
%
%        $Id: mglTestText.m 380 2008-12-31 04:39:55Z justin $
%      usage: mglTestText()
%         by: justin gardner
%       date: 05/10/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: 
%
function retval = mglTestText(screenNumber,noClose)

% check arguments
if ~any(nargin == [0 1 2])
  help mglTestText
  return
end

% check for screenNum
if ~exist('screenNumber','var'),screenNumber = [];,end
if ~exist('noClose','var'),noClose = 0;,end

% open up screen
mglOpen(screenNumber);
mglScreenCoordinates;
mglClearScreen;

doExpandingText = 1;
if doExpandingText
  % render the text into textures
  if exist('disppercent')
    disppercent(-inf,'Rendering text');
  else
    disp(sprintf('Rendering text'));
  end
  clear expandingText contractingText;
  nFrames = 0;
  for i = 16:40
    if exist('disppercent'),disppercent((i-11)/(40-11));,end
    % set the text (increasing fontsize each frame)
    mglTextSet([],i,[0 1 1],0,0,30,0,0,0,0);
    % and make the texture from the text
    nFrames = nFrames+1;
    expandingText(nFrames) = mglText('This text is getting larger');
    contractingText(nFrames) = mglText('This text is getting smaller');
  end
  if exist('disppercent'),disppercent(inf);,end

  % display the text
  for k = 1:2
    % display expanding text
    for i = 1:nFrames
      mglClearScreen;
      mglBltTexture(expandingText(i),[mglGetParam('screenWidth')/2 mglGetParam('screenHeight')/2],0,0);
      mglFlush;
    end
    mglWaitSecs(0.3);
    % display contracting text
    for i = nFrames:-1:1
      mglClearScreen;
      mglBltTexture(contractingText(i),[mglGetParam('screenWidth')/2 mglGetParam('screenHeight')/2],0,0);
      mglFlush;
    end
    mglWaitSecs(0.3);
  end
end

% clear screen
mglClearScreen;mglFlush;
mglClearScreen;mglFlush;

% draw text in various positions
mglTextSet('Didot',24,[0.8 0.2 0.8],0,0,0,0,0,0,0);
text = mglText('Wonderful it works now');
mglBltTexture(text,[0 0],-1,-1);

mglTextSet('Copperplate Gothic Bold',36,[0.8 0.2 0.8],0,0,0);
text = mglText('Wonderful it works now');
mglBltTexture(text,[400 200],-1,-1);

mglTextSet('Arial',36);
mglTextSet([],[],[0.2 0.8 0.2],0,1)
text = mglText('This text has been flipped vertically');
mglBltTexture(text,[500 300],-1,-1);

mglTextSet([],[],[0.2 0.8 0.2],1,0)
text = mglText('This text has been flipped horizontally');
mglBltTexture(text,[200 400],-1,-1);

mglTextSet('Courier',16,[0.2 0.8 0.2],0,0,0)
text = mglText('This text has been left justified');
mglBltTexture(text,[400 500],-1,-1);
text = mglText('This text has been center justified');
mglBltTexture(text,[400 500+text.imageHeight],0,-1);
text = mglText('This text has been right justified');
mglBltTexture(text,[400 500+text.imageHeight*2],1,-1);

mglTextSet('Century Gothic',200,[0.2 0.2 0.2],0,0,0)
text = mglText('Large Text');
mglBltTexture(text,[1000 700],1,-1);

% draw letters with circles behind them
mglTextSet('Helvetica',45,[1 1 1]);
letters = 'ABCDEFG';
for i = 1:length(letters)
  letter = mglText(letters(i));
  mglFillOval(300+i*60,60,[50 50],rand(1,3));
  mglBltTexture(letter,[300+i*60 60],0,0);
end

mglTextSet('Copperplate Gothic Bold',36,[0.2 0.9 0.5],0,0,40);
text = mglText('This text has been rotated');
mglBltTexture(text,[300 200],0,0);

mglTextSet('Courier',24,[0.9 0.8 0.2],0,0,0,1,0,0,0);
text = mglText('Bold');
mglBltTexture(text,[0 400],-1,0);

mglTextSet([],[],[],[],[],[],0,1,0,0);
text = mglText('Italic');
mglBltTexture(text,[0 400+text.imageHeight],-1,0);

mglTextSet([],[],[],[],[],[],0,0,1,0);
text = mglText('Underline');
mglBltTexture(text,[0 400+text.imageHeight*2],-1,0);

mglTextSet([],[],[],[],[],[],0,0,0,1);
text = mglText('Strike-through');
mglBltTexture(text,[0 400+text.imageHeight*3],-1,0);

% draw some japanese text
mglTextSet('Osaka',45,[1 1 0],0,0,-30,0,0,0,0);
fid = fopen('mglTest/japanese.txt','r','b');
jText = fread(fid,'*uint16')';
fclose(fid);
mglBltTexture(mglText(jText),[0 50],-1);

mglFlush;

% auto close the screen after two seconds
if ~noClose
  pause(5);
  mglClose;
end
