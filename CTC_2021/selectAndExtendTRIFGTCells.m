% Script which creates a tracking version with TRIF cells that have a
% ground truth marker in the first image.

basePath = 'C:\CTC2020';
seqPaths = {...
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIF', 'Fluo-N3DL-TRIF_01')
    fullfile(basePath, 'Challenge', 'Fluo-N3DL-TRIF', 'Fluo-N3DL-TRIF_02')};
version = '_210228_212744_unoptimized_seg_tracks_with_extensions_bug_fix';

for i = 1:length(seqPaths)
    selVersion = [version '_sel'];
%      if HasVersion(seqPaths{i}, version) && ~HasVersion(seqPaths{i}, selVersion)
        fprintf('Selecting and extending tracks in %s\n', seqPaths{i})
        SaveSelectedGTCells(seqPaths{i}, version, selVersion,...
            'Relink', true)
%      end
end