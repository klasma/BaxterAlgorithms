
subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

%basePath = 'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training';
basePath = 'C:\CellData\Training';
exPath = fullfile(basePath, 'Fluo-C3DH-A549');

optimizer = SEGOptimizerEx(exPath,...
    {'SegClipping'
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'
    'BPSegThreshold'});

optimizer.Optimize_coordinatedescent('MaxIter', 25)