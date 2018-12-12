function oCells = SwitchSegmentation(aImData, aCells, aBlobSeq, varargin)
% Switches the segmentation of previously tracked cells.
%
% The cells are first assigned to the blobs in the new segmentation with
% which they overlap the most. Then the blobs which have been assigned to
% multiple cells are broken into the correct number of fragments using
% k-means clustering with random seeding. Finally, the fragments are
% assigned to the cells so that the sum of the squares of the distances
% between the previous cell centroids and the centroids of the assigned
% blob fragments is minimized.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aCells - Previously tracked cells.
% aBlobSeq - Cell array of blobs segmented using the new segmentation
%            algorithm. Cell t contains an array with blobs at time point
%            t.
%
% Property/Value inputs:
% RedoMatching - Specifies if bipartite matching should be used to change
%                track links. The default value is false.
% MergeWatersheds - Specifies if false positive detections should be merged
%                   into adjacent cells, to deal with watershed
%                   over-segmentation. The default value is false.
% aGate - This input argument can be used to specify a gate in which to
%         look for blobs in the new segmentation. The gate is a circle or a
%         ball and this input argument gives the radius in pixels. If a
%         radius is specified, the cells are matched to the closest blob
%         centroid inside the gate instead of to the blob with the largest
%         overlap. This can be useful if the tracked objects are very
%         small, so that they cannot be assumed to overlap in different
%         segmentations. By default, this parameter is set to nan, and then
%         the overlaps are used to do the matching.
%
% Outputs:
% oCells - Cells with new segments. The function also alters aCells.
%
% See also:
% ReplaceSegemtation

% Get property/value inputs.
[aRedoMatching, aMergeWatersheds, aGate] = GetArgs(...
    {'RedoMatching', 'MergeWatersheds', 'Gate'},...
    {false, false, nan},...
    true,...
    varargin);

trueCells = AreCells(aCells);
IndexBlobs(aBlobSeq)  % Just in case the indices are incorrect.
if aImData.sequenceLength < max([aCells.lastFrame])
    % Pad with empty cells if the blob vector is shorter than the image
    % sequence. This can happen if there are no segments in the last image.
    aImData.sequenceLength = max([aCells.lastFrame]);
    aBlobSeq = [aBlobSeq cell(1, aImData.sequenceLength-length(aBlobSeq))];
end

if ~isempty(strfind(aImData.Get('TrackMigLogLikeList'), 'PHD'))
    % Compute GM-PHDs for all time points if the migration scores are based
    % on a GM-PHD filter.
    ComputeGMPHD(aBlobSeq, aImData);
end

% Cells that overlap with the blobs in aBlobSeq.
overlapCells = cell(size(aBlobSeq));
for t = 1:length(aBlobSeq)
    overlapCells{t} = cell(length(aBlobSeq{t}),1);
end
% Cells that don't overlap with blobs in aBlobSeq.
pointCells = cell(size(aBlobSeq));

blobCentroids = cell(size(aBlobSeq));
for t = 1:length(blobCentroids)
    if ~isempty(aBlobSeq{t})
        blobCentroids{t} = cat(1,aBlobSeq{t}.centroid);
    end
end

% Look for overlaps between blobs and cells.
for i = 1:length(trueCells)
    fprintf('Looking for overlaps for cell %d / %d\n', i, length(trueCells))
    c = trueCells(i);
    for t = c.firstFrame : c.lastFrame
        b = c.GetBlob(t);
        % Find the blobs with the largest overlap.
        overlaps = zeros(length(aBlobSeq{t}),1);
        if isnan(aGate)
            for j = 1:length(aBlobSeq{t})
                if ~any(isnan(b.boundingBox))
                    overlaps(j) = Overlap(b, aBlobSeq{t}(j));
                else
                    % Point blobs are said to overlap in one pixel if they
                    % are inside a region and can only overlap with one
                    % blob.
                    if length(b.centroid) == 3
                        overlaps(j) = aBlobSeq{t}(j).IsInside(...
                            b.centroid(1), b.centroid(2), b.centroid(3));
                    else
                        overlaps(j) = aBlobSeq{t}(j).IsInside(...
                            b.centroid(1), b.centroid(2));
                    end
                end
            end
        else
            cellCentroid = repmat(b.centroid, size(blobCentroids{t},1), 1);
            dist = sqrt(sum((blobCentroids{t}-cellCentroid).^2, 2));
            overlaps = max(0, aGate - dist);
        end
        
        [maxOverlap, maxIndex] = max(overlaps);
        
        % Store the cell in the right place for subsequent processing.
        if maxOverlap > 0
            overlapCells{t}{maxIndex} = [overlapCells{t}{maxIndex}; c];
        else
            pointCells{t} = [pointCells{t} c];
        end
    end
end

% Swap cell blobs for which there are segments in the new segmentation.
for t = 1:length(aBlobSeq)
    fprintf('Swapping blobs for image %d / %d\n', t, length(aBlobSeq))
    for j = 1:length(aBlobSeq{t})
        if isempty(overlapCells{t}{j})
            % No cells overlapped with the blob. A false positive cell will
            % be created later.
            continue
        end
        
        % Break the cell cluster.
        fragments = KMeansSplit(aBlobSeq{t}(j), length(overlapCells{t}{j}));
        
        % Compute the centroids of the fragments.
        fragmentCentroids = cat(1,fragments.centroid);
        
        % Compute the centroids of the ground truth cells.
        cellCentroids = nan(size(fragmentCentroids));
        for i = 1:length(overlapCells{t}{j})
            cellCentroids(i,:) = overlapCells{t}{j}(i).GetBlob(t).centroid;
        end
        
        % Assign the blob fragments to the cells so that the sum of the
        % squared distances is minimized.
        order = MinSquareDist(cellCentroids, fragmentCentroids);
        for i = 1:length(overlapCells{t}{j})
            overlapCells{t}{j}(i).SetBlob(fragments(order(i)), t)
        end
    end
end

% Create empty blobs for for cells that don't overlap with segments in the
% new segmentation.
for t = 1:length(aBlobSeq)
    fprintf('Creating empty blobs for image %d / %d\n', t, length(aBlobSeq))
    for i = 1:length(pointCells{t})
        oldBlob = pointCells{t}(i).GetBlob(t);
        emptyBlob = Blob(struct(...
            'BoundingBox', nan(size(oldBlob.boundingBox)),...
            'Image', nan,...
            'Centroid', oldBlob.centroid),...
            't', t,...
            'index', length(aBlobSeq{t})+i);
        pointCells{t}(i).SetBlob(emptyBlob.CreateSub(), t)
    end
end

% Add false positive cells corresponding to the blobs with no cells.
falseBlobs = FalseBlobs(aBlobSeq, trueCells);

% Redo bipartite matching.
if aRedoMatching
    trueCells = BipartiteMatch(trueCells, aImData);
end

% Merge false positives into adjacent cells.
if aMergeWatersheds
    if aImData.numZ == 1  % 2D
        falseBlobs = MergeFPWatersheds(aImData, trueCells, falseBlobs);
    else  % 3D
        falseBlobs = MergeFPWatersheds3D(aImData, trueCells, falseBlobs);
    end
end

% Handle blobs that were not assigned to any cells.
if aImData.Get('TrackFalsePos') == 1
    % Link false positive detections into tracks.
    falseCells = FPTrack(falseBlobs, aImData);
    
    if aImData.Get('TrackSaveFPAsCells')
        for i = 1:length(falseCells)
            falseCells(i).isCell = true;
        end
    end
    
    oCells = [trueCells, falseCells];
elseif aImData.Get('TrackFalsePos') == 2
    % Create a separate false positive cell for each detection.
    numBlobs = sum(cellfun(@length, falseBlobs));
    if numBlobs > 0
        falseCells(numBlobs) = Cell();
        n = aImData.GetDim();
        index = 1;
        for t = 1:length(falseBlobs)
            fprintf('Creating false positive cells for image %d / %d\n',...
                t, length(falseBlobs))
            for i = 1:length(falseBlobs{t})
                b = falseBlobs{t}(i);
                if n == 3  % 3D data.
                    cz = b.centroid(3);
                else  % 2D data.
                    cz = 0;
                end
                c = Cell(...
                    'imageData', aImData,...
                    'blob', b.CreateSub(),...
                    'cx', b.centroid(1),...
                    'cy', b.centroid(2),...
                    'cz', cz,...
                    'firstFrame', t,...
                    'lifeTime', 1,...
                    'isCell', false);
                falseCells(index) = c;
                index = index + 1;
            end
        end
    else
        falseCells = [];
    end
    oCells = [trueCells, falseCells];
else
    % Do not include false positive detections in the results.
    oCells = trueCells;
end
end