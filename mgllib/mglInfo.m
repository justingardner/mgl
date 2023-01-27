% mglFLush: Commit a frame of drawing commands and wait for the next frame.                            
%                                                                                                      
%      usage: [info, ackTime, processedTime] = mglInfo(socketInfo)
%         by: justin gardner
%       date: 01/26/2023                                                                               
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)                                            
%    purpose: Get Info from the mglMetal application
%      usage: info =  mglInfo();                                                                   
%       e.g.: mglOpen;                                                                                 
%             info = mglInfo;
%
function [info,ackTime, processedTime] = mglInfo(socketInfo)                                               
% set return structure
info = [];

% get scoket
if nargin < 1 || isempty(socketInfo)                                                                   
  global mgl                                                                                         
  socketInfo = mgl.activeSockets;                                                                    
end

% get display descriptions add add
info.displays = mglDescribeDisplays();

% write info command and wait for reply
mglSocketWrite(socketInfo, socketInfo(1).command.mglInfo);
ackTime = mglSocketRead(socketInfo, 'double');

% read data type
dataType = mglSocketRead(socketInfo, 'uint16');

% until we read send finished
while dataType ~= socketInfo(1).command.mglSendFinished
  if dataType == socketInfo(1).command.mglSendString
    fieldName = mglSocketReadString(socketInfo);
  else
    disp(sprintf('(mglInfo) Expecting string field name, but did not get a string'));
    keyboard
  end

  % read the data
  dataType = mglSocketRead(socketInfo, 'uint16');
  if dataType == socketInfo(1).command.mglSendDouble
    data = mglSocketRead(socketInfo, 'double');
  elseif dataType == socketInfo(1).command.mglSendString
    data = mglSocketReadString(socketInfo);
  else
    disp(sprintf('(mglInfo) Expecting mglSendDouble or mglSendString command, but got %i',dataType));
    keyboard
  end

  % see if field has a . in it
  if ~isempty(strfind(fieldName,'.'))
    % break into headingName and field
    [headingName, fieldName] = strtok(fieldName,'.');
    fieldName = fieldName(2:end);
    % check to see if heading exists
    if ~isfield(info,headingName)
      info.(headingName) = [];
    end
    % set the field
    info.(headingName).(fieldName) = data;
  else
    % set the field
    info.(fieldName) = data;
  end
  
  % read the next send command
  dataType = mglSocketRead(socketInfo, 'uint16');
end

processedTime = mglSocketRead(socketInfo, 'double');
if processedTime < 0
  disp(sprintf('(mglFlush) Error processing command.'));
end

