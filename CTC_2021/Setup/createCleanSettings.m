% Creates settings without algorithm parameters, to start segmentation
% optimization from.

dataSetFolder = 'C:\CTC2021\Training';

settingsToKeep = {'numZ' 'zStacked' 'bits' 'voxelHeight' 'channelMin' 'channelMax'};

currentPath = fileparts(mfilename('fullpath'));
newSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', 'CTC2021_clean');

exDirs = GetNames(dataSetFolder, '');
for e = 1:length(exDirs)
    exPath = fullfile(dataSetFolder, exDirs{e});
    seqDirs = GetNames(exPath, '');
    seqDirs = setdiff(seqDirs, 'Analysis');
    
    for s = 1:length(seqDirs)
        seqDir = seqDirs{s};
        settings = ReadSettings(exPath, seqDir);
        settings_clean = {'file'; seqDir};
        fprintf('Processing %s\n', seqDir)
        for i = 1:length(settingsToKeep)
            value = GetSeqSettings(settings, seqDir, settingsToKeep{i});
            settings_clean = SetSeqSettings(settings_clean, seqDir, settingsToKeep{i}, value);
        end
        settingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s.csv',...
                trainingOrChallenge{d}, exDirs{e}, seqDir(end-1:end));
        WriteSettings(fullfile(newSettingsPath, settingsFileName), settings_clean)
    end
end

fprintf('Done creating clean settings files.\n')