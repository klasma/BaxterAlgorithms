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
    'Fluo-C2DL-Huh7'
    'Fluo-N3DL-TRIF'
    };

for i = 1:length(exDirs)
    for j = 1:2
        batFilename = sprintf('%s-%02d.bat', exDirs{i}, j);
        settingsName = sprintf('Settings_ISBI_2021_Challenge_%s-%02d.csv',...
            exDirs{i}, j);
        fid = fopen(fullfile(base, batFilename), 'w');
        
        fprintf(fid, '@echo off\r\n');
        fprintf(fid, '\r\n');
        fprintf(fid, 'REM Prerequisities: MATLAB 2019b (x64)\r\n');
        fprintf(fid, '\r\n');
        fprintf(fid, 'matlab -wait -r "RunBaxterAlgorithms_ISBI_2021(''%s'', ''%02d'', ''%s'', '''')"\r\n', exDirs{i}, j, settingsName);
        
        fclose(fid);
    end
end

fprintf('Done generating bat-files.\n')