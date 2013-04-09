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
%             It can also be used to set digital lines on port 1 at a time of your choosing.
%
%             You can use the function testDigPort to test ability to read and write ports.
%             Note that due to the way the NI-DAQ mxBase library reads/writes the ports,
%             it seems that accuracy is on the order of 1/2 ms. Meaning that you can
%             pretty reliably read events (e.g. square wave pulse) of about 250Hz. At 500Hz
%             you will likely drop a few events and it gets worse from there.
%     
%             You will need to compile the mglPrivateDigIO.c function using mglMake('digio') 
%             for this to work. See instructions on the wiki.
%
%             Here are the commands it accepts:
%             
%             1:'init' Init the digIO thread. You need to run this before anything else will work. You
%                      can optional specify input and output ports which default to 1 and 2 respectively
%                      mglDigIO('init',inputPortNum,outputPortNum);
%                      You can call init with different port numbers to reset what ports you want
%                      to listen/write to/from without calling quit inbetween.
%             2:'digin' Returns all changes on the input digital port
%             3:'digout' Set the output digital port a time of your choosing. This takes
%                        2 other values. The time in seconds that you want the digital port
%                        to be set. And the value you want it to be set too. Time can be
%                        either an absolute time returned by mglGetSecs or it can be
%                        relative to now if it is a negative value:
%                        mglDigIO('digout',-5,0) -> Sets the output port to 0 five secs from now.
%             4:'list' Lists all pending digout events
%             0:'quit' Closes the nidaq ports, after this you won't be able to run other commands. Note
%                      that this does not shutdown the digIO thread. The reason for this is that the
%                      NIDAQ library is not thread safe, so you can only call its functions from one
%                      thread, so to be able to keep starting and stopping reading from the card,
%                      the thread is set to continue to run, and quit simply shuts down the nidaq tasks
%                      and stops logging events. After you call quit, you can use init again to restart
%                      reading/writing. If you need to shutdown the thread, use 'shutdown'
%             -1:'shutdown' Quits the digIO thread if it is running, after this you won't be able to run other commands
%
%
function retval = mglDigIO(command,arg1,arg2)

retval = [];
global mglDigIOWarning
if isequal(mglDigIOWarning,-1),retval = 0;return,end

% check arguments
if ~any(nargin == [1 2 3])
  help mglDigIO
  return
end

if isstr(command)
  commandNum = find(strcmp(lower(command),{'shutdown','quit','init','digin','digout','list'}))-2;
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
  % first check if the niddq libraries look like they exist
  if isempty(mglDigIOWarning) && ~isdir('/Library/Frameworks/nidaqmxbase.framework')
    if strcmp(questdlg('You do not have the directory /Library/Frameworks/nidaqmxbase.framework, which suggests that you do not have the NIDAQ libraries installed. To run mglDigIO, you will need to install NI-DAQmx Base from http://sine.ni.com/nips/cds/view/p/lang/en/nid/14480 and then mglDigIO should work with your NI card. If you think you are getting this warning in error, then hit ''Ignore and run mglDigIO anyway'' and the program will try to run, but will likely crash because the libraries are not installed on your system','NI-DAQmx Base is missing','Cancel','Ignore and run mglDigIO anyway','Cancel'),'Cancel')
      retval = 0;
      mglDigIOWarning = -1;
      return;
    end
    mglDigIOWarning = 1;
  elseif isempty(mglDigIOWarning) && (exist(['mglPrivateDigio.' mexext])==0)
    if strcmp(questdlg('You do not seem to have mglPrivateDigio compiled. Have you run mglMake(''digio''). Note that NI does not supply a 64 bit library for Mac OS X, so the 64-bit version of mglPrivateDigIO runs a 32-bit program outside matlab and communicates via a socket to it','(mglDigIO: Not compiled','Cancel','Cancel'),'Cancel')
      retval = 0;
      mglDigIOWarning = -1;
      return
    end
    mglDigIOWarning = 1;
  end
  % set the name of the socket which digio will use to communicate
  % to the standalone process (64 bit implementation only)
  if isempty(mglGetParam('digioSocketName'))
    % get home directory
    curpath = pwd;cd('~');homepath = pwd;cd(curpath);
    mglSetParam('digioSocketName',fullfile(homepath,'.mglDigIO'));
  end
  if nargin > 1,inputPortNum = arg1;else inputPortNum = 2;end
  if nargin > 2,outputPortNum = arg2;else outputPortNum = 1;end
  retval = mglPrivateDigIO(commandNum,inputPortNum,outputPortNum);
else
  % run the command
  retval = mglPrivateDigIO(commandNum);
end
