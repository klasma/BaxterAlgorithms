function SaveSEGGT(aFolder, aVersion, varargin)
% Saves a segmentation ground truth in the format used in CTC 3.
%
% This function takes a tracking version in mat-format and saves it as
% 16-bit tifs with label images, that can be used for evaluation of
% segmentation performance. The label images are saved in a folder named
% SEG, in a folder with the name of the image sequence followed by _GT, in
% the analysis folder of the experiment. This function works for 2D data
% and 3D data that include all z-slices. This means that 3D data can be
% exported in the same ground truth format as in the CTC dataset
% Fluo-N3DH-SIM+. It is not possible to export segmentation ground truths
% in the format used in the other challenge datasets.
%
% Inputs:
% aFolder - Path of folder with image sequences. This can be either a
%           folder with one image sequence (sequence), a folder containing
%           multiple such image sequence folders (experiment), or a folder
%           containing multiple such experiment folders (dataset).
% aVersion - Label associated with the tracking version to be used (not
%            including the prefix 'CellData').
%
% Property/Value inputs:
% FolderType - The type of folder given as the first input ('sequence',
%              'experiment', or 'dataset'). The default is 'sequence'.
%
% See also:
% SaveTRAGT

% Parse property/value inputs.
aFolderType = GetArgs({'FolderType'}, {'sequence'}, true, varargin);

% Handle experiment folders and dataset folders as inputs.
if ApplyToFolder(@SaveSEGGT, aFolder, aVersion, aFolderType)
    return
end

imData = ImageData(aFolder);

dstFolder = fullfile(imData.GetAnalysisPath(), [imData.GetSeqDir() '_GT'], 'SEG');

% Remove old ground truths.
if exist(dstFolder, 'dir')
    rmdir(dstFolder, 's')
end
mkdir(dstFolder)

cells = LoadCells(aFolder, aVersion, 'AreCells', true);
blobSeq = Cells2Blobs(cells, imData, 'Sub', true);

% Save label images for all time points with a segmentation.
for t = 1:length(blobSeq)
    if ~isempty(blobSeq{t})
        im = ReconstructSegmentsBlob(blobSeq{t}, imData.GetSize());
        if imData.sequenceLength <= 1000
            fmt = 'man_seg%03d.tif';
        else
            digits = ceil(log10(imData.sequenceLength));
            fmt = ['man_seg%0' num2str(digits) 'd.tif'];
        end
        imPath = fullfile(dstFolder, sprintf(fmt, t-1));
        if size(im,3) == 1  % 2D data.
            imwrite(uint16(im), imPath, 'Compression', 'lzw')
        else  % 3D data.
            for i = 1:size(im,3)
                imwrite(uint16(squeeze(im(:,:,i))), imPath,...
                    'WriteMode', 'append',...
                    'Compression', 'lzw')
            end
        end
    end
end

fprintf('Done saving SEG ground truth for %s\n', aFolder)
end