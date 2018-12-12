function oList = CountScores(aBlobSeq, aImData, varargin)
% Computes scores for different cell counts in blobs of an image sequence.
%
% The scores are the log-probabilities of the different cell counts. First,
% a classifier is used to find the probabilities of 0,...,K-1, and K or
% more cells in each blob. Then the likelihoods of K to 9 cells is
% extrapolated from the probability of K or more cells. The extrapolation
% is performed by assuming that the probabilities of different cell counts
% follow a geometric distribution, as described in [1]. The number K is
% usually 2, but depends on the classifier used. Instead of using a
% classifier, one can also specify the settings pCnt0, pCnt1, and pCnt2,
% which define fixed probabilities that a blob has 0, 1, or more than 1
% cell respectively.
%
% Inputs:
% aBlobSeq - Cell array where element t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - Image data object associated with the image sequence.
%
% Property/Value inputs:
% CreateOutputFiles - If this parameter is set to true, the computed list
%                     of scores is saved to a file named counts.mat in the
%                     resume-directory of the image sequence.
%
% Outputs:
% oList- N x 12 matrix where N is the total number of blobs in aBlobSeq.
%        The elements of the matrix are:
%    oList(:,1) - Frame index.
%    oList(:,2) - Index of the blob in frame oList(:,1).
%    oList(:,3:12) - Log-probability that the blob contains 0 to 9 cells.
%
% References:
% [1] Magnusson, K. E. G.; Jaldén, J.; Gilbert, P. M. & Blau, H. M. Global
%     linking of cell tracks using the Viterbi algorithm IEEE Trans. Med.
%     Imag., 2015, 34, 1-19
%
% See also:
% Track, Classify, ExtrapProbs

% Parse property/value inputs.
aCreateOutputFiles = GetArgs({'CreateOutputFiles'}, {false}, true, varargin);

if ~strcmp(aImData.Get('countClassifier'), 'none')  % Use classifier.
    % Load classifier.
    clPath = GetClassifierPath('Count', aImData.Get('countClassifier'));
    cl = load(clPath);
    
    % Create a matrix of features.
    featureMat = FeatureMatrix([aBlobSeq{:}], cl.featureNames);
    
    % Perform classification.
    countProbs = Classify(cl, featureMat);
else  % Use fixed probabilities from settings.
    countProbs = zeros(length([aBlobSeq{:}]),3);
    countProbs(:,1) = aImData.Get('pCnt0');
    countProbs(:,2) = aImData.Get('pCnt1');
    countProbs(:,3) = aImData.Get('pCnt2');
end

% Extrapolate up to a cell count of 9.
countProbs = ExtrapProbs(countProbs, 10, aImData.Get('pCntExtrap'));

cnt = 1;
oList = nan(size(countProbs,1),size(countProbs,2)+2);
for t = 1:length(aBlobSeq)
    for bIndex = 1:length(aBlobSeq{t})
        oList(cnt,1) = t;
        oList(cnt,2) = bIndex;
        % The score can be -inf if a classifier gives 0 probability to a
        % class. Therefore -inf is replaced by -1E6. This makes sense as
        % exp(-1E6) = 0 in double arithmetic.
        oList(cnt,3:end) = max(log(countProbs(cnt,:)), -1E6);
        cnt = cnt+1;
    end
end

if aCreateOutputFiles
    % Save the count probabilities.
    filename = fullfile(...
        aImData.GetResumePath(),...
        'counts.mat');
    counts = oList; %#ok<NASGU>
    save(filename, 'counts')
end
end