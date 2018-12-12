function WriteSettings(aPath, aSett, varargin)
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

aTranspose = GetArgs({'Transpose'}, {true}, true, varargin);

if ~isempty(regexpi(aPath, '.csv$'))
    % The path of the csv-file was specified directly.
    
    if ~exist(fileparts(aPath), 'dir')
        mkdir(fileparts(aPath))
    end
    sett = aSett;
    if aTranspose
        sett = sett';
        sett{1,1} = 'setting';
    else
        
    end
    WriteDelimMat(aPath, sett, ',')
else
    % The path of the experiment directory was specified.
    
    settingsLinkPath = fullfile(aPath, 'SettingsLinks.csv');
    if exist(settingsLinkPath, 'file')
        % Write settings to a linked file instead of to the file in the
        % default location.
        
        settLinks = ReadSettings(settingsLinkPath, aSett(2:end,1));
        
        % A linked settings file is modified once for every image sequence.
        % This can be inefficient if there are many image sequences, but
        % settings links are meant to be used for development and
        % competitions where the number of image sequences is limited, so
        % it should not be a problem.
        for i = 1:size(aSett,1)-1
            linkedPath = GetSettingsPath(settLinks{i+1,2});
            sett = ReadSettings(linkedPath);  % Load all rows in the settings file.
            for j = 1:size(aSett,2)-1
                % Modify the appropriate row in the settings file.
                sett = SetSeqSettings(sett, settLinks{i+1,3},...
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
    else
        % Write to the default location.
        sett = aSett;
        if aTranspose
            sett = sett';
            sett{1,1} = 'setting';
        end
        WriteDelimMat(fullfile(aPath, 'Settings.csv'), sett, ',')
    end
end
end