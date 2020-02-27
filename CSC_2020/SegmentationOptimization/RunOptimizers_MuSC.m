% Starting from the settings of the BaxterAlgorithms paper.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

basePath = 'C:\CTC2020\Training';
exPath = fullfile(basePath, 'BF-C2DL-MuSC');

MSC_optimizer = SEGOptimizerEx(exPath,...
    {'LVSegThreshold'
    'SegWHMax'
    'SegWSmooth'},...
    'Plot', true);

MSC_optimizer.Optimize_coordinatedescent('MaxIter', 25);