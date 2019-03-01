basePath = fullfile(ExternalDrive(),...
    'CellData_2011_2014\2019_02_14_Cell_Tracking_Challenge_2019\Challenge');

versions = {...
'DIC-C2DH-HeLa',        'DIC-C2DH-HeLa_01',         '_190215_014612_initial'
'DIC-C2DH-HeLa',        'DIC-C2DH-HeLa_02',         '_190215_014612_initial'
'Fluo-C2DL-MSC',        'Fluo-C2DL-MSC_01',         '_190215_014612_initial'
'Fluo-C2DL-MSC',        'Fluo-C2DL-MSC_02',         '_190215_014612_initial'
'Fluo-C3DH-A549',       'Fluo-C3DH-A549_01',        '_190301_194224_all_small_gaussians_1_5'
'Fluo-C3DH-A549',       'Fluo-C3DH-A549_02',        '_190301_194224_all_small_gaussians_1_5'
'Fluo-C3DH-A549-SIM',   'Fluo-C3DH-A549-SIM_01',    '_190301_180841_final'
'Fluo-C3DH-A549-SIM',   'Fluo-C3DH-A549-SIM_02',    '_190301_180841_final'
'Fluo-C3DH-H157',       'Fluo-C3DH-H157_01',        '_190215_014612_initial'
'Fluo-C3DH-H157',       'Fluo-C3DH-H157_02',        '_190215_014612_initial'
'Fluo-C3DL-MDA231',     'Fluo-C3DL-MDA231_01',      '_190215_014612_initial'
'Fluo-C3DL-MDA231',     'Fluo-C3DL-MDA231_02',      '_190215_014612_initial'
'Fluo-N2DH-GOWT1',      'Fluo-N2DH-GOWT1_01',       '_190215_014612_initial'
'Fluo-N2DH-GOWT1',      'Fluo-N2DH-GOWT1_02',       '_190215_014612_initial'
'Fluo-N2DH-SIM+',       'Fluo-N2DH-SIM+_01',        '_190215_014612_initial'
'Fluo-N2DH-SIM+',       'Fluo-N2DH-SIM+_02',        '_190215_014612_initial'
'Fluo-N2DL-HeLa',       'Fluo-N2DL-HeLa_01',        '_190215_014612_initial'
'Fluo-N2DL-HeLa',       'Fluo-N2DL-HeLa_02',        '_190215_014612_initial'
'Fluo-N3DH-CE',         'Fluo-N3DH-CE_01',          '_190215_014612_initial'
'Fluo-N3DH-CE',         'Fluo-N3DH-CE_02',          '_190215_014612_initial'
'Fluo-N3DH-CHO',        'Fluo-N3DH-CHO_01',         '_190215_014612_initial'
'Fluo-N3DH-CHO',        'Fluo-N3DH-CHO_02',         '_190215_014612_initial'
'Fluo-N3DH-SIM+',       'Fluo-N3DH-SIM+_01',        '_190215_014612_initial'
'Fluo-N3DH-SIM+',       'Fluo-N3DH-SIM+_02',        '_190215_014612_initial'
'Fluo-N3DL-DRO',        'Fluo-N3DL-DRO_01',         '_190219_173313_initial_sel'
'Fluo-N3DL-DRO',        'Fluo-N3DL-DRO_02',         '_190219_173313_initial_sel'
'Fluo-N3DL-TRIC',       'Fluo-N3DL-TRIC_01',        '_hpc4_sel'
'Fluo-N3DL-TRIC',       'Fluo-N3DL-TRIC_02',        '_local_sel'
'PhC-C2DH-U373',        'PhC-C2DH-U373_01',         '_190215_014612_initial'
'PhC-C2DH-U373',        'PhC-C2DH-U373_02',         '_190215_014612_initial'
'PhC-C2DL-PSC',         'PhC-C2DL-PSC_01',          '_190215_014612_initial'
'PhC-C2DL-PSC',         'PhC-C2DL-PSC_02',          '_190215_014612_initial'};

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