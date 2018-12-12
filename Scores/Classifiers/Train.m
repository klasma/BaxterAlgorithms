function [oClassifier, oMeans, oTransform] = Train(aFeatures, aClasses, aWeights, varargin)
% Trains a multinomial logistic regression classifier.
%
% The function will first transform the features into the space of their
% principal components. This ensures that the built in function mnrfit
% converges. I do not know why, but it is probably because the transform
% removes correlation between the features. Different weights can be given
% to the different classes. This corresponds to setting different priors
% for them. The type value for this classifier is 'mnrpca'. Classification
% is performed using the function Classify.
%
% Inputs:
% aFeatures - Feature matrix where each row corresponds to an observation
%             and each column corresponds to a feature.
% aClasses - Array with class labels for the different observations. The
%            labels are integers starting from 1.
% aWeights - Weights for the different classes. The weights have to be
%            equal to or larger than 1. An array of ones means that all
%            classes are equally likely. A weight of 2 means that the class
%            is twice as likely as a class with a weight of 1.
%
% Property/Value inputs:
% MaxSamples - The maximum number of samples to use for training in each
%              class. A random subset of samples will be selected if this
%              number is less than the number of samples in a class. The
%              default value is 1E4.
%
% Outputs:
% oClassifier - Array of coefficients for the multinomial logistic
%               regression. This array will be given as input to mnrval
%               when classification is performed.
% oMeans - Array of mean values for the features. NaN-values are excluded
%          from the computations.
% oTransform - Unitary matrix which transforms feature vectors into the
%              space of the principal components of the feature vectors
%              used for training.
%
% See also:
% TrainClassifiers, TrainClassifierGUI, Classify, FeatureMatrix, mnrfit,
% mnrval

% Parse property/value inputs.
aMaxSamples = GetArgs({'MaxSamples'}, {1E4}, true, varargin);

[features, classes] = SplitDataSet(aFeatures, aClasses, aMaxSamples, 0);

% Mean feature values.
oMeans = MeanNoNan(features,1);

% PCA transform.
features = ReplaceNanFeatures(features, oMeans);
[~, ~, oTransform] = svd(features);
features = features * oTransform;

% Compute sample weights.
numClasses = max(classes);
n = histc(classes, 1:numClasses);
samples = zeros(length(classes), numClasses);
for i = 1:numClasses
    % The factor max(n)/n(i) makes all classes equally likely. This factor
    % is then multiplied by the user specified weights to get the desired
    % relationship between the classes.
    samples(classes == i,i) = max(n) / n(i) * aWeights(i);
end

% Turn off warnings which occur regularly during training. The warnings do
% not seem to matter, because the classifiers have always worked.
warning('off','MATLAB:nearlySingularMatrix')
warning('off','stats:mnrfit:IterOrEvalLimit')

% Train the classifier.
oClassifier = mnrfit(features, samples);

% Turn the warnings back on.
warning('on','MATLAB:nearlySingularMatrix')
warning('on','stats:mnrfit:IterOrEvalLimit')
end