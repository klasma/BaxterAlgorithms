% Checks which image sequences in the CTC 2019 datasets have SegFillHoles
% set to true.

trainingPath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training');
challengePath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Challenge');
basePaths = {trainingPath challengePath};

for i = 1:length(basePaths)
    basePath = basePaths{i};
    exDirs = GetNames(basePath, '');
    for j = 1:length(exDirs)
        exPath = fullfile(basePath, exDirs{j});
        seqDirs = GetSeqDirs(exPath);
        for k = 1:length(seqDirs)
            seqPath = fullfile(exPath, seqDirs{k});
            imData = ImageData(seqPath);
            fprintf('Checking %s\n', seqPath)
            fillHoles = imData.Get('SegFillHoles');
            if fillHoles
                fprintf('Fillholes = 1\n')
            else
                fprintf('Fillholes = 0\n')
            end
        end
    end
end