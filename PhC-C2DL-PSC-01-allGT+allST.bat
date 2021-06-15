@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('PhC-C2DL-PSC', '01', 'Settings_ISBI_2021_Challenge_PhC-C2DL-PSC-01_trained_on_GT_plus_ST_all.csv', '-allGT+allST')"
