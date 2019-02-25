rootPath = 'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training';
exDirs = {
    'Fluo-C3DH-A549'
    'Fluo-C3DH-A549-SIM'
    'Fluo-N3DL-TRIC'};

for i = 1:length(exDirs)
    exPath = fullfile(rootPath, exDirs{i});
    fprintf('Creating tracking ground truths for experiment %d / %d.\n', i, length(exDirs))
    ISBICellGT(exPath)
end
fprintf('Done creating ground truths.\n')