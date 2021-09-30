function Train(aExDirs, aGtType)
% Optimizes segmentation on the primary track datasets for CTC 2021.
%
% For the challenge, the segmentation parameters were optimized using the
% scripts in CTC_2021\SegmentationOptimization. This function was added
% after the initial submission to make it easier to reproduce the training
% of segmentation parameters.
%
% To optimize segmentation parameters for a dataset, the dataset folder
% must be placed next to the SW-folder (the top folder of the
% git-repository). The settings are saved to a csv-file in one of the
% folders CTC2021_trained_on_GT, CTC2021_trained_on_ST,
% CTC2021_trained_on_GT_plus_ST, CTC2021_trained_on_GT_all,
% CTC2021_trained_on_ST_all and CTC2021_trained_on_GT_plus_ST_all in
% Files\Settings. The csv-files are given the same names as the existing
% csv-files for the training data, but '_new' is added as a suffix.
%
% Inputs:
% aExDirs - Cell array with dataset names (e.g. {'Fluo-C2DL-MSC'}). The
%           input must be a cell array even if a single dataset is
%           processed. If multiple datasets are given as input, the
%           segmentation parameters are optimized jointly on all datasets.
% aGtType - The type of ground truth that should be used for training
%           ('GT', 'ST', 'GT+ST', 'allGT', 'allST' or 'allGT+allST').

swPath = fileparts(mfilename('fullpath'));
subdirs = textscan(genpath(swPath), '%s', 'delimiter', pathsep);
addpath(subdirs{1}{:});

switch aGtType
    case 'GT'
        suffix = '_GT';
        suffix2 = [];
        longName = 'GT';
        numImages = nan;
        scoringFunction = '0.9*SEG+0.1*DET';
    case 'ST'
        suffix = '_ST';
        suffix2 = [];
        longName = 'ST';
        numImages = 32;
        scoringFunction = '0.9*SEG+0.1*DET';
    case 'GT+ST'
        suffix = '_GT';
        suffix2 = '_ST_minus_GT';
        longName = 'GT_plus_ST';
        numImages = 32;
        scoringFunction = '0.45*SEG1+0.45*SEG2+0.1*DET';    
    case 'allGT'
        suffix = '_GT';
        suffix2 = [];
        longName = 'GT_all';
        numImages = nan;
        scoringFunction = '0.9*SEG+0.1*DET';
    case 'allST'
        suffix = '_ST';
        suffix2 = [];
        longName = 'ST_all';
        numImages = 32;
        scoringFunction = '0.9*SEG+0.1*DET';
    case 'allGT+allST'
        suffix = '_GT';
        suffix2 = '_ST_minus_GT';
        longName = 'GT_plus_ST_all';
        numImages = 32;
        scoringFunction = '0.45*SEG1+0.45*SEG2+0.1*DET';
    otherwise
        error('aGtType must be either ''GT'', ''ST'' or ''GT+ST''')
end

maxIter = 25;
settingsToOptimize = {
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'
    'BPSegThreshold'
    'SegClipping'
    'SegWHMax'
    'SegWHMax2'
    'SegMinArea'
    'SegMinSumIntensity'
    };

exPaths = fullfile(fileparts(swPath), aExDirs);

DeleteOldOptimizationCellData(exPaths)

allSeqPaths = {};
allInitialImData = [];
allOptimizedSettingsPaths = {};

for i = 1:length(aExDirs)
    exPath = exPaths{i};
    if ~exist(exPath, 'dir')
        error('The dataset %s could not be found.', exPath)
    end
       
    seqDirs = GetSeqDirs(exPath);
    seqDirs = regexp(seqDirs, '.*(?<!(_GT|_ST))$', 'match', 'once');
    seqDirs = seqDirs(~cellfun(@isempty, seqDirs));
    seqPaths = fullfile(exPath, seqDirs);
    allSeqPaths = [allSeqPaths; seqPaths]; %#ok<AGROW>
    
    % Read initial settings which only have information about the images.
    initialImData = [];
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPath, seqDirs{j});
        settingsPath =...
            fullfile(swPath,...
            'Files',...
            'Settings',...
            sprintf('CTC2021_clean'),...
            sprintf('Settings_ISBI_2021_Training_%s-%s_clean.csv', aExDirs{i}, seqDirs{j}));
        imData = ImageData(seqPath, 'SettingsFile', settingsPath);
        initialImData = [initialImData; imData]; %#ok<AGROW>
    end
    allInitialImData = [allInitialImData; initialImData]; %#ok<AGROW>
    
    % Specify where the optimized settings should be saved.
    optimizedSettingsPaths = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        optimizedSettingsPaths{j} =...
            fullfile(swPath,...
            'Files',...
            'Settings',...
            sprintf('CTC2021_trained_on_%s', longName),...
            sprintf('Settings_ISBI_2021_Training_%s-%s_trained_on_%s_new.csv', aExDirs{i}, seqDirs{j}, longName));
    end
    allOptimizedSettingsPaths = [allOptimizedSettingsPaths; optimizedSettingsPaths]; %#ok<AGROW>
    
    % Create faked TRA ground truths for ST-folders if necessary.
    if strcmp(aGtType, 'ST')
        for j = 1:length(seqDirs)
            fprintf('Creating a TRA folder for the ST-ground truth of image sequence %d / %d\n', j, length(seqDirs))
            if ~exist(fullfile(initialImData(j).GetGroundTruthPath('_ST'), 'TRA'), 'dir')
                CreateSTTRA(initialImData(j).seqPath)
            end
        end
    end
    
    % Create an ST ground truth without objects that are present in the GT
    % ground truth if necessary.
    if strcmp(aGtType, 'GT+ST')
        for j = 1:length(seqDirs)
            fprintf('Creating a ST_minus_GT ground truth folder of image sequence %d / %d\n', j, length(seqDirs))
            if ~exist(fullfile(initialImData(j).GetGroundTruthPath('_ST_minus_GT', false), 'TRA'), 'dir')
                CreateStMinusGt(initialImData(j).seqPath)
            end
        end
    end
end

optimizer = SEGOptimizerEx(allSeqPaths, settingsToOptimize,...
    'NumImages', numImages,...
    'SavePaths', allOptimizedSettingsPaths,...
    'InitialImData', allInitialImData,...
    'ScoringFunction', scoringFunction,...
    'Suffix', suffix,...
    'Suffix2', suffix2,...
    'Plot', true);

optimizer.Optimize_coordinatedescent('MaxIter', maxIter)
end