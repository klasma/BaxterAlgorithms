@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'PhC-C2DH-U373'}, 'ST')"
