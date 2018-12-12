function [oBW, oGray, oImages] = Segment_localvariance(...
    aI,...
    aRegionShape,...
    aRegionSize,...
    aThreshold,...
    aFillHoles,...
    aErodeShape,...
    aErodeSize,...
    aMinHoleSize)
% Performs a segmentation of an image based on local variance (texture).
%
% The local variance image is computed by estimating the variance in a
% square or circular region around every pixel. There is also the option to
% compute a weighted local variance where summations over binary regions
% are replaced by convolutions with a Gaussian kernel. The local variance
% is thresholded to produce a segmentation. The segmentation algorithm
% works well for most types of transmission microscopy.
%
% Inputs:
% aI - Gray scale image to be segmented (with values between 0 and 255).
% aRegionShape - Shape of the region around every pixel where the variance
%                is computed. (square/round/gaussian)
% aRegionSize - Radius of region to compute the variance in. For the square
%               shape, the region is a 2r+1 x 2r+1 square, for the round
%               shape, the region is a circle of radius r (a circular mask
%               inside a 2r+1 x 2r+1 square), and for the Gaussian kernel,
%               the standard deviation is set to r.
% aThreshold - Threshold used on the local variance to produce the binary
%              segmentation mask. The variance is transformed by the
%              function log(1+x). I don't think that this is well
%              motivated, but it gives a nicer image when the local
%              variance is displayed. Perhaps the standard deviation should
%              be used instead.
% aFillHoles - Specifies if holes in the segmentation mask should be
%              filled.
% aErodeShape - Shape of erosion structuring object (square/round).
% aErodeSize - Size of the erosion structuring element. It is defined
%              exactly as the size of the variance region.
% aMinHoleSize - The smallest hole size (in pixels) allowed when holes are
%                filled. All smaller holes will be filled. To fill all
%                holes, this parameter can be set to inf. aFillHoles needs
%                to be 1 for this input to have an effect.
%
% Outputs:
% oBW - Binary segmentation mask.
% oGray - Image with local variance that can be displayed with imshow.
% oImages - Struct with intermediate processing results. The struct has the
%           fields 'variance', 'beforeErode' and 'mask' which correspond to
%           the local variance image, the binary segmentation mask prior to
%           erosion and the segmentation mask after erosion, respectively.
%
% References:
% [1] Wu, K. and Gauthier, D. and Levine, M.D., "Live cell image
%     segmentation", Biomedical Engineering, IEEE Transactions on, vol. 42,
%     no. 1, pp 1-12, 1995
%
% Known issues:
% Perhaps the transformation V = log(1+V) should be removed.

% Compute local variance.
switch lower(aRegionShape)
    case 'square'
        V = LocalVariance(aI, aRegionSize, 'Shape', 'square');
    case 'round'
        V = LocalVariance(aI, aRegionSize, 'Shape', 'round');
    case 'gaussian'
        V = LocalVariance_gauss(aI, aRegionSize);
    otherwise
        error('aRegionShape has to be either ''square'', ''round'' or ''gaussian''')
end

% Transform for nicer display and thresholds in a good range.
V = log(1+V);

oImages.variance = V;

% Variance image for display.
oGray = V/max(V(:));

% Threshold.
oBW = V >= aThreshold;

% Fill holes.
if aFillHoles
    if isinf(aMinHoleSize)
        % Fill all holes.
        oBW = imfill(oBW,'holes');
    else
        % Fill all holes smaller than a threshold.
        withoutHoles = imfill(oBW,'holes');
        holes = withoutHoles & ~oBW;
        largeholes = bwareaopen(holes, aMinHoleSize);
        oBW = withoutHoles & ~largeholes;
    end
end

oImages.beforeErode = oBW;

% Shrink the segments by eroding the segmentation mask.
if aErodeSize >= 1
    if strcmpi(aErodeShape, 'square')
        se = strel(ones(aErodeSize*2+1));
        oBW = imerode(oBW, se);
    elseif strcmpi(aErodeShape, 'round')
        se = strel(Ellipse(aErodeSize*ones(1,2)));
        oBW = imerode(oBW, se);
    else
        error('aErodeShape has to be either ''square'' or ''round''')
    end
end

oImages.mask = oBW;
end