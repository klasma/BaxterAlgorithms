function LoadSettingsGUI(aSeqPaths, varargin)
% GUI that loads saved settings from files.
%
% The function opens a dialog box that lets the user select what file to
% load settings from. Then the function opens dialog boxes for selection of
% what settings to load and what image sequences to load them from. The
% image sequence selection dialog is skipped if there are only settings for
% a single image sequence in the settings file. The loaded settings are
% saved to the settings files associated with the appropriate open image
% sequences. There are default settings saved in the SettingsFiles-folder
% in the program, but the user can also select settings files from other
% locations. If the selected settings file contains settings for multiple
% image sequences, the user can either select a single entry to load all
% settings from or a list with one entry per selected open image sequence.
%
% Inputs:
% aSeqPahts - Cell array with full paths names of all image sequences for
%             which settings should be loaded.
%
% Property/Value inputs:
% CsvPath - Full path of a csv-file to load settings from. If a file is
%           specified, the GUI will not open a dialog for selection of a
%           file.
% CloseFunction - Function handle of a function which will be executed
%                 after the GUI has been closed, if new settings have been
%                 saved. The default is an empty function.
%
% See also:
% SaveSettingsGUI, LoadSettingsImageGUI

[aCsvPath, aCloseFunction] = GetArgs(...
    {'CsvPath', 'CloseFunction'},...
    {[], @()disp([])},...
    true, varargin);

% Find the names of all settings files saved in the program.
settingsPath = FindFile('Settings');

% Select the settings file.
if isempty(aCsvPath)
    [file, folder] = uigetfile('*.csv', 'Select a settings file', settingsPath);
    if isequal(file, 0)
        return
    end
    loadPath = fullfile(folder, file);
else
    loadPath = aCsvPath;
end

% Load settings.
loadSett = ReadSettings(loadPath);

% Select what settings to load.
[sel_settings, ok_settings] = listdlg(...
    'PromptString', 'Select settings to be loaded',...
    'SelectionMode', 'multiple',...
    'ListString', loadSett(1,2:end),...
    'InitialValue', 1:size(loadSett,2)-1,...
    'ListSize', [600, 100]);
if ~ok_settings
    return
end

% Select from what image sequences the settings should be loaded.
if size(loadSett,1) > 2
    % There are settings for multiple sequences in the settings file.
    sel_seq = [];
    while length(sel_seq) ~= length(aSeqPaths)
        [sel_seq, ok_seq] = listdlg(...
            'PromptString', 'Select settings to be loaded',...
            'SelectionMode', 'multiple',...
            'ListString', loadSett(2:end,1),...
            'ListSize', [600, 100]);
        if ~ok_seq
            return
        end
        
        if length(sel_seq) == 1
            % Use the same settings for all open selected image sequences.
            sel_seq = sel_seq * ones(1, length(aSeqPaths));
        end
        
        if length(sel_seq) ~= length(aSeqPaths)
            errordlg('Selection error',...
                ['You must select either a single entry or as many '...
                'entries as you have selected sequences.'])
        end
    end
else
    % There is only a single image sequence from which all settings will
    % be taken.
    sel_seq = ones(1, length(aSeqPaths));
end

% Write to the settings files.
[exPaths, seqDirs] = FileParts2(aSeqPaths);
% All experiment paths, to which settings need to be saved.
exPathsUnique = unique(exPaths);
for i = 1:length(exPathsUnique)
    sett = ReadSettings(exPathsUnique{i});
    
    indices = find(strcmp(exPaths, exPathsUnique{i}));
    for j = 1:length(indices)
        settingsArgs = loadSett([1 sel_seq(indices(j))+1], sel_settings+1);
        settingsArgs = settingsArgs(:);
        sett = SetSeqSettings(sett, seqDirs{indices(j)}, settingsArgs{:});
    end
    
    WriteSettings(exPathsUnique{i}, sett)
    fprintf('Wrote to the settings file of %s\n', exPathsUnique{i});
    feval(aCloseFunction)
end
end