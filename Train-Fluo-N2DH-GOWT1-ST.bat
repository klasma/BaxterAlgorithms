@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'Fluo-N2DH-GOWT1'}, 'ST')"
