% mglSetScreenParams.m
%
%        $Id:$ 
%      usage: mglSetScreenParams(screenParams)
%         by: justin gardner
%       date: 07/17/09
%    purpose: Save screen params structure. This will get saved 
%             by default into the file ~/.mglScreenParams.mat
%             you can reset the location where this info is saved
%             by setting mglSetParam('screenParamsFilename',yourLocation,1);
%
function retval = mglSetScreenParams(saveScreenParams)

% check arguments
if ~any(nargin == [1])
  help mglSetScreenParams
  return
end

% get then name of the screen params filename
screenParamsFilename = mglGetParam('screenParamsFilename');
if isempty(screenParamsFilename)
  % set to store in local directory
  screenParamsFilename = fullfile('~','.mglScreenParams');
  mglSetParam('screenParamsFilename',screenParamsFilename,1);
end
screenParamsFilename = mglReplaceTilde(screenParamsFilename);

% make sure we have a .mat extension 
if (length(screenParamsFilename)<3) || ~isequal(screenParamsFilename(end-2:end),'mat')
  screenParamsFilename = sprintf('%s.mat',screenParamsFilename);
end

% now unpack digin fields
diginFields = {'acqLine','portNum','responseLine','acqType','responseType','use'};
for i = 1:length(saveScreenParams)
  for j = 1:length(diginFields)
    if isfield(saveScreenParams{i},'digin') && isfield(saveScreenParams{i}.digin,diginFields{j})
      diginFieldName =sprintf('digin%s',diginFields{j});
      diginFieldName(6) = upper(diginFieldName(6));
      saveScreenParams{i}.(diginFieldName) = saveScreenParams{i}.digin.(diginFields{j});
    end
  end
  if isfield(saveScreenParams{i},'digin')
    saveScreenParams{i} = rmfield(saveScreenParams{i},'digin');
  end
end

% make sure we have valid parameters
saveScreenParams = mglValidateScreenParams(saveScreenParams);

% save the new one
screenParams = saveScreenParams;
disp(sprintf('(mglSetScreenParams) Saving screen params file: %s',screenParamsFilename));
try
  eval(sprintf('save %s screenParams',screenParamsFilename));
catch
  disp(sprintf('(mglSetScreenParams) !!! Could not save screen params in: %s',screenParamsFilename));
  newScreenParamsFilename = input('Enter a new name (e.g. ~/.mglScreenParams) or hit ENTER to ignore: ','s');
  if ~isempty(newScreenParamsFilename)
    disp(sprintf('(mglSetScreenParams) Using mglSetParam(''screenParamsFilename'',''%s'',1); to set screenParamsFilename',newScreenParamsFilename));
    mglSetParam('screenParamsFilename',newScreenParamsFilename,1);
    mglSetScreenParams(saveScreenParams);
  end
end

