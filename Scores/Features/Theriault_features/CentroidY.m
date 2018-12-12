function oCentroidY = CentroidY(aBlob, aImProcessor)
% Returns the y-coordinate of a Blob centroid.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oCentroidY - y-coordinate of the centroid.
%
% See also:
% CentroidX, ComputeFeatures

oCentroidY = aImProcessor.GetYbar(aBlob);
end