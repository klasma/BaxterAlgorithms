function oVal = ICentroid(aBlob, aImProcessor)
% Feature which returns the intensity at the centroid of a blob.
%
% The centroid is the center of mass of the binary segmentation mask of the
% blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oVal - The computed feature value.
%
% See also:
% ComputeFeatures, IBoundary, ICenter, IFraction

im = aImProcessor.GetNormIm();
xc = round(aImProcessor.GetXbar(aBlob));
yc = round(aImProcessor.GetYbar(aBlob));
oVal = im(yc,xc);
end