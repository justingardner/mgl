function [pos] = mglEyelinkGetCurrentEyePos(devicecord)

    if nargin < 1
        devicecord = 1;
    end

    pos = mglPrivateEyelinkGetCurrentSample();
    if ~isempty(pos) && devicecord
        pos(1) = (pos(1)-(mglGetParam('screenWidth')/2))*mglGetParam('xPixelsToDevice');
        pos(2) = ((mglGetParam('screenHeight')/2)-pos(2))*mglGetParam('yPixelsToDevice');
    end
    
end