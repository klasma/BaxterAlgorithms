% Optimize segmentation on the TRIF sequences in CTC 2020.
%
% Starting from the TRIC settings of CTC 2019.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

% Settings to test on.
basePath = 'C:\CTC2021\Training';
initialSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_clean';
optimizedSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_trained_on_GT';
exDirs = {'Fluo-C2DL-MSC'};
maxIter = 1;
settingsToOptimize = {'BPSegThreshold'};

% % Real settings.
% basePath = 'C:\CTC2021\Training';
% initialSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_clean';
% optimizedSettingsFolder = 'C:\git\BaxterAlgorithms_CSC2019\Files\Settings\CTC2021_trained_on_GT';
% exDirs = {...
%     'BF-C2DL-HSC'
%     'BF-C2DL-MuSC'
%     'DIC-C2DH-HeLa'
%     'Fluo-C2DL-Huh7'
%     'Fluo-C2DL-MSC'
%     'Fluo-C3DH-A549'
%     'Fluo-C3DH-H157'
%     'Fluo-C3DL-MDA231'
%     'Fluo-N2DH-GOWT1'
%     'Fluo-N2DL-HeLa'
%     'Fluo-N3DH-CE'
%     'Fluo-N3DH-CHO'
%     'PhC-C2DH-U373'
%     'PhC-C2DL-PSC'};
% maxIter = 25;
% settingsToOptimize = {...
%     'BPSegHighStd'
%     'BPSegLowStd'
%     'BPSegBgFactor'
%     'BPSegThreshold'
%     'SegWSmooth'
%     'SegWHMax'
%     'SegWSmooth2'
%     'SegWHMax2'};

exPaths = fullfile(basePath, exDirs);

for i = 1:length(exPaths)
    exPath = exPaths{i};
    seqDirs = GetSeqDirs(exPath);
    seqPaths = fullfile(exPath, seqDirs);
    
    % Read initial settings which only have information about the images.
    initialSettings = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        settingsFileName = sprintf('Settings_ISBI_2021_Training_%s-%s.csv',...
            exDirs{e}, seqDirs{s}(end-1:end));
        settingsPath = fullfile(initialSettingsFolder, settingsFileName);
        initialSettings{j} = ReadDelimMat(settingsPath, ',');
    end
    
    % Specify where the optimized settings should be saved.
    optimizedSettingsPaths = cell(size(seqDirs));
    for j = 1:length(seqDirs)
        settingsFileName = sprintf('Settings_ISBI_2021_Training_%s-%s.csv',...
            exDirs{e}, seqDirs{s}(end-1:end));
        optimizedSettingsPaths{j} = fullfile(optimizedSettingsFolder, settingsFileName);
    end
    
    optimizer = SEGOptimizerEx(seqPaths, settingsToOptimize,...
        'SavePaths', optimizedSettingsPaths,...
        'InitialSettings', initialSettings);
    
    optimizer.Optimize_coordinatedescent('MaxIter', maxIter)
end