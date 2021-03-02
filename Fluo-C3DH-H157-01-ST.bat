@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-C3DH-H157', '01', 'Settings_ISBI_2021_Training_Fluo-C3DH-H157-01_trained_on_ST.csv', '-ST')"
