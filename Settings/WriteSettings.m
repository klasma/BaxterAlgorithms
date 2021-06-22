function WriteSettings(aInput, aSett, varargin)
% Saves a table of processing settings to a csv-file.
%
% The function can take either a csv-file path or an experiment path as
% input. Normally, the settings are written to a file named Settings.csv in
% the experiment directory. If an experiment name is specified and there
% exists a SettingsLinks.csv file which links to a settings file in the
% program directory, the settings table will be saved to that settings file
% instead. In this case, the settings file will be modified and not
% overwritten but if there are no linked settings, the old settings file is
% overwritten.
%
% Settings files start with 'Settings' and settings link files start with
% 'SettingsLinks'. If an experiment folder contains multipe settings link
% files and/or settings files, the first file returned by GetSettingsFiles
% will be used.
%
% The first column of the SettingsLinks files have the name of the image
% sequence, the second column has the name of the Settings file linked to
% and the third column has the sequence name linked to in that settings
% file.
%
% A linked settings file is modified once for every image sequence. This
% can be inefficient if there are many image sequences, but settings links
% are meant to be used for development and competitions where the number of
% image sequences is limited, so it should not be a problem.
%
% Inputs:
% aPath - Either the full path name of a csv-file or the full path name of
%         the experiment directory in which the settings file should be
%         stored.
% aSett - 2D cell array with a settings table of the same format as the
%         settings tables returned by ReadSettings. The table will be
%         transposed before it is saved, so that it is easier to look at
%         and so that a change to a single setting shows up as an edit to a
%         single line in git.
%
% Property/Value inputs:
% Transpose - If this parameter is set to false, the settings matrix is
%             saved exactly as it is. Otherwise, the matrix is transposed
%             and the top left element is changed to 'setting'. The
%             parameter should be set to false when a settings link file is
%             created.
%
% See also:
% ReadSettings, ReadSeqSettings, GetSeqSettings, WriteSeqSettings,
% SettingsGUI, SettingsPath, ReadSeqLog, WriteSeqLog, GetSettingsFiles

aTranspose = GetArgs({'Transpose'}, {true}, true, varargin);

if ~isempty(regexpi(aInput, '.csv$'))
    % A settings file or settings link file was given as input.
    settingsFile = aInput;
else
    % An experiment folder was given as input.
    allSettingsFiles = GetSettingsFiles(aInput);
    if isempty(allSettingsFiles)
        % Default settings file to be created.
        settingsFile = fullfile(aInput, 'Settings.csv');
    else
        settingsFile = allSettingsFiles{1};
    end
end

if isempty(regexpi(FileEnd(settingsFile), '^SettingsLinks'))
    % Write settings to a settings file.
    if ~exist(fileparts(settingsFile), 'dir')
        mkdir(fileparts(settingsFile))
    end
    sett = aSett;
    if aTranspose
        sett = sett';
        sett{1,1} = 'setting';
    else
        
    end
    WriteDelimMat(settingsFile, sett, ',')
else
    % Write settings to a linked file.
    
    settLinks = ReadDelimMat(settingsFile, ',');
    
    for i = 1:size(aSett,1)-1
        seqDir = aSett{i+1,1};
        linkIndex = find(strcmpi(settLinks(2:end,1), seqDir));
        assert(~isempty(linkIndex),...
            sprintf('No link for %s was found in the settings link file.', seqDir))
        assert(length(linkIndex) == 1,...
            sprintf('Multiple links %s were found in the settings link file.', seqDir))
        linkedPath = GetSettingsPath(settLinks{linkIndex+1,2});
        sett = ReadSettings(linkedPath);  % Load all rows in the settings file.
        for j = 1:size(aSett,2)-1
            % Modify the appropriate row in the settings file.
            sett = SetSeqSettings(sett, settLinks{linkIndex+1,3},...
                aSett{1,j+1}, aSett{i+1,j+1});
        end
        
        if aTranspose
            % Transpose the settings matrix so that changes can be
            % viewed in git.
            sett = sett';
            sett{1,1} = 'setting';
        end
        
        WriteDelimMat(linkedPath, sett, ',')
    end
end
end