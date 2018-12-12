function oRatio = ConvHeightNorm(aBlob, aImProcessor)
% The ratio between ConvHeightMean and HeightMean.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oHeight - The computed feature value.
%
% See also:
% ComputeFeatures, ConvHeightMean, HeightMean, ConvCompHeightMean

oRatio = ConvHeightMean(aBlob, aImProcessor) /...
    (HeightMean(aBlob, aImProcessor) + eps);
end