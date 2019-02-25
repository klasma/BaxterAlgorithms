% Optimize segmentation on the Drosophila sequences in CTC 2015.
%
% The parameter SegWHMax was changed from 0 to 0.001 before starting the
% script, to avoid getting a step length of 0.

subdirs = textscan(genpath(fileparts(fileparts(mfilename('fullpath')))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

basePath = 'D:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training';
exPath = fullfile(basePath, 'Fluo-N3DL-TRIC');

optimizer = SEGOptimizerEx(exPath,...
    {'SegClipping'
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'
    'BPSegThreshold'
    'SegWSmooth'
    'SegWHMax'
    'SegWSmooth2'
    'SegWHMax2'});

optimizer.Optimize_coordinatedescent('MaxIter', 25)