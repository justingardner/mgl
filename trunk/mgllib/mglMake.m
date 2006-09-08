% mglMake.m
%
%        $Id$
%      usage: mglMake(rebuild)
%         by: justin gardner
%       date: 05/04/06
%    purpose: rebuilds mex file, with no arguments checks
%             dates to see whether it should rebuild. With
%             rebuild set to 1 removes all mex files for
%             the current platform and ebuilds
%    
%
function retval = mglMake(rebuild)

% check arguments
if ~any(nargin == [0 1])
  help mglRebuild
  return
end

if ~exist('rebuild','var'),rebuild = 0;end

% remove all mex files if called for
if rebuild
  delete(sprintf('*.%s',mexext));
end

% make sure we have the mgl.h file--this will make
% sure we are in the correct directory
hfile = dir('mgl.h');
if (length(hfile) == 0)
  % try to switch to the diretory where mglOpen lives
  mgldir = fileparts(which('mglOpen'));
  if ~isempty(mgldir)
    cd(mgldir);
    hfile = dir('mgl.h');
  else
    disp(sprintf('(mglMake) Could not find source files'));
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
    if (length(mexfile)<1) || (datenum(mgldir(i).date) > datenum(mexfile(1).date)) || (datenum(hfile(1).date) > datenum(mexfile(1).date))
      disp(sprintf('mex %s',mgldir(i).name));
      eval(sprintf('mex %s',mgldir(i).name));
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
if exist('delimiter')~=1,delimiter='.';,end

retval = filename;
dotloc = findstr(filename,delimiter);
if length(dotloc) > 0
  retval = filename(1:dotloc(length(dotloc))-1);
end
