version = '_210613_022234_trained_on_GT_plus_ST';
versionA549 = '_210623_000305_trained_on_GT_plus_ST';

exDirs = {...
    'BF-C2DL-HSC'
    'BF-C2DL-MuSC'
    'DIC-C2DH-HeLa'
    'Fluo-C2DL-MSC'
    'Fluo-C3DH-H157'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DH-GOWT1'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CE'
    'Fluo-N3DH-CHO'
    'PhC-C2DH-U373'
    'PhC-C2DL-PSC'};

CopyResultsToSubmission(exDirs, version, '-GT+ST')
CopyResultsToSubmission({'Fluo-C3DH-A549'}, versionA549, '-GT+ST')