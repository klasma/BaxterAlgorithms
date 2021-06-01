subdirs = textscan(genpath(fileparts(fileparts(fileparts(mfilename('fullpath'))))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

basePath = 'C:\CTC2021\Training';
exDirs = {
    'Fluo-C2DL-MSC'
    'Fluo-N2DH-GOWT1'
    'Fluo-C3DH-A549'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CHO'
    'PhC-C2DL-PSC'
    'PhC-C2DH-U373'
    'DIC-C2DH-HeLa'
    'BF-C2DL-MuSC'
    'BF-C2DL-HSC'
    'Fluo-N3DH-CE'
    'Fluo-C3DH-H157'
    };

for i = 1:length(exDirs)
    exPath = fullfile(basePath, exDirs{i});
    seqDirs = GetSeqDirs(exPath);
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPath, seqDirs{j});
        fprintf('Creating ST minus GT for %s\n', fullfile(seqPath))
        CreateStMinusGt(seqPath)
    end
end

fprintf('Done creating ST_minus_GT folders.\n')