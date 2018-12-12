function oDist = MeanDistBetween(aBlob, aImProcessor, aWeights, aTo, aNormalize)
% Computes weighted averages of pixel distances in blobs.
%
% The function generates pixel weights inside a blob by normalizing the
% image or a modified version of it. The image can be modified by taking
% the absolute value, or by zeroing values above or below 0. The function
% will then compute the weighted average of the distances from the pixels
% to some part of the blob. Finally, the weighted average distances can be
% normalized by the un-weighted average distances, which can be computed
% using the function DistTo.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
% aWeights - The type of image used to compute the weights. The
%            alternatives are:
%    'val' - The image itself. Background subtraction and intensity
%            normalization are applied if that has been specified in the
%            settings of the image sequence.
%    'abs' - The absolute value of the image.
%    'neg' - Image where the positive values have been set to 0.
%    'pos' - Image where the negative values have been set to 0.
% aTo - The part of the blob that the pixel distances will be computed to.
%       The valid values are:
%    'boundary' - The distance to the closest background pixel.
%    'center' - The maximum distance to the closest boundary pixel, taken
%               over all pixels, minus the distance from the current pixel
%               to the closest boundary pixel. This is actually not the
%               distance to a specific point.
%    'centroid' - The distance to the center of mass of the blob mask.
% aNormalize - If this is set to true, the weighted average distance is
%              normalized by the un-weighted average distance, where all
%              pixels of the blob have the same weight.
%
% Outputs:
% oDist - The computed feature value.
%
% See also:
% ComputeFeatures, DistTo

% Create a un-normalized pixel weights.
pixels = aBlob.GetPixels(aImProcessor.GetNormIm());
switch lower(aWeights)
    case 'val'
        % No transformation.
    case 'abs'
        pixels = abs(pixels);
    case 'neg'
        pixels(pixels > 0) = 0;
    case 'pos'
        pixels(pixels < 0) = 0;
    otherwise
        error(['%s is not a valid value for aWeights. aWeights can '...
            'only take the values ''val'', ''abs'', ''neg'' and ''pos''.'])
end

% Compute the distances from the pixels to the desired part of the blob.
switch lower(aTo)
    case 'boundary'
        dist = aBlob.GetPixels(aImProcessor.GetDistIm());
    case {'center', 'centerboundary'}
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
        dist = (X-xc).^2 + (Y-yc).^2;  % TODO: Take the square root.
        
        % Remove pixels which are in the boundingbox but outside the mask.
        % bw should be logical but old data can have double arrays.
        dist = dist(logical(bw));
    otherwise
        error('%s is not a valid value for aTo.', aTo)
end

% Compute a weighted average of the distances.
oDist = sum(pixels.*dist) / (sum(pixels) + eps);

% Add normalization if that was requested.
if aNormalize
    switch lower(aTo)
        case {'boundary', 'centerboundary'}
            oDist = oDist / DistTo(aBlob, aImProcessor, 'boundary', 'mean');
        case 'center'
            oDist = oDist / DistTo(aBlob, aImProcessor, 'center', 'mean');
        case 'centroid'
            oDist = oDist / DistTo(aBlob, aImProcessor, 'centroid', 'mean');
        otherwise
            error('%s is not a valid value for aTo.', aTo)
    end
end