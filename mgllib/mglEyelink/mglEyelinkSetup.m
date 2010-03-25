function  = mglEyelinkSetup(displaycontext)
%   MGLEYELINKSETUP   Enters the Eyelink setup mode [] =
%     MGLEYELINKSETUP(DISPLAYCONTEXT)
% 
%   Switch into the EyeLink setup mode (for camera setup, calibration,
%   validation, etc.).
%    
%   Created by Eric DeWitt on 2010-03-25.
%   Copyright (c)  Eric DeWitt. All rights reserved.

  % TODO: add MGL screen/context handling
  
  mglPrivateEyelinkCalibration();

end %  function