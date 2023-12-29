% mglMakeSocket.m
%
%      usage: mglMakeSocket(rebuild)
%         by: Ben Heasly
%  copyright: (c) 2021 Justin Gardner(GPL see mgl/COPYING)
%    purpose: rebuild socket-related mex-functions.
%
function mglMakeSocket()

% Decide what to build.
socketDir = fileparts(which('mglMakeSocket.m'));
socketSrc = dir([socketDir, '/*.c']);
socketSrcFiles = {socketSrc.name};
mexCommandPrefix = getMexCommand();

oldPwd = pwd();
restorePwd = onCleanup(@() cd(oldPwd));
cd(socketDir);

% loop over filenams
for iFile = 1:length(socketSrcFiles)
    srcFile = socketSrcFiles{iFile};
    fprintf('\nBuilding %s\n\n', srcFile);

    mexStr = sprintf('%s %s', mexCommandPrefix, srcFile);
    disp(mexStr);
    eval(mexStr);
end

function mexCommand = getMexCommand

% choose build flags that depend on Mac hardware
if strcmp(mexext(), 'mexmaca64')
    % Apple silicon
    cflag_arch = 'arm64';
    extern_lib_arch = 'maca64';
else
    % Intel
    cflag_arch = 'x86_64';
    extern_lib_arch = 'maci64';
end

% setup compilation flags
cFlags=['-x objective-c -fno-common -no-cpp-precomp -arch ' cflag_arch ' -Wno-deprecated-declarations -Wno-deprecated -Wno-implicit-function-declaration '];

% and linker flags
ldFlags=['-Wl,-twolevel_namespace -undefined error -arch ' cflag_arch ' '];

% This specifies the matlab entrance point
tmw_root = matlabroot;
mapfile = 'mexFunction.map';
ldFlags=[ldFlags '-bundle -Wl,-exported_symbols_list,' tmw_root '/extern/lib/' extern_lib_arch '/' mapfile ' '];

% Specify the Mac frameworks
ldFlags=[ldFlags '-framework CoreServices '];

mglPath = fileparts(which('mgl.h'));
mglCommandTypesPath = fileparts(which('mglCommandTypes.h'));
mexopts = sprintf('-I%s -I%s', mglPath, mglCommandTypesPath);

% create mex commands
mexCommand = sprintf('mex %s CFLAGS=''%s'' LDFLAGS=''%s'' ', mexopts, cFlags, ldFlags);

