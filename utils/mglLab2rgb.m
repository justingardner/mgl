function [rgb,xyz] = mglLab2rgb(Lab,calib)
%% MGLLAB2RGB
%
%   Input:
%    Lab - a nx3 matrix of L*a*b* coordinates (CIELAB)
%    calib - a myscreen.calib structure with a spectrum calibrated xyz2rgb
%            matrix
%
%   Output:
%    rgb - a nx3 matrix of RGB coordinates
%

if isempty(calib) || ~isfield(calib,'colors') || ~isfield(calib.colors,'XYZ2RGB')
    oneTimeWarning('noxyz2rgb','Calibration doesn''t include a calculated color conversion matrix for XYZ -> RGB. Try running moncalib with spectrum=1 and color=1. Returning matlab lab2rgb values which are *NOT CALIBRATED*');
    rgb = lab2rgb(Lab);
    return
end

if size(Lab,2)~=3
    warning('Lab input size is not nx3');
    return
end

rgb = zeros(size(Lab));
xyz = zeros(size(Lab));

for i = 1:size(Lab,1)
    xyz_ = lab2xyz(Lab(i,:));
    
    xyz(i,:) = xyz_;
end

rgb = calib.colors.XYZ2RGB*xyz';
rgb = rgb';