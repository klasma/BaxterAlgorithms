function oDist = AvgMinPixelDist(aBlob1, aBlob2, aImData)
% Mean distance from pixels in a blob to the closest pixel in another blob.
%
% For every pixel in the first blob, the function computes the distance to
% the closest pixel in the other blob. The distances are then averaged. The
% distance is 0 if the second blob covers the first blob. For 3D blobs,
% distances in the z-dimension are scaled by the ratio between the voxel
% height and the voxel width, so that all distances are given in voxel
% widths.
%
% Inputs:
% aBlob1 - The first blob, over which the distances to the closest pixels
%          will be averaged.
% aBlob2 - The second blob, in which the closest pixels are found.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oDist - The mean distance to the closest pixel in aBlob2.
%
% See also:
% SelectCellsFromGTPixels

% Pixel coordinates in the first blob.
[x1, y1, z1] = aBlob1.GetPixelCoordinates();
n1 = length(x1);

% Pixel coordinates in the second blob.
[x2, y2, z2] = aBlob2.GetPixelCoordinates();
n2 = length(x2);

X1 = repmat(x1,1,n2);
Y1 = repmat(y1,1,n2);
Z1 = repmat(z1,1,n2) * aImData.voxelHeight;

X2 = repmat(x2',n1,1);
Y2 = repmat(y2',n1,1);
Z2 = repmat(z2',n1,1) * aImData.voxelHeight;

% Compute a distance matrix with distances between all blob pairs.
distances = sqrt( (X2-X1).^2 + (Y2-Y1).^2 + (Z2-Z1).^2 );

% Average the minimum distances from pixels in aBlob1 to the closest pixel
% in aBlob2.
oDist = mean( min(distances,[],2) );
end