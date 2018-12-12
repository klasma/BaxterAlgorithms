function MoveBlobCentroids(aBlobs)
% Recomputes the centroids of blobs from their pixel regions.
%
% Some processing operations change the pixel regions of blobs and
% therefore the centroids of the blobs need to be updated.
%
% Inputs:
% aBlobs - Array of blob objects for which the centroids need to be
%          updated.
%
% See also:
% MoveCentroids

for i = 1:length(aBlobs)
    b = aBlobs(i);
    if any(isnan(b.boundingBox))
        continue
    end
    if length(b.centroid) == 2  % 2D
        [x, y] = b.GetPixelCoordinates();
        xmean = mean(x);
        ymean = mean(y);
        
        b.centroid = [xmean ymean];
    else  % 3D
        [x, y, z] = b.GetPixelCoordinates();
        xmean = mean(x);
        ymean = mean(y);
        zmean = mean(z);
        
        b.centroid = [xmean ymean zmean];
    end
end
end