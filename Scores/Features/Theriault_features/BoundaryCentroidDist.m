function oProp = BoundaryCentroidDist(aBlob, aImProcessor, aProp)
% Feature which gives statistics on blob centroid-boundary distance.
%
% This is a Blob feature, which computes statistics on the distance between
% boundary pixels and the centroid of the blob. The function can compute
% the mean, standard deviation, the maximum and the minimum. All pixels
% that are 8-connected to background pixels are considered to be boundary
% pixels.
%
% Inputs:
% aBlob - Blob object for which the feature should be computed.
% aImProcessor - ImageProcessor object associated with the image.
% aProp - The desired statistic, which can be 'mean', 'std', 'min' or
%         'max'.
%
% Outputs:
% oProp - The requested statistic on the distances between boundary pixels
%         and the centroid.
%
% References:
% [1] Theriault, D. H.; Walker, M. L.; Wong, J. Y. & Betke, M. Cell
%     morphology classification and clutter mitigation in phase-contrast
%     microscopy images using machine learning Mach. Vis. Appl., Springer,
%     2012, 23, 659-673
%
% See also:
% ComputeFeatures

% Get centroid coordinates.
xbar = aImProcessor.GetXbar(aBlob);
ybar = aImProcessor.GetYbar(aBlob);

% Get boundary pixels.
B = bwboundaries(aBlob.image);
% Concatenate boundaries of all components and holes.
b = cat(1,B{:});
% Go from blob coordinates to image coordinates.
bb = aBlob.boundingBox;
b(:,1) = b(:,1) + bb(2) - 0.5;
b(:,2) = b(:,2) + bb(1) - 0.5;

% The distance from all boundary pixels to the centroid.
d = sqrt((b(:,1)-ybar).^2 + (b(:,2)-xbar).^2);

switch lower(aProp)
    case 'mean'
        oProp = mean(d);
    case 'std'
        oProp = std(d);
    case 'min'
        oProp = min(d);
    case 'max'
        oProp = max(d);
    otherwise
        error(['Unknown property %s, the property has to be mean, std, '...
            'min or max.'], aProp)
end
end