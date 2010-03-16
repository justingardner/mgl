%
%
%

function [] = mglEyelinkEDFPrintF(message, varargin)
%
%
%

    formattedMessage = sprintf(message, varargin{:});
    mglPrivateEyelinkEDFPrintF(formattedMessage);
    
end
