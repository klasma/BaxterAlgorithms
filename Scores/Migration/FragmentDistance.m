function [oDx, oDy] = FragmentDistance(aBlob1, aBlob2)
% Computes the distance between fragments of blobs.
%
% This function computes the distances between the centroid of the smaller
% blob the centorid of a fragment of the larger blob. The fragemnt is
% composed of the N pixels which are closest to the centorid of the smaller
% blob, where N is the area of the smaller blob. The function only works in
% 2D, but there is commented out code for a 3D version.

a1 = aBlob1.GetArea();
a2 = aBlob2.GetArea();

if a1 < a2
    aSmall = a1;
    smallBlob = aBlob1;
    largeBlob = aBlob2;
else
    aSmall = a2;
    smallBlob = aBlob2;
    largeBlob = aBlob1;
end

xcSmall = smallBlob.centroid(1);
ycSmall = smallBlob.centroid(2);
%zcSmall = smallBlob.centroid(3);
[xLarge, yLarge] = largeBlob.GetPixelCoordinates();

dx = xLarge - xcSmall;
dy = yLarge - ycSmall;
%dz = zLarge - zcSmall;
d = sqrt(dx.^2 + dy.^2);
[~, index] = sort(d, 'ascend');

xLarge = xLarge(index(1:aSmall));
yLarge = yLarge(index(1:aSmall));
%zLarge = zLarge(index(1:aSmall));
xcLarge = mean(xLarge);
ycLarge = mean(yLarge);
%zcLarge = mean(zLarge);
oDx = xcLarge-xcSmall;
oDy = ycLarge-ycSmall;
%oDz = zcLarge-zcSmall;
%oDistance = sqrt((xcLarge-xcSmall)^2 + (ycLarge-ycSmall)^2 + (zcLarge-zcSmall)^2);
end