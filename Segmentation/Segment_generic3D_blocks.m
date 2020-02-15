function oBlobs = Segment_generic3D_blocks(aImData, aFrame, aNumberOfBlocks, aMargin)

xMarg = aMargin;
yMarg = aMargin;
zMarg = aMargin;

xN = aNumberOfBlocks(2);
yN = aNumberOfBlocks(1);
zN = aNumberOfBlocks(3);

xBlock = ceil(aImData.imageWidth / xN);
yBlock = ceil(aImData.imageHeight / yN);
zBlock = ceil(aImData.numZ / zN);

blobGroups = cell(yN*xN*zN,1);
limits = cell(yN*xN*zN,1);
for index = 1 : xN*yN*zN
    [j,i,k] = ind2sub([yN xN zN], index);
    
    x1 = 1 + (i - 1) * xBlock;
    x2 = i * xBlock;
    y1 = 1 + (j - 1) * yBlock;
    y2 = j * yBlock;
    z1 = 1 + (k - 1) * zBlock;
    z2 = k * zBlock;
    
    s = struct(...
        'xMin', x1,...
        'xMax', x2,...
        'yMin', y1,...
        'yMax', y2,...
        'zMin', z1,...
        'zMax', z2);
    s.xMin(i==1) = -inf;
    s.yMin(j==1) = -inf;
    s.zMin(k==1) = -inf;
    s.xMax(i==xN) = inf;
    s.yMax(j==yN) = inf;
    s.zMax(k==zN) = inf;
    limits{index} = s;
    
    x1 = max(x1 - xMarg, 1);
    y1 = max(y1 - yMarg, 1);
    z1 = max(z1 - zMarg, 1);
    
    x2 = min(x2 + xMarg, aImData.imageWidth);
    y2 = min(y2 + yMarg, aImData.imageHeight);
    z2 = min(z2 + zMarg, aImData.numZ);
    
    fprintf('Segmenting i=%d, j=%d, k=%d\n', i, j, k)
    blobs = Segment_generic3D(aImData, aFrame,...
        'PixelRegion', {[y1 y2] [x1 x2]},...
        'Z1', z1,...
        'Z2', z2,...
        'NumBlocks', [1 1 1]);
    
    % Shift the blob centroids and bounding boxes to the full image.
    for bIndex = 1:length(blobs)
        blob = blobs(bIndex);
        blob.centroid = blob.centroid + [x1-1 y1-1 z1-1];
        blob.boundingBox = blob.boundingBox + [x1-1 y1-1 z1-1 0 0 0];
    end
    
    blobGroups{index} = blobs;
end

blobGroups = reshape(blobGroups, [yN xN zN]);
limits = reshape(limits, [yN xN zN]);

oBlobs = SelectBlobs(aImData, blobGroups, limits, aMargin);
end