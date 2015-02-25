% mglSystemCheck.m
%
%        $Id:$ 
%      usage: mglSystemCheck(toCheck)
%         by: justin gardner
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%       date: 02/24/15
%    purpose: Check for problems with system setup. Should return true if no problem
%             is detected. Called without any arguments checks everything it can.
%
%             mglSystemCheck
%
%             Called with a number (or array of numbers) tells what system to check
% 
%             mglSystemCheck(1)
%
%             Where the numeric codes mean:
%
%               1 = OS version check
%               2 = Keyboard and Mouse
%               3 = mrTools Utilities (needed for some special functions like mglEditScreenParams)
%
function retval = mglSystemCheck(toCheck)

retval = true;

% check arguments
if ~any(nargin == [0 1])
  help mglSystemCheck
  return
end

% if no arguments then check all systems, otherwise check specific systems specified
% by a number code
if nargin == 0
  toCheck = inf;
else
  if isempty(toCheck)
    toCheck = inf;
  end
end

% make sure we have a numeric value
if ~isnumeric(toCheck)
  disp(sprintf('(mglSystemCheck) Which system to check should be a numeric value'));
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check OS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~ismac
  % if pc warn that basically nothing works
  if ispc
    disp(sprintf('(mglSystemCheck) There is no completely working version of mgl for PC. Some functions have been ported, but functionality is not complete.'));
  end
  % if linux warn that a lot does not work
  if isunix
    disp(sprintf('(mglSystemCheck) The linux version of mgl does not have all of the functionality implemented that the mac version has'));
  end
else
  % check for 64 bit
  if ~isequal(computer,'MACI64')
    disp(sprintf('(mglSystemCheck) You are running an older 32 bit version of Matlab. You may find it necessary to recompile the libraries to support your system (our code is compiled to generally be up-to-date with current versions of the MacOS). We have supplied older 32 bit binaries as well, but these may not work (you will know because they will crash matlab). If this happens, you may find it necessary to recompile mgl. For more details on recompiling see: http://gru.stanford.edu/doku.php/mgl/gettingStarted#recompiling_mgl'));
  end
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check for whether the keyboard/mouse is setup to work. On mac, this means
% to check whether the accessibility options are setup or not 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isinf(toCheck) || ismember(2,toCheck)
  if ~mglPrivateSystemCheck(1)
    disp(sprintf('(mglSystemCheck) !!! There is a problem with your computers mouse and keyboard settings !!!'));
    if ismac
      global mglSystemCheckKeyboardMouseMessage
      % if we have not given the error before, then do so now
      if ~isequal(mglSystemCheckKeyboardMouseMessage,true)
	% open up the help page
	system('open http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events');
	% put up message
	if isequal(questdlg(sprintf('(mglSystemCheck) You need to tuun on accessibility options to allow mgl to get keyboard and mouse events with a high resolution time stamp. See the wiki page: http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events to give you information on how to do this. Click Ok to bring up the preference pane so that you can change this.'),'mglSystemCheck','Ok','Cancel','Ok'),'Ok')
	  system('open /System/Library/PreferencePanes/Security.prefPane/');
	end
      else
	disp(sprintf('(mglSystemCheck) !!! Check the wiki page for more info: http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events !!!'));
      end
      % set this to true if you don't want it to show message box again
      mglSystemCheckKeyboardMouseMessage = false;
      retval = false;
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check for GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isinf(toCheck) || ismember(3,toCheck)
  if ~mglIsMrToolsLoaded
    disp(sprintf('(mglSystemCheck) mrTools is not in your path. You do not need to have mrTools for most functions. But a few specific functions like mglEditScreenParams require it for some GUI functions to allow setting of parameters easier (specifically a function called mrParamsDialog). If you would like to use these functions like mglEditScreenParams you should download mrTools (or at least just the Utilities portion). Note that all basic functionality like displaying to screens, capturing mouse/keyboard events, playing sounds and the task code will all work perfectly fine without mrTools installed. For more information, see http://gru.stanford.edu/doku.php/mgl/gettingStarted#initial_setup'));
  end
end

