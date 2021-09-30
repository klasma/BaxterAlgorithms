@echo off

REM Prerequisities: MATLAB 2019b (x64)

matlab -wait -r "Train({'Fluo-C3DH-A549'}, 'GT')"
