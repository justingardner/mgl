%
%
%

function [] = mglEyelinkCMDPrintF(message, varargin)
%
%
%

    formattedMessage = sprintf(message, varargin{:});
    mglPrivateEyelinkCMDPrintF(formattedMessage);
    
end
