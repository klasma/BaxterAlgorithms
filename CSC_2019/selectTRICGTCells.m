% Script which creates a tracking version with TRIC cells that have a
% ground truth marker in the first image.

basePath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019');
seqPaths = {...
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIC-cropped', 'Fluo-N3DL-TRIC_01')
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIC-cropped', 'Fluo-N3DL-TRIC_02')
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_01')
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_02')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_01')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_02')};
version = '_hpc4';

parfor i = 1:length(seqPaths)
    selVersion = [version '_sel'];
    if HasVersion(seqPaths{i}, version) && ~HasVersion(seqPaths{i}, selVersion)
        SaveSelectedGTCells(seqPaths{i}, version, selVersion)
    end
end