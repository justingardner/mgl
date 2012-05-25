% mglMake.m
%
%        $Id$
%      usage: mglMake(rebuild)
%         by: justin gardner
%       date: 05/04/06
%  copyright: (c) 2006 Justin Gardner, Jonas Larsson (GPL see mgl/COPYING)
%    purpose: rebuilds mex file, with no arguments checks
%             dates to see whether it should rebuild. With
%             rebuild set to 1 removes all mex files for
%             the current platform and rebuilds
%
%             If rebuild is set to 'carbon' then it will rebuild mac files using only carbon
%             function calls (obsolete in 64bit Mac os). If set to 'cocoa' will build using
%             cocoa (the default).
%
%             To build digital I/O code (which requires the NI NIDAQ MX-base library), set
%             rebuild to 'digio'
%
%             To build eyelink code (which requires the eyelink developers kit), set
%             rebuild to 'eyelink'
%                  
%             You can pass arbitrary command line options to the mex
%             compilation after the first argument. (If the first argument is
%             not one of the commands listed above it will also be treated  as
%             a command line option.) Command line options must begin with a '-'.
%
function retval = mglMake(rebuild, varargin)

% check arguments
if any(nargin > 10) % arbitrary...
  help mglMake
  return
end

% interpret rebuild argument
digio = 0;eyelink = 0;
if ~exist('rebuild','var')
  rebuild=0;
  [s,r] = system('uname -r');
  osmajorver = str2num(strtok(r,'.'));
  if ismac() && osmajorver < 9
    varargin = {'-D__carbon__', varargin{:}};
    fprintf(2,'(mglMake) Defaulting to carbon')
  end            
else
  if isequal(rebuild,1) || isequal(rebuild,'rebuild')
    rebuild = 1;
  elseif isequal(rebuild,'carbon')
    varargin = {'-D__carbon__', varargin{:}};
    rebuild = 1;
  elseif isequal(rebuild,'cocoa')
    varargin = {'-D__cocoa__', varargin{:}};
    rebuild = 1;
  elseif isequal(lower(rebuild),'digio')
    rebuild = 0;
    digio = 1;
  elseif isequal(lower(rebuild),'eyelink')
    rebuild = 0;
    eyelink = 1;
  elseif ischar(rebuild) && isequal(rebuild(1), '-')
    varargin = {rebuild, varargin{:}};
    rebuild=0;
  else
    help mglMake
    return
  end
end
for nArg = 1:numel(varargin)
  if ischar(varargin{nArg}) && isequal(varargin{nArg}(1), '-')
    arg(nArg).name = varargin{nArg};
  elseif isequal(lower(varargin{nArg}),'digio')
    digio = true;
  elseif isequal(lower(varargin{nArg}),'eyelink')
    eyelink = true;
  else
    error('Attempted to pass an argument that is not a mex option.');
  end
end

% Select the mex options file and set any compile parameters based on the
% operating system and version.
if ismac
  [dumpvar,result] = system('system_profiler SPSoftwareDataType');
  sysinfo = regexp(result, 'Mac OS X 10.(?<ver>\d?)', 'names');
  if str2double(sysinfo.ver) >= 7 % >= lion
    % now check where the SDKs live. If they are in /Developer
    if isdir('/Developer/SDKs/MacOSX10.6.sdk')
      optf = '-f ./mexopts.sh';
    elseif isdir('/Developer/SDKs/MacOSX10.7.sdk')
      optf = '-f ./mexopts.10.7.sh';
    elseif isdir('/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.7.sdk')
      optf = '-f ./mexopts.10.7.xcode.4.3.sh';
    else
      disp(sprintf('(mglMake) !!! Could not find MacOSX sdk. Have you installed XCode? !!!'));
      return
    end
  else
    optf = '-f ./mexopts.10.5.sh';
  end
elseif ispc
  % We don't use a special options file.  The required libraries are set in
  % mgl.h and compile flags are set here.  The default mex setup file
  % should fill in the rest.
  optf = '-largeArrayDims COMPFLAGS="$COMPFLAGS /TP"';
end

% close all open displays
mglSwitchDisplay(-1);

% clear the MGL global
clear global MGL;

lastPath = pwd;
% make sure we have the mgl.h file--this will make
% sure we are in the correct directory
hfile = dir('mgl.h');
if isempty(hfile)
  % try to switch to the diretory where mglOpen lives
  mgldir = mglGetParam('mgllibDir');
  if ~isempty(mgldir) && exist(fullfile(mgldir,'mgl.h'), 'file') % test for header
    cd(mgldir);
    hfile = dir('mgl.h');
  else
    return
  end
else
  mgldir = pwd;
end

% set directories to check for mex files to compile
if eyelink
  mexdir{1} = fullfile(mgldir, 'mglEyelink');
else
  mexdir{1} = mgldir;
end

if ~digio
  for nDir = 1:numel(mexdir)
    % get the files in the mexdir
    cd(mexdir{nDir});
    sourcefile = dir('*.c');
    for i = 1:length(sourcefile)
      % check to make sure this is not a temp file
      if (~strcmp('.#',sourcefile(i).name(1:2)))
    % see if it is already compiled
    mexname = [stripext(sourcefile(i).name) '.' mexext];
    mexfile = dir(mexname);
    % mex the file if either there is no mexfile or
    % the date of the mexfile is older than the date of the source file
    if (rebuild || length(mexfile)<1) || ...
          (datenum(sourcefile(i).date) > datenum(mexfile(1).date)) || ...
          (datenum(hfile(1).date) > datenum(mexfile(1).date))
      command = sprintf('mex %s ', optf);
      if exist('arg', 'var') && isfield(arg, 'name');
        command = [command sprintf('%s ',arg.name)];
      end
      command = [command sprintf('%s',sourcefile(i).name)];
      % display the mex command
      disp(command);
      % now run it, catching an errors
      try
        eval(command);
      catch
        err = lasterror;
        disp(['Error compiling ' sourcefile(i).name]);
        disp(err.message);
        disp(err.identifier);
      end
    else
      disp(sprintf('%s is up to date',sourcefile(i).name));
    end    
      end
    end
  end
else 
  makeDigIO(rebuild);
end
cd(lastPath);

%%%%%%%%%%%%%%%%%%%
%%   makeDigIO   %%
%%%%%%%%%%%%%%%%%%%
function makeDigIO(rebuild)

% check for compiled digIO stuff
if ~isdir('/Library/Frameworks/nidaqmxbase.framework')
  if strcmp(questdlg('You do not have the directory /Library/Frameworks/nidaqmxbase.framework, which suggests that you do not have the NIDAQ libraries installed. To run mglDigIO, you will need to install NI-DAQmx Base from http://sine.ni.com/nips/cds/view/p/lang/en/nid/14480 and then mglDigIO should work with your NI card. If you think you are getting this warning in error, then hit ''Ignore and mex mglDigIO anyway'' and the program will try to compile the dig io code, but will likely crash because the libraries are not installed on your system','NI-DAQmx Base is missing','Cancel','Ignore and mex mglDigIO anyway','Cancel'),'Cancel')
    return
  end
end

% make sure we have the mgl.h file--this will make
% sure we are in the correct directory
mgldir = mglGetParam('mgllibDir');
if ~isempty(mgldir) && exist(fullfile(mgldir,'mgl.h'), 'file') % test for header
  cd(mgldir);
  hfile = dir('mgl.h');
else
  return
end

% fing the mgl digio directory
mgldiodir = mglGetParam('mglDigioDir');
if ~isempty(mgldiodir)
  cd(mgldiodir);
else
  return
end

% get the files in the utils dir
mgldiodir = dir('*.c');

for i = 1:length(mgldiodir)
  if (~strcmp('.#',mgldiodir(i).name(1:2)))
    % see if it is already compiled
    mexname = [stripext(mgldiodir(i).name) '.' mexext];
    mexfile = dir(mexname);
    % mex the file if either there is no mexfile or
    % the date of the mexfile is older than the date of the source file
    if (rebuild || length(mexfile)<1) || (datenum(mgldiodir(i).date) > datenum(mexfile(1).date)) || (datenum(hfile(1).date) > datenum(mexfile(1).date))
      command = sprintf('mex %s',mgldiodir(i).name);
                 % display the mex command
                 disp(command);
                 % now run it, catching an errors
                 try
                   eval(command);
                 catch
                   disp(['Error compiling ' mgldiodir(i).name]);
                 end
    else
      disp(sprintf('%s is up to date',mgldiodir(i).name));
    end    
  end
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

