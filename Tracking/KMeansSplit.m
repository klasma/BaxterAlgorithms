function oFragments = KMeansSplit(aBlob, aCount)
% Splits a Blob object into a specified number of fragments.
%
% The blob is split using k-means clustering of the pixel/voxel
% coordinates, with random seeding. The function is meant to split the
% blobs of cell clusters so that each cell gets its own blob fragment. If a
% cluster has fewer pixels/voxels than cells, some of the cells will get
% point blobs without pixels/voxels. The function resets the seed of the
% random number generator.
%
% Inputs:
% aBlob - Blob to be split into fragments.
% aCount - The number of fragments to be created.
%
% Outputs:
% oFragments - Array of Blob objects representing the blob fragments
%              created using k-means clustering. The blobs have the
%              original blob as super-blob.
%
% See also:
% BreakClusters, Cell, Blob

if aCount == 1
    % There is no need to perform clustering if there is only one cell.
    oFragments = aBlob.CreateSub();
    return
end

if any(isnan(aBlob.boundingBox))
    % Point blobs cannot be split.
    oFragments = [];
    for i = 1:aCount
        oFragments = [oFragments aBlob.CreateSub()]; %#ok<AGROW>
    end
    return
end

% K-means is stochastic, so for reproducibility we set the seed of the
% random number generator.
reset(RandStream.getGlobalStream);
opts = statset('MaxIter', 1000);  % Try to ensure convergence.

bb = aBlob.boundingBox;
ndims = length(bb)/2;  % Dimensionality of the image.

% Compute coordinates of all pixels/voxels in the blob.
if ndims == 2  % 2D
    [Y,X] = find(aBlob.image);
    points = [X(:) Y(:)];
else  % 3D
    ind = find(aBlob.image);
    [Y,X,Z] = ind2sub(size(aBlob.image),ind);
    points = [X(:) Y(:) Z(:)];
end

% If there are not enough pixels, some cells will not be given segments.
numClusters = min(aCount, size(points,1));

if size(points, 1) == 1
    % MATLAB's k-means does not work on a single point.
    IDX = 1;
    C = points;
else
    [IDX,C] = kmeans(points, numClusters, 'Options', opts);
end

% Create the blob fragments.
if ndims == 2  % 2D
    index = points(:,2) + size(aBlob.image, 1) * (points(:,1) - 1);
    oFragments(numClusters) = Blob();
    for j = 1:numClusters
        % Create a binary image of the same size as the old blob.
        binVec = find(IDX == j);
        labels = false(size(aBlob.image));
        labels(index(binVec)) = true;
        
        % Find the bounding box of the fragment inside the original blob.
        xMin = min(points(binVec,1));
        yMin = min(points(binVec,2));
        xMax = max(points(binVec,1));
        yMax = max(points(binVec,2));
        
        % Create properties for the blob fragment.
        props.Centroid = [bb(1)+C(j,1)-0.5 bb(2)+C(j,2)-0.5];
        props.Image = labels(yMin:yMax, xMin:xMax);
        props.BoundingBox = [bb(1)+xMin-1 bb(2)+yMin-1 xMax-xMin+1 yMax-yMin+1];
        
        % Create the blob fragment.
        fragment = Blob(props);
        fragment.super = aBlob;
        oFragments(j) = fragment;
    end
    
    % Add empty fragments (point blobs) if there were not enough pixels to
    % break the blob into the specified number of fragments.
    % TODO: Ensure in the tracking that the number of cells assigned to a
    % blob cannot exceed the number of pixels/voxels in the blob.
    for j = numClusters + 1 : aCount
        props = struct(...
            'BoundingBox', nan(1,4),...
            'Image', {{nan}},...
            'Centroid', aBlob.centroid);
        fragment = Blob(props);
        fragment.super = aBlob;
        oFragments = [oFragments fragment]; %#ok<AGROW>
    end
else  % 3D
    index = sub2ind(size(aBlob.image), points(:,2), points(:,1), points(:,3));
    oFragments(numClusters) = Blob();
    for j = 1:numClusters
        % Create a binary image of the same size as the old blob.
        binVec = find(IDX == j);
        labels = false(size(aBlob.image));
        labels(index(binVec)) = true;
        
        % Find the bounding box of the fragment inside the original blob.
        xMin = min(points(binVec,1));
        yMin = min(points(binVec,2));
        zMin = min(points(binVec,3));
        xMax = max(points(binVec,1));
        yMax = max(points(binVec,2));
        zMax = max(points(binVec,3));
        
        % Create properties for the blob fragment.
        props.Centroid = [bb(1)+C(j,1)-0.5 bb(2)+C(j,2)-0.5 bb(3)+C(j,3)-0.5];
        props.BoundingBox = [bb(1)+xMin-1 bb(2)+yMin-1 bb(3)+zMin-1 ...
            xMax-xMin+1 yMax-yMin+1 zMax-zMin+1];
        props.Image = labels(yMin:yMax, xMin:xMax, zMin:zMax);
        
        % Create the blob fragment.
        fragment = Blob(props);
        fragment.super = aBlob;
        oFragments(j) = fragment;
    end
    
    % Add empty fragments (point blobs) if there were not enough pixels to
    % break the blob into the specified number of fragments.
    % TODO: Ensure in the tracking that the number of cells assigned to a
    % blob cannot exceed the number of pixels/voxels in the blob.
    for j = numClusters + 1 : aCount
        props = struct(...
            'BoundingBox', nan(1,6),...
            'Image', {{nan}},...
            'Centroid', aBlob.centroid);
        fragment = Blob(props);
        fragment.super = aBlob;
        oFragments = [oFragments fragment]; %#ok<AGROW>
    end
end
end