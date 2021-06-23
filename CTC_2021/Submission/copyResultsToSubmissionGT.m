version = '_210613_022234_trained_on_GT';
versionA549 = '_210623_000305_trained_on_GT';
versionH157 = '_210623_000606_trained_on_GT';

exDirs = {...
    'BF-C2DL-HSC'
    'BF-C2DL-MuSC'
    'DIC-C2DH-HeLa'
    'Fluo-C2DL-MSC'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DH-GOWT1'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CE'
    'Fluo-N3DH-CHO'
    'PhC-C2DH-U373'
    'PhC-C2DL-PSC'};

CopyResultsToSubmission(exDirs, version, '-GT')
CopyResultsToSubmission({'Fluo-C3DH-A549'}, versionA549, '-GT')
CopyResultsToSubmission({'Fluo-C3DH-H157'}, versionH157, '-GT')