function oHeight = ConvCompHeightMean(aBlob, aImProcessor)
% Mean height of the convex complement of the smoothed intensity of a blob.
%
% First, the image is smoothed using a Gaussian kernel with a standard
% deviation of 5 pixels. Then the volume of the convex complement of the
% intensity profile is computed and divided by the area of the region. This
% feature is equal to the difference between ConvHeightMean and HeightMean.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oHeight - The computed feature value.
%
% See also:
% ComputeFeatures, ConvHeightMean, HeightMean, ConvHeightNorm

oHeight = ConvHeightMean(aBlob, aImProcessor) -...
    HeightMean(aBlob, aImProcessor);
end