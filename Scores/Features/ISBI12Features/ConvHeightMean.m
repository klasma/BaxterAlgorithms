function oHeight = ConvHeightMean(aBlob, aImProcessor)
% The mean height of a convexified smoothed intensity profile of a blob.
%
% First, the image is smoothed using a Gaussian kernel with a standard
% deviation of 5 pixels. Then the minimum value inside the blob is
% subtracted and the convex hull of the resulting intensity profile is
% computed. Finally, the average height of the convexified intensity
% profile is computed.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oHeight - The computed feature value.
%
% See also:
% ComputeFeatures, HeightMean, ConvHeightNorm, ConvVolMean

[x, y, ~] = aBlob.GetPixelCoordinates();
z = aBlob.GetPixels(aImProcessor.GetSmoothIm());
n = length(z);

% Add a floor to the polyhedron.
x = [x; x];
y = [y; y];
z = [z; min(z)*ones(size(z))];

if length(z) < 4
    % At least 4 points are needed to compute a convex hull. If there are
    % less than 4 points, the volume of the convex hull is 0.
    oHeight = 0;
else
    try
        [~, vol] = convhulln([x y z]);
        oHeight = vol/n;
    catch
        % If the points are degenerate, convhulln will throw an error. Then
        % the volume of the convex hull is 0.
        oHeight = 0;
    end
end
end