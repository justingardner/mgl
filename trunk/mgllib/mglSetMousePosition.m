% mglSetMousePosition.m
% 
%      program: mglSetMousePosition.c
%           by: Christopher Broussard
%         date: 02/03/11
%    copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%      purpose: Sets the position of the mouse cursor.  The position is in
%               absolute screen pixel coordinates where (0,0) is the  
% 				is bottom left corner of the screen.  If targetScreen
% 				specified, then the coordinates are relative to that screen.
% 				Otherwise, coordinates are relative to the main screen.
%        usage: mglSetMousePosition(xPos, yPos, targetScreen)
% 	     
% 		        % Move the mouse on the main screen.
% 			    mglSetMousePosition(512, 512);
% 
% 			    % Move the mouse on the secondary screen.
% 			    mglSetMousePosition(512, 512, 2);