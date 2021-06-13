% Resume GT+ST optimization of Fluo-C3DH-H157.

subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

maxIter = 25;

tmp = load('C:\CTC2021\Training\Fluo-C3DH-H157\Analysis\SegmentationOptimizers\PerExperimentGtPlusStOptimizerCTC2021_June_interrupted.mat');
optimizer = tmp.optimizer;
optimizer.PrepareToResumeOptimization(366)
optimizer.Optimize_coordinatedescent('MaxIter', maxIter)