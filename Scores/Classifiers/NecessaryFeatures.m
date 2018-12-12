function oFeatures = NecessaryFeatures(aImData, varargin)
% Returns a list of features that are required by the selected classifiers.
%
% The function finds the list of features that are necessary for using the
% combination of count, split and death classifiers associated with an
% image sequence.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
%
% Property/Value inputs:
% Classifiers - Cell array with any subset of the strings 'count', 'split'
%               and 'death', specifying the classifier types to compute a
%               feature list for. The default is to include all classifier
%               types.
%
% Outputs:
% oFeatures - Cell array of strings with the names of the necessary
%             features.
%
% See also:
% ComputeFeatures, Classify

% Parse property/value inputs.
aClassifiers = GetArgs({'Classifiers'}, {{'count' 'split' 'death'}},...
    true, varargin);

oFeatures = {};

% Add count features.
if any(strcmpi(aClassifiers, 'count')) &&...
        ~strcmp(aImData.Get('countClassifier'), 'none')
    % Path of count classifier.
    clPath = GetClassifierPath('Count', aImData.Get('countClassifier'));
    countFeatures = getfield(load(clPath), 'featureNames');
    oFeatures = [oFeatures; countFeatures];
end

% Add split features.
if any(strcmpi(aClassifiers, 'split')) &&...
        ~strcmp(aImData.Get('splitClassifier'), 'none')
    % Path of split classifier.
    clPath = GetClassifierPath('Split', aImData.Get('splitClassifier'));
    splitFeatures = getfield(load(clPath), 'featureNames');
    oFeatures = [oFeatures; splitFeatures];
end

% Add death features.
if any(strcmpi(aClassifiers, 'death')) &&...
        ~strcmp(aImData.Get('deathClassifier'), 'none')
    % Path of death classifier.
    clPath = GetClassifierPath('Death', aImData.Get('deathClassifier'));
    deathFeatures = getfield(load(clPath), 'featureNames');
    oFeatures = [oFeatures; deathFeatures];
end

oFeatures = SubstituteFeatureNames(unique(oFeatures));
end