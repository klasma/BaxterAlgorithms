% Add default tracking settings to segmentation settings trained on GT.

trainingOrChallenge = 'Training';
suffix = '_trained_on_ST_all';

dataSetFolder = ['C:\CTC2021\' trainingOrChallenge];

defaults = {
    'TrackSaveMat', '0',...
    };
exDirs = {
    'Fluo-N3DH-CE'
    };

% defaults = {
%     'TrackSaveFPAsCells', '1',...
%     'TrackPAppear', '1E-3',...
%     'TrackPDisappear', '1E-3',...
%     'TrackXSpeedStd', '15',...
%     'TrackZSpeedStd', '15',...
%     'TrackSaveCTC', '1',...
%     };
% 
% exDirs = {
%     'Fluo-C2DL-MSC'
%     'Fluo-N2DH-GOWT1'
%     'Fluo-C3DH-A549'
%     'Fluo-C3DL-MDA231'
%     'Fluo-N2DL-HeLa'
%     'Fluo-N3DH-CHO'
%     'PhC-C2DL-PSC'
%     'Fluo-N3DH-CE'
%     'Fluo-C3DH-H157'
%     };

currentPath = fileparts(mfilename('fullpath'));
newSettingsPath = fullfile(currentPath, '..', '..', 'Files', 'Settings', ['CTC2021' suffix]);


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
                trainingOrChallenge, exDirs{e}, num, suffix);
        WriteSettings(linkFilePath, settings)
    end
end

fprintf('Done adding settings.\n')