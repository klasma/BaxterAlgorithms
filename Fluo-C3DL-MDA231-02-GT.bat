@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-C3DL-MDA231', '02', 'Settings_ISBI_2021_Training_Fluo-C3DL-MDA231-02_trained_on_GT.csv', '-GT')"