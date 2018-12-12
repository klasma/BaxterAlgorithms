function oCells = FPTrack(aBlobSeq, aImData)
% Links false positive blobs into false positive tracks.
%
% Blobs that were found to be false positive detections by the program are
% linked into false positive tracks, so that the tracks can be used in the
% manual correction step, in case the false positive blobs contain real
% cells. It is much faster to mark a false positive track as being a true
% track than to manually link all the false positive blobs into a track.
% The linking is done using Viterbi track linking. The migration scores are
% the same as those used for tracking of cells, but the count scores are
% set so that all blobs get a single cell associated with them. The scores
% for appearance and disappearance are set so that unlikely migrations are
% not included in the tracks. Mitosis and apoptosis are not allowed. In the
% Viterbi track linking, there is a single idle state in each image, for
% both tracks that have not yet entered the sequence and tracks that have
% left the sequence. This makes it possible to add multiple tracks in each
% iteration, and results in a significant speedup in cases when a large
% number of short tracks need to be added.
%
% Inputs:
% aBlobSeq - Cell array with one cell per frame in the image sequence. Each
%            cell contains an array with the false positive blobs that were
%            found in the corresponding frame.
% aImData - ImageData object associated with the image sequence.
%
% Outputs:
% oCells - Array of Cell objects representing the false positive tracks.
%          The isCell property is set to false for all cells, indicating
%          that they are considered to be false positives.
%
% See also:
% Track, ViterbiTrackLinking.cpp, Cell, Blob

% Minimum migration score. Migrations with a lower score will not be
% included in the false positive tracks.
MIN_MIG_SCORE = log(1E-2);

% The number of blos in each frame.
numDets = cellfun(@length, aBlobSeq);

fprintf('Computing scores for connection of false positives.\n')

% Mitosis and apoptosis are not allowed.
splitScores = [];
deathScores = [];

% Set appearance scores to exclude unlikely migrations.
appearanceScores = zeros(sum(numDets(2:end)), 4);
index = 1;
for t = 2:length(aBlobSeq)
    for i = 1:length(aBlobSeq{t})
        appearanceScores(index, :) = [t i 0 MIN_MIG_SCORE/2];
        index = index + 1;
    end
end

% Set disappearance scores to exclude unlikely migrations.
disappearanceScores = zeros(sum(numDets(1:end-1)), 4);
index = 1;
for t = 1:length(aBlobSeq)-1
    for i = 1:length(aBlobSeq{t})
        disappearanceScores(index, :) = [t i 0 MIN_MIG_SCORE/2];
        index = index + 1;
    end
end

% Set counts scores so that all blobs get exactly one cell.
countScores = zeros(sum(numDets), 5);
index = 1;
for t = 1:length(aBlobSeq)
    for i = 1:length(aBlobSeq{t})
        % The score for having zero cells is set to 1.01*MIN_MIG_SCORE. It
        % could be set lower, but it is not necessary, and could result in
        % too greedy creation of tracks. The score for having 2 cells is
        % set low enough that no blobs will ever get multiple cells.
        countScores(index, :) = [t i 1.01*MIN_MIG_SCORE 0 -1E4];
        index = index + 1;
    end
end

migrationScores = MigrationScores_generic(aBlobSeq, aImData);

fprintf('Connecting false positives.\n')

[cellMat, divMat, deathMat] = ViterbiTrackLinking(...
    numDets,...
    countScores,...
    migrationScores,...
    splitScores,...
    deathScores,...
    appearanceScores,...
    disappearanceScores,...
    true,...
    inf,...
    '',...
    '');

oCells = Matrix2Cell(cellMat, divMat, deathMat, aBlobSeq, aImData);

% Specify that all the cells are false positives.
for i = 1:length(oCells)
    oCells(i).isCell = false;
end
end