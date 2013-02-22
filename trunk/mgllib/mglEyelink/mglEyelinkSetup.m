function mglEyelinkSetup(displayNumber, targetParams)
% MGLEYELINKSETUP   Enters the Eyelink setup mode.
%
% Syntax:
% mglEyelinkSetup
% mglEyelinkSetup(displayNumber)
% mglEyelinkSetup(displayNumber, targetParams)
% 
% Description:
% Switch into the EyeLink setup mode (for camera setup, calibration,
% validation, etc.).
%
% Input:
% displayNumber (scalar) - The MGL display number of the screen on which to
%     run the calibration.  If unspecified or empty, the current MGL
%     windows is used.
% targetParams (struct) - Struct containing parameters for the target
%     during calibration.  Contains the following fields:
%     outerRGB (1x3) - RGB value of the outer part of the target.
%     innerRGB (1x3) - RGB value of the inner part of the target.
    
%   Created by Eric DeWitt on 2010-03-25.
%   Copyright (c)  Eric DeWitt. All rights reserved.

% TODO: add MGL screen/context handling

if nargin > 2
	error(help('mglEyelinkSetup'));
end

% Set the default display number if it isn't specified.
if ~exist('displayNumber', 'var') || isempty(displayNumber)
  displayNumber = mglGetParam('displayNumber');
end

% Set the default target parameters if not specified.
if ~exist('targetParams', 'var') || isempty(targetParams)
	% Make it an empty struct here because validateTargetParams will setup
	% the defaults for us.
	targetParams = struct;
end

% Switch to the specified MGL window if it's not -1.  -1 is a special
% number switch closes all open MGL windows.
if displayNumber ~= -1
	mglSwitchDisplay(displayNumber);
end

% Make sure an MGL window is open.
if mglGetParam('displayNumber') == -1
  error('(mglEyelinkSetup) An MGL window must be opened prior to running mglEyelinkSteup.');
end

% Make sure the targetParams struct is setup properly.
targetParams = validateTargetParams(targetParams);

% Run the EyeLink setup.  
mglPrivateEyelinkSetup(displayNumber, targetParams);


function targetParams = validateTargetParams(targetParams)
if ~isstruct(targetParams)
	error('(mglEyelinkSetup) "targetParams" must be a struct.');
end

% Make sure that the struct has all the appropriate fields.  If it's
% missing a field, we'll stick in a default.
if isfield(targetParams, 'outerRGB')
	if ~isequal(size(targetParams.outerRGB), [1 3])
		error('(mglEyelinkSetup) "outerRGB" must be a 1x3.');
	end
else
	targetParams.outerRGB = [1 0 0];
end
if isfield(targetParams, 'innerRGB')
	if ~isequal(size(targetParams.innerRGB), [1 3])
		error('(mglEyelinkSetup) "innerRGB" must be a 1x3.');
	end
else
	targetParams.innerRGB = ones(1,3) * 0.8;
end
