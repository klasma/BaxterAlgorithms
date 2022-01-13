@echo off

REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('PhC-C2DH-U373', '01', 'Settings_ISBI_2021_Challenge_PhC-C2DH-U373-01_trained_on_ST_all.csv', '-allST')"