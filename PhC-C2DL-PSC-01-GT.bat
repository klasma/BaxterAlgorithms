@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('PhC-C2DL-PSC', '01', 'Settings_ISBI_2021_Training_PhC-C2DL-PSC-01_trained_on_GT.csv', '-GT')"
