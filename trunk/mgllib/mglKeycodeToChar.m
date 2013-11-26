function keyname=mglKeycodeToChar(keycode)
% keyname=mglKeycodeToChar(keycode)
%
% Returns the keynames of a (list of) keycodes
% 
% INPUT
% keycode : vector of integer keycodes for each keyname entry
%           e.g. keyname=[44 43 11] 
% OUTPUT 
% keyname : cell array where each entry is a key name string
%           e.g. for the above example, keyname = {'h','g' '1'} (on Linux)
%           Special keys: 
%           On Linux (X), special keys and function keys have
%           unique names, e.g., 'Escape', 'F1', etc., so obtaining
%           the keynames for these returns these names
%           On Macs, the keynames for special keys are non-transparent;
%           use the the mglShowKey function to retrieve the keycode and keyname 
%           of a single key.
%           
% 
% Example: testing which keys were pressed:
% while (1); k=mglGetKeys; if (any(k)),break;end;end 
% keycodes=find(k);
% keynames=mglKeycodeToChar(keycodes)
% 
% Technical note: keycodes are identical to system keycodes+1
% 
% jl 20061020

% check input arguments
if nargin ~= 1
  help mglKeycodeToChar;
  keyname = [];
  return
end
% check to see if there is a stored keycodeToChar array
keycodeToChar = mglGetParam('keycodeToChar');
if isempty(keycodeToChar)
  % get the mapping of keycodes to chars
  keycodeToChar = mglPrivateKeycodeToChar(1:128);
  % add a blank keycode for out of range
  keycodeToChar{129} = [];
  % store in mgl param
  mglSetParam('keycodeToChar',keycodeToChar);
end

% make sure we are in range
if any(keycode<1) || any(keycode>128)
  disp(sprintf('(mglKeycodeToChar) Keycode out of range'));
  % set to the special out of range code
  keycode((keycode<1) | (keycode>128)) = 129;
end

% now lookup mapping and retrun
keyname = keycodeToChar(keycode);

