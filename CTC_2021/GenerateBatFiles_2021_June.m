% Generates all bat-files necessary for the software submission in the ISBI
% 2021 cell tracking challenge. Every file runs the tracking on a single
% image sequence in a data set. It is assumed that the top BaxterAlgorithms
% folder from the git repository is put in a folder named SW, inside the
% Challenge (or Training) data set folder. The bat-files can be executed
% from the windows command line. The files run the function
% RunBaxterAlgorithms_ISBI_2021 using the command matlab -r. -wait is added
% as an additional flag so that the bat file waits for MATLAB to complete
% execution before it continues to execute the rest of the bat-file. If
% this is not done, and many bat-files are called from another bat-file,
% there will be many MATLAB windows open at the same time.
%
% See also:
% RunBaxterAlgorithms_ISBI_2021, BaxterAlgorithmsTerminal, BaxterAlgorithms

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

configurationsAndSuffixes = {
    'GT' '_trained_on_GT'
    'ST' '_trained_on_ST'
    'GT+ST' '_trained_on_GT_plus_ST'
    'allGT' '_trained_on_GT_all'
    'allST' '_trained_on_ST_all'
    'allGT+allST' '_trained_on_GT_plus_ST_all'
    };

for i = 1:length(exDirs)
    for j = 1:2
        for k = 1:length(configurationsAndSuffixes)
            configuration = configurationsAndSuffixes{k,1};
            suffix = configurationsAndSuffixes{k,2};
            batFilename = sprintf('%s-%02d-%s.bat', exDirs{i}, j, configuration);
            settingsName = sprintf('Settings_ISBI_2021_Challenge_%s-%02d%s.csv',...
                exDirs{i}, j, suffix);
            fid = fopen(fullfile(base, batFilename), 'w');
            
            fprintf(fid, '@echo off\r\n');
            fprintf(fid, '\r\n');
            fprintf(fid, 'REM Prerequisities: MATLAB 2019b (x64)\r\n');
            fprintf(fid, '\r\n');
            fprintf(fid, 'matlab -wait -r "RunBaxterAlgorithms_ISBI_2021(''%s'', ''%02d'', ''%s'', ''-%s'')"\r\n', exDirs{i}, j, settingsName, configuration);
            
            fclose(fid);
        end
    end
end

fprintf('Done generating bat-files.\n')