function SaveTRAGT(aFolder, aVersion, varargin)
% Saves a tracking ground truth in the format used in CTC 3.
%
% The function saves an existing tracking result in the ground truth format
% that was used in the ISBI 2015 Cell Tracking Challenge (CTC 3). The
% tracking ground truth files are saved in a folder named TRA, in a folder
% with the name of the image sequence followed by '_GT', in the analysis
% folder of the experiment. The ground truth consists of 16-bit tifs with
% label images named 'man_track' followed by a zero based frame index. In
% addition to the tif-files, there is also a file named 'man_track.txt'
% which holds information about the tracks and the relationships between
% them. If a tracking ground truth already exists, it is removed before a
% new ground truth is created.
%
% The actual ground truth tracks must be created by the user in the manual
% correction GUI. The tracking ground truth can be used to evaluate
% tracking performance.
%
% The ground truth format is the same as the format which was used to save
% tracking results in CTC 3, except that the files are named differently.
% This function creates the ground truth by first calling SaveCellsTif to
% create a tracking result in the CTC 3 format. Then, the tracking result
% files are copied to the ground truth folder and renamed to create a
% corresponding ground truth.
%
% Inputs:
% aFolder - Path of folder with image sequences. This can be either a
%           folder with one image sequence (sequence), a folder containing
%           multiple such image sequence folders (experiment), or a folder
%           containing multiple such experiment folders (dataset).
% aVer - Name of the tracking version which should be saved as a ground
%        truth, without the prefix 'CellData'. 
%
% Property/Value inputs:
% FolderType - The type of folder given as the first input ('sequence',
%              'experiment', or 'dataset'). The default is 'sequence'.
%
% See also:
% SaveSEGGT, SaveCellsTif, ManualCorrectionPlayer

% Parse property/value inputs.
aFolderType = GetArgs({'FolderType'}, {'sequence'}, true, varargin);

% Handle experiment folders and dataset folders as inputs.
if ApplyToFolder(@SaveTRAGT, aFolder, aVersion, aFolderType)
    return
end

imData = ImageData(aFolder);
cells = LoadCells(aFolder, aVersion);
SaveCellsTif(imData, cells, aVersion, false);

srcFolder = fullfile(...
    imData.GetCellDataDir('Version', aVersion),...
    'RES',...
    [imData.GetSeqDir() '_RES']);
dstFolder = fullfile(...
    imData.GetAnalysisPath(),...
    [imData.GetSeqDir() '_GT'],...
    'TRA');

% Remove old ground truths.
if exist(dstFolder, 'dir')
    rmdir(dstFolder, 's')
end
mkdir(dstFolder)

% Copy all the label images.
tifs = GetNames(srcFolder, 'tif');
for i = 1:length(tifs)
    src = fullfile(srcFolder, tifs{i});
    dst = fullfile(dstFolder, strrep(tifs{i}, 'mask', 'man_track'));
    copyfile(src, dst)
end

% Copy text file with track information.
src = fullfile(srcFolder, 'res_track.txt');
dst = fullfile(dstFolder, 'man_track.txt');
copyfile(src, dst)

fprintf('Done saving ground truth for %s\n', aFolder)
end
