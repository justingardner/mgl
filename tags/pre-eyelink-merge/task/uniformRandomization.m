% uniformRandomization.m
%
%      usage: uniformRandomization()
%         by: justin gardner
%       date: 01/22/07
%    purpose: function that decides order of parameters,
% 
function retval = uniformRandomization(parameter,previousParamIndexes)

%%%%%%%%%%%%%%%%%%%%%%
% do init
%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1
  parameter = initRandomization(parameter);
  % set the block length (that is how many trials to compute out for)
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
  eval(sprintf('sequence = repmat(parameter.%s,1,ceil(parameter.blocklen_/parameter.size_(i)));',parameter.names_{i}));
  % and set it in the block to a random permutation.
  eval(sprintf('block.parameter.%s = sequence(randperm(parameter.blocklen_));',parameter.names_{i}));
end
retval = block;
