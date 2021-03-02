@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-C3DH-A549', '02', 'Settings_ISBI_2021_Training_Fluo-C3DH-A549-02_trained_on_GT_all.csv', '-allGT')"
