function oRatio = EdgeDistMeanNorm(aBlob, aImProcessor)
% Ratio between the mean distance to the background in blob and circle.
%
% This feature computes the mean distance to the closest background pixel,
% for pixels in a blob. That distance is then divided by the mean distance
% to the background in a circular disk. The values range between 1 for a
% perfectly circular blob and zero for an infinitely thin blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oRatio - The computed feature value.
%
% See also:
% ComputeFeatures, EdgeDistMaxNorm, DistTo

meanDist = DistTo(aBlob, aImProcessor, 'boundary', 'mean');
meanDistCircle = 2/3*sqrt(Area(aBlob, aImProcessor))/pi;
oRatio = meanDist / meanDistCircle;
end