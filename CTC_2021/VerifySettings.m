% Verifies that the settings from the optimizers have been stored correctly
% in the corresponding settings files. The verification is performed by
% saving the optimized settings of all optimizers to the settings files in
% the git-repo, to see if any changes are made.

optimizerFolder = 'C:\CTC2021\SegmentationOptimizers';

exDirs = GetNames(optimizerFolder, '');
exDirs = setdiff(exDirs, 'All');

optimizerNames = {...
    'PerExperimentOptimizerCTC2021_June.mat'
    'PerExperimentGtPlusStOptimizerCTC2021_June.mat'
    'PerExperimentStOptimizerCTC2021_June.mat'};

for i = 1:length(optimizerNames)
    optimizerName = optimizerNames{i};
    for j = 1:length(exDirs)
        exDir = exDirs{j};
        optimizerPath = fullfile(...
            optimizerFolder, exDir, optimizerName);
        tmp = load(optimizerPath);
        optimizer = tmp.optimizer;
        for k = 1:length(optimizer.seqOptimizers)
            segOptimizer = optimizer.seqOptimizers(k);
            segOptimizer.savePath = strrep(segOptimizer.savePath,...
                'CTC2021_STopt', 'CTC2021');
            segOptimizer.SaveSettings(optimizer.xBest);
        end
    end
end

optimizerNamesAll = {...
    'AllExperimentOptimizerCTC2021_June.mat'
    'AllExperimentGtPlusStOptimizerCTC2021_June.mat'
    'AllExperimentStOptimizerCTC2021_June.mat'};

for i = 1:length(optimizerNamesAll)
    optimizerName = optimizerNamesAll{i};
    optimizerPath = fullfile(...
        optimizerFolder, 'All', optimizerName);
    tmp = load(optimizerPath);
    optimizer = tmp.optimizer;
    for k = 1:length(optimizer.seqOptimizers)
        segOptimizer = optimizer.seqOptimizers(k);
        segOptimizer.savePath = strrep(segOptimizer.savePath,...
            'CTC2021_STopt', 'CTC2021');
        segOptimizer.SaveSettings(optimizer.xBest);
    end
end