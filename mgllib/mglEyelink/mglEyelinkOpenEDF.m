function  mglEyelinkOpenEDF(filename)
%   MGLEYELINKOPENEDF   Opens an edf file on the Eyelink computer for writing
%     [] = MGLEYELINKOPENEDF(FILENAME)
% 
%   Opens a file on the Eyelink computer for writing data. The filename must
%   be a valid DOS filename
%    
%   Created by Eric DeWitt on 2010-03-25.
%   Copyright (c)  Eric DeWitt. All rights reserved.

  % check for filename valididty. This could be more robust
  if numel(filename) > 8
    fprintf(2,'(mglEyelinkOpenEDF) Invalid DOS filename. Filename must be under 8char.');
    return;
  end
  mglPrivateEyelinkOpenEDF(filename);

end %  function