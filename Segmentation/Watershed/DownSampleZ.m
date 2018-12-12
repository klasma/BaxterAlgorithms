function oStack = DownSampleZ(aStack, aRate)
% Down-samples the z-dimension of a z-stack.
%
% Used to remove virtual z-planes added using UpSampleZ or StretchZ.
%
% Inputs:
% aStack - Stack for which the number of z-planes will be reduced.
% aRate - Rate by which the z-stack will be down-sampled. Every aRate:th
%         z-plane will be kept, starting from the first z-plane.
%
% Outputs:
% oStack - Down-sampled z-stack.
%
% See also:
% UpSampleZ, StretchZ

oStack = aStack(:,:,1:aRate:end);
end