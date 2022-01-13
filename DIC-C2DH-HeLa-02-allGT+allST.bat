@echo off

REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('DIC-C2DH-HeLa', '02', 'Settings_ISBI_2021_Challenge_DIC-C2DH-HeLa-02_trained_on_GT_plus_ST_all.csv', '-allGT+allST')"
