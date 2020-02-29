% Starting from optimized settings after adding a secondary watershed
% transform.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

basePath = 'C:\CTC2020\Training';
exPath = fullfile(basePath, 'BF-C2DL-MuSC');

MuSC_optimizer = SEGOptimizerEx(exPath,...
    {'LVSegThreshold'
    'SegWHMax'
    'SegWSmooth'
    'SegWSmooth2'
    'SegWHMax2'},...
    'Plot', true);

MuSC_optimizer.Optimize_coordinatedescent('MaxIter', 25);