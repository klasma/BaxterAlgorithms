function oValue = IDistPower(aBlob, aImProcessor, aInOut, aPower)
% Feature which computes weighted averages of the image in a blob.
%
% The function computes the distance from each blob pixel to the closest
% background pixel. These distances are then normalized to values between 0
% and 1. This gives a measure of how close to the boundary of the blob a
% pixel is, where 1 means that the pixel is at the center of the blob. This
% pixel measure is then raised to a power to produce weights for the
% pixels, which are higher at the center of the blob. The weights can also
% be made higher at the boundary of the blob, by taking 1 minus the
% original measure and raising that to the same power. The weights are
% divided by the distances to the closest background pixels plus 0.25, and
% normalized so that they sum to one. Finally, the weights are used to
% compute a weighted sum of the pixel intensities inside the blob.
%
% Now, I question if the division step which is performed before the
% normalization. I do not remember why I added it, and it should probably
% be removed. The altered feature should however be named something else to
% ensure backward compatibility with old results.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
% aInOut - If this is set to 'inner', more weight is given to the pixels
%          at the center of the the blob and if it is set to 'outer', more
%          weight is given to the pixels at the boundary of the blob.
% aPower - The power that the pixel distances are raised to when the
%          weights of the pixels are computed.
%
% Outputs:
% oValue - The computed feature value.
%
% TODO: Remove pixel-wise division.
%
% See also:
% ComputeFeatures, IBoundary, ICenter, ICentroid, IFraction

dist = aBlob.GetPixels(aImProcessor.GetDistIm());
im = aBlob.GetPixels(aImProcessor.GetNormIm());
distMax = max(dist);
switch lower(aInOut)
    case 'inner'
        weights = (1-dist/distMax).^aPower./(dist+0.25);
    case 'outer'
        weights = (dist/distMax).^aPower./(dist+0.25);
    otherwise
        error('%s is not a valid value for aInOut', aInOut)
end
weights = weights/sum(weights(:));
oValue = sum(im.*weights);
end