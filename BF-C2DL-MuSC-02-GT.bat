@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('BF-C2DL-MuSC', '02', 'Settings_ISBI_2021_Training_BF-C2DL-MuSC-02_trained_on_GT.csv', '-GT')"
