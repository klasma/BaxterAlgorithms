function oCells = SelectCellsFromGTPixels(aCells, aImData, varargin)
% Selects tracks which match a ground truth segmentation in frame 1.
%
% This function is used to pick out cells that have a ground truth in the
% Drosophila embryos of the CTC 2015. To match blobs in the tracks with
% blobs in the ground truth, the function uses the average distance between
% pixels in the track blob and the corresponding closest pixels in the
% ground truth blobs. The blobs also need to overlap in at least one pixel.
%
% Inputs:
% aCells - Array with all the tracked cells.
% aImData - ImageData object of the image sequence. If re-linking is done,
%           the object must have the version property defined.
%
% Property/Value inputs:
% KeepAll - If this is set to true, cells which are not selected will be
%           kept as false positives, otherwise the cells are not kept.
% Relink - If this is set to true, the tracks of the selected cells are
%          extended to span the entire image sequence. This is done by
%          appending sections of un-selected tracks. The linking is done by
%          propagating the cell, which should be extended, to the next
%          image and finding the closest un-selected track there.
%
% Outputs:
% oCells - Array of selected Cell objects.
%
% See also:
% AvgMinPixelDist, GetGTBlobs, KalmanFilterCell, SaveSelectedGTCells

% Parse property/value inputs.
[aKeepAll, aRelink] =...
    GetArgs({'KeepAll', 'Relink'}, {false, false}, true, varargin);

% Find ground truth blobs in the first image.
blobs = GetGTBlobs(aImData, 1);

keepCells = false(size(aCells));
usedBlobs = false(size(blobs));

% Keep all cells that overlap with a ground truth blob.
for i = 1:length(blobs)
    fprintf('Looking for overlap on blob %d / %d\n', i, length(blobs))
    for j = 1:length(aCells)
        if aCells(j).firstFrame == 1
            cellBlob = aCells(j).GetBlob(1);
            overlap = Overlap(cellBlob, blobs(i));
            if overlap > 0
                keepCells = SetToKeep(aCells, aCells(j), keepCells);
                usedBlobs(i) = true;
            end
        end
    end
end

blobs = blobs(~usedBlobs);
usedBlobs = false(size(blobs));

% Find the average distances to the closest pixels in the ground truth
% blobs.
dists = zeros(length(blobs), length(aCells));
for i = 1:length(blobs)
    fprintf('Matching ground truth blob %d / %d\n', i, length(blobs))
    for j = 1:length(aCells)
        if aCells(j).firstFrame > 1
            % Cells not present in the first image cannot be matched.
            dists(i,j) = inf;
        else
            cellBlob = aCells(j).GetBlob(1);
            dists(i,j) = AvgMinPixelDist(blobs(i), cellBlob, aImData);
        end
    end
end
fprintf('Done matching ground truth blobs\n')

% For each blob, add the closest cell track in the first image. When there
% are conflicts, the smallest distances are processed first. The progeny of
% the added cells are added recursively.
[sortedDists, order] = sort(dists(:), 'ascend');
for i = 1:length(sortedDists)
    if sortedDists(i) == inf
        % All subsequent distances will also be inf.
        break
    end
    [b, c] = ind2sub(size(dists), order(i));
    if ~keepCells(c) && ~usedBlobs(b)
        keepCells = SetToKeep(aCells, aCells(c), keepCells);
        usedBlobs(b) = true;
    end
end

% Check if tracks were found for all ground truth blobs.
if sum(keepCells) < length(blobs)
    warning('%d cells could not be found\n', length(blobs)-sum(keepCells))
end

oCells = aCells;

% Specify that all matching objects should be cells and that everything
% else is false positives.
for i = 1:length(oCells)
    if keepCells(i)
        oCells(i).isCell = true;
    else
        oCells(i).isCell = false;
    end
end

if aRelink
    fprintf('Extending selected cells\n')
    oCells = Relink(oCells, aImData);
    fprintf('Done extending selected cells\n')
end

if ~aKeepAll
    % Do not include un-selected cells as false positives. We cannot use
    % keepCells for indexing because Relink may have removed cells.
    oCells = AreCells(oCells);
end
end

function oCells = Relink(aCells, aImData)
% Relinks selected tracks that end before the last frame.
%
% Cells where the isCell property is true are extended, by linking them to
% fragments of cells where the isCell property is false, until they reach
% the end of the image sequence. This is done by appending sections of
% false positive tracks. The linking is done by propagating the cell, which
% should be extended, to the next image and finding the closest false
% positive track there. No link is created if the false positive track is
% more than 100 pixels away.
%
% Inputs:
% aCells - Array with all cells.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oCells - Cell array where the true cells have been extended.

% Maximum number of pixels in linked gap.
distThreshold = 100;

oCells = aCells;
areCells = AreCells(oCells);

% Cells that need to be extended.
brokenCells = areCells(arrayfun(@(x)~x.Exist(aImData.sequenceLength), areCells));

if isempty(brokenCells)
    % No cells need to be extended.
    return
end

for i = 1:length(brokenCells)
    % Extend each cell until it reaches the last image or until there are
    % no other cells to use for the extension.
    while brokenCells(i).lastFrame < aImData.sequenceLength
        fromCell = brokenCells(i);
        fromFrame = fromCell.lastFrame;
        toFrame = fromFrame + 1;
        toCells = AliveCells(NotCells(oCells), toFrame);
        
        
        % % Perform matching on using the previous position.
        % fromCentroid = fromCell.GetBlob(fromFrame).centroid;
        
        % Perform matching using the propagated previous position.
        fromCentroid = KalmanFilterCell(fromCell, toFrame, aImData);
        
        % Centroid positions in the next frame.
        toCentroids = nan(length(toCells), aImData.GetDim());
        for j = 1:length(toCells)
            toCentroids(j,:) = toCells(j).GetBlob(toFrame).centroid;
        end
        
        % The distances from the position in the previous image to all
        % positions in the next image.
        differences = toCentroids - repmat(fromCentroid, size(toCentroids,1), 1);
        differences(:,3) = differences(:,3) * aImData.voxelHeight;
        distances = sqrt(sum(differences.^2, 2));
        
        [minDist, minIndex] = min(distances);
        
        % Extend the track.
        if minDist < distThreshold
            closestToCell = toCells(minIndex);
            if closestToCell.firstFrame == toFrame
                % Append and entire track.
                oCells(oCells == closestToCell) = [];
            else
                % Append the end of a track.
                closestToCell = closestToCell.Split(toFrame);
            end
            brokenCells(i).AddCell(closestToCell);
        else
            break
        end
    end
end
end

function oKeepVector = SetToKeep(aAllCells, aCell, aKeepVector)
% Specifies that a cell and all its progeny should be kept.
%
% The function recursively adds the cell and its progeny to the binary
% array which indicates which cells should be included in the output.
%
% Inputs:
% aAllCells - Array of all cell objects.
% aCell - The cell object that should be kept in the output. All progeny of
%         this cell will also be kept.
% aKeepVector - Binary array of the same size as aAllCells, which
%               indicates which cells have already been marked to be kept.
%
% Outputs:
% oKeepVector - Binary array indicating which cells should be kept in the
%               output, after aCell and its progeny have been added.

oKeepVector = aKeepVector;

% Keep the cell itself.
oKeepVector(aAllCells == aCell) = true;

% Keep the daughter cells and their progeny.
for i = 1:length(aCell.children)
    oKeepVector = SetToKeep(aAllCells, aCell.children(i), oKeepVector);
end
end