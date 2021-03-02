% Creates settings without algorithm parameters, to start segmentation
% optimization from.

dataSetFolder = 'C:\CTC2021\Challenge';

suffix = '_trained_on_GT';

currentPath = fileparts(mfilename('fullpath'));
settingsFolder = fullfile(currentPath, '..', '..', 'Files', 'Settings', ['CTC2021' suffix]);

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