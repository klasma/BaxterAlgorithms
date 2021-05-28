function CopyResultsToSubmission(aVersion, aConfigurationSuffix)

exDirs = {
%     'Fluo-C2DL-MSC'
%     'Fluo-N2DH-GOWT1'
%     'Fluo-C3DH-A549'
%     'Fluo-C3DL-MDA231'
%     'Fluo-N2DL-HeLa'
%     'Fluo-N3DH-CHO'
%     'PhC-C2DL-PSC'
    'Fluo-N3DH-CE'
%     'Fluo-C3DH-H157'
    };

for i = 1:length(exDirs)
    fprintf('Copying results for %s\n', exDirs{i})
    for j = 1:2
        src = fullfile('C:\CTC2021\Challenge', exDirs{i}, 'Analysis', ['CellData' aVersion], 'RES', sprintf('%s_%02d_RES', exDirs{i}, j));
        dst = fullfile('C:\CTC2021\Submission', exDirs{i}, sprintf('%02d_RES%s', j, aConfigurationSuffix));
        copyfile(src, dst)
    end
end
fprintf('Done copying results\n')
end