function oMeasure = PerformanceDET(aSeqPath, aTestVer, varargin)
% Computes the DET measure based on a partial segmentation result.
%
% To make the measure drive the optimization also for results that are
% worse than a segmentation with no cells, the output is 1 - totalCosts /
% totalCostsBlack instead of max(1 - totalCosts / totalCostsBlack, 0).

% Parse property/value inputs.
aSuffix = GetArgs({'Suffix'}, {'_GT'}, true, varargin);

imData = ImageData(aSeqPath);

[~, ~, frameErrors, ~, frameErrorsBlack] = PerformanceTRA(aSeqPath, aTestVer,...
    'Suffix', aSuffix);

% Folder with results.
resPath = fullfile(imData.GetCellDataDir('Version', aTestVer),...
    'RES', [imData.GetSeqDir() '_RES']);

if ~exist(resPath, 'dir')
    error('The result path %s does not exist.', resPath)
end

% Find the frames with segmentation results.
resImages = GetNames(resPath, 'tif');
frameStrings = regexp(resImages, '(?<=mask_?)\d+', 'match', 'once');
framesWithDuplicates = cellfun(@str2double, frameStrings) + 1;
frames = unique(framesWithDuplicates);
binaryFrames = zeros(1, imData.sequenceLength);
binaryFrames(frames) = 1;

costs = [5 10 1 0 0 0]';

frameCosts = frameErrors * costs;
frameCostsBlack = frameErrorsBlack * costs;

totalCosts = binaryFrames * frameCosts;
totalCostsBlack = binaryFrames * frameCostsBlack;

oMeasure = 1 - totalCosts / totalCostsBlack;
fprintf('DET measure: %.6g\r\n', oMeasure)
end