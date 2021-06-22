% Creates settings without algorithm parameters, to start segmentation
% optimization from.

dataSetFolder = 'C:\CTC2021\Challenge';

suffixes = {...
    '_trained_on_GT'
    '_trained_on_GT_all'
    '_trained_on_GT_plus_ST'
    '_trained_on_GT_plus_ST_all'
    '_trained_on_ST'
    '_trained_on_ST_all'};

for i = 1:length(suffixes)
    suffix = suffixes{i};
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
            
            trainingSettingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
                'Training', exDirs{e}, num, suffix);
            trainingSettingsPath = fullfile(settingsFolder, trainingSettingsFileName);
            
            challengeSettingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
                'Challenge', exDirs{e}, num, suffix);
            challengeSettingsPath = fullfile(settingsFolder, challengeSettingsFileName);
            
            copyfile(trainingSettingsPath, challengeSettingsPath)
            
            if strcmp(seqDir, 'Fluo-C3DH-A549_02')
                challengeSpecificSettings = {'numZ', '34'};
            elseif strcmp(seqDir, 'Fluo-N3DH-CE_01')
                challengeSpecificSettings = {'numZ', '31'};
            else
                challengeSpecificSettings = {};
            end
            
            if ~isempty(challengeSpecificSettings)
                data = ReadSettings(challengeSettingsPath);
                data = SetSeqSettings(data, num, challengeSpecificSettings{:});
                WriteSettings(challengeSettingsPath, data)
            end
        end
    end
end

fprintf('Done copying settings files.\n')