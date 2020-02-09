function oBlobs = Segment_generic3D_blocks(aImData, aFrame, aNumberOfBlocks)

fprintf('Segment_generic3D_blocks')
xMarg = 50;
yMarg = 50;
zMarg = 50;

xN = aNumberOfBlocks(2);
yN = aNumberOfBlocks(1);
zN = aNumberOfBlocks(3);

xBlock = ceil(aImData.imageWidth / xN);
yBlock = ceil(aImData.imageHeight / xN);
zBlock = ceil(aImData.numZ / xN);

I = aImData.GetDoubleZStack(aFrame, 'Channel', aImData.Get('SegChannel'));

blobGroups = cell(yN*xN*zN,1);
limits = cell(yN*xN*zN,1);
images = cell(yN*xN*zN,1);
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
    
    x1 = max(x1 - xMarg, 1);
    y1 = max(y1 - yMarg, 1);
    z1 = max(z1 - zMarg, 1);
    
    x2 = min(x2 + xMarg, aImData.imageWidth);
    y2 = min(y2 + yMarg, aImData.imageHeight);
    z2 = min(z2 + zMarg, aImData.numZ);
    
    s.x1 = x1;
    s.x2 = x2;
    s.y1 = y1;
    s.y2 = y2;
    s.z1 = z1;
    s.z2 = z2;
    limits{index} = s;
    
    images{index} = I(y1:y2, x1:x2, z1:z2);
end

imParameters = ImageParameters(aImData.seqPath);

fprintf('Segment_generic3D_blocks before parfor')

parfor index = 1:xN*yN*zN
    [j,i,k] = ind2sub([yN xN zN], index);
    fprintf('Segmenting i=%d, j=%d, k=%d\n', i, j, k)
    blobs = Segment_generic3D_image(images{index}, imParameters, aFrame);
    
    % Shift the blob bounding boxes to the full image.
    for bIndex = 1:length(blobs)
        blobs(bIndex).boundingBox = blobs(bIndex).boundingBox +...
            [limits{index}.x1-1 limits{index}.y1-1 limits{index}.z1-1 0 0 0];
    end
    
    blobGroups{index} = blobs;
end

blobGroups = reshape(blobGroups, [yN xN zN]);
limits = reshape(limits, [yN xN zN]);

oBlobs = SelectBlobs(blobGroups, limits, 50);
end