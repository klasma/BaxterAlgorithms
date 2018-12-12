function oVal = ICenter(aBlob, aImProcessor)
% Feature which returns the intensity at the center of a blob.
%
% The center of the blob is defined as the pixels which are furthest away
% from the blob boundary. If multiple pixels are equally far away from the
% boundary, the returned value is the average intensity taken over the
% pixels.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oVal - The computed feature value.
%
% See also:
% ComputeFeatures, IBoundary, ICentroid, IFraction

% Find the pixels furthest away from the boundary.
dist = aBlob.GetPixels(aImProcessor.GetDistIm());
[~, maxIndex] = max(dist);

% Compute the average image intensity for the pixels.
im = aBlob.GetPixels(aImProcessor.GetNormIm());
oVal = mean(im(maxIndex));
end