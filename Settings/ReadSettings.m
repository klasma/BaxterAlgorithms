function oSett = ReadSettings(aInput, aSeqDirs)
% Reads .csv settings files.
%
% The function can take either the full filename of the settings file or
% the full path name of an experiment folder. The output is a cell array
% with a table containing settings. A second input argument with a cell
% array with image sequence names can be given, in which case only settings
% for the specified image sequences will be included in the table. If there
% are no settings to be returned, the function will return {'file'}.
%
% If there is a SettingsLinks file in the experiment directory, linking to
% a different settings file, the settings will be taken from that settings
% file. The first column of the SettingsLinks files have the name of the
% image sequence, the second column has the name of the Settings file
% linked to and the third column has the sequence name linked to in that
% settings file. The linked settings file is read once for every image
% sequence. This can be inefficient if there are many image sequences, but
% settings links are meant to be used for development and competitions
% where the number of image sequences is limited, so it should not be a
% problem.
%
% Settings files start with 'Settings' and settings link files start with
% 'SettingsLinks'. If an experiment folder contains multipe settings link
% files and/or settings files, the first file returned by GetSettingsFiles
% will be used.
%
% Inputs:
% aInput - Path of experiment, or the full path name of a settings file.
% aSeqDirs (optional) - Names of sequences for which to read settings.
%                       Either a character array with one sequence name or
%                       a cell array with one or multiple.
%
% Outputs:
% oSett - A (m+1)x(n+1) array with m files and n settings in the format.
%
% 'file'        [Setting name 1]  [Setting name 2]  ...  [Setting name n]
% [Filename 1]  value             value                  value
% [Filename 2]  value             value                  value
% ...           ...               ...                    ...
% [Filename 1]  value             value                  value
%
% See also:
% ReadSeqSettings, WriteSettings, GetSeqSettings, WriteSeqSettings,
% SettingsGUI, SettingsPath, ReadSeqLog, WriteSeqLog, GetSettingsFiles

% Convert char input to cell array with one cell.
if nargin == 2 && ~iscell(aSeqDirs)
    aSeqDirs = {aSeqDirs};
end

if ~isempty(regexpi(aInput, '.csv$'))
    % A settings file or settings linnk file was given as input.
    settingsFile = aInput;
else
    % An experiment folder was given as input.
    allSettingsFiles = GetSettingsFiles(aInput);
    if isempty(allSettingsFiles)
        % Return empty settings if there is no settings file.
        oSett = {'file'};
        if nargin == 2
            oSett = [oSett; aSeqDirs(:)];
        end
        return
    end
    settingsFile = allSettingsFiles{1};
end

if isempty(regexpi(FileEnd(settingsFile), '^SettingsLinks'))
    % Read a specified settings file.
    assert(exist(aInput, 'file') == 2,...
        sprintf('The settings file %s does not exist.', aInput))
    oSett = ReadDelimMat(settingsFile, ',');
else
    % Read a settings file linked to by a settings link file.
    
    settLinks = ReadDelimMat(settingsFile, ',');
    
    if size(settLinks,1) == 2
        % Faster version for a single image sequence.
        linkedPath = GetSettingsPath(settLinks{2,2});
        oSett = ReadSettings(linkedPath, settLinks{2,3});
        oSett{2,1} = settLinks{2,1};
    else
        oSett = settLinks(:,1);
        for i = 1:size(settLinks,1)-1
            if nargin == 2 && ~any(strcmp(aSeqDirs,settLinks{i+1,1}))
                % There is no reason to get information for image
                % sequences that we are not interested in.
                continue
            end
            linkedPath = GetSettingsPath(settLinks{i+1,2});
            sett = ReadSettings(linkedPath, settLinks{i+1,3});
            for j = 1:size(sett,2)-1
                oSett = SetSeqSettings(oSett, settLinks{i+1,1},...
                    sett{1,j+1}, sett{2,j+1});
            end
        end
    end
end

% Transpose the settings matrix if necessary.
if strcmpi(oSett{1,1}, 'setting')
    oSett = oSett';
    oSett{1,1} = 'file';
end

% Pick only the desired rows. If a settings link file is defined, there
% will not be any unwanted image sequence at this stage.
if nargin == 2
    tmpSett = [oSett(1,:); repmat({''}, size(oSett(1,:)))];
    for i = 1:length(aSeqDirs)
        tmpSett(1+i,1) = aSeqDirs(i);
        index = find(strcmp(oSett(2:end,1), aSeqDirs{i}))+1;
        if ~isempty(index)
            tmpSett(i+1,2:end) = oSett(index,2:end);
        else
            warning('No settings were found for %s in %s.',...
                aSeqDirs{i}, settingsFile)
        end
    end
    oSett = tmpSett;
end
end