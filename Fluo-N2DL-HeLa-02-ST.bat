@echo off

REM Prerequisities: MATLAB 2018b (x64)

matlab -wait -r "RunBaxterAlgorithms_ISBI_2021('Fluo-N2DL-HeLa', '02', 'Settings_ISBI_2021_Training_Fluo-N2DL-HeLa-02_trained_on_ST.csv', '-ST')"
