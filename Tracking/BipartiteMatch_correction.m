function [oCells, oEditedCells] =...
    BipartiteMatch_correction(aCells, aBlobSeq, aBlobIndices, aTmax, aImData)
% Bipartite matching routine where a subset of the matchings are changed.
%
% Just like BipartiteMatch, this function breaks clusters of cells using
% k-means clustering and then changes assignments to optimize the scoring
% function. In contrast to BipartiteMatch, this function can however break
% clusters and change assignments in a subset of the cells. This is used to
% reduce the processing time during manual correction, where only the
% matchings that involve edited blobs need to be updated.
%
% Inputs:
% aCells - Array with Cell objects representing all tracks in the image
%          sequence.
% aBlobSeq - Cell array where cell i contains all of the blobs that were
%            created in the segmentation of frame i.
% aBlobIndices - Cell array with information about which blobs to update.
%                Cell i is a binary array which indicates which blobs in
%                frame i should be processed. Cell objects which are not
%                inside these blobs will not be changed. Assignments of
%                parents and daughters can however change if the parent or
%                the daughter is inside one of the blobs.
% aTmax - The last frame to process. The blobs and assignments in
%         subsequent frames are not changed.
% aImData - ImageData object associated with the image sequence.
%
% Outputs:
% oCells - Array with Cell objects representing all tracks in the image
%          sequence after modifications made by the function.
% oEditedCells - Array of Cell objects that were changed by the function.
%
% See also:
% BipartiteMatch, BreakClusters, Hungarian, ManualCorrectionPlayer

oCells = aCells;
oEditedCells = [];
if isempty(oCells)
    % There are no cells to process.
    return
end

% Score put on edges that are not allowed in the matching.
INF_SCORE = -1E4;

% Consider all matching options and not just the most likely ones.
imData = aImData.Clone();
imData.Set('TrackNumNeighbours', inf)

for t = 1 : aTmax
    if ( t == 1 || ~any(aBlobIndices{t-1}) ) &&  ~any(aBlobIndices{t})
        % There are no blobs that need to be updated in this frame.
        continue
    end
    
    % Cells to be updated in this iteration of the loop.
    indexedCells = [];
    for i = 1:length(oCells)
        c = oCells(i);
        if c.firstFrame <= t-1 && c.lastFrame >= t-1 &&...
                aBlobIndices{t-1}(c.GetBlob(t-1).super.index)
            % The cell is present in a blob of image t-1.
            indexedCells = [indexedCells c]; %#ok<AGROW>
        elseif c.firstFrame <= t && c.lastFrame >= t &&...
                aBlobIndices{t}(c.GetBlob(t).super.index)
            % The cell is present in a blob of image t.
            indexedCells = [indexedCells c]; %#ok<AGROW>
        elseif c.firstFrame == t && ~isempty(c.parent) &&...
                aBlobIndices{t-1}(c.parent.GetBlob(t-1).super.index)
            % The parent of the cell is present in a blob of image t-1.
            indexedCells = [indexedCells c]; %#ok<AGROW>
        elseif c.lastFrame == t-1 && ~isempty(c.children) &&...
                (aBlobIndices{t}(c.children(1).GetBlob(t).super.index) ||...
                aBlobIndices{t}(c.children(2).GetBlob(t).super.index))
            % One of the daughters of the cell is present in a blob of
            % image t.
            indexedCells = [indexedCells c]; %#ok<AGROW>
        end
    end
    
    if isempty(indexedCells)
        % The blobs to be updated only had false positive cells.
        continue
    end
    
    BreakClusters(indexedCells, aBlobSeq{t}, t, imData)
    
    if t == 1
        % In the first iteration, we only split clusters.
        if nargout > 1
            oEditedCells = [oEditedCells indexedCells]; %#ok<AGROW>
        end
        continue
    end
    
    % % Extract cells that undergo different events.
    
    firstFrames = [indexedCells.firstFrame];
    lastFrames = [indexedCells.lastFrame];
    divided = [indexedCells.divided];
    appeared = [indexedCells.firstFrame] > 1 &...
        arrayfun(@(x)isempty(x.parent),indexedCells);
    disappeared = [indexedCells.disappeared];
    
    cellsToMigrate = indexedCells(firstFrames <= t-1 & lastFrames >= t);
    cellsToAppear = indexedCells(firstFrames == t & appeared);
    cellsToDisappear = indexedCells(lastFrames == t-1 & disappeared);
    parents = indexedCells(lastFrames == t-1 & divided);
    daughters = [];
    for i = 1:length(parents)
        daughters = [daughters parents(i).children]; %#ok<AGROW>
    end
    
    % The number of cells that undergo each event.
    nMig = length(cellsToMigrate);
    nApp = length(cellsToAppear);
    nDis = length(cellsToDisappear);
    nMit = length(parents);
    
    % % Extract the blobs of the cells.
    
    blobs = cell(1,2);
    for i = 1:length(cellsToMigrate)
        blobs{1} = [blobs{1} cellsToMigrate(i).GetBlob(t-1)];
        blobs{2} = [blobs{2} cellsToMigrate(i).GetBlob(t)];
    end
    for i = 1:length(cellsToAppear)
        blobs{2} = [blobs{2} cellsToAppear(i).GetBlob(t)];
    end
    for i = 1:length(cellsToDisappear)
        blobs{1} = [blobs{1} cellsToDisappear(i).GetBlob(t-1)];
    end
    for i = 1:length(parents)
        % The parent blobs are added twice, as they need to be matched to
        % two daughters.
        blobs{1} = [blobs{1} parents(i).blob(end) parents(i).blob(end)];
    end
    for i = 1:length(daughters)
        blobs{2} = [blobs{2} daughters(i).blob(1)];
    end
    
    % % Compute scores for different matching options.
    
    scores = INF_SCORE * ones(nMig + nApp + nDis + 2*nMit);
    
    % Enter migration scores.
    migrationScores = MigrationScores_generic(blobs, imData);
    if ~isempty(migrationScores)
        scores(sub2ind(size(scores), migrationScores(:,2), migrationScores(:,3))) =...
            migrationScores(:,5) - migrationScores(:,4);
    end
    
    % Enter appearance scores.
    appearScores = AppearanceScores(blobs, imData);
    for i = 1:size(appearScores,1)
        scores(length(blobs{1})+1:end, appearScores(i,2)) =...
            appearScores(i,4) - appearScores(i,3);
    end
    
    % Enter disappearance scores.
    blobs{1} = blobs{1}(1:nMig+nDis);  % Dividing cells are not allowed to disappear.
    disappearScores = DisappearanceScores(blobs, imData);
    for i = 1:size(disappearScores,1)
        scores(disappearScores(i,2), length(blobs{2})+1:end) =...
            disappearScores(i,4) - disappearScores(i,3);
    end
    
    % % Perform matching.
    
    match = Hungarian(-scores);
    
    % % Break cell chains and put them together according to the matching.
    
    for i = 1:length(parents)
        % Break mitotic links.
        parents(i).RemoveChildren();
    end
    % The daughter cells and appearing cells can become second halves of
    % tracks and should therefore not be in the outputs any more.
    oCells = SetdiffCells(oCells, [daughters cellsToAppear]);
    % Cells ending at time t-1.
    cells1 = [cellsToMigrate cellsToDisappear];
    if nargout > 1
        oEditedCells = [oEditedCells cells1]; %#ok<AGROW>
    end
    cellsAfterMigration = cellsToMigrate;
    for i = 1:length(cellsAfterMigration)
        cellsAfterMigration(i) = cellsAfterMigration(i).Split(t);
    end
    % Cells starting at time t.
    cells2 = [cellsAfterMigration cellsToAppear daughters];
    
    % Add links for migrations.
    for i = 1:length(cells1) % Put cell chains back together.
        if match(i) <= length(cells2)
            cells1(i).AddCell(cells2(match(i)));
        else
            cells1(i).disappeared = true;
        end
    end
    
    % Add links for mitosis.
    for i = 1:nMit
        daughter1 = cells2( match(nMig + nDis + 2*i - 1) );
        daughter2 = cells2( match(nMig + nDis + 2*i) );
        parents(i).AddChild(daughter1);
        parents(i).AddChild(daughter2);
        % All daughter cells have been removed from the output.
        oCells = [oCells daughter1 daughter2]; %#ok<AGROW>
        if nargout > 1
            oEditedCells = [oEditedCells daughter1 daughter2]; %#ok<AGROW>
        end
    end
    
    % Add appearing cells.
    for i = 1:nApp
        appearingCell = cells2(match(nMig + nDis + 2*nMit + i));
        oCells = [oCells appearingCell]; %#ok<AGROW>
        if nargout > 1
            oEditedCells = [oEditedCells appearingCell]; %#ok<AGROW>
        end
    end
end

if nargout > 1
    % Cells may have been added to this array multiple times.
    oEditedCells = UniqueCells(oEditedCells);
end
end