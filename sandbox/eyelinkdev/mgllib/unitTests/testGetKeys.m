mglOpen()

% resultN = 1;
% startT = mglGetSecs;
% fprintf(1,'testing mglGetKeys');
% while mglGetSecs(startT) < 60
%     mglGetKeysResults(resultN).keys = mglGetKeys;
%     mglGetKeysResults(resultN).time = mglGetSecs;
%     mglGetKeysResults(resultN).requested = 0;
%     resultN = resultN + 1;
%     fprintf(1,'.');
%     pause(1);        
% end
% 
% startT = mglGetSecs;
% fprintf(1,'\nPlease press keys during this period.\n');
% while mglGetSecs(startT) < 60
%     mglGetKeysResults(resultN).keys = mglGetKeys;
%     mglGetKeysResults(resultN).time = mglGetSecs;
%     mglGetKeysResults(resultN).requested = 1;
%     resultN = resultN + 1;
%     fprintf(1,'.');
%     pause(1);        
% end
% fprintf(1,'\nFinished collecting data.\n');


resultN = 1;
startT = mglGetSecs;
fprintf(1,'testing mglGetKeys');
while mglGetSecs(startT) < 60
    mglGetKeyEventResults(resultN).keys = mglGetKeyEvent;
    mglGetKeyEventResults(resultN).time = mglGetSecs;
    mglGetKeyEventResults(resultN).requested = 0;
    resultN = resultN + 1;
    fprintf(1,'.');
    % pause(1);        
end

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
% 

