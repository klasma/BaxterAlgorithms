datasetFolders = {
    'C:\CTC2021\Training'};
trainingOrChallenge = {
    'Challenge'
    'Training'};


for d = 1:length(datasetFolders)
    exDirs = GetNames(datasetFolders{d}, '');
    for e = 1:length(exDirs)
        exPath = fullfile(datasetFolders{d}, exDirs{e});
        CreateSettingsLinkFile(exPath, 'Training', '_clean')
        CreateSettingsLinkFile(exPath, 'Training', '_trained_on_GT')
        CreateSettingsLinkFile(exPath, 'Training', '_trained_on_GT_all')
        CreateSettingsLinkFile(exPath, 'Training', '_trained_on_ST')
        CreateSettingsLinkFile(exPath, 'Training', '_trained_on_ST_all')
    end
end

fprintf('Done creating settings link files.\n')