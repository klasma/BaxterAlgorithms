dataSetFolders = {
    'C:\CTC2021\Challenge'
    'C:\CTC2021\Training'};

for d = 1:length(dataSetFolders)
    exDirs = GetNames(dataSetFolders{d}, '');
    for e = 1:length(exDirs)
        exPath = fullfile(dataSetFolders{d}, exDirs{e});
        fprintf('Processing %s\n', exPath)
        seqDirs = GetNames(exPath, '');
        seqDirs = setdiff(seqDirs, {'Analysis' [exDirs{e} '_01'] [exDirs{e} '_02']});
        settingsLinksPath = fullfile(exPath, 'SettingsLinks.csv');
        
        if exist(settingsLinksPath, 'file')
            delete(settingsLinksPath)
        end
        
        for s = 1:length(seqDirs)
            src = fullfile(exPath, seqDirs{s});
            dst = fullfile(exPath, [exDirs{e} '_' seqDirs{s}]);
            movefile(src, dst, 'f')
        end
    end
end

fprintf('Done renaming folders.\n')