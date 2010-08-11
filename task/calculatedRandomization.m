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
  % get a sequence of the parameter values
  eval(sprintf(['block.parameter.%s = repmat(parameter.%s,1,' ...
    'ceil(parameter.blocklen_/parameter.size_(i)));'], ...
    parameter.names_{i},parameter.names_{i}));
end
retval = block;
