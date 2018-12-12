function oImage = Smooth(aImage, aSigma)
% Smooths an n-dimensional image using a Gaussian kernel.
%
% The convolution is performed using a separate convolution for each
% dimension. This makes the computations faster and it is possible since
% the kernel can be written as the convolution between 3 arrays with
% different orientations.
%
% Inputs:
% aImage - Image to be smoothed.
% aSigma - Standard deviation of the Gaussian kernel. aSigma can be either
%          a vector with a separate standard deviation for each image
%          dimension, or it can be a single standard deviation to be used
%          in all dimensions.
%
% Outputs:
% oImage - Smoothed image.
%
% See also:
% SmoothComp


dims = ndims(aImage);

% Parse std input.
if length(aSigma) == dims
    sigma = aSigma;
elseif length(aSigma) == 1
    sigma = aSigma * ones(1,dims);
else
    error(['aSigma must either be a scalar or a vector with one '...
        'element per image dimension.'])
end

oImage = double(aImage);
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
    oImage = convn(oImage, gauss, 'same');
end
end