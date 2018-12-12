function SEGmeasure(aResPath, aGtPath, aRelaxed)
% Computes the SEG measure or the relaxed SEG measure for tracking results.
%
% The SEG measure is the measure of segmentation performance that was used
% in the cell tracking challenges. The function computes the mean Jaccard
% similarity index for ground truth regions and the matching computer
% generated regions. The Jaccard similarity index is the number of pixels
% in the intersection divided by the number of pixels in the union. In the
% normal SEG measure, the computer generated region with the largest
% overlap is considered to be matching provided that it covers more than
% half of the ground truth region. If no region is matching, the Jaccard
% similarity index is set to 0. In the relaxed SEG measure, the computer
% generated region which gives the highest Jaccard similarity index is
% considered to be matching. That gives a better evaluation of segmentation
% results with regions that are too small. The Jaccard similarity indices
% and the final measures are saved to files named SEG_log.txt or
% SEGR_log.txt, so that they can be loaded later.
%
% Inputs:
% aResPath - Full path of the folder with computer generated tracking
%            results.
% aGtPath - Full path of the SEG folder in a ground truth.
% aRelaxed - If this is true, the relaxed SEG measure is computed.
%
% See also:
% PerformanceSEG, PerformanceCTC14SEG

% Find the names of all tif-files with label images.
resFiles = GetNames(aResPath, 'tif');
gtFiles = GetNames(aGtPath, 'tif');

% Create the log file.
if aRelaxed
    fid = fopen(fullfile(aResPath, 'SEGR_log.txt'), 'w');
else
    fid = fopen(fullfile(aResPath, 'SEG_log.txt'), 'w');
end

jaccard = [];  % Jaccard indices for all ground truth regions.
for i = 1:length(gtFiles)
    % Ground truth label image.
    gtIm = imread(fullfile(aGtPath, gtFiles{i}));
    
    % Extract the zero based frame index from the file name.
    frame = regexpi(gtFiles{i}, '(?<=man_seg_?)\d+', 'match', 'once');
    frame = str2double(frame);
    
    % Extract the zero based z-slice index from the file name. For 2D data,
    % the slice index is set to 0.
    slice = regexpi(gtFiles{i}, '(?<=man_seg_?\d+_)\d+', 'match', 'once');
    if isempty(slice)
        slice = 0;
    else
        slice = str2double(slice);
    end
    
    % Load the corresponding label image with computer generated results.
    resName = regexpi(resFiles, ['mask0*' num2str(frame) '.tif'],...
        'match', 'once');
    resName = resName{~cellfun(@isempty, resName)};
    resIm = imread(fullfile(aResPath, resName), slice+1);
    
    % Compute the Jaccard indices for all ground truth regions.
    jaccard_i = JSI(resIm, gtIm, aRelaxed);
    
    % Write the Jaccard indices for this frame to the log-file.
    fprintf(fid, '----------T=%d Z=%d----------\r\n', frame, slice);
    for j = 1:length(jaccard_i)
        if isnan(jaccard_i(j))
            continue
        end
        fprintf(fid, 'GT_label=%d J=%.6g\r\n', j, jaccard_i(j));
    end
    
    jaccard = [jaccard; jaccard_i]; %#ok<AGROW>
end
% Compute the SEG measure.
SEG = mean(jaccard(~isnan(jaccard)));

% Write the SEG measure to the log file.
fprintf(fid, '========================================================\r\n');
if aRelaxed
    fprintf(fid, 'SEGR measure: %.6g\r\n', SEG);
else
    fprintf(fid, 'SEG measure: %.6g\r\n', SEG);
end
fclose(fid);

% Write the SEG measure to the command line.
if aRelaxed
    fprintf('SEGR measure: %.6g\n', SEG)
else
    fprintf('SEG measure: %.6g\n', SEG)
end
end

function oJaccard = JSI(aResIm, aGtIm, aRelaxed)
% Computes the Jaccard similarity indices for ground truth regions.
%
% Inputs:
% aResIm - Label image for computer generated results.
% aGtIm - Label image for ground truth.
% aRelaxed - If this is true, the ground truth regions are matched to the
%            computer generated regions which give the highest Jaccard
%            similarity index. Otherwise, they are matched to the computer
%            generated regions with the largest overlap, provided that more
%            than half of the ground truth regions are covered. The Jaccard
%            index is always set to 0 if there is no matching computer
%            generated region.
%
% Outputs:
% oJaccard - The Jaccard similarity indices for all ground truth regions.
%            If labels are missing from the ground truth label images, the
%            corresponding Jaccard similarity indices are set to nan.

% The labels in the computer generated result represent cells, and since
% all cells are not present in every image, many labels will be missing
% from each image. To speed up the computations and decrease the memory
% usage, we map the labels into integers from 1 to the total number of
% regions.
labels = unique(aResIm(:));
% The total number of computer generated regions.
resNum = length(labels);
% Converts from labels to integers from 1 to resNum.
resMap(labels+1) = 1:resNum;

%  The number of ground truth regions. We do not check if regions are
%  missing. Missing regions are given a Jaccard similarity index of nan.
gtNum = max(aGtIm(:))+1;

% Matrix where the number of overlapping pixels are counted for each region
% pair. overlaps(i,j) is the overlap between region i in the ground truth
% and region j in the computer generated results. In these calculations,
% the backgrounds are counted as regions.
overlaps = zeros(gtNum, resNum);

% Count the overlaps.
for i = 1:numel(aResIm)
    res = resMap(aResIm(i)+1);
    gt = aGtIm(i)+1;
    overlaps(gt, res) = overlaps(gt, res) + 1;
end

% Sum to get the number of pixels in each region.
resCounts = sum(overlaps,1);
gtCounts = sum(overlaps,2);

% Remove the background counts from the ground truth.
overlaps = overlaps(2:end,:);
gtCounts = gtCounts(2:end);
gtNum = gtNum - 1;

% Remove the background counts from the computer generated tracks.
if ~isnan(resMap(1))
    overlaps = overlaps(:,2:end);
    resCounts = resCounts(2:end);
    resNum = resNum - 1;
end

if resNum == 0
    oJaccard = zeros(gtNum,1);
else
    % Expand the region areas to full matrices.
    resAreas = repmat(resCounts, gtNum, 1);
    gtAreas = repmat(gtCounts, 1, resNum);
    
    % Compute the Jaccard indices for all region pairs.
    jaccard = overlaps ./ (resAreas + gtAreas - overlaps);
    
    % Extract the Jaccard indices for the matching computer generated regions.
    if aRelaxed
        oJaccard = max(jaccard, [], 2);
    else
        [~, matches] = max(overlaps, [], 2);
        jaccard(overlaps <= gtAreas / 2) = 0;
        oJaccard = jaccard(sub2ind(size(overlaps), (1:gtNum)', matches));
    end
end

% Set the Jaccard indices to nan for missing ground truth labels.
oJaccard(gtCounts == 0) = nan;
end
