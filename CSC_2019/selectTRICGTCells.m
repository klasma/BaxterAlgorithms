% Script which creates a tracking version with TRIC cells that have a
% ground truth marker in the first image.

basePath = 'D:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019';
seqPaths = {...
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_02')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_01')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIC', 'Fluo-N3DL-TRIC_02')};
version = '_190219_173313_initial';

for i = 1:length(seqPaths)
    selVersion = [version '_sel'];
    if ~HasVersion(seqPaths{i}, selVersion)
        SaveSelectedGTCells(seqPaths{i}, version, selVersion)
    end
end