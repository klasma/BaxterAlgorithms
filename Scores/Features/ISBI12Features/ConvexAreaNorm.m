function oConvexArea = ConvexAreaNorm(aBlob, ~)
% Feature which divides the convex hull's area by the area of the blob.
%
% The feature is 1 for a convex region and increases unboundedly as the
% region becomes move and more non-convex.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
%
% Outputs:
% oConvexArea - The ratio between the area of the convex hull of the blob
%               and the area of the blob.
%
% See also:
% ComputeFeatures, ConvexArea

props = regionprops(double(aBlob.image), 'ConvexArea');
oConvexArea = props.ConvexArea / sum(aBlob.image(:));
end