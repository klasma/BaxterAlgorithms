function TrackingGUI(aSeqPaths, aQueue, varargin)
% GUI to start tracking on image sequences.
%
% The user needs to specify a label for the tracking results, and the
% number of parallel processing cores to use. Parallelization can be done
% over image sequences or over images in the segmentation step. The user
% can also specify that existing results should be overwritten, and write
% notes about the tracking that is to be performed.
%
% Inputs:
% aSeqPaths - Cell array with the paths of image sequences to stabilize.
% aQueue - Queue object that can be used to queue the execution and start
%          it later.
%
% Property/Value inputs:
% ExitFunction - Function handle that should be executed once the tracking
%                is finished.
%
% See also:
% TrackSave, Track, CuttingGUI, StabilizationGUI

% Parse property/value inputs.
aExitFunction = GetArgs({'ExitFunction'}, {@()disp([])}, true, varargin);

mainFigure = figure('Name', 'Tracking',...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Units', 'pixels',...
    'Position', [200 200 500 500],...
    'Resize', 'off');

versions = GetVersions(aSeqPaths);
existingVersions = unique([versions{:}])';
info.Existing_Versions = Setting(...
    'name', 'Existing Versions',...
    'type', 'list',...
    'default', {},...
    'alternatives_basic', existingVersions,...
    'tooltip', 'Click on an existing version to select that name.',...
    'callbackfunction', @ExistingVersionCallback);
info.Save_Version = Setting(...
    'name', 'Save Version',...
    'tooltip', 'Label for the generated tracks. Use letters, numbers and underscores.',...
    'type', 'char',...
    'default', datestr(now, '_yymmdd_HHMMss'));
coreAlts = arrayfun(@num2str, 1:MaxWorkers(), 'UniformOutput', false);
info.Number_of_cores = Setting(...
    'name', 'Number of cores',...
    'tooltip', 'The number of processor cores used for parallel processing.',...
    'type', 'choice',...
    'default', coreAlts(end),...
    'alternatives_basic', coreAlts);
info.Parallelize_over = Setting(...
    'name', 'Parallelize over',...
    'tooltip', 'Run one sequence per worker or one frame per worker (only parallelizes segmentation).',...
    'type', 'choice',...
    'default', 'Image sequences',...
    'visiblefunction', @(x) str2double(x.Get('Number_of_cores')) > 1,...
    'alternatives_basic', {'Image sequences', 'Segmentation frames'});
info.Overwrite = Setting(...
    'name', 'Overwrite',...
    'tooltip', 'Delete existing files associated with the save version.',...
    'type', 'check',...
    'default', false);
exPaths = unique(FileParts2(aSeqPaths));
settingsFiles = cellfun(@GetSettingsFiles, exPaths,...
    'UniformOutput', false);
settingsFiles = cat(1, settingsFiles{:});
settingsFiles = FileEnd(settingsFiles);
settingsFiles = unique(settingsFiles);
info.Settings = Setting(...
    'name', 'Settings',...
    'tooltip', 'Settings file or settings link file defining settings.',...
    'type', 'choice',...
    'default', settingsFiles{1},...
    'alternatives_basic', settingsFiles);

sPanel = SettingsPanel(info,...
    'Parent', mainFigure,...
    'Position', [0 0.4 1 0.6],...
    'Split', 0.3,...
    'MinList', 10);

uicontrol(...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 0.5 0.15],...
    'String', 'Start',...
    'Tooltip', 'Start processing',...
    'Callback', @StartButton_Callback);
uicontrol(...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0.5 0 0.5 0.15],...
    'String', 'Queue',...
    'Tooltip', 'Put the processing in a queue',...
    'Callback', @QueueButton_Callback);

% Create a text box where the user can write notes.
uicontrol(...
    'HorizontalAlignment', 'left',...
    'Style', 'text',...
    'Units', 'normalized',...
    'Position', [0 0.35 1 0.05],...
    'String', 'Notes',...
    'Tooltip', 'Notes saved in the log-files of the tracking results');
noteTextbox = uicontrol(...
    'BackgroundColor', 'white',...
    'HorizontalAlignment', 'left',...
    'Style', 'edit',...
    'Min', 0,...
    'Max', 2,...  % Multiple lines.
    'Units', 'normalized',...
    'Position', [0 0.15 1 0.2],...
    'String', '',...
    'Tooltip', 'Notes saved in the log-files of the tracking results');

    function ExistingVersionCallback(~, ~)
        % Copies a version name from the list box to the text box.
        %
        % The function will also enter user notes from the selected version
        % in the textbox for user notes.
        
        selectedVer = sPanel.GetValue('Existing_Versions');
        if ~isempty(selectedVer)
            % Enter the version name in the version name textbox.
            sPanel.SetValue('Save_Version', selectedVer{1})
            
            % Enter user notes in the note textbox.
            note = '';
            for i = 1:length(aSeqPaths)
                if HasVersion(aSeqPaths{i}, selectedVer{1})
                    imData = ImageData(aSeqPaths{i});
                    logFile = imData.GetLogPath('Version', selectedVer{1});
                    if exist(logFile, 'file')
                        note = ReadLogNote(logFile);
                        note = FileStrToEditStr(note);
                        % The note from the first log-file is used.
                        break
                    end
                end
            end
            set(noteTextbox, 'String', note)
        end
    end

    function StartButton_Callback(~, ~)
        % Starts stabilizing the image sequences.
        
        % Get processing parameters specified by the user.
        version = sPanel.GetValue('Save_Version');
        settingsFile = sPanel.GetValue('Settings');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        parallelizeOver = sPanel.GetValue('Parallelize_over');
        switch parallelizeOver
            case 'Image sequences'
                parallelizeSegmentation = false;
            case 'Segmentation frames'
                parallelizeSegmentation = true;
            otherwise
                error('Unknown parallelization option %s.\n', parallelizeOver)
        end
        overwrite = sPanel.GetValue('Overwrite');
        notes = EditStrToFileStr(get(noteTextbox, 'String'));
        
        % Check that the entered version label is valid.
        if isempty(version) || ~isvarname(['a' version])
            VersionNameErrorDialog()
            return
        end
        
        RunTracking(...
            aSeqPaths,...
            version,...
            settingsFile,...
            numCores,...
            parallelizeSegmentation,...
            overwrite,...
            notes,...
            aExitFunction);
    end

    function QueueButton_Callback(~, ~)
        % Puts the execution on a processing queue, to be started later.
        
        % Get processing parameters specified by the user.
        version = sPanel.GetValue('Save_Version');
        settingsFile = sPanel.GetValue('Settings');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        parallelizeOver = sPanel.GetValue('Parallelize_over');
        switch parallelizeOver
            case 'Image sequences'
                parallelizeSegmentation = false;
            case 'Segmentation frames'
                parallelizeSegmentation = true;
            otherwise
                error('Unknown parallelization option %s.\n', parallelizeOver)
        end
        overwrite = sPanel.GetValue('Overwrite');
        notes = EditStrToFileStr(get(noteTextbox, 'String'));
        
        % Check that the entered version label is valid.
        if isempty(version) || ~isvarname(['a' version])
            VersionNameErrorDialog()
            return
        end
        
        aQueue.Add(@()RunTracking(...
            aSeqPaths,...
            version,...
            settingsFile,...
            numCores,...
            parallelizeSegmentation,...
            overwrite,...
            notes,...
            aExitFunction))
    end
end

function RunTracking(...
    aSeqPaths,...
    aVersion,...
    aSettingsFile,...
    aNumCores,...
    aParallelizeSegmentation,...
    aOverwrite,...
    aNotes,...
    aExitFunction)
% Starts tracking on all the image sequences.
%
% Inputs:
% aSeqPaths - Cell array with paths of image sequences to be tracked.
% aVersion - Name of the tracking version to be created.
% aNumCores - The number of processor cores to use for parallel processing.
% aParallelizeSegmentation - If this is true, different frames are
%                            segmented in parallel, but only one image
%                            sequence is processed at a time. If this is
%                            false, entire image sequences are processed in
%                            parallel.
% aOverWrite - If this input is true, existing results with the same
%              version name will be overwritten. Otherwise the processing
%              will be resumed.
% aNotes - Notes written by the user about the tracking version.
% aExitFunction - Function handle that should be executed once the tracking
%                 is finished.

% Delete all existing files if Overwrite has been selected.
if aOverwrite
    for i = 1:length(aSeqPaths)
        fprintf(['Deleting existing tracking files for sequence '...
            '%d / %d.\n'], i, length(aSeqPaths))
        DeleteVersion(aSeqPaths{i}, aVersion)
    end
end

imDatas = [];
for i = 1:length(aSeqPaths)
    seqPath = aSeqPaths{i};
    exPath = FileParts2(seqPath);
    settingsPath = fullfile(exPath, aSettingsFile);
    
    if ~exist(settingsPath, 'file')
        warning('The settings file %s did not exist. Not processing %s.',...
            settingsPath, seqPath)
        continue
    end
    
    if ~HasSettings(settingsPath, FileEnd(seqPath))
        warning('The settings file %s did not contain settings for %s. Not processing %s.',...
            settingsPath, FileEnd(seqPath), seqPath)
        continue
    end
    
    imData = ImageData(seqPath,...
        'version', aVersion,...
        'SettingsFile', settingsPath);
    imDatas = [imDatas imData]; %#ok<AGROW>
end

% Copy all of the settings from the sequences to the
% CellData-folder with the tracking results, so that they can be
% reviewed later. This cannot be done in the parfor-loop, as
% multiple workers could try to access the same file at the same
% time.
for i = 1:length(imDatas)
    exPath = imDatas(i).GetExPath();
    seqDir = imDatas(i).GetSeqDir();
    if ~exist(fullfile(exPath, 'Analysis', ['CellData' aVersion]), 'dir')
        mkdir(fullfile(exPath, 'Analysis', ['CellData' aVersion]))
    end
    logFile = fullfile(exPath, 'Analysis', ['CellData' aVersion],...
        'Logs', [seqDir '.txt']);
    if ~exist(logFile, 'file')
        % Only copy the settings if the sequence has not been tracked. If
        % it has been tracked, it is better to keep the old settings that
        % were used for tracking.
        CopySettings(imDatas(i), fullfile(exPath, 'Analysis',...
            ['CellData' aVersion], seqDir))
    end
end

errorFiles = {}; % Files where processing errors occurred.
errorStructs = []; % MATLAB structs with information about the errors.

if aNumCores == 1 || aParallelizeSegmentation
    % If aNumCores is larger than 1 and there is a single image sequence,
    % parallelization will be done over images in the segmentation.
    wbar = waitbar(0, sprintf(['Processing sequence 1 / %d. '...
        '(Press ctrl+c in the command window to cancel.)'],...
        length(imDatas)), 'Name', 'Tracking...');
    for i = 1:length(imDatas)
        try
            if ishandle(wbar)
                waitbar((i-1)/length(imDatas), wbar,...
                    sprintf(['Processing sequence %d / %d. '...
                    '(Press ctrl+c in the command window to cancel.)'],...
                    i, length(imDatas)))
            end
            TrackSequence(imDatas(i), aNotes,...
                'SegmentationCores', aNumCores)
        catch ME % Allow processing of the other files to continue if an error occurs.
            disp(getReport(ME))
            errorFiles = [errorFiles {FileEnd(imDatas(i).GetSeqDir())}]; %#ok<AGROW>
            errorStructs = [errorStructs ME]; %#ok<AGROW>
        end
    end
    if ishandle(wbar)
        close(wbar)
    end
else
    % Parallel processing is run in a separate loop, to avoid
    % automatically starting parallel workers when parallel
    % processing has not been selected.
    StartWorkers(aNumCores)
    wbar_parfor = ParforProgMon(...
        'Tracking... (Press ctrl+c in the command window to cancel.) ',...
        length(imDatas), 1, 600, 80);
    parfor i = 1:length(imDatas)
        try
            TrackSequence(imDatas(i), aNotes)
        catch ME % Allow processing of the other files to continue if an error occurs.
            disp(getReport(ME))
            errorFiles = [errorFiles {FileEnd(imDatas(i))}];
            errorStructs = [errorStructs ME];
        end
        wbar_parfor.increment(); %#ok<PFBNS>
    end
    wbar_parfor.delete()
end
fprintf('Done tracking image sequences.\n')

% Display all errors.
for err = 1:length(errorFiles)
    disp('Unable to process:')
    disp(errorFiles{err})
    disp('The following error occurred:')
    disp(getReport(errorStructs(err)))
end

feval(aExitFunction)
end

function TrackSequence(aImData, aNotes, varargin)
% Runs tracking on a single image sequence and writes a log file.
%
% Inputs:
% aImData - Path of image sequence folder to be tracked. The version
%           property has to be set.
% aNotes - Notes written by the user about the tracking version.
%
% Property/Value inputs:
% SegmentationCores - The number of cores to use for parallel processing in
%                     the segmentation step.

aSegmentationCores = GetArgs({'SegmentationCores'}, {1}, true, varargin);

logFile = aImData.GetLogPath();
if ~exist(logFile, 'file')
    SaveTrack(aImData, 'SegmentationCores', aSegmentationCores);
    WriteLog(logFile, 'TrackingGUI', aNotes)
end
end

function VersionNameErrorDialog()
% Opens an error dialog when the entered tracking version label is invalid.
%
% The check is performed before the processing is stated or put in an
% execution queue.

errordlg(['The tracking version label must not be empty and must only '...
    'contain English letters, numbers, and underscores.'],...
    'Invalid Save Version')
end