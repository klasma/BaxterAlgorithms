function oConvexArea = ConvexArea(aBlob, ~)
% Feature which returns the area of the convex hull of a blob.
%
% Inputs:
% aBlob - Blob object to compute the area of the convex hull for.
%
% Outputs:
% oConvexArea - The area of the convex hull.
%
% See also:
% ComputeFeatures, ConvexAreaNorm

props = regionprops(double(aBlob.image), 'ConvexArea');
oConvexArea = props.ConvexArea;
end