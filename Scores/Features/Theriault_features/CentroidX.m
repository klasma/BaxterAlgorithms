function oCentroidX = CentroidX(aBlob, aImProcessor)
% Returns the x-coordinate of a Blob centroid.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oCentroidX - x-coordinate of the centroid.
%
% See also:
% CentroidY, ComputeFeatures

oCentroidX = aImProcessor.GetXbar(aBlob);
end