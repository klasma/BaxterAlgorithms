function oStack = UpSampleZ(aStack, aRate)
% Add virtual z-planes between existing z-planes in a z-stack.
%
% The voxel values are assigned using linear interpolation. No
% extrapolation is done, so the top and bottom planes of the stack will be
% the same before and after up-sampling. This technique can be used to
% improve the performance 3D watershed algorithms on z-stacks when the the
% voxel height is much larger than the voxel width.
%
% Inputs:
% aStack - The z-stack to be up-sampled.
% aRate - The rate of up-sampling. This parameter determines by what factor
%         the number of z-planes will increase. Setting it to 1 will not
%         change the input stack, setting it to 2 will insert one virtual
%         plane between all pairs of planes, and so forth.
%
% Outputs:
% oStack - Up-sampled z-stack.
%
% See also:
% DownSampleZ, StretchZ

oStack = zeros(size(aStack,1), size(aStack,2), (size(aStack,3)-1)*aRate+1);

for i = 1:size(aStack,3)-1
    for k = 1:aRate
        % Linear interpolation.
        alpha = (aRate+1-k) / aRate;
        beta = (k-1) / aRate;
        iup = (i-1) * aRate + k;
        oStack(:,:,iup) = alpha*aStack(:,:,i) + beta*aStack(:,:,i+1);
    end
end
oStack(:,:,end) = aStack(:,:,end);
end