@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('DIC-C2DH-HeLa', '01', 'Settings_ISBI_2021_Challenge_DIC-C2DH-HeLa-01_trained_on_GT_plus_ST_all.csv', '-allGT+allST')"