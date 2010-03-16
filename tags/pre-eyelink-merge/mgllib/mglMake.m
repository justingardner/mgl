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
%
function retval = mglMake(rebuild)

% check arguments
if ~any(nargin == [0 1])
  help mglRebuild
  return
end

% interpret rebuild argument
useCarbon = 0;useCocoa = 0;
if ~exist('rebuild','var')
  rebuild = 0;
elseif isequal(rebuild,'carbon')
  useCarbon = 1;
  useCocoa = 0;
  rebuild = 1;
elseif isequal(rebuild,'cocoa')
  useCocoa = 1;
  useCarbon = 0;
  rebuild = 1;
elseif isequal(rebuild,'digio')
  makeDigIO(1);
  return
end

thisPath = pwd;
makeMGL(rebuild,useCocoa,useCarbon);
cd(thisPath);

%%%%%%%%%%%%%%%%%
%%   makeMGL   %%
%%%%%%%%%%%%%%%%%
function makeMGL(rebuild,useCocoa,useCarbon)

% if we find the mglPrivateListener, then shut it down
% to avoid crashing
if rebuild >= 2
  if exist('mglPrivateListener')==3,mglListener('quit');end
  if exist('mglPrivatePostEvent')==3,mglPrivatePostEvent(0);end

  % close all open displays
  mglSwitchDisplay(-1);
end

% clear the MGL global
clear global MGL;

% make sure we have the mgl.h file--this will make
% sure we are in the correct directory
hfile = dir('mgl.h');
if isempty(hfile)
  % try to switch to the diretory where mglOpen lives
  mgldir = mglGetParam('mgllibDir');
  if ~isempty(mgldir)
    cd(mgldir);
    hfile = dir('mgl.h');
  else
    return
  end
end

% get the files in the mgldir
mgldir = dir('*.c');

for i = 1:length(mgldir)
  if (~strcmp('.#',mgldir(i).name(1:2)))
    % see if it is already compiled
    mexname = [stripext(mgldir(i).name) '.' mexext];
    mexfile = dir(mexname);
    % mex the file if either there is no mexfile or
    % the date of the mexfile is older than the date of the source file
    if (rebuild || length(mexfile)<1) || (datenum(mgldir(i).date) > datenum(mexfile(1).date)) || (datenum(hfile(1).date) > datenum(mexfile(1).date))
      if useCarbon
	command = sprintf('mex -D__carbon__ %s',mgldir(i).name);
      elseif useCocoa
	command = sprintf('mex -D__cocoa__ %s',mgldir(i).name);
      else
	command = sprintf('mex %s',mgldir(i).name);
      end
      % display the mex command
      disp(command);
      % now run it, catching an errors
      try
	eval(command);
      catch
	disp(['Error compiling ' mgldir(i).name]);
      end
    else
      disp(sprintf('%s is up to date',mgldir(i).name));
    end    
  end
end

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
% fing the mgl digio directory
mgldir = mglGetParam('mglDigioDir');
if ~isempty(mgldir)
  cd(fullfile(mgldir));
  hfile = dir('mgl.h');
else
  return
end

% get the files in the utils dir
mgldir = dir('*.c');

for i = 1:length(mgldir)
  if (~strcmp('.#',mgldir(i).name(1:2)))
    % see if it is already compiled
    mexname = [stripext(mgldir(i).name) '.' mexext];
    mexfile = dir(mexname);
    % mex the file if either there is no mexfile or
    % the date of the mexfile is older than the date of the source file
    if (rebuild || length(mexfile)<1) || (datenum(mgldir(i).date) > datenum(mexfile(1).date)) || (datenum(hfile(1).date) > datenum(mexfile(1).date))
      command = sprintf('mex %s',mgldir(i).name);
      % display the mex command
      disp(command);
      % now run it, catching an errors
      try
	eval(command);
      catch
	disp(['Error compiling ' mgldir(i).name]);
      end
    else
      disp(sprintf('%s is up to date',mgldir(i).name));
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
if exist('delimiter', 'var')~=1,delimiter='.';end

retval = filename;
dotloc = findstr(filename,delimiter);
if ~isempty(dotloc)
  retval = filename(1:dotloc(length(dotloc))-1);
end