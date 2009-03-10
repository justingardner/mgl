function keycode=mglCharToKeycode(keyname,returnAllMatches)
% keycode=mglCharToKeycode(keyname,<returnAllMatches>)
%
% Returns the keycodes of a (list of) keynames
% 
% INPUT
% keyname : cell array where each entry is a key name string
%           e.g. keyname = {'h','g' '1'}
%           Special keys: 
%           On Linux (X), special keys and function keys have
%           unique names, e.g., 'Escape', 'F1', etc., so obtaining
%           the keycodes for these is done by 
%           mglCharToKeycode({'Escape','F1'}) etc.
%           On Macs, this is not possible; instead, test for 
%           the keycode and name of a key using the mglShowKey function.
% returnAllMatches: (default 0) If set to 1, then returns all matches
%          this makes the output a cell array rather than a vector
%          array. This is useful for if a key has multiple matches,
%          like for instance the number keys.
%           
% OUTPUT 
% keycode : vector of integer keycodes for each keyname entry
%           e.g. for the above example, keyname=[44 43 11] (on Linux)
%           (if returnAllMatches=1 then returns a cell array)
% 
% The keycodes match those used by mglGetKeys and mglGetKeyEvent
%
% Example: testing for specific keypresses:
% keycodes=mglCharToKeycode({'1','2' '3'}) % keys 1-3 on main keyboard
% while (1); k=mglGetKeys(keycodes); if (any(k)),break;end;end 
% 
% Technical note: the returned keycodes are identical to system keycodes+1
% 
% jl 20061020

