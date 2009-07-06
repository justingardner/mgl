% mglDigIO.m
%
%        $Id: mglDigIO.m 438 2009-01-30 04:46:05Z justin $
%      usage: mglDigIO(command,<arg1>,<arg2>)
%         by: justin gardner
%       date: 06/30/09
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: This is a mac specific command that is used to control a NI digital
%             IO board. It has been tested with the NI USB-6501. It runs as a thread
%             that reads digital port 2 and logs any change in state (either up or down)
%             It can also be used to set digital lines on port 1 at a time of your choosing
%
%             Here are the commands it accepts:
%             
%             1:'init' Init the digIO thread. You need to run this before anything else will work. You
%                      can optional specify input and output ports which default to 1 and 2 respectively
%                      mglDigIO('init',inputPortNum,outputPortNum);
%             2:'digin' Returns all changes on the input digital port
%             3:'digout' Set the output digital port a time of your choosing. This takes
%                        2 other values. The time in seconds that you want the digital port
%                        to be set. And the value you want it to be set too. Time can be
%                        either an absolute time returned by mglGetSecs or it can be
%                        relative to now if it is a negative value:
%                        mglDigIO('digout',-5,0) -> Sets the output port to 0 five secs from now.
%             4:'list' Lists all pending digout events
%             0:'quit' Quits the digIO thread, after this you won't be able to run other commands
%
%
function retval = mglDigIO(command,arg1,arg2)

retval = [];

% check arguments
if ~any(nargin == [1 2 3])
  help mglDigIO
  return
end

if isstr(command)
  commandNum = find(strcmp(lower(command),{'quit','init','digin','digout','list'}))-1;
  if isempty(commandNum)
    disp(sprintf('(mglDigIO) Unknown command %s',command));
    return
  end
elseif isscalar(command)
  commandNum = command;
else
  help mglDigIO;
  return
end

% check for digout command which has three arguments
if commandNum == 3
  if (nargin ~= 3)
    disp(sprintf('(mglDigIO) DIGOUT command requires a time and a value'));
    return
  end
  % set a relative time if arg1 is less than zero
  if arg1 <= 0
    arg1 = mglGetSecs-arg1;
  end
  % run the command
  mglPrivateDigIO(commandNum,arg1,arg2);
% check for init command which can specify input and output ports
elseif commandNum == 1
  if nargin > 1,inputPortNum = arg1;else inputPortNum = 2;end
  if nargin > 2,outputPortNum = arg2;else outputPortNum = 1;end
  retval = mglPrivateDigIO(commandNum,inputPortNum,outputPortNum);
else
  % run the command
  retval = mglPrivateDigIO(commandNum);
end

  


