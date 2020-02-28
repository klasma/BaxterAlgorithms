% Set SegTopHatRadius to 300 and started optimizing from the parameters
% in CTC 2019.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

basePath = 'C:\CTC2020\Training';
seqPath = fullfile(basePath, 'Fluo-C2DL-MSC', 'Fluo-C2DL-MSC_02');

MSC_optimizer1 = TRAOptimizerSeq(seqPath,...
    {'SegTopHatRadius'
    'BPSegThreshold'
    'BPSegHighStd'
    'BPSegLowStd'
    'BPSegBgFactor'},...
    'Grids', {1:5000 [] [] [] []},...
    'SegmentationCores', 8,...
    'Plot', true);

MSC_optimizer1.Optimize_coordinatedescent('MaxIter', 25);