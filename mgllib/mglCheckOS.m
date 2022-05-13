% mglCheckOS
%
%      usage: mglCheckOS(majorVersion,minorVersion)
%         by: justin gardner
%       date: 05/13/2022
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: Checks os version and returns t/f if equal or better to
%    arguments. Will also set mglGetParams to have the version of the os
%    and matlab
%      usage: tf = mglCheckOS
% e.g.
% if mglCheckOS(10,15)
%    disp('pass');
%end
function tf = mglCheckOS(majorVersion,minorVersion)

% check arguments
if ~any(nargin == [0])
  help mglCheckOS
  return
end

% these are the versions needed
majorVersionNeeded = 10;
minorVersionNeeded = 15;
matlabMajorVersionNeeded = 9;
matlabMinorVersionNeeded = 3;

% default to false
tf = false;

% check for mac
if ~ismac
  disp(sprintf('(mglCheckOS) mgl is only supported on macOS'));
  return
end

if isempty(mglGetParam('macOSMajorVersion'))
  % check for os version
  [status, result] = unix('sw_vers');
  if status~=0
    disp(sprintf('(mglOpen) Could not determine OS version.'));
    return
  end
  % look for os version
  osVersion = [];
  resultSplit = split(result);
  for iResult = 1:length(resultSplit)
    if contains(lower(resultSplit{iResult}),'productversion') && (length(resultSplit)>iResult)
      osVersion = resultSplit{iResult+1};
    end
  end
  if isempty(osVersion)
    disp(sprintf('(mglCheckOS) Could not determine OS version'));
    return
  end
  % get the version
  versionNum = split(osVersion,'.');
  if length(versionNum)<2
    disp(sprintf('(mglCheckOS) Could not determine OS version.'));
    return
  end
  majorVersion = str2num(versionNum{1});
  minorVersion = str2num(versionNum{2});
  mglSetParam('macOSMajorVersion',majorVersion);
  mglSetParam('macOSMinorVersion',minorVersion);
else
  majorVersion = mglGetParam('macOSMajorVersion');
  minorVersion = mglGetParam('macOSMinorVersion');
end

% get matlab major version
if isempty(mglGetParam('matlabMajorVersion'))
  % set version of matlab
  vInfo = ver('MATLAB');
  [matlabMajorVersion theRest] = strtok(vInfo.Version,'.');
  [matlabMinorVersion theRest] = strtok(theRest,'.');
  matlabMajorVersion = str2num(matlabMajorVersion);
  matlabMinorVersion = str2num(matlabMinorVersion);
  mglSetParam('matlabMajorVersion',matlabMajorVersion);
  mglSetParam('matlabMinorVersion',matlabMinorVersion);
else
  matlabMajorVersion = mglGetParam('matlabMajorVersion');
  matlabMinorVersion = mglGetParam('matlabMinorVersion');
end

% check mac os version
if (majorVersion > majorVersionNeeded) || ((majorVersion == majorVersionNeeded) && (minorVersion >= minorVersionNeeded))
    % check matlab version
    if (matlabMajorVersion > matlabMajorVersionNeeded) || ((matlabMajorVersion == matlabMajorVersionNeeded) && (matlabMinorVersion >= matlabMinorVersionNeeded))
        tf = true;
    else
      disp(sprintf('(mglCheckOS) mglMetal needs matlab version %i.%i or greater (yours is: %i.%i)',matlabMajorVersionNeeded,matlabMinorVersionNeeded,matlabMajorVersion,matlabMinorVersion));
    end
else
  disp(sprintf('(mglCheckOS) mglMetal needs macOS version %i.%i or greater (yours is: %i.%i)',majorVersionNeeded,minorVersionNeeded,majorVersion,minorVersion));
end
