function oBlobs = SelectBlobs(aBlobGroups, aLimits, aMargin)

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
                limits = aLimits(j,i,k);
                
                dx1 = bb(1) - limits.xMin;
                dx2 = limits.xMax - (bb(1) + bb(4));
                
                dy1 = bb(2) - limits.yMin;
                dy2 = limits.yMax - (bb(2) + bb(5));
                
                dz1 = bb(3) - limits.zMin;
                dz2 = limits.zMax - (bb(3) + bb(6));
                
                distances(bIndex) = min([dx1 dx2 dy1 dy2 dz1 dz2]);
            end
            allDistances = [allDistances distances];
        end
    end
end

[allDistances, order] = sort(allDistances, 'descend');
allBlobs = allBlobs(order);

selectedBlobs(numel(allBlobs),1) = Blob();
index = 1;

for bIndex = 1:length(allBlobs)
    blob = allBlobs(bIndex);
    if (allDistances(bIndex) > aMargin)
        selectedBlobs(index) = blob;
        index = index + 1;
    else
        overlap = false;
        for bIndex2 = 1:index-1
            if Overlap(blob, selectedBlobs(bIndex2)) > 0 % TODO: handle small overlaps
                overlap = true;
                break;
            end
        end
        if ~overlap
            selectedBlobs(index) = blob;
            index = index + 1;
        end
    end
end

oBlobs = selectedBlobs(1:index-1);
end