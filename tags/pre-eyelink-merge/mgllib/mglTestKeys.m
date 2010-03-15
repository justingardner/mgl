% mglTestKeys.m
%
%      usage: mglTestKeys()
%         by: justin gardner
%       date: 09/13/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: 
%
function retval = mglTestKeys(screenNumber)

% check arguments
if ~any(nargin == [0 1])
  help mglTestKeys
  return
end

% check for screenNum
if ~exist('screenNumber','var'),screenNumber = [];,end

% default key numbers
ESCKEY = 54;
RETURNKEY = 61;
SPACEKEY = 50;

% test using mglGetKeys
lastkey = RETURNKEY;thiskey = 0;
disp(sprintf('Hit any key to return code using mglGetKeys (SPACE to go to next test, ESC to end)'));
while (length(thiskey) ~= 1) || ((thiskey ~= SPACEKEY) && (thiskey ~= ESCKEY))
  thiskey = find(mglGetKeys);
  if ~isempty(thiskey)
    if thiskey(1) ~= lastkey
      disp(sprintf('%i',thiskey(1)));
      lastkey = thiskey(1);
    end
  else
    lastkey = 0;
  end
end

if thiskey == ESCKEY
  return
end

% test using mglGetKeyEvent
disp(sprintf('Now testing mglGetKeyEvent'));

ESCKEY = 27;

mglOpen(screenNumber);
mglVisualAngleCoordinates(57,[16 12]);
mglTextDraw('Now testing mglGetKeyEvent',[0 0]);
mglTextDraw('Hit any key to return code using mglGetKeyEvent (ESC to end)',[0 -2]);
mglFlush;
keyEvent = mglGetKeyEvent(0,1);
lastkey = 0;thiskey = 0;
while thiskey ~= ESCKEY
  keyEvent = mglGetKeyEvent;
  if ~isempty(keyEvent)
    thiskey = keyEvent.charCode;
    mglClearScreen(0);
    mglTextDraw('Now testing mglGetKeyEvent',[0 0]);
    mglTextDraw('Hit any key to return code using mglGetKeyEvent (ESC to end)',[0 -2]);
    mglTextDraw(sprintf('char: %s keyCode: %i keyboard: %i when: %f',char(keyEvent.charCode),keyEvent.keyCode,keyEvent.keyboard,keyEvent.when),[0 -4]);
    mglFlush;
    lastkey = thiskey;
  end
end
mglClose;
