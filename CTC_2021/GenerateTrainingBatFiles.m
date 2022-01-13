% Generates bat-files that reproduce the training of segmentation settings
% in the 2021 cell tracking challenge. For each of the configurations GT,
% ST and GT+ST there is one bat-file per dataset. For the configurations
% allGT, allST and allGT+allST there is one bat-file per configuration, and
% that bat-file generates settings for all datasets. It is assumed that the
% top BaxterAlgorithms folder from the git repository is put in a folder
% named SW, inside the Challenge (or Training) data set folder. The
% bat-files can be executed from the windows command line. The files run
% the function Train using the command matlab -r. -wait is added as an
% additional flag so that the bat file waits for MATLAB to complete
% execution before it continues to execute the rest of the bat-file. If
% this is not done, and many bat-files are called from another bat-file,
% there will be many MATLAB windows open at the same time.
%
% See also:
% GenerateBatFiles_2021_June

% Add necessary paths.
subdirs = textscan(genpath(fileparts(fileparts(mfilename('fullpath')))), '%s','delimiter', pathsep);
addpath(subdirs{1}{:});

base = fileparts(fileparts(mfilename('fullpath')));  % SW.

exDirs = {
    'Fluo-C2DL-MSC'
    'Fluo-N2DH-GOWT1'
    'Fluo-C3DH-A549'
    'Fluo-C3DL-MDA231'
    'Fluo-N2DL-HeLa'
    'Fluo-N3DH-CHO'
    'PhC-C2DL-PSC'
    'Fluo-N3DH-CE'
    'Fluo-C3DH-H157'
    'PhC-C2DH-U373'
    'DIC-C2DH-HeLa'
    'BF-C2DL-MuSC'
    'BF-C2DL-HSC'
    };

configurations = {'GT' 'ST' 'GT+ST'};

for i = 1:length(exDirs)
    for j = 1:length(configurations)
        batFilename = sprintf('Train-%s-%s.bat', exDirs{i}, configurations{j});
        fid = fopen(fullfile(base, batFilename), 'w');
        
        fprintf(fid, '@echo off\r\n');
        fprintf(fid, '\r\n');
        fprintf(fid, 'REM Prerequisities: MATLAB 2019b (x64) including toolboxes for Image Processing, Optimization, Parallel Computing, and Statistics and Machine Learning\r\n');
        fprintf(fid, '\r\n');
        fprintf(fid, 'matlab -wait -r "Train({''%s''}, ''%s'')"\r\n', exDirs{i}, configurations{j});
        
        fclose(fid);
    end
end

jointConfigurations = {'allGT' 'allST' 'allGT+allST'};

for j = 1:length(jointConfigurations)
    batFilename = sprintf('Train-%s.bat', jointConfigurations{j});
    fid = fopen(fullfile(base, batFilename), 'w');
    
    fprintf(fid, '@echo off\r\n');
    fprintf(fid, '\r\n');
    fprintf(fid, 'REM Prerequisities: MATLAB 2019b (x64)\r\n');
    fprintf(fid, '\r\n');
    fprintf(fid, 'matlab -wait -r "Train({''%s''}, ''%s'')"\r\n', strjoin(exDirs, ''', '''), jointConfigurations{j});
    
    fclose(fid);
end

fprintf('Done generating bat-files.\n')