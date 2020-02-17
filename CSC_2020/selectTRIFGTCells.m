% Script which creates a tracking version with TRIF cells that have a
% ground truth marker in the first image.

basePath = 'C:\CTC2020';
seqPaths = {...
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIF', 'Fluo-N3DL-TRIF_01')
    fullfile(basePath, 'Training', 'Fluo-N3DL-TRIF', 'Fluo-N3DL-TRIF_02')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIF', 'Fluo-N3DL-TRIF_01')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIF', 'Fluo-N3DL-TRIF_02')};
version = '_200216_005123';

for i = 1:length(seqPaths)
    selVersion = [version '_sel'];
    if HasVersion(seqPaths{i}, version) && ~HasVersion(seqPaths{i}, selVersion)
        SaveSelectedGTCells(seqPaths{i}, version, selVersion)
    end
end