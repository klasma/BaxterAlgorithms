basePath = 'D:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Training';
version = '_190217_022351_no_foi_erosion';

exDirs = GetNames(basePath, '');

for i = 1:length(exDirs)
    exPath = fullfile(basePath, exDirs{i});
    seqDirs = GetSeqDirs(exPath);
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPath, seqDirs{j});
        if HasVersion(seqPath, version)
            imData = ImageData(seqPath);
            foiErosion = imData.Get('foiErosion');
            fprintf('%s %d\n', seqDirs{j}, foiErosion)
        end
    end
end