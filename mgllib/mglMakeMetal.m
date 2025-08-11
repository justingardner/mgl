% mglMakeMetal.m
%
%      usage: mglMakeMetal(rebuild)
%         by: justin gardner
%       date: 09/28/2021 Based on version from 05/04/06
%  copyright: (c) 2021 Justin Gardner(GPL see mgl/COPYING)
%    purpose: rebuilds mex file, with no arguments checks
%             dates to see whether it should rebuild. With
%             rebuild set to 1 removes all mex files for
%             the current platform and rebuilds. With a
%             single filename rebuilds that function
%       e.g.: mglMakeMetal
%             %To force rebuild
%             mglMakeMetal(1);
%             % to rebuild a single files
%             mglMakeMetal mglText.c
%
%             to make eyelink code
%             mglMakeMetal mglEyelink
%
%             to force remake of all eyelink code
%             mglMakeMetal mglEyelinkForce
%
function mglMakeMetal(varargin)

% process arguments, and return structure with info on running
info = processArgs(varargin);

% this gets the appropriate mex commad with all flags correctly specified
info = getMexCommand(info);

% loop over filenams
for iFile = 1:length(info.filenames)
  % create command to compile
  mexStr = sprintf('%s %s',info.mexCommand,info.filenames{iFile});
  % check to see if we have to compile
  if info.forceRebuild || testDateForCompile(info.filenames{iFile},info.mglHeaderFile)
    % display command string
    dispHeader(sprintf('Compiling %s',info.filenames{iFile}));
    disp(mexStr);
    try
      % and evaulate
      eval(mexStr);
      dispHeader(sprintf('Compilation SUCCESSFUL for %s',info.filenames{iFile}));
    catch
      [giveUp info] = processMexError(info,iFile);
      if giveUp,cd(info.curpwd);return,end
    end
  else
    disp(sprintf('(mglMakeMetal) File %s is up-to-date',info.filenames{iFile}));
  end
end

cd(info.curpwd);

%%%%%%%%%%%%%%%
% processArgs
%%%%%%%%%%%%%%%
function info = processArgs(args)

info.verbose = false;

% Gets the mgl header file mgl.h to compare the timestamps
% note that this will cd into the mgllib directory if it
% doesn't find the mgl.h file in the current directory
info.curpwd = pwd;
info.mglHeaderFile = getMGLHeaderFile;

% build only if out-of-date
info.forceRebuild = false;

% set mex flags
info.mexopts = '';

% whether to include eyelink frameworks or not.
info.includeEyelinkFrameworks = false;

% check for eyelink (allow a few different ways of specifying, including
% mglEyelink or eyelink and adding the word force to force compilation
if ~isempty(args) && any(strcmp(lower(args{1}), {'mgleyelink', 'eyelink', 'eyelinkforce','mgleyelinkforce','forceeyelink','forcemgleyelink'}))
    cd('mglEyelink');
    if ~isempty(strfind(lower(args{1}),'force'))
      info.forceRebuild = true;
    else
      info.forceRebuild = false;        
    end
    % set to mglEyelink so the code below works properly
    args{1} = 'mglEyelink';
    % set mex flags
    info.mexopts = '-R2018a';
    info.includeEyelinkFrameworks = true;
end

% if no arguments or the first argument is not a string, or building
% mglEyelink, then collect all c files in directory
if isempty(args) || isnumeric(args{1}) || strcmp(args{1}, 'mglEyelink')
  filenames = dir('*.c');
  info.filenames = {filenames.name};
  % check for rebuild
  if (length(args)>0) && isequal(args{1},1)
    info.forceRebuild = true;
  end
elseif isstr(args{1})
  % if a single string, then get the filename
  info.filenames{1} = args{1};
  % add extension if needed
  if isempty(getext(info.filenames{1}))
    info.filenames{1} = setext(info.filenames{1},'c');
  end
  % force reubuild
  info.forceRebuild = true;
end

% gets set to keep running after mex compilation error if user wants
info.continueAfterMexError = false;

%%%%%%%%%%%%%%%%%%%%%%
% testDateForCompile
%%%%%%%%%%%%%%%%%%%%%%
function tf = testDateForCompile(filename,mglHeaderFile)

tf = false;

% get the sourcefile info
sourcefile = dir(filename);
% see if it is already compiled
mexname = [stripext(filename) '.' mexext()];
mexfile = dir(mexname);
% mex the file if either there is no mexfile or
% the date of the mexfile is older than the date of the source file
tf =   (length(mexfile)<1) || ...
        (datenum(sourcefile.date) > datenum(mexfile.date)) || ...
        (datenum(mglHeaderFile.date) > datenum(mexfile.date));


%%%%%%%%%%%%%
% getMGLDir
%%%%%%%%%%%%%
function mglHeaderFile = getMGLHeaderFile

mglHeaderFile = dir('mgl.h');
if isempty(mglHeaderFile)
  % try to switch to the diretory where mglOpen lives
  mgldir = mglGetParam('mgllibDir');
  if ~isempty(mgldir) && exist(fullfile(mgldir,'mgl.h'), 'file') % test for header
    cd(mgldir);
    mglHeaderFile = dir('mgl.h');
  else
    mgldir = '';
    mglHeaderFile = '';
    return
  end
else
  mgldir = pwd;
end

%%%%%%%%%%%%%%%%%%%
% processMexError %
%%%%%%%%%%%%%%%%%%%
function [giveUp info] = processMexError(info, iFile);

% display error
err = lasterror;
disp(['(mglMakeMetal) Error compiling ' info.filenames{iFile}]);
disp(err.message);
disp(err.identifier);

% default to keep going
giveUp = false;

% display failure message
dispHeader(sprintf('Compilation FAILED for %s',info.filenames{iFile}));

% see if we should continue going or not
if ~info.continueAfterMexError
  % capture any lingering text output from system - this can
  % occur for example after a ctrl-c which leaves mex: interrupted around
  [a b] = system('');
  % ask user what to do if this is not the last file
  if iFile ~= length(info.filenames)
    r = askuser('(mglMakeMetal) Compilation failure. Do you want to continue compiling other files',1);
  else
    r = 0;
  end
  if isinf(r)
    info.continueAfterMexError = 1;
  elseif (r==0)
    giveUp = true;
  end
end


%%%%%%%%%%%%%%%%%
% getMexCommand %
%%%%%%%%%%%%%%%%%
function info = getMexCommand(info)

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
if info.includeEyelinkFrameworks
  cFlags=[cFlags '-I/Library/Frameworks/eyelink_core.framework/Headers  -I/Library/Frameworks/edfapi.framework/Headers '];
end

% and linker flags
%ldFlags=['-Wl,-twolevel_namespace -F/Library/Frameworks -undefined error -arch ' archs ' '];
%ldFlags=['-Wl,-twolevel_namespace -F/Library/Frameworks -arch ' cflag_arch ' '];
ldFlags=['-Wl,-twolevel_namespace,-rpath,/Library/Frameworks -F/Library/Frameworks -arch ' cflag_arch ' '];

% This specifies the matlab entrance point
tmw_root = matlabroot;
mapfile = 'mexFunction.map';
ldFlags=[ldFlags '-bundle -Wl,-exported_symbols_list,' tmw_root '/extern/lib/' extern_lib_arch '/' mapfile ' '];

% Specify the Mac frameworks
ldFlags=[ldFlags '-framework Carbon -framework Cocoa -framework CoreServices -framework openGL -framework CoreAudio'];
if info.includeEyelinkFrameworks
  ldFlags=[ldFlags ' -framework eyelink_core -framework edfapi'];
end

% mex options
mexopts = '';
if isfield(info,'mexopts')
  mexopts = info.mexopts;
end

% create mex commands
info.mexCommand = sprintf('mex %s CFLAGS=''%s'' LDFLAGS=''%s'' ',mexopts,cFlags,ldFlags);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% askuser.m
%
%      usage: askuser(question,<toall>,<useDialog>)
%         by: justin gardner
%       date: 02/08/06
%    purpose: ask the user a yes/no question. Question is a string or a cell arry of strings with the question. This
%             function will return 1 for yes and 0 for no. If toall is set to 1, then
%             'Yes to all' will be an option, which if selected will return inf
%
function r = askuser(question,toall,useDialog,verbose)

% check arguments
if ~any(nargin == [1 2 3])
  help askuser
  return
end

if ieNotDefined('toall'),toall = 0;,end
if ieNotDefined('useDialog'),useDialog=0;end
if ieNotDefined('verbose'),verbose=false;end

% if explicitly set to useDialog then use dialog, otherwise
% check verbose setting
if useDialog
  verbose = 1;
end

r = [];

question=cellstr(question); %convert question into a cell array


while isempty(r)
  % ask the question
  if ~verbose
    % not verbose, use text question
    %fprintf('\n');
    for iLine = 1:length(question)-1
      fprintf([question{iLine} '\n']);
    end
    if toall
      % ask the question (with option for all)
      r = input([question{end} ' (y/n or a for Yes to all)? '],'s');
    else
      % ask question (without option for all)
      r = input([question{end} ' (y/n)? '],'s');
    end
  else
    if toall
      % verbose, use dialog
      r = questdlg(question,'','Yes','No','All','Yes');
      r = lower(r(1));
    else
      r = questdlg(question,'','Yes','No','Yes');
      r = lower(r(1));
    end
  end
  % make sure we got a valid answer
  if (lower(r) == 'n')
    r = 0;
  elseif (lower(r) == 'y')
    r = 1;
  elseif (lower(r) == 'a') & toall
    r = inf;
  else
    r =[];
  end
end

% dispHeader.m
%
%        $Id:$
%      usage: dispHeader(header,<len=40>,<c='='>)
%         by: justin gardner
%       date: 04/22/11
%    purpose: displays a line of 60 characters as a header line, for example
%
%             >> dispHeader('header text')
%             ============= header text ==============
%
%             You can change the text length and or the separator character:
%             >> dispHeader('header text',20,'+')
%             +++ header text ++++
%
function retval = dispHeader(header,len,c)

% check arguments
if ~any(nargin == [0 1 2 3])
  help dispHeader
  return
end

% default header is just a full line
if nargin < 1, header = '';end

% default length
if (nargin < 2) || isempty(len),len = 60;end

% default separator character
if (nargin < 3) || isempty(c),c = '=';end

% get length of texgt
headerLen = length(header);

% if it is longer than the desired header length, then
% display two lines of separators one above and below the header
if (headerLen+2) >= len
  disp(repmat(c,1,len));
  disp(header)
  disp(repmat(c,1,len));
elseif headerLen == 0
  % if the header is empty, just display a full line
  disp(repmat(c,1,len));
else
  % otherwise put header inside separator characters
  fillerLen = ((len-(headerLen+2))/2);

  % display the first part
  disp(sprintf('%s %s %s',repmat(c,1,floor(fillerLen)),header,repmat(c,1,ceil(fillerLen))));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% removes file extension if it exists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function retval = stripext(filename,delimiter)

if ~any(nargin == [1 2])
  help stripext;
  return
end
% dot delimits end
if exist('delimiter', 'var')~=1
  delimiter='.';
end

retval = filename;
dotloc = findstr(filename,delimiter);
if ~isempty(dotloc)
  retval = filename(1:dotloc(length(dotloc))-1);
end

% getext.m
%
%      usage: getext(filename)
%         by: justin gardner
%       date: 02/08/05
%    purpose: returns extension if it exists
%
function retval = getext(filename,separator)

if ~any(nargin == [1 2])
  help getext;
  return
end

if ~exist('separator'),separator = '.';,end
retval = '';
dotloc = findstr(filename,separator);
if (length(dotloc) > 0) && (dotloc(length(dotloc)) ~= length(filename))
  retval = filename(dotloc(length(dotloc))+1:length(filename));
end
