% Creates settings without algorithm parameters, to start segmentation
% optimization from.

trainingOrChallenge = 'Challenge';

dataSetFolder = ['C:\CTC2021\' trainingOrChallenge];

suffix = '_trained_on_ST';

settingsToKeep = {
    'numZ'
    };

defaults = {
    };

currentPath = fileparts(mfilename('fullpath'));
newSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', ['CTC2021' suffix]);

exDirs = {
    'Fluo-C2DL-MSC'
    'Fluo-N2DH-GOWT1'
    'Fluo-C3DH-A549'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CHO'
    'PhC-C2DL-PSC'
    'PhC-C2DH-U373'
    'DIC-C2DH-HeLa'
    'BF-C2DL-MuSC'
    'BF-C2DL-HSC'
    'Fluo-N3DH-CE'
    'Fluo-C3DH-H157'
    };

for e = 1:length(exDirs)
    exPath = fullfile(dataSetFolder, exDirs{e});
    seqDirs = GetNames(exPath, '');
    seqDirs = setdiff(seqDirs, 'Analysis');
    
    for s = 1:length(seqDirs)
        seqDir = seqDirs{s};
        num = seqDir(end-1:end);
        settings_old = ReadSettings(exPath, seqDir);
        
        settingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
            trainingOrChallenge, exDirs{e}, num, suffix);
        settingsPath = fullfile(newSettingsPath, settingsFileName);
        
        linkFilePath = fullfile(exPath, sprintf('SettingsLinks%s.csv', suffix));
        settings_new = ReadSettings(settingsPath);
        fprintf('Processing %s\n', seqDir)
        for i = 1:length(settingsToKeep)
            value = GetSeqSettings(settings_old, seqDir, settingsToKeep{i});
            settings_new = SetSeqSettings(settings_new, num, settingsToKeep{i}, value);
        end
        settings_new = SetSeqSettings(settings_new, num, defaults{:});

        WriteSettings(settingsPath, settings_new)
    end
end

fprintf('Done transfering settings files.\n')