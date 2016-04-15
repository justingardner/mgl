% script to test for gamma table setting problem. The issue is that if you change resolution (either pixels or refresh rate) from the default settings of the monitor in mglEditScreenParams then mac will need to reset the monitor which takes a brief moment and the screen goes dark. initScreen then sets the gammaTable to linearize it - if you have a valid screen calibration - but then mac sets it back some seconds later. So, now initScreen checks for this and waits 3 seconds before trying to set the gamma table. This code checks for this by opening the screen and displaying gray. If the problem exists then you will see the screen change color from a dark gray to a light gray
msc = initScreen;
mglClearScreen(0.5);
mglFlush
mglWaitSecs(5);
msc = initScreen;
mglClearScreen(0.5);
mglFlush

