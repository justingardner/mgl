% mglSocketWrite.m
%
%      usage: s = mglSocketWrite(s,data);
%         by: justin gardner
%       date: 12/24/2019
%    purpose: Writes data to socket.
%             s = data structure returned from mglSocketOpen
%             data can take multiple forms:
%               uint16: is a command number for sending commands
%                       and is transferred as is, just two bytes
%             e.g. mglSocketWrite(s,uint16(1));
%
