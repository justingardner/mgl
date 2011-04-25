% calculatedRandomization.m
%
%      usage: calculatedRandomization()
%         by: eric dewitt
%       date: 10/28/2009
%    purpose: function that decides order of parameters,
% 
function retval = calculatedRandomization(parameter,previousParamIndexes)

%%%%%%%%%%%%%%%%%%%%%%
% do init
%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1
  parameter = initRandomization(parameter);
  % set the block length
  if ~isfield(parameter,'blocklen_')
    parameter.blocklen_ = 250;
  end
  retval = parameter;
  return
end

%%%%%%%%%%%%%%%%%%%%%%
% calculate a block
%%%%%%%%%%%%%%%%%%%%%%
block.trialn = parameter.blocklen_;
for i = 1:parameter.n_
  % get which parameter name we are working on
  thisParameterName = parameter.names_{i};
  % and how many repeats we need.
  nRepeats = ceil(parameter.blocklen_/parameter.size_(i));
  % now init the stimulus
  if isscalar(parameter.(thisParameterName))
    % get a sequence of the parameter values
    block.parameter.(thisParameterName) = repmat(parameter.(thisParameterName),1,nRepeats);
  else
    for j = 1:nRepeats
      % get a sequence of the parameter values
      block.parameter.(thisParameterName){j} = parameter.(thisParameterName);
    end
  end    
end
retval = block;
