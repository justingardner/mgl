% mglIsMrToolsLoaded.m
%
%        $Id:$ 
%      usage: mglIsMrToolsLoaded()
%         by: justin gardner
%       date: 04/20/14
%    purpose: Test whether mrtools is in path or not
%
function tf = mglIsMrToolsLoaded()

% check arguments
if ~any(nargin == [0])
  help mglIsMrToolsLoaded
  return
end

if ~exist('mrParamsDialog')
  disp(sprintf('(mglIsMrToolsLoaded) You must have mrTools in your path to run the GUI for this function.\nSee here: http://gru.stanford.edu/doku.php/mgl/gettingStarted#initial_setup'));
  tf = false;
else
  tf = true;
end

