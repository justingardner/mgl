% mglFillRect - draw filled rectangle(s) on the screen
%
%      usage: [  ] = mglFillRect(x,y, size, [rgb])
%         by: denis schluppeck
%       date: 2006-05-12
%     inputs: x,y - vectors of x and y coordinates of center
%             size - [width height] of oval
%             color - [r g b] triplet for color
%
%    purpose: draw filled rectangles(s) centered at x,y with size [xsize
%    ysize] and color [rgb]. the function is vectorized, so if you
%    provide many x/y coordinates (identical) ovals will be plotted
%    at all those locations. 
%
%       e.g.: 
%
%mglOpen;
%mglVisualAngleCoordinates(57,[16 12]);
%x = [-1 -4 -3 0 3 4 1];
%y = [-1 -4 -3 0 3 4 1];
%sz = [1 1]; 
%mglFillRect(x, y, sz,  [1 1 0]);
%mglFlush();





