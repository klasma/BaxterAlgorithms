@echo off

REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-C3DL-MDA231', '01', 'Settings_ISBI_2021_Challenge_Fluo-C3DL-MDA231-01_trained_on_ST_all.csv', '-allST')"
