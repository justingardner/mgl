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
function [metalAppName, metalDir] = mglMetalExecutableName

metalAppName = '';
metalDir = '';

% Search xCode for the mglMetal build output. (why is this so hard with xcode?)
xCodeOutputPath = '~/Library/Developer/XCode/DerivedData/';
xCodeOutputDir = dir(xCodeOutputPath);
if isempty(xCodeOutputDir)
    fprintf('(mglOpen) Could not find mglMetal executable in %s. Perhaps you need to compile in XCode\n',xCodeOutputPath)
    return
end

% Choose the most recent "mglMetal-" build dir.
isMglMetal = cellfun(@(s)startsWith(s, "mglMetal-"), {xCodeOutputDir.name});
mglMetalDirs = xCodeOutputDir(isMglMetal);
[~, sortedIndexes] = sort([mglMetalDirs.datenum]);
mglMetalDir = mglMetalDirs(sortedIndexes(end));

% Get the full absolute path to the most recent mglMetal app.
mglProductsPath = fullfile(mglMetalDir.folder, mglMetalDir.name, 'Build','Products');
debugAppName = fullfile(mglProductsPath, 'Debug', 'mglMetal.app');
releaseAppName = fullfile(mglProductsPath, 'Release', 'mglMetal.app');
if isfolder(debugAppName)
    metalAppName = debugAppName;
    fprintf('(mglOpen) Found Debug build of mglMetal: %s\n',metalAppName)
elseif isfolder(releaseAppName)
        metalAppName = releaseAppName;
    fprintf('(mglOpen) Found Release build of mglMetal: %s\n',metalAppName)
else
    fprintf('(mglOpen) Could not find mglMetal in %s. Perhaps you need to compile in XCode\n',mglProductsPath)
    return
end

% Get working directory where mglMetal app runs from.
% This seems to be a macOs/xCode convention, so good to use this during
% development.
% Once stable, we may be able to choose any dir to run from?
metalDir = '~/Library/Containers/gru.mglMetal/Data';
if ~isfolder(metalDir)
    fprintf('(mglMetalTest) Please compile the mglMetal app which should create the dir: %s\n',metalDir);
    return
end

% Reolve absoulte path to the same metalDir
metalDirInfo = dir(metalDir);
metalDir = fullfile(metalDirInfo(1).folder);
