function oDist = DistTo(aBlob, aImProcessor, aTo, aProp)
% Computes the mean or maximum pixel distance to different parts of a blob.
%
% The pixel distance is computed for each pixel in the binary mask of the
% blob. The the mean or the maximum value is returned, depending on the
% inputs arguments.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
% aTo - The part of the blob that the pixel distances will be computed to.
%       The valid values are:
%    'boundary' - The distance to the closest background pixel.
%    'center' - The maximum distance to the closest boundary pixel, taken
%               over all pixels, minus the distance from the current pixel
%               to the closest boundary pixel. This is actually not the
%               distance to a specific point.
%    'centroid' - The distance to the center of mass of the blob mask.
% aProp - The desired statistical property of the pixel distances. The
%         valid alternatives are 'mean' and 'max'.
%
% Outputs:
% oDist - The computed feature value.
%
% See also:
% ComputeFeatures

switch lower(aTo)
    case 'boundary'
        dist = aBlob.GetPixels(aImProcessor.GetDistIm());
    case 'center'
        dist = aBlob.GetPixels(aImProcessor.GetDistIm());
        dist = max(dist) - dist;
    case 'centroid'
        % Convert the centroid from image coordinates to blob coordinates.
        xc = aImProcessor.GetXbar(aBlob) - aBlob.boundingBox(1) + 0.5;
        yc = aImProcessor.GetYbar(aBlob) - aBlob.boundingBox(2) + 0.5;
        
        bw = aBlob.image;
        
        % Create grids with x- and y-coordinates for all pixels in the
        % boundingbox.
        [X, Y] = meshgrid(1:size(bw,2), 1:size(bw,1));
        
        % Compute the distances from the pixels to the centroid.
        dist = sqrt((X-xc).^2 + (Y-yc).^2);
        
        % Remove pixels which are in the boundingbox but outside the mask.
        % bw should be logical but old data can have double arrays.
        dist = dist(logical(bw));
    otherwise
        error('%s is not a valid value for aTo.', aTo)
end

switch lower(aProp)
    case 'mean'
        oDist = mean(dist);
    case 'max'
        oDist = max(dist);
    otherwise
        error('%s is not a valid value for aProp.', aProp)
end
end