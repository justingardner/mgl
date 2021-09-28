% mglMetalExecutableName: Returns the name of the mglMetal application
%
%        $Id$
%      usage: mglMetalExecutableName
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns the name of the mglMetal application
%      usage: mglAppName = mglMetalExecutableName;
%
function [metalAppName metalDir] = mglMetalExecutableName

mglAppName = '';
metalDir = '';

% find where the runtime is (why is this so hard with xcode?)
mglSearchDir = '~/Library/Developer/XCode/DerivedData/mglMetal*';
mglDir = dir(mglSearchDir);
if isempty(mglSearchDir)
  disp(sprintf('(mglOpen) Could not find mglMetal executable in %s. Perhaps you need to compile in XCode',mglSearchDir))
  return
end
mglDir = fullfile(mglDir(1).folder,mglDir(1).name);
mglDir = fullfile(mglDir,'Build','Products','Release');
metalAppName = fullfile(mglDir,'mglMetal.app');
if ~isdir(metalAppName)
  disp(sprintf('(mglOpen) Could not find mglMetal executable in %s. Perhaps you need to compile in XCode',metalAppName))
  return
end

%get directory where mglMetal app runs from
metalDir = '~/Library/Containers/gru.mglMetal/Data';
if ~isdir(metalDir)
    disp(sprintf('(mglMetalTest) Please compile the mglMetal app which should create the dir: %s',metalDir));
    while ~isdir(metalDir)
    end
end
