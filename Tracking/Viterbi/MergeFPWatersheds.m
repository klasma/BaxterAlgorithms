function oBlobSeq = MergeFPWatersheds(aImData, aCells, aBlobSeq)
% Reduces watershed over-segmentation by merging false positive blobs.
%
% The function merges false positive blobs, generated through watershed
% algorithm over-segmentation, into adjacent cell segments. The function
% operates only on 2D Blobs.
%
% First the function merges adjacent false positive blobs and after that,
% it merges false positive blobs adjacent to cell blobs into the cell
% blobs. Regions that are closer than 2*sqrt(2) pixels apart are merged,
% regardless of whether or not they were separated by the watershed
% algorithm. If the distance between the regions is 2*sqrt(2) pixels or
% more, they can however not have been separated by the watershed
% algorithm.
%
% Inputs:
% aImData - Image data associated with the image sequence.
% aCells - Array of cell objects that the false positive blobs can be
%          merged into.
% aBlobSeq - Cell array of blobs where each cell has an array with Blob
%            objects. There is one cell per image and it contains the blobs
%            in that image.
%
% Outputs:
% oBlobSeq - Cell array with the false positive blobs that remain after the
%            function is done merging.
%
% See also:
% MeregeFPWatersheds3D, MergeWatersheds.cpp

oBlobSeq = aBlobSeq;

% Merge blobs to other blobs.
for f = 1:length(oBlobSeq)
    segmentsBlob = ReconstructSegmentsBlob(oBlobSeq{f}, aImData.GetSize());
    deleteBlobs = [];  % Indices of blobs that have been merged into other blobs.
    for i = 1:length(oBlobSeq{f})
        if any(deleteBlobs == i)
            continue
        end
        
        b = oBlobSeq{f}(i);
        
        if any(isnan(b.boundingBox))
            % Point blobs can not be merged.
            continue
        end
        
        % Create a dilated version of blob i, that overlaps with the blobs
        % that blob i is adjacent to.
        dilatedBlob = DilateBlob(aImData, b, ones(3));
        dilatedBlob = DilateBlob(aImData, dilatedBlob, [0 1 0; 1 1 1; 0 1 0]);
        bb = dilatedBlob.boundingBox;
        
        % Find the other blobs that the blob under analysis is adjacent to.
        overlapBlob = segmentsBlob(bb(2)+0.5:bb(2)+bb(4)-0.5, bb(1)+0.5:bb(1)+bb(3)-0.5)...
            .* dilatedBlob.image;
        overlapBlob = unique(overlapBlob(overlapBlob~=0));
        overlapBlob = setdiff(overlapBlob, i);  % The blob is adjacent to itself.
        
        % Merge all of the adjacent blobs into blob i.
        if ~isempty(overlapBlob)
            CombineBlobs(b, oBlobSeq{f}(overlapBlob));
            deleteBlobs = [deleteBlobs; overlapBlob(:)]; %#ok<AGROW>
            
            % Make sure that blobs that are adjacent to the blobs in
            % overlapBlob will be merged into blob i.
            deleteSegments = ReconstructSegmentsBlob(oBlobSeq{f}(overlapBlob), aImData.GetSize());
            segmentsBlob(deleteSegments > 0) = i;
        end
    end
    % Remove blob objects that have been merged into other blobs.
    oBlobSeq{f}(deleteBlobs) = [];
end

% Merge blobs to cells.
for f = 1:length(oBlobSeq)
    segmentsCell = ReconstructSegments(aImData, aCells, f);
    % Indices of blobs that have been merged into other blobs.
    deleteBlobs = false(size(oBlobSeq{f}));
    for i = 1:length(oBlobSeq{f})
        b = oBlobSeq{f}(i);
        
        if any(isnan(b.boundingBox))
            % Point blobs can not be merged.
            continue
        end
        
        % Create a dilated version of blob i, that overlaps with the cells
        % that the blob i is adjacent to.
        dilatedBlob = DilateBlob(aImData, b, ones(3));
        dilatedBlob = DilateBlob(aImData, dilatedBlob, [0 1 0; 1 1 1; 0 1 0]);
        bb = dilatedBlob.boundingBox;
        
        % Find the cells that the blob is adjacent to.
        overlapCell = segmentsCell(bb(2)+0.5:bb(2)+bb(4)-0.5, bb(1)+0.5:bb(1)+bb(3)-0.5)...
            .* dilatedBlob.image;
        overlapCell = unique(overlapCell(overlapCell~=0));
        
        if ~isempty(overlapCell)
            % Find the closest cell.
            distances = zeros(size(overlapCell));
            for j = 1:length(distances)
                c = aCells(overlapCell(j));
                distances(j) = norm(b.centroid(:) - [c.GetCx(f); c.GetCy(f)]);
            end
            [~, minIndex] = min(distances);
            
            % Merge the blob into the closest cell.
            closestCell = aCells(overlapCell(minIndex));
            cellBlob = closestCell.blob(f-closestCell.firstFrame+1);
            % This region can contain many cells, but it has to be altered.
            CombineBlobs(cellBlob.super, b);
            CombineBlobs(cellBlob, b);
            
            deleteBlobs(i) = true;
        end
    end
    % Remove blob objects that have been merged into cells.
    oBlobSeq{f}(deleteBlobs) = [];
end
MoveCentroids(aCells)
end