function CopyOptimizers(aDatasetPath, aOptimizerFolder)

exDirs = GetNames(aDatasetPath, '');
exDirs = setdiff(exDirs, 'SegmentationOptimizers');

allSrcFolder = fullfile(aDatasetPath, 'SegmentationOptimizers');
allDstFolder = fullfile(aOptimizerFolder, 'All');
CopyMatFiles(allSrcFolder, allDstFolder)

for i = 1:length(exDirs)
    srcFolder = fullfile(aDatasetPath,...
        exDirs{i}, 'Analysis', 'SegmentationOptimizers');
    dstFolder = fullfile(aOptimizerFolder, exDirs{i});
    CopyMatFiles(srcFolder, dstFolder)
end
end

function CopyMatFiles(aSrcFolder, aDstFolder)
    optimizers = GetNames(aSrcFolder, 'mat');
    for j = 1:length(optimizers)
        srcPath = fullfile(aSrcFolder, optimizers{j});
        dstPath = fullfile(aDstFolder, optimizers{j});
        if exist(dstPath, 'file')
            fprintf('The optimizer %s already exists.\n', dstPath)
            continue
        end
        if ~exist(fileparts(dstPath), 'dir')
            mkdir(fileparts(dstPath))
        end
        fprintf('Copying to %s\n', dstPath)
        copyfile(srcPath, dstPath)
    end
end