% mglEditScreenParams.m
%
%        $Id:$ 
%      usage: mglEditScreenParams()
%         by: justin gardner
%       date: 07/17/09
%    purpose: 
%
function retval = mglEditScreenParams()

% check arguments
if ~any(nargin == [0])
  help mglEditScreenParams
  return
end

% get the screenParams
screenParams = mglGetScreenParams(0);
if isempty(screenParams),return,end

% get all field names
paramNames = {};
for i = 1:length(screenParams)
  paramNames = union(fieldnames(screenParams{i}),paramNames);
end

% reorder them
paramNames = putOnTopOfList('displaySize',paramNames);
paramNames = putOnTopOfList('displayDistance',paramNames);
paramNames = putOnTopOfList('framesPerSecond',paramNames);
paramNames = putOnTopOfList('screenHeight',paramNames);
paramNames = putOnTopOfList('screenWidth',paramNames);
paramNames = putOnTopOfList('screenNumber',paramNames);
paramNames = putOnTopOfList('displayName',paramNames);
paramNames = putOnTopOfList('computerName',paramNames);

% now go through the screenparams and make into cell arrays of current parameters
paramValues = [];
for i = 1:length(screenParams)
  for j = 1:length(paramNames)
    if isfield(screenParams{i},paramNames{j});
      paramValues.(paramNames{j}){i} = screenParams{i}.(paramNames{j});
    else
      paramValues.(paramNames{j}){i} = '';
    end
  end
end

% list of params that get converted from empty to -1 and vice versa for working with gui
convertEmptyParams = {'screenNumber','screenWidth','screenHeight','framesPerSecond','displayDistance'};

paramsInfo = {};
paramsInfo{1} = {'screenParamsNum',1,'incdec=[-1 1]',sprintf('minmax=[1 %i]',length(screenParams))};
for i = 1:length(paramNames)
  % get rid of [] and replace with -1
  if any(strcmp(paramNames{i},convertEmptyParams))
    for j = 1:length(paramValues.(paramNames{i}))
      if isempty(paramValues.(paramNames{i}){j})
	paramValues.(paramNames{i}){j} = -1;
      end
    end
  end
  switch paramNames{i}
   case 'screenNumber'
    paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}),'group=screenParamsNum','type=numeric','incdec=[-1 1]','Choose the display that you want to open when on this computer (choose -1, if you want to set to [] which opens up the default screen'};
   case {'screenWidth','screenHeight','framesPerSecond','displayDistance','saveData'}
    paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}),'group=screenParamsNum','type=numeric','incdec=[-1 1]'};
   case {'autoCloseScreen'}
    paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}),'group=screenParamsNum','type=numeric','incdec=[-1 1]'};
   case {'displaySize','flipHV','diginAcqType','diginResponseType'}
%    paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}){1},'group=screenParamsNum','type=array'};
    paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}),'type=array','group=screenParamsNum'};
   case {'digin'}
%    paramsInfo{i+1} = {paramNames{i},paramValues.(paramNames{i}),'group=screenParamsNum','type=numeric','incdec=[-1 1]','minmax=[0 inf]'};
   otherwise
    if isnumeric(paramValues.(paramNames{i})(1))
      paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}),'group=screenParamsNum','type=numeric'};
    else
      paramsInfo{end+1} = {paramNames{i},paramValues.(paramNames{i}),'group=screenParamsNum','type=String'};
    end
  end
end

% get the params
params = mrParamsDialog(paramsInfo);

% if cancel then just return
if isempty(params),return,end

for j = 1:length(paramNames)
  % switch -1 to []
  if any(strcmp(paramNames{i},convertEmptyParams))
    for j = 1:length(params.(paramNames{i}))
      if isequal(params.(paramNames{i}){j},-1)
	params.(paramNames{i}){j} = [];
      end
    end
  end
end

% get the names of the parameters we have set
paramNames = fieldnames(params);
paramNames = setdiff(paramNames,{'screenParamsNum','paramInfo'});

% now read back into structure
for i = 1:length(screenParams)
  for j = 1:length(paramNames)
    % get the value for this param 
    if iscell(params.(paramNames{j}))
      % get val out of cell array
      val = params.(paramNames{j}){i};
    else
      % or get value of a numeric array, but first
      % convert any values that are -1 to [] if they need to be converted
      val = params.(paramNames{j})(i);
      if any(strcmp(paramNames{j},convertEmptyParams))
	if params.(paramNames{j})(i) == -1
	  val = [];
	end
      end
    end
    % if not nan, then go ahead and set it
    if ~isequal(val,nan)
      screenParams{i}.(paramNames{j}) = val;
    end
  end
end

% set the screenParams
mglSetScreenParams(screenParams);

