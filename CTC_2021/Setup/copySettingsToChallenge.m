% Creates settings without algorithm parameters, to start segmentation
% optimization from.

dataSetFolder = 'C:\CTC2021\Challenge';

% suffix = '_trained_on_GT';
% suffix = '_trained_on_GT_all';
% suffix = '_trained_on_GT_plus_ST';
% suffix = '_trained_on_GT_plus_ST_all';
% suffix = '_trained_on_ST';
suffix = '_trained_on_ST_all';

currentPath = fileparts(mfilename('fullpath'));
settingsFolder = fullfile(currentPath, '..', '..', 'Files', 'Settings', ['CTC2021' suffix]);

exDirs = GetNames(dataSetFolder, '');
exDirs = setdiff(exDirs, {'Fluo-C2DL-Huh7', 'SegmentationOptimizers'});

for e = 1:length(exDirs)
    exPath = fullfile(dataSetFolder, exDirs{e});
    seqDirs = GetNames(exPath, '');
    seqDirs = setdiff(seqDirs, 'Analysis');
    
    for s = 1:length(seqDirs)
        seqDir = seqDirs{s};
        num = seqDir(end-1:end);
        settings_old = ReadSettings(exPath, seqDir);
        
        trainingSettingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
            'Training', exDirs{e}, num, suffix);
        trainingSettingsPath = fullfile(settingsFolder, trainingSettingsFileName);
        
        challengeSettingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
            'Challenge', exDirs{e}, num, suffix);
        challengeSettingsPath = fullfile(settingsFolder, challengeSettingsFileName);
        
        copyfile(trainingSettingsPath, challengeSettingsPath)
    end
end

fprintf('Done copying settings files.\n')