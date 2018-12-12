function ExportCellsTif(aSeqPath, aVersion)
% Exports tracking results to the format used in the CTCs.
%
% The function loads tracking results from mat-files created using
% SaveCells and then saves them in the tif-format that was used in the cell
% tracking challenges, using SaveCellsTif. The format is described in
% detail in SaveCellsTif. The exported tracking results are placed in a
% folder named RES inside the CellData-folder of the tracking version that
% is exported. The function will not overwrite previously exported tracking
% results.
%
% Inputs:
% aSeqPath - Full path of the image sequence.
% aVersion - Label of the tracking version to export. The function will
%            generate an error if the tracking version does not exist.
%
% See also:
% CTCExportGUI, SaveCellsTif, SaveCells

% Check that the tracking version to be exported exists.
if ~HasVersion(aSeqPath, aVersion)
    error('The tracking version %s does not exist for %s', aVersion, aSeqPath)
end

imData = ImageData(aSeqPath);

% The folder where the exported tracking results will be saved. The
% function will not overwrite the folder if it already exists.
saveDir = fullfile(....
    imData.GetCellDataDir('Version', aVersion),...
    'RES',...
    [imData.GetSeqDir(), '_RES']);

if ~exist(saveDir, 'dir')
    cells = LoadCells(aSeqPath, aVersion);
    SaveCellsTif(imData, cells, aVersion, false,...
        'SaveDeaths', true,...
        'SaveFP', true);
end
end