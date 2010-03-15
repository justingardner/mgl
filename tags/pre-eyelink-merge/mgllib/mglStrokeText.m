function mglStrokeText( string, x, y, scalex, scaley, linewidth, ...
			color, rotation );
% [x,y]=mglStrokeText( string, x, y, scalex, scaley, linewidth, color, rotation );
%
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
% Draws a stroked fixed-width character or string on mgl display. Default width
% is 1, default height 1.8 (in current screen coordinates)
% INPUT:
%        $Id$
%    string : text string. Unsupported characters are printed as #
%       x,y : center coordinates of first character (current screen coordinates)
%    scalex : scale factor in x dimension (relative to character)
%             (current screen coordinates). Note that text can be
%             mirrored by setting this factor to a negative value.
%    scaley : scale factor in y dimension (relative to character)
%             (current screen coordinates). Optional, defaults to
%             scalex. 
% linewidth : self-explanatory. Default 1.
%     color : ditto. Default [1 1 1]
%   rotation: in radians. Default 0.
% OUTPUT:
%       x,y : position after last letter (for subsequent calls) [optional] 
%
%      e.g. :
%
%mglOpen
%mglVisualAngleCoordinates(57,[16 12]);
%mglStrokeText('Hello',0,0);
%mglFlush;