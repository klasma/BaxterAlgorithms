% Resume joint segmentation optimization on the primary track datasets for CTC 2021.

maxIter = 25;

tmp = load('C:\CTC2021\Training\SegmentationOptimizers\AllExperimentStOptimizerCTC2021_interrupted.mat');
optimizer = tmp.optimizer;
optimizer.PrepareToResumeOptimization(165)
optimizer.Optimize_coordinatedescent('MaxIter', maxIter)