% mglGetScreenParams.m
%
%        $Id:$ 
%      usage: mglGetScreenParams()
%         by: justin gardner
%       date: 07/17/09
%    purpose: just returns the screenParams
%
function screenParams = mglGetScreenParams(convertDigFields)

% check arguments
if ~any(nargin == [0 1])
  help mglGetScreenParams
  return
end

if nargin == 0
  convertDigFields = 1;
end

% get then name of the screen params filename
screenParamsFilename = mglGetParam('screenParamsFilename');
if isempty(screenParamsFilename)
  screenParamsFilename = fullfile(mglGetParam('taskdir'),'mglScreenParams');
end

% make sure we have a .mat extension 
[pathstr name] = fileparts(screenParamsFilename);
screenParamsFilename = sprintf('%s.mat',fullfile(pathstr,name));

% check for file
if ~isfile(screenParamsFilename)
  disp(sprintf('(mglEditScreenParams) UHOH: Could not find screenParams file %s',screenParamsFilename));
  screenParams = {};
else
  % load the file
  screenParams = load(screenParamsFilename);
end

% check to make sure it has the right field
if isfield(screenParams,'screenParams')
  screenParams = screenParams.screenParams;
elseif ~isempty(screenParams)
  disp(sprintf('(mglEditScreenParams) UHOH: File %s does not contain screenParams',screenParamsFilename));
  screenParams = {};
end

if isempty(screenParams),return,end

% make sure that we have valid parameters
screenParams = mglValidateScreenParams(screenParams);

% make sure that dispalySize and flipHV are row arrays
rowArrayVars = {'displaySize','flipHV','diginAcqType','diginResponseType'};
for i = 1:length(screenParams)
  for j = 1:length(rowArrayVars)
    if isfield(screenParams{i},rowArrayVars{j})
      % make sure the arrays are oriented properly
      if size(screenParams{i}.(rowArrayVars{j}),1) > 1
	screenParams{i}.(rowArrayVars{j}) = screenParams{i}.(rowArrayVars{j})';
      end
      % now make sure that they are of length two
      if isempty(screenParams{i}.(rowArrayVars{j}))
	screenParams{i}.(rowArrayVars{j}) = [0 0];
      elseif size(screenParams{i}.(rowArrayVars{j}),2) < 2
	screenParams{i}.(rowArrayVars{j})(end:2) = nan;
      end
    end
  end
end

% set some default values
defaultValues = {{'diginAcqType',[0 1]},{'diginResponseType',[0 1]}};
for i = 1:length(screenParams)
  for j = 1:length(defaultValues)
    if ~isfield(screenParams{i},defaultValues{j}{1})
      screenParams{i}.(defaultValues{j}{1}) = defaultValues{j}{2};
    end
  end
end

if convertDigFields
  % check for digin fields and then convert them to a structure. We are doing this just for convenience
  % in the saveParams strucutre we save fields like diginAcqLine and in initScreen we want to group
  % them together into fields like digin.acqLine, so we do a little conversion here
  for i = 1:length(screenParams)
    digin = [];
    paramNames = fieldnames(screenParams{i});
    for j = 1:length(paramNames)
      if findstr('digin',paramNames{j}) == 1
	% get the field that begins with digin and pack into a structure
	if ~isstruct(screenParams{i}.(paramNames{j}))
	  paramNames{6} = lower(paramNames{6});
	  val = screenParams{i}.(paramNames{j});
	  if isstr(val),val = str2num(val);end
	  digin.(paramNames{j}(6:end)) = val;
	end
	% remove the field from screenParams
	screenParams{i} = rmfield(screenParams{i},paramNames{j});
      end
    end
    if ~isempty(digin)
      screenParams{i}.digin = digin;
    end
  end
end


