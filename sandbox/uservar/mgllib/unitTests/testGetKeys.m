mglOpen(0)
mglListener('init');
resultN = 1;
startT = mglGetSecs;
fprintf(1,'testing mglGetKeys\n');
while mglGetSecs(startT) < 60
    mglGetKeysResults(resultN).keys = mglGetKeys;
    mglGetKeysResults(resultN).time = mglGetSecs;
    mglGetKeysResults(resultN).requested = 0;
    resultN = resultN + 1;
    fprintf(1,'.');
    pause(1);        
end

startT = mglGetSecs;
fprintf(1,'\nPlease press keys during this period.\n');
while mglGetSecs(startT) < 60
    mglGetKeysResults(resultN).keys = mglGetKeys;
    mglGetKeysResults(resultN).time = mglGetSecs;
    mglGetKeysResults(resultN).requested = 1;
    resultN = resultN + 1;
    fprintf(1,'.');
    pause(1);        
end
fprintf(1,'\nFinished collecting data.\n');

keypresses = reshape([mglGetKeysResults.keys], 128, [])';
if any(any(keypresses(1:60,:),2))
    fprintf(2,'ERROR: Unexpected key presses found during no-press aquisition.\n');
end
if ~any(any(keypresses(61:120,:),2))
    fprintf(2,'ERROR: No key presses found during key-press aquisition.\n')
end

% resultN = 1;
% startT = mglGetSecs;
% fprintf(1,'testing mglGetKeyEvent\n');
% while mglGetSecs(startT) < 60
%     mglGetKeyEventResults(resultN).keys = mglGetKeyEvent;
%     mglGetKeyEventResults(resultN).time = mglGetSecs;
%     mglGetKeyEventResults(resultN).requested = 0;
%     resultN = resultN + 1;
%     fprintf(1,'.');
%     pause(1);        
% end
% 
% startT = mglGetSecs;
% fprintf(1,'\nPlease press keys during this period.\n');
% while mglGetSecs(startT) < 60
%     mglGetKeyEventResults(resultN).keys = mglGetKeyEvent;
%     mglGetKeyEventResults(resultN).time = mglGetSecs;
%     mglGetKeyEventResults(resultN).requested = 1;
%     resultN = resultN + 1;
%     fprintf(1,'.');
%     pause(1);        
% end
% fprintf(1,'\nFinished collecting data.\n');

mglListener('quit');

