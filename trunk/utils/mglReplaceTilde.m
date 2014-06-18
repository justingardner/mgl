% mglReplaceTilde.m
%
%        $Id:$ 
%      usage: filename =  mglReplaceTilde(filename)
%         by: justin gardner
%       date: 12/07/11
%    purpose: If filename starts with a tilde, will replace with
%             fully qualified path (e.g. ~/uhm will become /Users/justin/uhm)
%
function filename = mglReplaceTilde(filename)

% check arguments
if ~any(nargin == [1])
  help mglReplaceTilde
  return
end

if (length(filename) >= 1) && (filename(1) == '~')
  % get tilde dir
  if ispc
    tildeDir = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
  else
    tildeDir = getenv('HOME');
  end

  % apend tildeDir
  filename = fullfile(tildeDir,filename(2:end));
end

