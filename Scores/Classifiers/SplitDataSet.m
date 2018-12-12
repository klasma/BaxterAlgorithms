function [oFeatures1, oClasses1, oFeatures2, oClasses2] =...
    SplitDataSet(aFeatures, aClasses, aMax, aSeed)
% Selects a subset of samples in a training dataset for classification.
%
% The function selects a random subset of feature vectors and their
% associated class labels in a training dataset for classification. This
% can be useful to reduce the time required for training.
%
% Inputs:
% aFeatures - Feature matrix where each row corresponds to a sample and
%             each column corresponds to a feature.
% aClasses - Array with class labels for the samples.
% aMax - The maximum number of samples to keep in each class. Additional
%        samples will be rejected.
% aSeed - Seed for the random number generator.
%
% Outputs:
% oFeatures1 - Feature matrix for selected samples.
% oClasses1 - Array with class labels for selected samples.
% oFeatures2 - Feature matrix for samples that were not selected.
% oClasses2 - Array with class labels for samples that were not selected.
%
% See also:
% Train

% Set the seed of the random number generator to get reproducibility.
rs = RandStream('mt19937ar', 'Seed', aSeed);

numClasses = max(aClasses);
keep = false(length(aClasses),1);
for i = 1:numClasses
    % Pick (up to) aMax samples of class i by randomly permuting all
    % samples and selecting the aMax first samples in the permutation.
    index = find(aClasses == i);
    perm = randperm(rs, length(index));
    keep(index(perm(1:min(aMax, length(index))))) = true;
end

% Extract the selected features and class labels.
oFeatures1 = aFeatures(keep,:);
oClasses1 = aClasses(keep);

% Extract the features and class labels that were not selected.
oFeatures2 = aFeatures(~keep,:);
oClasses2 = aClasses(~keep);
end