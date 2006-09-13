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
ESCKEY = 46;
RETURNKEY = 61;
SPACEKEY = 42;

% test using mglGetKeys
lastkey = RETURNKEY;thiskey = 0;
disp(sprintf('Hit any key to return code using mglGetKeys (SPACE to go to next test)'));
while (length(thiskey) ~= 1) || (thiskey ~= SPACEKEY)
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

% test using mglGetKeyEvent
disp(sprintf('Now testing mglGetKeyEvent'));
disp(sprintf('Input focus must be on the screen'));

ESCKEY = 27;

mglOpen(screenNumber)
disp(sprintf('Hit any key to return code using mglGetKeyEvent (ESC to end)'));
lastkey = 0;thiskey = 0;
while thiskey ~= ESCKEY
  keyEvent = mglGetKeyEvent;
  if keyEvent.charCode ~= 0
    thiskey = keyEvent.charCode;
    disp(sprintf('%i %i %i %i',keyEvent.charCode,keyEvent.keyCode,keyEvent.keyboard,keyEvent.when));
    lastkey = thiskey;
  end
end
mglClose;