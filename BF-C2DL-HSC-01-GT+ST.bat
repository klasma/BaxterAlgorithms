@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('BF-C2DL-HSC', '01', 'Settings_ISBI_2021_Training_BF-C2DL-HSC-01_trained_on_GT.csv', '-GT+ST')"
