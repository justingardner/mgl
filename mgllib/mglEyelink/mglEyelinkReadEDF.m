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

retval = mglPrivateEyelinkReadEDF(filename,verbose);
