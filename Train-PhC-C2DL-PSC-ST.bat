@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'PhC-C2DL-PSC'}, 'ST')"
