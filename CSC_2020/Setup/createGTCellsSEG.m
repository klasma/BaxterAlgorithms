rootPath = 'C:\CTC2020\Training';
exDirs = {
    'BF-C2DL-HSC'
    'BF-C2DL-MuSC'};

for i = 1:length(exDirs)
    exPath = fullfile(rootPath, exDirs{i});
    fprintf('Creating segmentation ground truths for experiment %d / %d.\n', i, length(exDirs))
    ISBICellGTSeg(exPath)
end
fprintf('Done creating ground truths.\n')