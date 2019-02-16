% Prints the number of z-slices and the maximum voxel value for image
% sequences in the new datasets from CSC 2019. These values are needed to
% create settings files.

rootPath = 'E:\CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019';
trainingOrChallenge = {'Training'; 'Challenge'};
exDirs = {
    'Fluo-C3DH-A549'
    'Fluo-C3DH-A549-SIM'
    'Fluo-N3DL-TRIC'};

for i = 1:length(trainingOrChallenge)
    for j = 1:length(exDirs)
        exPath = fullfile(rootPath, trainingOrChallenge{i}, exDirs{j});
        seqDirs = GetSeqDirs(exPath);
        for k = 1:length(seqDirs)
            seqPath = fullfile(exPath, seqDirs{k});
            numSlices = NumSlices(seqPath);
            maxPixelValue = MaxPixelValue(seqPath);
            fprintf('%-9s %-21s %4d %5d\n',...
                trainingOrChallenge{i},...
                seqDirs{k},...
                numSlices,...
                maxPixelValue)
        end
    end
end