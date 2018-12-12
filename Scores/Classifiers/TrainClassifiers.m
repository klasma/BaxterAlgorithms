function TrainClassifiers(aSeqPaths, aVer, aSaveName, aFeatures, aCount, aMitosis, aDeath, varargin)
% Trains logistic regression classifiers for cell count, mitosis and death.
%
% The classifiers are saved as mat-files to the corresponding subfolders of
% BaxterAlgorithms\Files\Classifiers. To train a classifier, there must be
% at least 10 samples from each class. Warnings are issued if this
% criterion is not met. The count classifiers have a class for false
% positives, a class for single cells and a class for clusters with 2 or
% more cells.
%
% Inputs:
% aSeqPaths - Paths of the image sequences to train on.
% aVer - Tracking version to train on.
% aSaveName - Name of the classifier. The function creates count, split,
%             and death classifiers with this name.
% aFeatures - The names of the features to be used for classification. The
%             same features are used for all 3 classifiers.
% aCount - True if a count classifier should be trained.
% aMitosis - True if a mitosis classifier should be trained.
% aDeath - True if a death classifier should be trained.
%
% Property/Value inputs:
% MaxSamples - The maximum number of samples to use for training in each
%              class. A random subset of samples will be selected if this
%              number is less than the number of samples in a class. The
%              default value is 1E4.
% MaxCount - The minimum number of cells in the highest cell count class.
% EqualCountPriors - If this is set to true, equal priors will be used when
%                    the count classifier is trained. This means that the
%                    classes are considered to be equally likely a priori,
%                    no matter how many samples there are in each class.
%                    This can be useful if the number of detections in each
%                    class varies a lot between image sequences. If this
%                    parameter is false, the priors are taken from the
%                    relative frequencies of the classes in the training
%                    data. The default is false.
%
% See also:
% TrainClassifierGUI, Train, Classify

% Parse property/value inputs.
[aMaxSamples, aMaxCount, aEqualCountPriors] = GetArgs(...
    {'MaxSamples', 'MaxCount', 'EqualCountPriors'},...
    {1E4, 2, false},...
    true, varargin);

% Minimum number of samples in each class that are required to train a
% classifier. If this condition is not met, a warning is issued and no
% classifier is created.
MIN_EX = 10;

% Variables that will be saved.
type = 'mnrpca'; %#ok<NASGU>
featureNames = aFeatures;

% Check for tracking results with the specified name.
vers = GetVersions(aSeqPaths);
if ~any(strcmpi([vers{:}], aVer))
    error('The specified tracking name does not exist')
end

% Folder in which classifiers are saved. The classifiers are in subfolders
% named Count, Split and Death.
saveFolder = FindFile('Classifiers');

% Create the dataset for training.
[features, counts, splits, deaths] = DataSet(aSeqPaths, aVer, featureNames);

% Create and save count classifier.
if aCount
    counts(counts > aMaxCount) = aMaxCount;
    
    % Count the number of samples in each class.
    numSamples = zeros(aMaxCount+1,1);
    for i = 0:aMaxCount
        numSamples(i+1) = sum(counts == i);
    end
    
    if any(numSamples < MIN_EX)
        warning(['Not enough samples from all classes to train a count '...
            'classifier'])
    else
        fprintf('Training count classifier\n')
        
        if aEqualCountPriors
            % Equal weights for all classes.
            weights = [1 1 1];
        else
            % Weights based on the number of samples in each class.
            weights = TrainWeights(counts, 0:aMaxCount);
        end
        
        % Train the classifier.
        [classifier, means, transform] =...
            Train(features, counts+1, weights,...
            'MaxSamples', aMaxSamples); %#ok<ASGLU>
        
        % Save the classifier.
        savePathCount = fullfile(saveFolder, 'Count', [aSaveName '.mat']);
        save(savePathCount,...
            'type', 'featureNames', 'classifier', 'means', 'transform')
    end
end

% Create and save split classifier.
if aMitosis
    if ~(sum(splits == 0) > MIN_EX && sum(splits == 1) > MIN_EX)
        warning(['Not enough samples from all classes to train a split '...
            'classifier'])
    else
        fprintf('Training split classifier\n')
        
        % Weights proportional to class frequencies.
        weights = TrainWeights(splits, [0 1]);
        
        % Train the classifier.
        [classifier, means, transform] =...
            Train(features, splits+1, weights,...
            'MaxSamples', aMaxSamples); %#ok<ASGLU>
        
        % Save the classifier.
        savePathSplit = fullfile(saveFolder, 'Split', [aSaveName '.mat']);
        save(savePathSplit,...
            'type', 'featureNames', 'classifier', 'means', 'transform')
    end
end

% Create and save death classifier.
if aDeath
    if ~(sum(deaths == 0) > MIN_EX && sum(deaths == 1) > MIN_EX)
        warning(['Not enough samples from all classes to train a death '...
            'classifier'])
    else
        fprintf('Training death classifier\n')
        
        % Weights proportional to class frequencies.
        weights = TrainWeights(deaths, [0 1]);
        
        % Train the classifier.
        [classifier, means, transform] =...
            Train(features, deaths+1, weights,...
            'MaxSamples', aMaxSamples); %#ok<ASGLU>
        
        % Save the classifier.
        savePathDeath = fullfile(saveFolder, 'Death', [aSaveName '.mat']);
        save(savePathDeath,...
            'type', 'featureNames', 'classifier', 'means', 'transform')
    end
end

fprintf('Done training classifiers\n')
end