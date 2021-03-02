@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-C2DL-MSC', '02', 'Settings_ISBI_2021_Challenge_Fluo-C2DL-MSC-02_trained_on_GT.csv', '-GT')"
