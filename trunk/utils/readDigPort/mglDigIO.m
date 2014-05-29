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
%             This can also output analog sine waves of different frequencies and amplitudes
%             If you are using an NI USB-6211 that has analog output ports.
%
%             Here are the commands it accepts:
%             
%             1:'init' Init the digIO thread. You need to run this before anything else will work. You
%                      can optional specify input and output ports which default to 2 and 1 respectively
%                      mglDigIO('init',inputPortNum,outputPortNum);
%                      You can also specify the device number using: 
%                      mglDigIO('init',inputPortNum,outputPortNum,inputDevnum,outputDevnum). 
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
%             5:'ao'   Sets the output port to produce a sine wave and then return to 0, you call it with
%                      parameters time (like digout above), channel (0 or 1 for A0 or A1), frequency,
%                      amplitude (volts peak - it will produce a sine wave that goes from -amplitude to 
%                      amplitude) and duration in seconds. For example:
%                      mglDigIO('ao',-1,0,500,2.5,1);
%                      Will produce a 500Hz sine wave of amplitude -2.5 <-> 2.5 volts for 1 second on A0
%                      You can optionally set the sample rate (default is 250000 samples/second):
%                      mglDigIO('ao',-1,0,500,2.5,1,100000);
%                      And you can specify the device number (below will use the default sample rate, and
%                      use dev2/ao0):
%                      mglDigIO('ao',-1,0,500,2.5,1,[],2);
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
function retval = mglDigIO(command,arg1,arg2,arg3,arg4,arg5,arg6,arg7)

retval = [];
global mglDigIOWarning
if isequal(mglDigIOWarning,-1),retval = 0;return,end

% check arguments
if nargin < 1
  help mglDigIO
  return
end

if isstr(command)
  commandNum = find(strcmp(lower(command),{'shutdown','quit','init','digin','digout','list','ao'}))-2;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for digout command which has three arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for ao which has multiple ways of being called
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif commandNum == 5
  if ~any(nargin == [6 7 8])
    disp(sprintf('(mglDigIO) AO command requires a time, channel, freq, ampitude, duration'));
    disp(sprintf('           e.g. mglDigIO(''ao'',-1,0,500,1,2);'));
    return
  end
  % set a relative time if arg1 is less than zero
  if arg1 <= 0
    arg1 = mglGetSecs-arg1;
  end
  % default samplerate
  if (nargin < 7) || isempty(arg6)
    % this is maximum samles/second for NI USB-6211
    arg6 = 250000;
  end
  % default dig input device number
  if (nargin < 8) || isempty(arg7)
    % Default to dev1
    arg7 = 1;
  end
  % see how many channels we are setting on
  numChannels = length(arg2);
  % make sure all relevant fields have numChannels entries. If they do not
  % then replicate the last entry the necessary number of times
  arg1(end+1:numChannels) = arg1(end);
  arg3(end+1:numChannels) = arg3(end);
  arg4(end+1:numChannels) = arg4(end);
  arg5(end+1:numChannels) = arg5(end);
  % some checks
  if length(unique(arg1)) > 1
    disp(sprintf('(mglDigIO) !!! Different start times on different channels not supported yet !!!'));
  end
  if length(unique(arg3)) > 1
    disp(sprintf('(mglDigIO) !!! Different frequencies on different channels not supported yet !!!'));
  end
  if length(unique(arg5)) > 1
    disp(sprintf('(mglDigIO) !!! Different durations on different channels not supported yet !!!'));
  end
  % run the command
  mglPrivateDigIO(commandNum,numChannels,arg1,arg2,arg3,arg4,arg5,arg6,arg7);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for init command which can specify input and output ports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
  % read input arguments
  inputPortNum = [];outputPortNum = [];inputDevnum = [];outputDevnum = [];
  if nargin > 1,inputPortNum = arg1; end
  if nargin > 2,outputPortNum = arg2; end
  if nargin > 3,inputDevnum = arg3; end
  if nargin > 4,outputDevnum = arg4; end
  % set defaults
  if isempty(inputPortNum) inputPortNum = 2;end
  if isempty(outputPortNum) outputPortNum = 1;end
  if isempty(inputDevnum) inputDevnum = 1;end
  if isempty(outputDevnum) outputDevnum = inputDevnum;end
  retval = mglPrivateDigIO(commandNum,inputPortNum,outputPortNum,inputDevnum,outputDevnum);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% all other command numbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
  % run the command
  retval = mglPrivateDigIO(commandNum);
end
