@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'BF-C2DL-MuSC'}, 'ST')"
