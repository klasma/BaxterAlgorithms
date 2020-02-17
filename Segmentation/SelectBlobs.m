function oBlobs = SelectBlobs(aImData, aBlobGroups, aLimits, aMargin)

[yN, xN, zN] = size(aBlobGroups);

allBlobs = [];
allDistances = [];

for i = 1:xN
    for j = 1:yN
        for k = 1:zN
            blobs = aBlobGroups{j,i,k};
            distances = nan(size(blobs));
            allBlobs = [allBlobs blobs];
            for bIndex = 1:length(blobs)
                blob = blobs(bIndex);
                bb = blob.boundingBox;
                limits = aLimits{j,i,k};
                
                dx1 = bb(1) + 0.5 - limits.xMin;
                dx2 = limits.xMax - (bb(1) + bb(4) - 0.5);
                
                dy1 = bb(2) + 0.5 - limits.yMin;
                dy2 = limits.yMax - (bb(2) + bb(5) - 0.5);
                
                dz1 = bb(3) + 0.5 - limits.zMin;
                dz2 = limits.zMax - (bb(3) + bb(6) - 0.5);
                
                distances(bIndex) = min([dx1 dx2 dy1 dy2 dz1 dz2]);
            end
            allDistances = [allDistances distances];
        end
    end
end

[allDistances, order] = sort(allDistances, 'descend');
allBlobs = allBlobs(order);

selectedBlobs(size(allBlobs)) = Blob();
index = sum(allDistances > aMargin);
selectedBlobs(1:index) = allBlobs(1:index);
index = index + 1;
startIndex = index;

% Remove blobs that touch the artificial borders, as there can be
% segmentation artifacts close to the borders.
allBlobs = allBlobs(allDistances > -aMargin);

for bIndex = startIndex:length(allBlobs)
    blob = allBlobs(bIndex);
    totalOverlap = 0;
    area = blob.GetArea();
    select = true;
    for bIndex2 = startIndex:index-1
        blob2 = selectedBlobs(bIndex2);
        overlap = Overlap(blob, blob2);
        if overlap > 0
            totalOverlap = totalOverlap + overlap;
            if totalOverlap > 0.1 * area
                select = false;
                break;
            else
                [x, y, z] = blob2.GetPixelCoordinates();
                indices = sub2ind(aImData.GetSize(), y, x, z);
                RemoveBlobPixels(blob, indices, aImData)
            end
        end
    end
    if select
        selectedBlobs(index) = blob;
        index = index + 1;
    end
end

oBlobs = selectedBlobs(1:index-1);
end