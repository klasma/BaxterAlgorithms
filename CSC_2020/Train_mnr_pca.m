function oCl = Train_mnr_pca(aFeatures, aFeatureNames, aClasses, varargin)

oCl.type = 'mnr_pca';
oCl.featureNames = aFeatureNames;

% Get property/value inputs.
[aWeights, aRank, aMaxExamples, aSavename] = GetArgs(...
    {'Weights', 'Rank', 'MaxExamples', 'Savename'},...
    {TrainWeights(aClasses, 1:max(aClasses)), size(aFeatures,2), 1E4, ''},...
    1,...
    varargin);

% Compute priors for the different classes.
tab = tabulate(aClasses);
oCl.priors = tab(:,2) / sum(tab(:,2));

% Reduce the number of training examples.
[features, classes, ~, ~] = SplitDataSet(aFeatures, aClasses, aMaxExamples, 0);

% Mean feature values.
oCl.dataset_means = MeanNoNan(features,1);

% PCA transform.
features = ReplaceNanFeatures(features, oCl.dataset_means);
[~, ~, V] = svd(features, 'econ');
oCl.transform = V(:,1:min(aRank,size(V,2)));
features = features * oCl.transform;

% Samples.
numClasses = max(classes);
n = histc(classes, 1:numClasses);
samples = zeros(length(classes), numClasses);
for i = 1:numClasses
%     max(n)/n(i) puts equal weight on all classes and aWeights sets the
%     desired weights.
    samples(classes == i,i) = max(n)/n(i) * aWeights(i);
end

oCl.classifier = mnrfit(features, samples);

if ~isempty(aSavename)
    type = oCl.type;
    featureNames = oCl.featureNames;
    dataset_means = oCl.dataset_means;
    transform = oCl.transform;
    classifier = oCl.classifier;
    priors = oCl.priors;
    
    if ~exist(fileparts(aSavename), 'dir')
        mkdir(fileparts(aSavename))
    end
    save(aSavename, 'type', 'featureNames', 'dataset_means', 'transform', 'classifier', 'priors')
end
end