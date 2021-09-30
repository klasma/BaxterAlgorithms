@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'DIC-C2DH-HeLa'}, 'GT')"
