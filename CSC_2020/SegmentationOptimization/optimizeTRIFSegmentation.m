% Optimize segmentation on the TRIF sequences in CTC 2020.
%
% Starting from the TRIC settings of CTC 2019.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

basePath = 'C:\CTC2020\Training';
exPath = fullfile(basePath, 'Fluo-N3DL-TRIF-cropped');

optimizer = SEGOptimizerEx(exPath,...
    {'SegTopHatRadius'
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'
    'BPSegThreshold'
    'SegWSmooth'
    'SegWHMax'
    'SegWSmooth2'
    'SegWHMax2'});

optimizer.Optimize_coordinatedescent('MaxIter', 25)