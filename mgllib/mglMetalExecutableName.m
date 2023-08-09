% mglMetalExecutableName: Returns the full path to the mglMetal.app bundle.
%
%        $Id$
%      usage: mglMetalExecutableName
%         by: justin gardner
%       date: 09/27/2021
%  copyright: (c) 2021 Justin Gardner (GPL see mgl/COPYING)
%    purpose: Returns the full path of the mglMetal.app application
%             and also the name of the "sandbox" directory that the app
%             has access to.
%      usage: [mglMetalApp, mglMetalSandbox] = mglMetalExecutableName
%
function [mglMetalApp, mglMetalSandbox] = mglMetalExecutableName

% The mglMetal app should live within the mgl repo, just like the mex-function binaries do.
mglDir = fileparts(fileparts(which('mglOpen')));


% Use the "latest" development version if present, otherwise use the "stable" version.
latestAppDir = fullfile(mglDir, 'metal', 'binary', 'latest', 'mglMetal.app');
if isfolder(latestAppDir)
    mglMetalApp = latestAppDir;
else
    mglMetalApp = fullfile(mglDir, 'metal', 'binary', 'stable', 'mglMetal.app');
end

% Check to see if there is a newer version in the default debug build pathway
% so that developers can compile and check before deploying 
debugMetalApp = '~/Library/Developer/Xcode/DerivedData/Build/Products/Debug/mglMetal.app';
if isdir(debugMetalApp)
  % check date on the build
  executableName = 'Contents/MacOS/mglMetal';
  if isfile(fullfile(debugMetalApp,executableName)) && isfile(fullfile(mglMetalApp,executableName))
    % get info on the two apps, to compare timestamps
    debugMetalAppInfo = dir(fullfile(debugMetalApp,executableName));
    metalAppInfo = dir(fullfile(mglMetalApp,executableName));
    % compare the timestamps
    if (debugMetalAppInfo.datenum > metalAppInfo.datenum)
      fprintf('(mglMetalExecutableName) Debug app %s has a newer timestamp than %s\n',debugMetalApp,mglMetalApp);
      % swap to use the debug app
      mglMetalApp = debugMetalApp;
    else
      fprintf('(mglMetalExecutableName) Default app %s has a newer timestamp than %s\n');
    end
  end
end


% print what version we are using
fprintf('(mglMetalExecutableName) Using mglMetal app at %s\n', mglMetalApp);

% The mglMetal app runs in a "sandbox" with limited file system access.
% We don't need this, but it seems like a reasonable idea to go along with.
% The sandbox is in your user folder, with a name based on the app's id.
% The id is the "PRODUCT_BUNDLE_IDENTIFIER" in the Xcode project.
% The same id gets written into the mglMetal.app at, for example:
%   mgl/metal/binary/stable/mglMetal.app/Contents/Info.plist
% We could parse out the "CFBundleIdentifier" from here if we need to.
% But the value seems unlikely to change, so for now here it is.
mglMetalAppId = 'gru.mglMetal';
homeDirInfo = dir('~');
homeDir = homeDirInfo(1).folder;
mglMetalSandbox = fullfile(homeDir, 'Library', 'Containers', mglMetalAppId, 'Data');
