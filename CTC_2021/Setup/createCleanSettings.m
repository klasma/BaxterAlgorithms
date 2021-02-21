% Creates settings without algorithm parameters, to start segmentation
% optimization from.

dataSetFolder = 'C:\CTC2021\Training';

settingsToKeep = {
    'numZ'
    'zStacked'
    'bits'
    'voxelHeight'
    'channelMin'
    'channelMax'
    };
bgSubSettings = {
    'SegBgSubAlgorithm'
    'SegMediaChanges'
    'SegBgSubAtten'
    };
bgSubEx = {
    'BF-C2DL-HSC'
    'BF-C2DL-MuSC'
    };
defaults = {...
    'SegMinArea', '0',...
    'BPSegHighStd', '10',...
    'BPSegLowStd', '3',...
    'BPSegThreshold', '0.01',...
    'SegWatershed', 'intermediate'...
    'SegWSmooth', '0',...
    'SegWHMax', '0.01',...
    'SegWatershed2', 'shape'...
    'SegWSmooth2', '0',...
    'SegWHMax2', '2',...
    };

currentPath = fileparts(mfilename('fullpath'));
newSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', 'CTC2021_clean');

exDirs = GetNames(dataSetFolder, '');
for e = 1:length(exDirs)
    exPath = fullfile(dataSetFolder, exDirs{e});
    seqDirs = GetNames(exPath, '');
    seqDirs = setdiff(seqDirs, 'Analysis');
    
    for s = 1:length(seqDirs)
        seqDir = seqDirs{s};
        num = seqDir(end-1:end);
        settings = ReadSettings(exPath, seqDir);
        settings_clean = {'file'; num};
        fprintf('Processing %s\n', seqDir)
        for i = 1:length(settingsToKeep)
            value = GetSeqSettings(settings, seqDir, settingsToKeep{i});
            settings_clean = SetSeqSettings(settings_clean, num, settingsToKeep{i}, value);
        end
        if any(strcmpi(bgSubEx, exDirs{e}))
            for i = 1:length(bgSubSettings)
                value = GetSeqSettings(settings, seqDir, bgSubSettings{i});
                settings_clean = SetSeqSettings(settings_clean, num, bgSubSettings{i}, value);
            end
        end
        settings_clean = SetSeqSettings(settings_clean, num, defaults{:});
        settingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s_clean.csv',...
                'Training', exDirs{e}, num);
        WriteSettings(fullfile(newSettingsPath, settingsFileName), settings_clean)
    end
    
    CreateSettingsLinkFile(exPath, 'Training', '_clean')
end

fprintf('Done creating clean settings files.\n')