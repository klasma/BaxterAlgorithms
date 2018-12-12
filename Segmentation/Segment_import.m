function [oBlobs, oBw] = Segment_import(aImData, aFrame)
% Imports a segmentation which has been saved as 16-bit tif label images.
%
% This function returns both a set of Blobs and a binary segmentation mask.
% The segmented regions can be adjacent, and the function can handle
% missing labels. The function works for both 2D and 3D data. For 3D data,
% the 3D settings from the microscopy image sequence are used.
%
% To use this function, a folder needs to be placed in the Analysis folder.
% To be detected by the software, the folder name has to start with
% 'Segmentation'. The label images should be placed in a sub-folder to this
% folder, with the same name as the image sequence. Information about the
% sub-folder is stored in the field segImData in the ImageData object of
% the image sequence, provided that the settings SegAlgorithm and
% SegImportFolder have been specified correctly.
%
% Inputs:
% aImData - ImageData object of the image sequence.
% aFrame - The index of the frame to be segmented (starting from 1).
%
% Outputs:
% oBlobs - Array of blobs representing the segmentation.
% oBw - Binary segmentation mask.
%
% See also:
% Segment_import_binary, AddCellProfilerFeatures

segImData = aImData.segImData;

if isempty(segImData)
    error('The segmentation to be loaded was not found correctly.')
end

if segImData.sequenceLength < aFrame
    warning('There is no segmentation for frame %d.', aFrame)
    oBw = zeros(aImData.GetSize());
    return
end

labels = segImData.GetDoubleZStack(aFrame);
oBw = labels > 0;
oBlobs = Labels2Blobs(labels, aFrame);

% Add features computed in CellProfiler.
featureFile = fullfile(segImData.seqPath, 'labels.csv');
if exist(featureFile, 'file')
    AddCellProfilerFeatures(oBlobs, featureFile, aFrame)
end
end