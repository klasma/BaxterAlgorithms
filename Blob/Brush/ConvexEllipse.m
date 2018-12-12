function oImage = ConvexEllipse(aA)
% Creates a 2D or 3D ellipsoid which is "convex" according to bwconvhull.
%
% An elliptical disk or an ellipsoid produced with this function will not
% change if the built in function for convex hulls (bwconvhull) is applied
% to it. The disk is made symmetric, even though the output from bwconvhull
% is not always symmetric. The disk can be used for example as a brush in
% segmentation editing.
%
% Inputs:
% aA - Vector with the lengths of the ellipsoid semi-axes. Dimension d will
%      have 2*aA(d)+1 elements.
%
% Outputs:
% oImage - Binary image where the ellipsoid is 1s and the background is 0s.
%
% See also:
% ConvexDisk, Ellipse, Brush

oImage = logical(Ellipse(aA));

% Make the region "convex".
oImage = BwConvHull3D(oImage);

% Make the region symmetric. bwconvhull does not always produce symmetric
% regions.
oImage = oImage | flipud(oImage) | fliplr(oImage) | rot90(oImage,2);
if ndims(oImage) == 3
    oImage = oImage | flip(oImage,3);
end
end