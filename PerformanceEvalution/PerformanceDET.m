function oMeasure = PerformanceDET(aSeqPath, aTestVer, varargin)
% Computes the DET measure based on a partial segmentation result.
%
% To make the measure drive the optimization also for results that are
% worse than a segmentation with no cells, the output is 1 - totalCosts /
% totalCostsBlack instead of max(1 - totalCosts / totalCostsBlack, 0).

imData = ImageData(aSeqPath);

[~, ~, frameErrors, ~, frameErrorsBlack] = PerformanceTRA(aSeqPath, aTestVer);

% Find the ground truth folder.
seqDir = imData.GetSeqDir();
gtPath = fullfile(imData.GetAnalysisPath(), [seqDir '_GT'], 'SEG');
if ~exist(gtPath, 'dir')
    % If the ground truth folder is not found, we check if the folder name
    % has been abbreviated.
    gtPath = fullfile(imData.GetAnalysisPath(), [seqDir(end-1:end) '_GT'], 'SEG');
end
if ~exist(gtPath, 'dir')
    error('No ground truth exists for %s.', imData.seqPath)
end

% Find the frames with ground truth segmentations.
gtImages = GetNames(gtPath, 'tif');
gtStrings = regexp(gtImages, '(?<=man_seg_?)\d+', 'match', 'once');
gtFramesWithDuplicates = cellfun(@str2double, gtStrings) + 1;
gtFrames = unique(gtFramesWithDuplicates);
binaryFrames = zeros(1, imData.sequenceLength);
binaryFrames(gtFrames) = 1;

costs = [5 10 1 0 0 0]';

frameCosts = frameErrors * costs;
frameCostsBlack = frameErrorsBlack * costs;

totalCosts = binaryFrames * frameCosts;
totalCostsBlack = binaryFrames * frameCostsBlack;

oMeasure = 1 - totalCosts / totalCostsBlack;
fprintf('DET measure: %.6g\r\n', oMeasure)
end