basePath = fullfile('C:\CTC2020\Challenge');

submissionPath = fullfile('C:\CTC2020\Submission');

exDirs = GetNames(basePath, '');

for i = 1:length(exDirs)
    folderPath = fullfile(submissionPath, exDirs{i});
    mkdir(folderPath)
end