function CopyResultsToSubmission(aExDirs, aVersion, aConfigurationSuffix)

for i = 1:length(aExDirs)
    fprintf('Copying results for %s\n', aExDirs{i})
    for j = 1:2
        src = fullfile('C:\CTC2021\Challenge', aExDirs{i}, 'Analysis', ['CellData' aVersion], 'RES', sprintf('%s_%02d_RES', aExDirs{i}, j));
        dst = fullfile('C:\CTC2021\Submission_June', aExDirs{i}, sprintf('%02d_RES%s', j, aConfigurationSuffix));
        copyfile(src, dst)
        
        fpFolder = fullfile(dst, 'false_positives');
        if exist(fpFolder, 'dir')
            rmdir(fpFolder, 's')
        end
        
        deathsFile = fullfile(dst, 'deaths.txt');
        if exist(deathsFile, 'file')
            delete(deathsFile)
        end
    end
end
fprintf('Done copying results\n')
end