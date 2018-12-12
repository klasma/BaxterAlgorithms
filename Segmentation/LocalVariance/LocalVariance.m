function oV = LocalVariance(aI, aN, varargin)
% Computes the local variance of an image.
%
% The function computes the local sample variance in a rectangular or
% ellipsoidal region around around all pixels in an image, using
% convolutions. The convolutions are used to compute the mean of the square
% pixel values and the square of the mean pixel values in the regions. Then
% the variance is computed from the difference between the two values. A
% third convolution is used to find the number of pixels in each region.
% More about local variance and the computations involved can be found in
% [1]. The function works on N-dimensional arrays.
%
% Inputs:
% aI - Grayscale image
% aN - Size of the region over which the variance is computed. The input
%      can be either a scalar or a vector with one element for each
%      dimension of the image. The width of the region in dimension i will
%      be aN(i)*2+1.
%
% Property/Value inputs:
% RegionShape - Shape of the region around every pixel where the variance
%               is computed. The two options are 'square' for rectangular
%               regions 'round' for ellipsoidal regions. The default is
%               'square'.
%
% Outputs:
% oV - Local variance image.
%
% References:
% [1] K. Wu, D. Gauthier, and M. Levine, “Live cell image segmentation,”
%     Biomedical Engineering, IEEE Transactions on, vol. 42, no. 1, pp.
%     1–12, 1995.
%
% See also:
% LocalVariance_gauss

% Parse property/value inputs.
aShape = GetArgs({'Shape'}, {'square'}, true, varargin);

dims = ndims(aI);

% Parse region size input.
if length(aN) == dims
    N = aN;
elseif length(aN) == 1
    N = aN * ones(1,dims);
else
    error(['aN must either be a scalar or a vector with one element '...
        'per image dimension.'])
end

% Region where the sample variance is computed.
switch aShape
    case 'square'
        mask = ones(N*2+1);
    case 'round'
        mask = Ellipse(N);
    otherwise
        error('The parameter Shape must either be ''square'' or ''round''.')
end

Isum = conv2(aI, mask, 'same');
I2sum = conv2(aI.^2, mask, 'same');
cnt = conv2(ones(size(aI)), mask, 'same');

% Unbiased variance esetimator.
oV = I2sum ./ (cnt-1) - Isum.^2 ./ (cnt.*(cnt-1));
end