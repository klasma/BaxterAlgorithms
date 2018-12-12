function oCells = BipartiteMatch(aCells, aImData)
% Breaks clusters and swaps assignments to optimize the scoring function.
%
% BipartiteMatch breaks cell clusters and swaps assignments in cell chains
% in an attempt to maximize the migration scores and scores for appearance
% and disappearance after cell clusters have been broken into individual
% cells. Mitotic and apoptotic events are not moved from one track to
% another, but the daughter cells of a mitotic events can change if the
% migration events following directly after the mitotic event are changed.
% The splitting of clusters is done using k-means clustering of pixel
% coordinates, with random seeding.
%
% Inputs:
% aCells - Array of Cell objects where multiple cells can be associated
%          with the same outline.
% aImData - ImageData object associated with the image sequence.
%
% Outputs:
% oCells - Array of Cell objets where every cell has its own outline.
%
% See also:
% BreakClusters, Hungarian.cpp, BipartiteMatch_correction

oCells = aCells;
if isempty(oCells)
    % There is nothing to match.
    return
end

% Score put on edges that are not allowed in the matching.
INF_SCORE = -1E4;

% Consider all matching options and not just the most likely ones.
imData = aImData.Clone();
imData.Set('TrackNumNeighbours', inf)

% Blobs from segmentation.
blobSeq = Cells2Blobs(oCells, aImData);

fprintf(['Performing bipartite matching and post tracking segmentation '...
    'on frame %d / %d.\n'], 1, length(blobSeq))
BreakClusters(oCells, blobSeq{1}, 1, imData)

for t = 2 : length(blobSeq)
    fprintf(['Performing bipartite matching and post tracking '...
        'segmentation on frame %d / %d.\n'], t, length(blobSeq))
    
    BreakClusters(oCells, blobSeq{t}, t, imData)
    
    % % Extract cells that undergo different events.
    
    firstFrames = [oCells.firstFrame];
    lastFrames = [oCells.lastFrame];
    divided = [oCells.divided];
    appeared = [oCells.firstFrame] > 1 &...
        arrayfun(@(x)isempty(x.parent),oCells);
    disappeared = [oCells.disappeared];
    
    cellsToMigrate = oCells(firstFrames <= t-1 & lastFrames >= t);
    cellsToAppear = oCells(firstFrames == t & appeared);
    cellsToDisappear = oCells(lastFrames == t-1 & disappeared);
    parents = oCells(lastFrames == t-1 & divided);
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
    
    scores = INF_SCORE * ones(nMig + nApp + nDis + 2*nMit + min(nMig,20));
    scores(length(blobs{1})+1:end,length(blobs{2})+1:end) = 0;
    
    % Enter migration scores.
    migrationScores = MigrationScores_generic(blobs, imData);
    if ~isempty(migrationScores)
        scores(sub2ind(size(scores), migrationScores(:,2), migrationScores(:,3))) =...
            max(migrationScores(:,5) - migrationScores(:,4), INF_SCORE/10);
    end
    
    % Enter appearance scores.
    appearScores = AppearanceScores(blobs, imData);
    for i = 1:size(appearScores,1)
        scores(length(blobs{1})+1:end, appearScores(i,2)) =...
            max(appearScores(i,4) - appearScores(i,3), INF_SCORE/10);
    end
    
    % Enter disappearance scores.
    blobs{1} = blobs{1}(1:nMig+nDis);  % Dividing cells are not allowed to disappear.
    disappearScores = DisappearanceScores(blobs, imData);
    for i = 1:size(disappearScores,1)
        scores(disappearScores(i,2), length(blobs{2})+1:end) =...
            max(disappearScores(i,4) - disappearScores(i,3), INF_SCORE/10);
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
    cellsAfterMigration = cellsToMigrate;
    for i = 1:length(cellsAfterMigration)
        cellsAfterMigration(i) = cellsAfterMigration(i).Split(t);
    end
    % Cells starting at time t.
    cells2 = [cellsAfterMigration cellsToAppear daughters];
    
    % Add links for migrations.
    for i = 1:length(cells1) % Put cell chains back together.
        if match(i) <= length(cells2)
            if scores(i,match(i)) > INF_SCORE
                cells1(i).AddCell(cells2(match(i)));
            else
                % The migration is impossible.
                cells1(i).disappeared = true;
                oCells = [oCells cells2(match(i))]; %#ok<AGROW>
            end
        else
            cells1(i).disappeared = true;
        end
    end
    
    % Add links for mitosis.
    for i = 1:nMit
        daughter1 = cells2( match(nMig + nDis + 2*i - 1) );
        daughter2 = cells2( match(nMig + nDis + 2*i) );
        score1 = scores(nMig + nDis + 2*i - 1, match(nMig + nDis + 2*i - 1));
        score2 = scores(nMig + nDis + 2*i, match(nMig + nDis + 2*i));
        if score1 > INF_SCORE && score2 > INF_SCORE
            parents(i).AddChild(daughter1);
            parents(i).AddChild(daughter2);
            % All daughter cells have been removed from the output.
            oCells = [oCells daughter1 daughter2]; %#ok<AGROW>
        elseif score1 > INF_SCORE
            % The migration to daughter 2 is impossible.
            parents(i).AddCell(daughter1);
            oCells = [oCells daughter2]; %#ok<AGROW>
        elseif score2 > INF_SCORE
            % The migration to daughter 1 is impossible.
            parents(i).AddCell(daughter2);
            oCells = [oCells daughter1]; %#ok<AGROW>
        else
            % The migrations to both daughters are impossible.
            parents(i).disappeared = true;
            oCells = [oCells daughter1 daughter2]; %#ok<AGROW>
        end
    end
    
    % Add appearing cells.
    for i = 1 : nApp + min(nMig,20)
        m = match(nMig + nDis + 2*nMit + i);
        if m <= length(cells2)
            appearingCell = cells2(m);
            oCells = [oCells appearingCell]; %#ok<AGROW>
        end
    end
end
end