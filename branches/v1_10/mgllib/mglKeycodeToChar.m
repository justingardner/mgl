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

