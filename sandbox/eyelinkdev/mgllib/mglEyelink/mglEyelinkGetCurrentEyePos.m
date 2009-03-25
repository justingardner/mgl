function [pos] = mglEyelinkGetCurrentEyePos(devicecord)

    if nargin < 1
        devicecord = 0;
    end
    
    sample = mglPrivateEyelinkGetCurrentSample();
    if ~isempty(sample)
        if devicecord
            pos(1) = (sample(1)-(mglGetParam('screenWidth')/2))*mglGetParam('xPixelsToDevice');
            pos(2) = ((mglGetParam('screenHeight')/2)-sample(2))*mglGetParam('yPixelsToDevice');
        else
            pos(1) = sample(1);
            pos(2) = sample(2);
        end
    else
        pos = [NaN NaN];
    end
    
end