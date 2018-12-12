function oList = DeathScores(aBlobSeq, aImData)
% Computes scores for death events in blobs of an image sequence.
%
% The scores are log-probabilities of death events. The log-probabilities
% can either be computed using classification of blob features, or they can
% be set to a fixed value by specifying the setting pDeath. When a
% classifier is used, the total score of a tracking solution can sometimes
% be increased by adding a mitotic event followed by a death event a few
% frames later. To avoid this, one can specify a value for the setting
% TrackMaxDeathProb which sets an upper threshold on the death probability
% in blobs. One can also specify the setting TrackDeathShift which is a
% factor that multiplies the death probabilities.
%
% Inputs:
% aBlobSeq - Cell array where element t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - Image data object associated with the image sequence.
%
% Outputs:
% oList - N x 4 matrix where N is the total number of blobs in all frames
%         except the last. Only possible death events are included in the
%         list, so if the death probability is set to 0, an empty list will
%         be returned.
%         The elements of the matrix are:
%    oList(:,1) - Frame index.
%    oList(:,2) - Index of the blob in frame oList(:,1).
%    oList(:,3) - Log-probability that no death event takes place in the
%                 blob.
%    oList(:,4) - Log-probability that at least one death event takes place
%                 in the blob.
%
% See also:
% SplitScores, Track, Classify

if ~strcmp(aImData.Get('deathClassifier'), 'none')  % Use classifier.
    % Load classifier.
    clPath = GetClassifierPath('Death', aImData.Get('deathClassifier'));
    cl = load(clPath);
    
    % Create a matrix of features.
    featureMat = FeatureMatrix([aBlobSeq{1:end-1}], cl.featureNames);
    
    % Perform classification.
    deathProbs = Classify(cl, featureMat);
    
    % Threshold how high the probability of death can be.
    tooSure = deathProbs(:,2) > aImData.Get('TrackMaxDeathProb');
    deathProbs(tooSure,1) = 1 - aImData.Get('TrackMaxDeathProb');
    deathProbs(tooSure,2) = aImData.Get('TrackMaxDeathProb');
    
    if aImData.Get('TrackDeathPriorChange')
        % Adjust classification results based on changed death priors.
        deathProbs = ChangePriors(...
            deathProbs,...
            cl.priors,...
            [1-aImData.Get('pDeath') aImData.Get('pDeath')]);
    end
else  % Use fixed probabilities from settings.
    if aImData.Get('pDeath') == 0
        % If the death probability is set to 0, we do not add any death
        % events at all.
        oList = zeros(0,4);
        return
    else
        % There is no need to find death scores in the last frame.
        deathProbs = zeros(length([aBlobSeq{1:end-1}]),2);
        deathProbs(:,1) = 1-aImData.Get('pDeath');
        deathProbs(:,2) = aImData.Get('pDeath');
    end
end

oList = zeros(size(deathProbs,1),4);
cnt = 1;
for t = 1:length(aBlobSeq)-1
    for bIndex = 1:length(aBlobSeq{t})
        oList(cnt,1) = t;
        oList(cnt,2) = bIndex;
        % The score can be -inf if a classifier gives 0 probability to a
        % class. Therefore -inf is replaced by -1E6. This makes sense as
        % exp(-1E6) = 0 in double arithmetic.
        oList(cnt,3) = max(log(1-deathProbs(cnt,2)*aImData.Get('TrackDeathShift')), -1E6);
        oList(cnt,4) = max(log(deathProbs(cnt,2)*aImData.Get('TrackDeathShift')), -1E6);
        cnt = cnt + 1;
    end
end
end