function keycode=mglShowKey;
% keycode=mglShowKey;
% 
% Displays the keycode of a single pressed key. Useful for returing the keycodes of 
% special keys, e.g. ESC, CTRL, function keys etc.
  
  pause(0.5)
  keycode=[];
while(1 & isempty(keycode))
  a=mglGetKeys;
  if (~isempty(a))
    keycode=find(a);
  end
end
  
