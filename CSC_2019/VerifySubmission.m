basePath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Challenge');

versions = {...
'DIC-C2DH-HeLa', '_190215_014612_initial'
'Fluo-C2DL-MSC', '_190215_014612_initial'
'Fluo-C3DH-A549',
'Fluo-C3DH-A549-SIM', '_190301_111634_reverted_again'
'Fluo-C3DH-H157', '_190215_014612_initial'
'Fluo-C3DL-MDA231', '_190215_014612_initial'
'Fluo-N2DH-GOWT1', '_190215_014612_initial'
'Fluo-N2DH-SIM+', '_190215_014612_initial'
'Fluo-N2DL-HeLa', '_190215_014612_initial'
'Fluo-N3DH-CE', '_190215_014612_initial'
'Fluo-N3DH-CHO', '_190215_014612_initial'
'Fluo-N3DH-SIM+', '_190215_014612_initial'
'Fluo-N3DL-DRO', '_190219_173313_initial_sel'
'Fluo-N3DL-TRIC', 'hpc4_sel'
'PhC-C2DH-U373', '_190215_014612_initial'
'PhC-C2DL-PSC', '_190215_014612_initial'};

% Check that the settings files are the same as the checked in ones.
for i = 1:size(versions,1)
    exPath = fullfile(basePath, versions{i,1});
    seqDirs = GetSeqDirs(exPath);
    for j = 1:length(seqDirs)
        seqPath = fullfile(exPath, seqDirs{j});
        dataSettingsFile = fullfile(exPath, 'Analysis', ['CellData' versions{j,2}], 'Settings.csv');
        checkedInSettingsFile
    end
end