% mglEatKeys.m
%
%        $Id:$
%      usage: mglEatKeys(keyCodes)
%         by: justin gardner
%       date: 1/29/09
%  copyright: (c) 2009 Justin Gardner (GPL see mgl/COPYING)
%    purpose: starts eating keypresses (i.e. the sent in keycodes
%             will no longer be sent to the application). keyCodes
%             can also be a char array or the myscreen variable. Note
%             that if you press any key that is not being eaten, then
%             key eating will stop.
%
function mglEatKeys(keyCodes)

if (nargin ~= 1)
  help mglEatKeys;
  return
end

% start eating keys
if isstruct(keyCodes) && isfield(keyCodes,'keyboard')
  if mglListener('init') == 0
    disp(sprintf('(mglEatKeys) Eating keys not available'));
    return
  end
  keyfields = fieldnames(keyCodes.keyboard);
  eatkeys = [];
  for i = 1:length(keyfields)
    eatkeys = [eatkeys keyCodes.keyboard.(keyfields{i})];
  end
  mglListener('eatKeys',eatkeys);
elseif isempty(keyCodes)
  mglListener('quit');
elseif isstr(keyCodes) || isnumeric(keyCodes)
  if mglListener('init') == 0
    disp(sprintf('(mglEatKeys) Eating keys not available'));
    return
  end
  mglListener('eatKeys',keyCodes);
end
