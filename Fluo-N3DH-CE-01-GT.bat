@echo off

REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-N3DH-CE', '01', 'Settings_ISBI_2021_Challenge_Fluo-N3DH-CE-01_trained_on_GT.csv', '-GT')"