@echo off

REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning

matlab -wait -r "Train({'Fluo-C3DH-A549'}, 'GT+ST')"