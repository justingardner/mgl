function [keycode,keyname]=mglShowKey;
% [keycode,keyname]=mglShowKey;
% 
% Displays the keycode of a single pressed key. Useful for returning the keycodes of 
% special keys, e.g. ESC, CTRL, function keys etc.
  
  pause(0.5)
  keycode=[];
while(1 & isempty(keycode))
  a=mglGetKeys;
  if (~isempty(a))
    keycode=find(a);
  end
end
  
keyname=mglKeycodeToChar(keycode);
fprintf('Keycode: %i, key name: %s\n',keycode,keyname{1})
