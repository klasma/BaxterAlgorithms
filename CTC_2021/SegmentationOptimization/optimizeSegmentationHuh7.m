% Optimize segmentation on the primary track datasets for CTC 2021.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

% % Settings to test on.
% basePath = 'C:\CTC2021\Training';
% exDirs = {'Fluo-C2DL-MSC'};
% maxIter = 25;
% settingsToOptimize = {
%     'BPSegThreshold'
%     };
% overWriteOldOptimizers = false;
% optimizerName = 'TestOptimizer.mat';

% Real settings.
basePath = 'C:\CTC2021\Training';
% The fluorescence experiments are ordered so that the fastest ones are
% processed first.
exDirs = {
    'Fluo-C2DL-Huh7'
    };
maxIter = 25;
settingsToOptimize = {
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'
    'BPSegThreshold'
    'SegClipping'
    'SegWHMax'
    'SegWHMax2'
    };
overWriteOldOptimizers = false;
optimizerName = 'Huh7OptimizerCTC2021_SEG.mat';

exPaths = fullfile(basePath, exDirs);

DeleteOldOptimizationCellData(exPaths)

allSettings = AllSettings();

for i = 1:length(exPaths)
    fprintf('Processing experiment %d / %d %s\n', i, length(exDirs), exDirs{i})
    exPath = exPaths{i};
    seqDirs = GetSeqDirs(exPath);
    seqPaths = fullfile(exPath, seqDirs);
    
    % Read initial settings which only have information about the images.
    initialImData = [];
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPaths{i}, seqDirs{j});
        settingsPath = fullfile(exPath, 'SettingsLinks_clean.csv');
        imData = ImageData(seqPath, 'SettingsFile', settingsPath);
        initialImData = [initialImData; imData];
    end
    
    % Specify where the optimized settings should be saved.
    optimizedSettingsPaths = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        optimizedSettingsPaths{j} = fullfile(exPath, 'SettingsLinks_trained_on_GT.csv');
    end
    
    % Specify where the segmentation optimizer should be saved.
    optimizerSavePath = fullfile(exPath, 'Analysis', 'SegmentationOptimizers', optimizerName);
    if ~overWriteOldOptimizers
        assert(~exist(optimizerSavePath, 'file'),...
            'The optimizer ''%s'' already exists.', optimizerSavePath)
    end
    
    optimizer = SEGOptimizerEx(seqPaths, settingsToOptimize,...
        'SavePaths', optimizedSettingsPaths,...
        'OptimizerSavePath', optimizerSavePath,...
        'InitialImData', initialImData,...
        'ScoringFunction', 'SEG',...
        'Plot', true);
    
    optimizer.Optimize_coordinatedescent('MaxIter', maxIter)
end