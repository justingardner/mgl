% mglValidateScreenParams.m
%
%        $Id:$ 
%      usage: mglValidateScreenParams()
%         by: justin gardner
%       date: 07/23/09
%    purpose: Validates a screenParams structure to make sure that it 
%             has all necessary fields
%
% screenParams = mglDefaultScreenParams;
% screenParams = mglValidateScreenParams(screenParams);
%
function screenParams = mglValidateScreenParams(screenParams)

  % check arguments
  if ~any(nargin == [1])
    help mglValidateScreenParams
    return
  end

  if iscell(screenParams)
    for i = 1:length(screenParams)
      screenParams{i} = mglValidateScreenParams(screenParams{i});
    end
    return
  end

 % List of necessary fields and their default values
necessaryFields = {
  'computerName',        mglGetHostName;
  'displayName',         '';
  'screenNumber',        [];
  'screenWidth',         [];
  'screenHeight',        [];
  'displayDistance',     57;
  'displaySize',         [16 12];
  'calibProportion',     0.36;
  'squarePixels',        false;
  'displayPos',          [0 0];
  'shiftOrigin',         [0 0];
  'scale',               0;
  'scaleScreen',         [1 1];
  'crop',                0;
  'cropScreen',          [0 0];
  'framesPerSecond',     60;
  'autoCloseScreen',     0;
  'saveData',            50;
  'backtickChar',        '`';
  'responseKeys',        {'1' '2' '3' '4' '5' '6' '7' '8' '9' '0'};
  'eatKeys',             0;
  'monitorGamma',        [];
  'calibType',           [];
  'calibFilename',       '';
  'flipHV',              [0 0];
  'hideCursor',          0;
  'diginUse',            0;
  'diginPortNum',        [];
  'diginAcqLine',        [];
  'diginAcqType',        [];
  'diginResponseLine',   [];
  'diginResponseType',   [];
  'eyeTrackerType',      [];
  'simulateVerticalBlank', false;
  'useScreenMask',       false;
  'screenMaskFunction',  '';
  'screenMaskStencilNum', 7;
  'enableChanges',       1;
  'setVolume',           0;
  'volumeLevel',         1;
  'transparentBackground', 0;
  'waitForPrescan',      0;
};

% Extract names for fast lookup
necessaryFieldNames = necessaryFields(:,1);

% Use a containers.Map for O(1) membership check
necessarySet = containers.Map(necessaryFieldNames, true(1, numel(necessaryFieldNames)));

% Fill missing fields with defaults
for i = 1:numel(necessaryFieldNames)
    fn = necessaryFieldNames{i};
    if ~isfield(screenParams, fn)
        screenParams.(fn) = necessaryFields{i, 2};
    end
end

% Remove unneeded fields in one go
thisFieldNames = fieldnames(screenParams);
keepMask = ismember(thisFieldNames, necessaryFieldNames) | strcmp(thisFieldNames, 'digin');
removeMask = ~keepMask;
if any(removeMask)
    % Display all removed fields at once (faster than per field)
    removed = thisFieldNames(removeMask);
    fprintf('(mglValidateScreenParams) Removed unnecessary fields from %s:%s: %s\n', ...
        screenParams.computerName, screenParams.displayName, strjoin(removed', ', '));
    screenParams = rmfield(screenParams, removed);
end

% Handle calibType defaults
if ~isfield(screenParams, 'calibType') || isempty(screenParams.calibType)
    if ~isempty(screenParams.calibFilename)
        screenParams.calibType = 'Specify particular calibration';
    elseif ~isempty(screenParams.monitorGamma)
        screenParams.calibType = 'Specify gamma';
    else
        screenParams.calibType = 'Find latest calibration';
    end
end


