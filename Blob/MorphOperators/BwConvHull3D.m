function oImage = BwConvHull3D(aImage)
% Restricted 3D implementation of the function convhull2D.
%
% The function computes the convex hull of a binary pixel image, and
% returns a binary image where all pixels that lie inside the convex hull
% are ones and the other pixels are zeros. The function is a 3D equivalent
% to the built in 2D function bwconvhull, but it cannot handle different
% connectivities or convex hulls of individual objects.
%
% The function works by computing the 3-dimensional convex hull of the
% pixel coordinates. Then it computes a Delaunay triangulation of the
% points in the convex hull, which decomposes the convex hull into
% tetrahedra (simplexes). Then it generates a pixel grid and puts all grid
% points which lie inside a tetrahedron in the foreground of the image.
% The conversion from the convex hull to a pixel image was taken from
% http://stackoverflow.com/questions/2769138/converting-convex-hull-to-binary-mask.
%
% Inputs:
% aImage - 3D binary image.
%
% Outputs:
% oImage - A binary image representing the convex hull of the pixels in
%          aImage.
%
% See also:
% ConvexAllBlobs, ConvexBlob, bwconvhull, regionprop, sconvhulln

if size(aImage,1) == 1
    aImage = permute(aImage, [2 3 1]);
    oImage = bwconvhull(aImage);
    oImage = ipermute(oImage, [2 3 1]);
    return
elseif size(aImage,2) == 1
    aImage = permute(aImage, [1 3 2]);
    oImage = bwconvhull(aImage);
    oImage = ipermute(oImage, [1 3 2]);
    return
elseif size(aImage,3) == 1
    oImage = bwconvhull(aImage);
    return
end

index = find(aImage);
[y, x, z] = ind2sub(size(aImage), index);  % Coordinates of foreground.

% Find the pixels which are a part of the convex hull. convhulln returns
% pixel indices defining a set of triangles which represent the convex
% hull, so I simply take the pixels which are at the corners of at least
% one triangle.

try
    K = convhulln([x y z]);
catch
    % If all points are in a plane, convhulln gives an error.
    % TODO: Make this nicer.
    oImage = aImage;
    return
end
convIndices = unique(K(:));
% Coordinates of pixels defining the convex hull.
xConv = x(convIndices);
yConv = y(convIndices);
zConv = z(convIndices);

% Decompose the convex hull into a set of tetrahedra using a Delaunay
% triangulation.
dTri = delaunayTriangulation([xConv yConv zConv]);

% Create a pixel grid.
[yMax, xMax, zMax] = size(aImage);
[X,Y,Z] = meshgrid(1:xMax, 1:yMax, 1:zMax);

% Find the tetrahedron in which each grid point lies.
tetrahedronIndex = pointLocation(dTri , X(:), Y(:), Z(:));
tetrahedronImage = reshape(tetrahedronIndex, size(aImage));

% Points outside the convex hull have a tetrahedron index of NaN.
oImage = ~isnan(tetrahedronImage);
end