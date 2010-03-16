% needed for video test
mglOpen()
mglScreenCoordinates()
mglClearScreen([0.5 0.5 0.5]);

% open the link
% calls mglPrivateEyelinkOpen, default ip is '100.1.1.1', default conntype is 0
mglEyelinkOpen('100.1.1.1', 0);

%mglPrivateEyelinkSendCommand

% set up some variables
mglEyelinkCMDPrintF('screen_pixel_coords = 0 0 %d %d', mglGetParam('screenWidth'), mglGetParam('screenHeight')); 
mglEyelinkCMDPrintF('calibration_type = HV9');
mglEyelinkCMDPrintF('file_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); 
mglEyelinkCMDPrintF('file_sample_data = RIGHT,GAZE,AREA,GAZERES,STATUS'); 
mglEyelinkCMDPrintF('sample_rate = 500');

% run the calibration
mglPrivateEyelinkCalibration

% open up a data file
mglPrivateEyelinkOpenEDF('foo.edf');
% mglEyelinkEDFPrintf()
% eyemsg_printf("DISPLAY_COORDS %ld %ld %ld %ld", dispinfo.left, dispinfo.top, dispinfo.right, dispinfo.bottom); 
% eyemsg_printf("FRAMERATE %1.2f Hz.", dispinfo.refresh);
% start recording
mglPrivateEyelinkRecordingStart([1 1 1 1]);

% write some messages to the EDF file
mglEyelinkEDFPrintF('this is my message')

for nSample = 1:300
    % get a sample
    eyePos(nSample,:) = mglPrivateEyelinkGetCurrentSample();
    pause(1/75);
end


% stop recording
mglEyelinkRecordingStop();

% check recording state
fprintf(2,'Recording state should be ''0'' and is %d', mglEyelinkRecordingCheck());

% close the datafile
mglEyelinkCMDPrintF('close_data_file');

% go offline
mglPrivateEyelinkGoOffline();

% transfer the datafile
mglPrivateEyelinkEDFGetFile('foo.edf');

% close the link
mglPrivateEyelinkClose();

scatter(mglGetParam('deviceWidth')-eyePos(:,1),mglGetParam('deviceHeight')-eyePos(:,2), 0.2);

% close context
mglClose
