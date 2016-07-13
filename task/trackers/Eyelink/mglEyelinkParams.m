% mglEyelinkParams.mglEyelink
%
%      usage: mglEyelinkParams()
%         by: justin gardner
%       date: 04/16/10
%    purpose: Set/get parameters for eyelink 
%
%             To bring up a GUI to edit current params
%
%             mglEyelinkParams;
%
%             To get parameters for eyelink tracker:
%
%             params = mglEyelinkParams([]);
%
%             To change a setting and save:
%
%             params = mglEyelinkParams;
%             params.sampleRate = 1000;
%             mglEyelinkParams(params);
%
function params = mglEyelinkParams(params)

% check arguments
if ~any(nargin == [0 1])
  help mglEyelinkParams
  return
end

% with no input arguments, then bring up GUI
if (nargin == 0)
  params = mglEyelinkValidateParams(mglGetParam('eyelinkParams'));
  params = mglEyelinkValidateParams(mglEyelinkSetParams(params));
  return
end

% if one params argument, then validate and save
if (nargin == 1) 
  if isstruct(params)
    params = mglEyelinkValidateParams(params);
    mglSetParam('eyelinkParams',params,1);
    return
  else 
    % if one argument and empty, just return parameters
    params = mglEyelinkValidateParams(mglGetParam('eyelinkParams'));
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   mglEyelinkSetParams   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function params = mglEyelinkSetParams(params)

% get calibration type
paramsInfo = {};
paramsInfo{end+1} = {'calibrationType',putOnTopOfList(params.calibrationType,{'HV9','HV5','HV3','H3','HV13'}),'Set the default calibration type to do'};
paramsInfo{end+1} = {'calibrationAreaX',params.calibrationAreaX,'incdec=[-0.1 0.1]','minmax=[0.2 1]','Set the porportion of the area of the screen to do the calibration with (i.e. 0.5 would put the calibration targets at 50% of the screen width. This is sometimes useful if calibration at the far parts of the screen are impossible. Note that Eyelink does not allow values below 0.2 (gives an error of bad value if you try to set below 0.2)'};
paramsInfo{end+1} = {'calibrationAreaY',params.calibrationAreaY,'incdec=[-0.1 0.1]','minmax=[0.2 1]','Set the porportion of the area of the screen to do the calibration with (i.e. 0.5 would put the calibration targets at 50% of the screen width. This is sometimes useful if calibration at the far parts of the screen are impossible. Note that Eyelink does not allow values below 0.2 (gives an error of bad value if you try to set below 0.2)'};
paramsInfo{end+1} = {'cornerScaling',params.cornerScaling,'incdec=[-0.1 0.1]','minmax=[0.2 1]','Set the porportion that the corner targets are shifted towards the center of the screen (0.5 would be mean 50% of the way). This is sometimes useful if calibration at the far parts of the screen are impossible'};
% get sampleRate
paramsInfo{end+1} = {'sampleRate',putOnTopOfList(params.sampleRate,{500,1000,2000}),'Set the sample rate at which you would like to acquire data'};

paramsInfo{end+1} = {'parserSensitivity', params.parserSensitivity,'type=checkbox','Click for more sensitivity event parsing, better for psychophysics'};
  
% get field names, and look for eventFilter and sampleData fileds
thisFieldNames = fieldnames(params);
for i = 1:length(thisFieldNames)
  if ~isempty(strfind(thisFieldNames{i},'eventFilter')) & (length(thisFieldNames{i}) > 11)
    paramsInfo{end+1} = {thisFieldNames{i},params.(thisFieldNames{i}),'type=checkbox',sprintf('Click to save events for: %s',thisFieldNames{i}(12:end))};
  end
  if ~isempty(strfind(thisFieldNames{i},'sampleData')) & (length(thisFieldNames{i}) > 12)
    paramsInfo{end+1} = {thisFieldNames{i},params.(thisFieldNames{i}),'type=checkbox',sprintf('Click to save samples for: %s',thisFieldNames{i}(11:end))};
  end
end


% bring up dialog
params = mrParamsDialog(paramsInfo,'Set Eyelink parameters');

% set the parameters
if ~isempty(params)
  mglSetParam('eyelinkParams',params,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   mglEyelinkValidateParams   %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function params = mglEyelinkValidateParams(params)

% list of necessary fields and their default values
necessaryFields = {'calibrationType','HV9';
  'calibrationAreaX',0.88;		   
  'calibrationAreaY',0.88;		   
  'cornerScaling',1;		   
  'eventFilterLeft',1;
  'eventFilterRight',1;
  'eventFilterFixation',1;
  'eventFilterSaccade',1;
  'eventFilterBlink',1;
  'eventFilterMessage',1;
  'eventFilterButton',1;
  'sampleDataLeft',1;
  'sampleDataRight',1;
  'sampleDataGaze',1;
  'sampleDataArea',1;
  'sampleDataGazeres',1;
  'sampledataStatus',1;
  'sampleRate',500;
  'parserSensitivity',1;
  };

% look for fields and set defaults if the do not exist
for f = 1:size(necessaryFields,1)
  % get field name and its default value
  fieldName = necessaryFields{f,1};
  default = necessaryFields{f,2};
  % if the field doesn't exist, then set it to the default
  if ~isfield(params,fieldName)  
    params.(fieldName) = default;
  end
end

% remove any fields that are not required
thisFieldNames = fieldnames(params);
for f = 1:length(thisFieldNames)
  % check if it is a necessary field
  if ~any(strcmp(thisFieldNames{f},necessaryFields))
    % if not warn
    if ~any(strcmp(thisFieldNames{f},{'paramInfo','sampleData','eventFilter'}))
      disp(sprintf('(mglEyelinkParams:mglEyelinkValidateParams) Removed unecessary field %s from Eyelink params',thisFieldNames{f}));
    end
    params = rmfield(params,thisFieldNames{f});
  end
end

% now create eventFilter and sampleFilter fields
params.eventFilter = '';
params.sampleData = '';
for i = 1:length(thisFieldNames)
  if ~isempty(strfind(thisFieldNames{i},'eventFilter'))
    params.eventFilter = sprintf('%s%s,',params.eventFilter,upper(thisFieldNames{i}(12:end)));
  end
  if ~isempty(strfind(thisFieldNames{i},'sampleData'))
    params.sampleData = sprintf('%s%s,',params.sampleData,upper(thisFieldNames{i}(11:end)));
  end
end
params.eventFilter = params.eventFilter(1:end-1);
params.sampleData = params.sampleData(1:end-1);
