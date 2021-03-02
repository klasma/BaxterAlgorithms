load('C:\CTC2021\Training\SegmentationOptimizers\AllExperimentStOptimizerCTC2021.mat')
% figure()
% for i = 1:length(optimizer.seqOptimizers)
%     seqOptimizer = optimizer.seqOptimizers(i);
%     fprintf('%d %f %s\n', i, seqOptimizer.fBest, FileEnd(seqOptimizer.seqPath))
%     plot(1-seqOptimizer.fAll)
%     hold all
% end

helaOptimizer = optimizer.seqOptimizers(10);
helaOptimizer.EvaluateObjective(helaOptimizer.xBest)