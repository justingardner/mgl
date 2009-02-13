
% open the link
mglPrivateEyelinkOpen('100.1.1.1');

%mglPrivateEyelinkSendCommand

% set up some variables
mglPrivateEyelinkCMDPrintF('screen_pixel_coords = 0 0 1152 870'); 
mglPrivateEyelinkCMDPrintF('calibration_type = HV9');
mglPrivateEyelinkCMDPrintF('file_event_filter = RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON'); 
mglPrivateEyelinkCMDPrintF('file_sample_data = RIGHT,GAZE,AREA,GAZERES,STATUS'); 
mglPrivateEyelinkCMDPrintF('sample_rate = 500');

% run the calibration
%mglPrivateEyelinkCalibration

% open up a data file
mglPrivateEyelinkOpenEDF('foo.edf');

% start recording
mglPrivateEyelinkStartRecording([1 1 1 1]);

% write some messages to the EDF file
mglPrivateEyelinkEDFPrintF('this is my message')

% get a sample
mglPrivateEyelinkGetCurrentSample()

% stop recording
mglEyelinkStopRecording();

% close the datafile
mglPrivateEyelinkCMDPrintF('close_data_file');

% go offline
mglPrivateEyelinkGoOffline();

% transfer the datafile
mglPrivateEyelinkEDFGetFile('foo.edf');

% close the link
mglPrivateEyelinkClose();

