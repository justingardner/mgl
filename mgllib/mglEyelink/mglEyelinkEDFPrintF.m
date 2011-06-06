% mglEyelinkEDFPrintF.m
%
%       $Id$	
%      usage: mglEyelinkEDFPrintF(message)
%         by: eric dewitt & eli merriam
%       date: 
%    purpose: send a message to the eyelink eyetracker to be stored in the edf data file
%             mglEyelinkEDFPrintF(sprintf('trial %i', trialnum));
%

function [] = mglEyelinkEDFPrintF(message, varargin)

% check arguments
if ~any(nargin == [1:10])
  help mglEyelinkEDFPrintF
  return
end

formattedMessage = sprintf(message, varargin{:});
mglPrivateEyelinkEDFPrintF(formattedMessage);
