function mglEyelinkEDFOpen(filename)
%   MGLEYELINKOPENEDF   Opens an edf file on the Eyelink computer for writing
%     [] = MGLEYELINKOPENEDF(FILENAME)
% 
%   Opens a file on the Eyelink computer for writing data. The filename must
%   be a valid DOS filename
%    
%   Created by Eric DeWitt on 2010-03-25.
%   Copyright (c)  Eric DeWitt. All rights reserved.

% Make sure a filename was passed.
if nargin ~= 1
  fprintf(2, '(mglEyelinkEDFOpen) A filename must be provided.');
  return;
end

% Make sure the filename is actually a string.  A string is defined as a
% row vector of characters.
if ~ischar(filename) || ndims(filename) ~= 2 || size(filename, 1) ~= 1
  fprintf(2, '(mglEyelinkEDFOpen) filename must be a row vector of characters, i.e. a string.');
  return;
end

% Make sure the length of the filename is DOS compatible.
if length(filename) > 8
  fprintf(2, '(mglEyelinkEDFOpen) Invalid DOS filename. Filename must be under 8 characters.');
  return;
end

mglPrivateEyelinkEDFOpen(filename);
