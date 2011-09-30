% mglGetMouse.m
%
%        $Id$
%      usage: mglGetMouse
%         by: justin gardner
%       date: 09/12/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Return state of mouse buttons and its position.  Position is
%             in global screen coordinates unless a target screen is
%             specified.
%      usage: mglGetMouse([targetScreen])
%           
%             % Get mouse info in global screen coordinates.
%             mouseInfo = mglGetMouse;
% 
%             % Get mouse info in screen 2 coordinates.
%             mouseInfo = mglGetMouse(2);



