function SaveSelectedGTCells(aSequence, aVersion, aSaveVersion, varargin)
% Saves cells which correspond to a ground truth cell in the first image.
%
% The function will load a tracking version, select the cells which have a
% corresponding cell in a manual tracking ground truth, and then save the
% selected cells as a new tracking version. This function is used to
% process the Drosophila dataset of Cell Tracking Challenge III 2015.
%
% Inputs:
% aSeqPath - ImageData object or full path of the image sequence folder.
% aVersion - The tracking version which should be loaded.
% aSaveVersion - The version name that the selected tracks will be saved
%                under.
%
% Property/Value inputs:
% Property/Value inputs for SelectCellsFromGTPixels.
%
% See also:
% SelectCellsFromGTPixels, SaveCells

% Create an ImageData object of the image sequence.
if ischar(aSequence)
    imData = ImageData(aSequence, 'version', aVersion);
else
    imData = aSequence;
end

% Load a tracking version with all cells.
cells = LoadCells(imData.seqPath, aVersion);

% Select cells which correspond to a ground truth cell in the first image.
selectedCells = SelectCellsFromGTPixels(cells, imData, varargin{:});

% Save the selected cells as a new version.
SaveCells(selectedCells, imData.seqPath, aSaveVersion)
end