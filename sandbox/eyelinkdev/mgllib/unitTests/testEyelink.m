% needed for video test
mglOpen()
mglScreenCoordinates()
mglClearScreen([0.5 0.5 0.5]);

% open the link
% calls mglPrivateEyelinkOpen, default ip is '100.1.1.1', default conntype is 0
mglEyelinkOpen('100.1.1.1', 0);

%mglPrivateEyelinkSendCommand

% set up some variables
mglEyelinkCMDPrintF('screen_pixel_coords = 0 0 %d %d', mglGetParam('deviceWidth'), mglGetParam('deviceHeight')); 
mglEyelinkCMDPrintF('calibration_type = HV9');
mglEyelinkCMDPrintF('file_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); 
mglEyelinkCMDPrintF('file_sample_data = RIGHT,GAZE,AREA,GAZERES,STATUS'); 
mglEyelinkCMDPrintF('sample_rate = 500');

% % get a key even listener
% mglListener('init');

% run the calibration
mglPrivateEyelinkCalibration

% open up a data file
mglEyelinkOpenEDF('foo.edf');
% mglEyelinkEDFPrintf()
% eyemsg_printf("DISPLAY_COORDS %ld %ld %ld %ld", dispinfo.left, dispinfo.top, dispinfo.right, dispinfo.bottom); 
% eyemsg_printf("FRAMERATE %1.2f Hz.", dispinfo.refresh);
% start recording
mglPrivateEyelinkStartRecording([1 1 1 1]);

% write some messages to the EDF file
mglPrivateEyelinkEDFPrintF('this is my message')

for nSample = 1:300
    % get a sample
    eyePos(nSample,:) = mglPrivateEyelinkGetCurrentSample();
    pause(1/75);
end

% stop recording
mglEyelinkStopRecording();

% close the datafile
mglEyelinkCMDPrintF('close_data_file');

% go offline
mglPrivateEyelinkGoOffline();

% transfer the datafile
mglPrivateEyelinkEDFGetFile('foo.edf');

% % get a key even listener
% mglListener('quit');

% close the link
mglPrivateEyelinkClose();

scatter(mglGetParam('widthHeight')-eyePos(:,1),mglGetParam('deviceHeight')-eyePos(:,2), 0.2);

% close context
mglClose