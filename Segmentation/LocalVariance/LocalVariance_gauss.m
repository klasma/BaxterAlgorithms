function oV = LocalVariance_gauss(aI, aSigma)
% Computes a weighted local variance of an image, using a Gaussian kernel.
%
% The output is an image which represents estimates of the local variance
% at different locations in the image. Pixels close to a location are
% weighted higher in the computation of the variance at that location. The
% function seems to give a smoother variance image than LocalVariance.m.
% The function convolves the different dimensions of the image using
% separate 1D convolutions. This is possible since the N-dimensional
% Gaussian kernel can be represented as the convolution between N vectors.
% The function works for images with an arbitrary number of dimensions.
%
% Inputs:
% aI - N-dimensional double image for which the local variance will be
%      computed.
% aSigma - Standard deviation of the Gaussian summation kernel. The input
%          can either be a scalar or a vector with one element for each
%          dimension.
%
% Outputs:
% oV - Weighted estimate of the local variance.
%
% See also:
% LocalVariance, Segment_localvariance

dims = ndims(aI);

% Parse std input.
if length(aSigma) == dims
    sigma = aSigma;
elseif length(aSigma) == 1
    sigma = aSigma * ones(1,dims);
else
    error(['aSigma must either be a scalar or a vector with one '...
        'element per image dimension.'])
end

Isum = aI;  % Smoothed image.
I2sum = aI.^2;  % Smoothed squared image.
% Smoothed image of ones (used to get the scaling right at the edges.)
N = ones(size(aI));

for i = 1:dims
    % Create samples from a Gaussian.
    width = ceil(3 * sigma(i));
    support = -width : width;
    gauss = exp( - (support / sigma(i)).^2 / 2);
    gauss = gauss / sum(gauss);  % Normalize.
    
    % Orient the Gaussian vector to convolve with dimension i.
    shape = ones(1,dims);
    shape(i) = length(gauss);
    gauss = reshape(gauss, shape);
    
    % Convolve in dimension i.
    Isum = convn(Isum, gauss, 'same');
    I2sum = convn(I2sum, gauss, 'same');
    N = convn(N, gauss, 'same');
end

oV = I2sum./N - (Isum./N).^2;
end