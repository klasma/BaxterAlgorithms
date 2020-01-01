basePath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Challenge');

submissionPath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Submission');

exDirs = GetNames(basePath, '');

for i = 1:length(exDirs)
    folderPath = fullfile(submissionPath, exDirs{i});
    mkdir(folderPath)
end