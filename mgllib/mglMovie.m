% mglMovie.m
%
%        $Id: mglMovie.m,v 1.1 2007/10/23 22:21:23 justin Exp $
%      usage: movieStruct = mglMovie(filename,position) or mglMovie(movieStruct,command,<argument>);
%         by: justin gardner
%       date: 12/23/08
%    purpose: Used to display quicktime movies. This *only* works on 64 bit mac for now.
%             (There is some issue with the quicktime library QTKit and threads which
%             does not seem to be a problem on 64 bit). 
%
%             Also, note that the movies will play in front of the openGL buffer. Thus
%             you can't draw on top of the movie and mglFrameGrab won't grab the movie
%             frame -- you can grab movie frames with mglMovie(m,'getFrame');
%
%             To init the movie, you open with a filename, and an optional position
%             array and save the returned structure.
%
%             m = mglMovie('movie.mov');
%
%             Then you can run commands on the movie:
%
%             mglMovie(m,'play');
%
%             If no position is specified, the movie will be made to fill the display. 
%             Then pass in the structure with any of the following commands:
%
%             0:'close" - Close the movie. After you run this, you will no longer be
%                         able to play the movieStruct again since the memory will have
%                         been released.
%             1:'play' Play the movie
%             2:'pause' Pause the movie
%             3:'gotoBeginning' Goto the beginning of the movie
%             4:'gotoEnd' Goto the end of the movie
%             5:'stepForward' Step one frame forward in the mvoie
%             6:'stepBackward' Step one frame backward in the movie
%             7:'hide' Hide the movie. This does not close the movie, so you will
%                      be able to show the movieStruct again by using show.
%             8:'show' Show the movie after it has been hidden
%             9:'getDuration' Get a string that represents the length of the movie
%            10:'getCurrentTime' Gets the current time of the movie
%            11:'setCurrentTime' Sets the current time of the movie to the string
%                      passed in. Make sure the string is one returned from getCurrentTime
%            12:'getFrame' Returns a nxmx3 matrix containing RGB data for current frame
%
%mglOpen(0);
%m = mglMovie('bosque.mov');
%mglMovie(m,'play');
function movieStruct = mglMovie(varargin)

movieStruct = [];
% check arguments
if ~any(nargin == [1 2 3 4])
  help mglMovie;
  return
end

% check for open display
if mglGetParam('displayNumber') == -1
  disp(sprintf('(mglMovie) You must use mglOpen to open a display before using this command'));
  return
end

% list of commands and descriptions
validCommands = {'close','play','pause','gotobeginning','gotoend','stepforward','stepbackward','hide','show','getduration','getcurrenttime','setcurrenttime','getframe'};
		 
% see if it is an init with filename
if isstr(varargin{1})
  % get the filename
  filename = varargin{1};
  % see if we have a position
  if length(varargin) < 2
    position = [0 0 mglGetParam('screenWidth') mglGetParam('screenHeight')];
  elseif isvector(varargin{2})
    position = [0 0 mglGetParam('screenWidth') mglGetParam('screenHeight')];
    if length(varargin{2}) >= 1,position(1) = varargin{2}(1);,end
    if length(varargin{2}) >= 2,position(2) = varargin{2}(2);,end
    if length(varargin{2}) >= 3,position(3) = varargin{2}(3);,end
    if length(varargin{2}) >= 4,position(4) = varargin{2}(4);,end
  end
  % create the movie structure
  movieStruct = mglPrivateMovie(filename,position);
  % if we got a non-empty
  if ~isempty(movieStruct)
    % add it to global registration
    movieStructs = mglGetParam('movieStructs');
    movieStructs{end+1} = movieStruct;
    mglSetParam('movieStructs',movieStructs);
    % set the id of the movieStruct
    movieStruct.id = length(movieStructs);
    % tack on filename to structure
    movieStruct.filename = filename;
  end
  return;
end

% movie struct passed in, run command
if isstruct(varargin{1})
  m = varargin{1};
  % check for movie struct
  if ~isfield(m,'moviePointer')
    disp(sprintf('(mglMovie) Passed in structure is not a movie'));
    help mglMovie;
    return
  end
  % check for command
  if (length(varargin) < 2)
    disp(sprintf('(mglMovie) No command passed in'));
    return
  end
  % convert string commands
  if isstr(varargin{2})
    command = find(strcmp(lower(varargin{2}),validCommands));
    if isempty(command)
      disp(sprintf('(mglMovie) Unrecogonized command %s',varargin{2}));
      return
    end
    % commands start at 0
    command = command-1;
  elseif isscalar(varargin{2})
    command = floor(varargin{2});
  else
    disp(sprintf('(mglMovie) Unrecogonized command'));
    return
  end
  % now check to see if object is registered in global
  movieStructs = mglGetParam('movieStructs');
  if (length(movieStructs) < m.id) || isempty(movieStructs{m.id}) || (movieStructs{m.id}.moviePointer ~= m.moviePointer)
    disp(sprintf('(mglMovie) Movie struct is no longer valid (either it has been closed or it was made for a different display)'));
    return
  end
    
  % run the command
  if any(command == [11])
    if nargin < 3
      % commands with a single argument
      disp(sprintf('(mglMovie) Command %s needs another argument',validCommands{command+1}));
      return;
    else
      retval = mglPrivateMovie(m,command,varargin{3});
    end
  else
    % commands with no arguments
    retval = mglPrivateMovie(m,command);
  end
  % if command was a close, then remove struct from global
  if command == 0
    movieStructs = mglGetParam('movieStructs');
    movieStructs{m.id} = [];
    mglSetParam('movieStructs',movieStructs);
  end
  % return any return value
  if ~isempty(retval),movieStruct = retval;end
end 




