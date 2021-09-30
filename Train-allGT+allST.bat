@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'Fluo-C2DL-MSC', 'Fluo-N2DH-GOWT1', 'Fluo-C3DH-A549', 'Fluo-C3DL-MDA231', 'Fluo-N2DL-HeLa', 'Fluo-N3DH-CHO', 'PhC-C2DL-PSC', 'Fluo-N3DH-CE', 'Fluo-C3DH-H157', 'PhC-C2DH-U373', 'DIC-C2DH-HeLa', 'BF-C2DL-MuSC', 'BF-C2DL-HSC'}, 'allGT+allST')"
