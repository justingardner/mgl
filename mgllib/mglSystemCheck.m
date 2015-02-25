% mglSystemCheck.m
%
%        $Id:$ 
%      usage: mglSystemCheck()
%         by: justin gardner
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%       date: 02/24/15
%    purpose: Check for problems with system setup. Should return true if no problem
%             is detected.
%
function retval = mglSystemCheck()

% check arguments
if ~any(nargin == [0])
  help mglSystemCheck
  return
end


% Check for whether the keyboard/mouse is setup to work. On mac, this means
% to check whether the accessibility options are setup or not 
if ~mglPrivateSystemCheck(1)
  disp(sprintf('(mglSystemCheck) !!! There is a problem with your computers mouse and keyboard settings !!!'));
  if ismac
    global mglSystemCheckKeyboardMouseMessage
    % if we have not given the error before, then do so now
    if ~isequal(mglSystemCheckKeyboardMouseMessage,true)
      % open up the help page
      system('open http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events');
      % put up message
      if isequal(questdlg(sprintf('(mglSystemCheck) You need to tuun on accessibility options to allow mgl to get keyboard and mouse events with a high resolution time stamp. See the wiki page: http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events to give you information on how to do this'),'mglSystemCheck','Ok','Ok'),'Ok')
      end
    else
      disp(sprintf('(mglSystemCheck) !!! Check the wiki page for more info: http://gru.stanford.edu/doku.php/mgl/beta#keyboard_events !!!'));
    end

    mglSystemCheckKeyboardMouseMessage = true;
  end
end


