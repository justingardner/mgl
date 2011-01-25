function mglEyelinkEDFGetFile(fileName, fileDestination)
% program: mglPrivateEyelinkEDFGetFile.c
% by:      eric dewitt and eli merriam
% date:    02/08/09
% copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
% purpose: Receives a data file from the EyeLink tracker PC.
% usage:   mglEyelinkEDFGetFile(fileName, [fileDestination])

if nargin < 1 || nargin > 2
	help mglEyelinkEDFGetFile
	return;
end

% Set the default file destination.
if nargin == 1
	fileDestination = sprintf('.%s', filesep);
end

% Validate the file destination.
if ~exist(fileDestination, 'dir')
	error('%s does not exist.', fileDestination);
end

% Make sure there is a folder separator at the end of the file destination.
% Not 100% sure if this is necessary, but it doesn't hurt.
if fileDestination(end) ~= filesep
	fileDestination(end+1) = filesep;
end

% Get the EDF file.
mglPrivateEyelinkEDFGetFile(fileName, fileDestination);
