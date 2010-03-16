% mglOpen();
initScreen;
mglClearScreen(22);
mglFlush();
mglEyelinkOpen();
mglScreenCoordinates();
mglPrivateEyelinkCalibration();
mglEyelinkClose();
% mglClose();