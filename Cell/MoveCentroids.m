function MoveCentroids(aCells)
% Moves the coordinates of a set of cells to the centroids of the blobs.
%
% This can be used to deal with errors caused by merging of watershed
% segments without cells.
%
% Inputs:
% aCells - Cells where the centroids parameters might not agree with the
%          centroids of the blobs.
%
% See also:
% MoveBlobCentroids

for i = 1:length(aCells)
    c = aCells(i);
    for j = 1:length(c.blob)
        b = c.blob(j);
        if ~any(isnan(b.boundingBox))
            if length(b.centroid) == 2  % 2D
                [x, y] = b.GetPixelCoordinates();
                xmean = mean(x);
                ymean = mean(y);
                
                c.cx(j) = xmean;
                c.cy(j) = ymean;
                b.centroid = [xmean ymean];
            else  % 3D
                [x, y, z] = b.GetPixelCoordinates();
                xmean = mean(x);
                ymean = mean(y);
                zmean = mean(z);
                
                c.cx(j) = xmean;
                c.cy(j) = ymean;
                c.cz(j) = zmean;
                b.centroid = [xmean ymean zmean];
            end
        end
    end
end
end