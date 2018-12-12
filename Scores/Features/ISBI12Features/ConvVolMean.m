function oHeight = ConvVolMean(aBlob, aImProcessor)
% Volume per pixel of a convexified smoothed intensity profile of a blob.
%
% First, the image is smoothed using a Gaussian kernel with a standard
% deviation of 5 pixels. Then the convex hull of the resulting intensity
% profile is computed. The feature is that volume divided by the area of
% the region. The feature is very similar to ConvHeightMean, but that
% function computes the volume under the convex intensity profile, while
% this function computes the volume of the polyhedron spanned by the points
% in the intensity profile. If the profile is a plane in 3D, ConvHeightMean
% would return the average height of the plane while this function would
% return 0.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oHeight - The computed feature value.
%
% See also:
% ComputeFeatures, HeightMean, ConvHeightMean, ConvHeightNorm

[x, y, ~] = aBlob.GetPixelCoordinates();
z = aBlob.GetPixels(aImProcessor.GetSmoothIm());

try
    [~, vol] = convhulln([x y z]);
    oHeight = vol/length(z);
catch
    % If the points are degenerate, convhulln will throw an error. Then the
    % volume of the convex hull is 0.
    oHeight = 0;
end
end