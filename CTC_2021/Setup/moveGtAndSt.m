dataSetFolder = 'C:\CTC2021\Challenge';

exDirs = GetNames(dataSetFolders{d}, '');
for e = 1:length(exDirs)
    exPath = fullfile(dataSetFolders{d}, exDirs{e});
    mkdir(fullfile(exPath, 'Analysis'))
    if exist(fullfile(exPath, '01_GT'), 'dir')
        movefile(fullfile(exPath, '01_GT'),fullfile(exPath, 'Analysis', '01_GT'))
    end
    if exist(fullfile(exPath, '02_GT'), 'dir')
        movefile(fullfile(exPath, '02_GT'),fullfile(exPath, 'Analysis', '02_GT'))
    end
    if exist(fullfile(exPath, '01_ST'), 'dir')
        movefile(fullfile(exPath, '01_ST'),fullfile(exPath, 'Analysis', '01_ST'))
    end
    if exist(fullfile(exPath, '02_ST'), 'dir')
        movefile(fullfile(exPath, '02_ST'),fullfile(exPath, 'Analysis', '02_ST'))
    end
end

