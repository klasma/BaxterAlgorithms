@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-N3DH-CHO', '01', 'Settings_ISBI_2021_Challenge_Fluo-N3DH-CHO-01_trained_on_GT.csv', '-GT+ST')"
