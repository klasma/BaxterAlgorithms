% Optimize segmentation on the primary track datasets for CTC 2021.
%
% Starting from the TRIC settings of CTC 2019.

subdirs = textscan(genpath(fileparts(fileparts(mfilename('fullpath')))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

% % Settings to test on.
% basePath = 'C:\CTC2021\Training';
% initialSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_clean';
% optimizedSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_trained_on_GT';
% exDirs = {'Fluo-C2DL-MSC'};
% maxIter = 1;
% settingsToOptimize = {'BPSegThreshold'};

% Real settings.
basePath = 'C:\CTC2021\Training';
initialSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_clean';
optimizedSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_trained_on_GT';
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
    };
% % Switch to this when watersheds are used in the initial settings files.
% settingsToOptimize = {
%     'BPSegHighStd'
%     'BPSegLowStd'
%     'BPSegBgFactor'
%     'BPSegThreshold'
%     'SegWSmooth'
%     'SegWHMax'
%     'SegWSmooth2'
%     'SegWHMax2'
% };

exPaths = fullfile(basePath, exDirs);

allSettings = AllSettings();

for i = 1:length(exPaths)
    exPath = exPaths{i};
    seqDirs = GetSeqDirs(exPath);
    seqPaths = fullfile(exPath, seqDirs);
    
    % Read initial settings which only have information about the images.
    initialImData = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPaths{i}, seqDirs{j});
        settingsFileName = sprintf('Settings_ISBI_2021_Training_%s-%s_clean.csv',...
            exDirs{i}, seqDirs{j}(end-1:end));
        settingsPath = fullfile(initialSettingsFolder, settingsFileName);
        initialImData{j} = ImageData(seqPath, 'SettingsFile', settingsPath);
    end
    
    % Specify where the optimized settings should be saved.
    optimizedSettingsPaths = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        settingsFileName = sprintf('Settings_ISBI_2021_Training_%s-%s_trained_on_GT.csv',...
            exDirs{i}, seqDirs{j}(end-1:end));
        optimizedSettingsPaths{j} = fullfile(optimizedSettingsFolder, settingsFileName);
    end
    
    optimizer = SEGOptimizerEx(seqPaths, settingsToOptimize,...
        'SavePaths', optimizedSettingsPaths,...
        'InitialImData', initialImData);
    
    optimizer.Optimize_coordinatedescent('MaxIter', maxIter)
end