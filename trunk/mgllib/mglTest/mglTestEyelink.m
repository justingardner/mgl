% needed for video test
mglOpen
mglScreenCoordinates()
mglClearScreen([0.5 0.5 0.5]);

% open the link
% calls mglPrivateEyelinkOpen, default ip is '100.1.1.1', default conntype is 0
try
  mglEyelinkOpen('100.1.1.1', 0);
catch err
  mglEyelinkOpen('100.1.1.1', 1);
end
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
mglEyelinkRecordingStart('file-sample', 'link-sample', 'file-event', 'link-event');
mglEyelinkRecordingStop();
mglEyelinkRecordingStart('edf-sample', 'link-sample', 'edf-event', 'link-event');

% write some messages to the EDF file
mglEyelinkEDFPrintF('this is my message')

fprintf(2,'Sample test (''s'': sample received, ''.'': no sample)\n');
totalSamples = 0;
for nSample = 1:300
    % get a sample
    newSample = mglPrivateEyelinkGetCurrentSample();
    if ~isempty(newSample)
      totalSamples = totalSamples + 1;
      eyePos(totalSamples,:) = newSample;
      fprintf(2,'s')
    else
      fprintf(2,'.');
    end
    pause(1/75);
end
fprintf(2,'\nEnd sample test.\n')

% stop recording
mglEyelinkRecordingStop();

% check recording state
fprintf(2,'Recording state should be ''0'' and is %d\n', mglEyelinkRecordingCheck());

% close the datafile
mglEyelinkCMDPrintF('close_data_file');

% go offline
mglPrivateEyelinkGoOffline();

% transfer the datafile
mglPrivateEyelinkEDFGetFile('foo.edf');

% close the link
mglPrivateEyelinkClose();

if totalSamples > 0
  scatter(mglGetParam('deviceWidth')-eyePos(:,1),mglGetParam('deviceHeight')-eyePos(:,2), 0.2);
end

% close context
mglClose
