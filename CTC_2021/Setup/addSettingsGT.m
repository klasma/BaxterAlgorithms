% Add default tracking settings to segmentation settings trained on GT.

dataSetFolder = 'C:\CTC2021\Training';

% defaults = {
%     'TrackSaveMat', '0',...
%     'TrackSaveCTC', '1',...
%     };

defaults = {
    'TrackSaveFPAsCells', '1',...
    'TrackPAppear', '1E-3',...
    'TrackPDisappear', '1E-3',...
    'TrackXSpeedStd', '15',...
    'TrackZSpeedStd', '15',...
    'TrackSaveCTC', '1',...
    };

suffix = '_trained_on_GT';

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
    seqDirs = GetSeqDirs(exPath);
    seqDirs = setdiff(seqDirs, 'Analysis');
    
    for s = 1:length(seqDirs)
        seqDir = seqDirs{s};
        num = seqDir(end-1:end);
        linkFilePath = fullfile(exPath, sprintf('SettingsLinks%s.csv', suffix));
        settings = ReadSettings(linkFilePath, seqDir);
        settings = SetSeqSettings(settings, seqDir, defaults{:});
        settingsFileName = sprintf('Settings_ISBI_2021_%s_%s-%s%s.csv',...
                'Training', exDirs{e}, num, suffix);
        WriteSettings(linkFilePath, settings)
    end
end

fprintf('Done adding settings.\n')