@echo off

REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('BF-C2DL-MuSC', '02', 'Settings_ISBI_2021_Challenge_BF-C2DL-MuSC-02_trained_on_ST_all.csv', '-allST')"
