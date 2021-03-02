@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-N2DH-GOWT1', '01', 'Settings_ISBI_2021_Training_Fluo-N2DH-GOWT1-01_trained_on_ST_all.csv', '-allST')"
