function oList = SplitScores(aBlobSeq, aImData, aMigList, aMinScore)
% Computes a list of cell division scores.
%
% The function computes mitosis scores for all mitotic events that can take
% place in an image sequence. For each detection, all possible pairs of
% outgoing migrations, given by the list of migration events returned by
% MigrationScores_generic, give rise to mitotic events. In this process,
% migrations are paired with themselves, meaning that the daughter cells
% can end up in the same detection after the mitotic event. If a mitosis
% classifier has been defined, the scores are computed from features
% of the parent blobs. The scores are taken to be the log-probabilities of
% mitosis. If no classifier has been defined, the setting pSplit is used as
% a fixed mitosis probability. The mitosis scores do not depend on the
% child blobs, but in the track linking performed by ViterbiTrackLinking,
% the scores of migrations between the parent cell and the two child cells
% are added to the mitosis scores. Thereby mitotic events will not be
% introduced if the daughter cells are too far away from the parent cell.
%
% Inputs:
% aBlobSeq - Cell array where element t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - ImageData object associated with the image sequence.
% aMigList - List of migration scores returned by MigScores_generic. Only
%            the first three columns with indices of frames and blobs are
%            used. The actual scores are not needed. The indices are used
%            to determine which mitosis events to return scores for.
% aMinScore - Score threshold below which migrations will not be included
%             in the output.
%
% Outputs:
% oList - N x 6 matrix, where N is the number of returned mitotic events.
%         The elements of the matrix are:
%    oList(:,1) - Frame index of the first detection in the mitotic event.
%    oList(:,2) - Index of the parent blob in image oList(:,1).
%    oList(:,3) - Index of the first child blob in image oList(:,1)+1.
%    oList(:,4) - Index of the second child blob in image oList(:,1)+1.
%                 This can be equal to the index of the first child
%                 detection.
%    oList(:,5) - Log-likelihood of the mitotic event NOT occurring.
%    oList(:,6) - Log-likelihood of the mitotic event occurring.
%
% See also:
% MigrationScores_generic, DeathScores, Track, ViterbiTrackLinking.cpp

migList = aMigList;
if size(migList,1) == 0
    % There are no possible migrations and therefore no possible mitotic
    % events.
    oList = zeros(0,6);
    return
end

% Sort the migration list on the time points, the index of the first
% blob, and the index of the second blob, in that priority order.
for i = 3:-1:1
    [~, order] = sort(migList(:,i));
    migList = migList(order,:);
end

% Compute probabilities that mitotic events take place in the parent blobs.
if ~strcmp(aImData.Get('splitClassifier'), 'none')  % Use classifier.
    % Load classifier.
    clPath = GetClassifierPath('Split', aImData.Get('splitClassifier'));
    cl = load(clPath);
    
    % Create a matrix of features.
    featureMat = FeatureMatrix([aBlobSeq{:}], cl.featureNames);
    
    % Perform classification.
    splitProbs = Classify(cl, featureMat);
    
    if aImData.Get('TrackSplitPriorChange')
        % Adjust classification results based on changed mitosis priors.
        splitProbs = ChangePriors(...
            splitProbs,...
            cl.priors,...
            [1-aImData.Get('pSplit') aImData.Get('pSplit')]);
    end
else  % Use fixed probabilities from settings.
    if aImData.Get('pSplit') == 0
        % If the mitosis probability is set to 0, we do not add any mitotic
        % events at all.
        oList = zeros(0,6);
        return
    else
        % There is no need to find mitosis scores in the last frame.
        splitProbs = zeros(length([aBlobSeq{1:end-1}]),2);
        splitProbs(:,1) = 1-aImData.Get('pSplit');
        splitProbs(:,2) = aImData.Get('pSplit');
    end
end

% Allocate an output list that may be too long.
maxArcs = aImData.Get('TrackNumNeighbours');
maxMig = (maxArcs+1)*maxArcs/2;
oList = zeros(size(splitProbs,1)*maxMig, 6);

index = 1;  % Index of row in oList.
parentIndex = 0;  % Index of row in splitProbs;
t = nan;
parent = nan;
for i = 1:size(migList,1)
    if parent ~= migList(i,2) || t ~= migList(i,1)
        % We have gotten to the next parent cell (and row in splitScores).
        t = migList(i,1);
        parent = migList(i,2);
        parentIndex = parentIndex + 1;
        
        % The mitosis scores only depend on the parent cells. Migration
        % scores from the parent cell to the two daughter cells are added
        % in ViterbiTrackLinking.
        scores = log(splitProbs(parentIndex,:));
        % The score can be -inf if a classifier gives 0 probability to
        % a class. Therefore -inf is replaced by -1E6. This makes sense
        % as exp(-1E6) = 0 in double arithmetic.
        scores = max(scores, -1E6);
    end
    
    child1 = migList(i,3);
    
    % Go through all blobs that can be the second child and store scores
    % for the corresponding mitotic events.
    j = i;
    while j <= size(migList,1) && migList(j,1) == t && migList(j,2) == parent
        child2 = migList(j,3);
        oList(index,:) = [t, parent, child1, child2, scores];
        j = j + 1;
        index = index + 1;
    end
end
% Crop away unused rows from the output list.
oList = oList(1:index-1,:);

% Remove mitosis events with too low scores.
scoreDiff = oList(:,6) - oList(:,5);
oList(scoreDiff < aMinScore, :) = [];
end