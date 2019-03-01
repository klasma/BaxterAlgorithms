function RunBaxterAlgorithm_ISBI_2015(aExDir, aSeqDir)
% Runs cell tracking on a specific image sequence in the ISBI 2015 Cell
% Tracking Challenge data set. The function assumes that the program has
% been put in a directory named SW in the directory containing all
% training data or all challenge data. The function assumes that the folder
% structure is the same as that on the ftp-server ftp://gryf.fi.muni.cz.
% The function does not create any mat-files with cell tracks, that can be
% played in the GUI. The only files saved are those required for the
% performance evaluation of in the challenge. The function is meant to be
% called from a bat-file and therefore it will close the MATLAB window
% after execution.
%
% Inputs:
% aExDir - The name of the experiment, for example C2DL-MSC.
%
% aSeqDir - The name of the image sequence, for example 01.
%
% See also:
% BaxterAlgorithm, SaveTrack
%
% Comments are up to date.

% Add necessary paths.
subdirs = textscan(genpath(fileparts(mfilename('fullpath'))), '%s','delimiter',pathsep);
addpath(subdirs{1}{:});

fprintf('Processing %s-%s\n', aExDir, aSeqDir)

baxterAlgorithmDir = fileparts(mfilename('fullpath'));
baseDir = fileparts(fileparts(baxterAlgorithmDir));  % isbi170.
settingsName = sprintf('Settings_ISBI_2015_Challenge_%s-%s.csv', aExDir, aSeqDir);
% Path of a settings file located in the program directory.
settingsPath = GetSettingsPath(settingsName);

% Path of the image sequence to be processed.
seqPath = fullfile(baseDir, aExDir, aSeqDir);

if ~exist(seqPath, 'dir')
    % Exit if the sequence can not be found so that more bat-files can be
    % called in cases when the data set directory is not complete.
    exit
end

imData = ImageData(seqPath,...
    'version', 'tmp',...
    'SettingsFile', settingsPath);

cells = Track(imData,...
    'CreateOutputFiles', false);

if imData.Get('TrackSelectFromGT')
    cells = SelectCellsFromGTPixels(cells, imData, 'ReLink', true);
end

SaveCellsTif(imData, cells, [], true);

% Close MATLAB so that there are not 38 MATLAB windows open after all image
% sequences have been processed.
exit
end