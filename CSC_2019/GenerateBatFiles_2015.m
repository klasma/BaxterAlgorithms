% Generates all bat-files necessary for the software submission in the ISBI
% 2015 cell tracking challenge. Every file runs the tracking on a single
% image sequence in a data set. It is assumed that the top BaxterAlgorithm
% folder from the git repository is put in a folder named SW, inside the
% Challenge (or Training) data set folder. The bat-files can be executed
% from the windows command line. The files run the function
% RunBaxterAlgorithm_ISBI_2015 using the command matlab -r. -wait is added
% as an additional flag so that the bat file waits for MATLAB to complete
% execution before it continues to execute the rest of the bat-file. If
% this is not done, and many bat-files are called from another bat-file,
% there will be many MATLAB windows open at the same time. There is a
% bat-file named RunAll.bat that will execute all bat-files.
%
% See also:
% RunBaxterAlgorithm_ISBI_2015, RunBaxterAlgorithm_ISBI_2014,
% RunBaxterAlgorithm_ISBI_2013, BaxterAlgorithmTerminal,
% RunAllMatAndTif_ISBI_2013, BaxterAlgorithm
%
% Comments are up to date.

% Add necessary paths.
subdirs = textscan(genpath(fileparts(mfilename('fullpath'))), '%s','delimiter',pathsep);
addpath(subdirs{1}{:});

% Only used to get the right file structure. The files don't need to be
% here when the bat-files are executed.
challengePath = 'C:\CTC2015\Challenge';

exDirs = GetNames(challengePath);
exPaths = strcat(challengePath, filesep, exDirs);
base = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));  % SW.

for i = 1:length(exPaths)
    seqDirs = GetSeqDirs(exPaths{i});
    for j = 1:length(seqDirs);
        batFilename = sprintf('%s-%02d.bat', exDirs{i}, j);
        fid = fopen(fullfile(base, batFilename), 'w');
        
        fprintf(fid, '@echo off\r\n');
        fprintf(fid, '\r\n');
        fprintf(fid, 'REM Prerequisities: MATLAB 2012b (x64) or later\r\n');
        fprintf(fid, '\r\n');
        fprintf(fid, 'matlab -wait -r "cd BaxterAlgorithm; RunBaxterAlgorithm_ISBI_2015(''%s'', ''%02d'')"\r\n', exDirs{i}, j);
        
        fclose(fid);
    end
end

fprintf('Done generating bat-files.\n')