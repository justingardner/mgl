% mglValidateScreenParams.m
%
%        $Id:$ 
%      usage: mglValidateScreenParams()
%         by: justin gardner
%       date: 07/23/09
%    purpose: 
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

% list of necessary fields and their default values
necessaryFields = {'computerName',mglGetHostName;
		   'displayName','';
		   'screenNumber',[];
		   'screenWidth',[];
		   'screenHeight',[];
		   'displayDistance',57;
		   'displaySize',[16 12];
		   'framesPerSecond',60;
		   'autoCloseScreen',0;
		   'saveData',50;
		   'monitorGamma',[];
		   'calibType',[];
		   'calibFilename','';
		   'flipHV',[0 0];
		   'diginUse',0;
		   'diginPortNum',[];
		   'diginAcqLine',[];
		   'diginAcqType',[];
		   'diginResponseLine',[];
		   'diginResponseType',[];
		  };

% look for optional fields
for f = 1:size(necessaryFields,1)
  % get field name and its default value
  fieldName = necessaryFields{f,1};
  default = necessaryFields{f,2};
  % if the field doesn't exist, then set it to the default
  if ~isfield(screenParams,fieldName)  
    screenParams.(fieldName) = default;
  end
end

% remove any fields that are not required
thisFieldNames = fieldnames(screenParams);
for f = 1:length(thisFieldNames)
  % check if it is a necessary field
  if ~any(strcmp(thisFieldNames{f},necessaryFields))
    % if not warn
    disp(sprintf('(mglValidateScreenParams) Removed unecessary field %s form %s:%s screen params',thisFieldNames{f},screenParams.computerName,screenParams.displayName));
    screenParams = rmfield(screenParams,thisFieldNames{f});
  end
end

if isempty(screenParams.calibType)
  screenParams.calibType = 'Find latest calibration';
  if ~isempty(screenParams.monitorGamma),screenParams.calibType = 'Specify gamma';end
  if ~isempty(screenParams.calibFilename),screenParams.calibType = 'Specify particular calibration';end
end


	      
