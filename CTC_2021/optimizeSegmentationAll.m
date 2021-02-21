% Optimize segmentation jointly on the primary track datasets for CTC 2021.

subdirs = textscan(genpath(fileparts(fileparts(mfilename('fullpath')))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

% % Settings to test on.
% basePath = 'C:\CTC2021\Training';
% exDirs = {'Fluo-C2DL-MSC'; 'Fluo-N2DH-GOWT1'};
% maxIter = 1;
% settingsToOptimize = {'BPSegThreshold'};

% Real settings.
basePath = 'C:\CTC2021\Training';
% The fluorescence experiments are ordered so that the fastest ones are
% processed first. Transmission microscopy datasets for which bandpass
% filtering is not the best segmentation algorithm are placed at the end.
exDirs = {
    'Fluo-C2DL-MSC'
    'Fluo-N2DH-GOWT1'
    'Fluo-C3DH-A549'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CHO'
    'PhC-C2DL-PSC'
    'Fluo-C3DH-H157'
    'Fluo-N3DH-CE'
    'PhC-C2DH-U373'
    'DIC-C2DH-HeLa'
    'BF-C2DL-MuSC'
    'BF-C2DL-HSC'
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


exPaths = fullfile(basePath, exDirs);

allSettings = AllSettings();

allSeqPaths = {};
allInitialImData = {};
allOptimizedSettingsPaths = {};
for i = 1:length(exPaths)
    fprintf('Processing experiment %d / %d %s\n', i, length(exDirs), exDirs{i})
    exPath = exPaths{i};
    seqDirs = GetSeqDirs(exPath);
    seqPaths = fullfile(exPath, seqDirs);
    
    % Read initial settings which only have information about the images.
    initialImData = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPaths{i}, seqDirs{j});
        settingsPath = fullfile(exPath, 'SettingsLinks_clean.csv');
        initialImData{j} = ImageData(seqPath, 'SettingsFile', settingsPath);
    end
    
    % Specify where the optimized settings should be saved.
    optimizedSettingsPaths = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        optimizedSettingsPaths{j} = fullfile(exPath, 'SettingsLinks_trained_on_GT_all.csv');
    end
    
    allSeqPaths = [allSeqPaths; seqPaths];
    allInitialImData = [allInitialImData; initialImData];
    allOptimizedSettingsPaths = [allOptimizedSettingsPaths; optimizedSettingsPaths];
end

optimizer = SEGOptimizerEx(allSeqPaths, settingsToOptimize,...
    'SavePaths', allOptimizedSettingsPaths,...
    'InitialImData', allInitialImData);

optimizer.Optimize_coordinatedescent('MaxIter', maxIter)