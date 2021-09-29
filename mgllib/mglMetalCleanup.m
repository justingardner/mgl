% mglMetalCleanup.m
%
%      usage: mglMetalCleanup()
%         by: justin gardner
%       date: 09/29/2021
%    purpose: Helper function to clean-up directories for digital
%
function mglMetalCleanup

% get mgldir
mgldir = mglGetParam('mgllibDir');

% change directory
curdir = pwd;
cd(mgldir);

% get all recompiled filenames
compiledFiles = dir(fullfile(mgldir,'*.mexmaci64'));

% list of files that should be updated
metalList = {'mglText'};

% remove all other files
for iFiles = 1:length(compiledFiles)
  filename = compiledFiles(iFiles).name;
  if isfile(filename) && ~any(strcmp(stripext(filename),metalList))
    disp(sprintf('Restoring: %s',filename));
    system(sprintf('git restore %s',filename));
  end
end

cd(curdir);
