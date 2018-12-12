function oRatio = EdgeDistMaxNorm(aBlob, aImProcessor)
% Ratio between the maximum distance to the background in blob and circle.
%
% This feature computes the maximum distance to the closest background
% pixel, for pixels in a blob. That distance is then divided by the radius
% of a circle with the same area as the blob. The values range between 1
% for a perfectly circular blob and zero for an infinitely thin blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oRatio - The computed feature value.
%
% See also:
% ComputeFeatures, EdgeDistMeanNorm, DistTo

maxDist = DistTo(aBlob, aImProcessor, 'boundary', 'max');
maxDistCircle = sqrt(Area(aBlob, aImProcessor))/pi;
oRatio = maxDist / maxDistCircle;
end