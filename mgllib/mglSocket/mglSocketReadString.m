% mglSocketReadString.m
%
%      usage: s = mglSocketReadString(socketInfo)
%         by: justin gardner
%       date: 01/26/23
%    purpose: Reads a string from the socket
%
function s = mglSocketReadString(socketInfo)

% get scoket
if nargin < 1 || isempty(socketInfo)                                                                   
  global mgl                                                                                         
  socketInfo = mgl.activeSockets;                                                                    
end

% read the length
strlen = mglSocketRead(socketInfo, 'uint16');

% read each UTF16 character
s = [];
for iChar = 1:strlen
  s(iChar) = mglSocketRead(socketInfo, 'uint16');
end

s = char(s);



