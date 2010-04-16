% mglEyelinkReadEDF.m
%
%      usage: mglEyelinkReadEDF(filename,<verbose>)
%         by: justin gardner
%       date: 04/04/10
%    purpose: Function to read EyeLink eye-tracker files into matlab
%
function retval = mglEyelinkReadEDF(filename,verbose)

% default return argument
retval = [];

% check arguments
if ~any(nargin == [1 2])
  help mglEyelinkReadEDF
  return
end

% default arguments
if nargin < 2,verbose = 1;end

if isfile(setext(filename,'edf'))
  % mglPrivateEleyinkReadEDF returns two matrices. The first
  % is the eye data with rows gaze x, gaze y, pupil, whichEye and
  % time. The second contains Mgl messages which has rows:
  % time, segmentNum, trialNum, blockNum, phaseNum, taskID
  [retval.d retval.m] = mglPrivateEyelinkReadEDF(filename,verbose);
else
  disp(sprintf('(mglEyelinkReadEDF) Could not open file %s',filename));
end
