function [pos] = mglEyelinkGetCurrentEyePos(devicecord)

    if nargin < 1
        devicecord = 0;
    end

    pos = mglPrivateEyelinkGetCurrentSample();
    if devicecord
        pos(1) = pos(1)*mglGetParam('xPixelsToDevice');
        pos(2) = pos(2)*mglGetParam('yPixelsToDevice');
    end
    
end