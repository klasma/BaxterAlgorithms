function ReplaceSegmentation(aSeqPaths, aQueue, varargin)
% GUI that can be used to switch the segmentation in a tracking version.
%
% The GUI lets the user input settings and then calls SegmentSequene and
% SwitchSegmentation, which perform segmentation and apply the new
% segmentation to the old tracks. The function then saves the new tracking
% results under a name specified by the user. The current segmentation
% settings will be used for the new segmentation. Parallel processing can
% be used to process multiple image sequences at a time. If parallel
% processing is selected when there is a single image sequence, the
% parallelization will be done over the frames in the segmentation step.
%
% Inputs:
% aSeqPaths - Cell array with full paths of image sequences, for which the
%             segmentation should be replaced.
% aQueue - Queue object that can be used to queue the execution and start
%          it later.
%
% Property/Value inputs:
% ExitFunction - Function handle that should be executed once the
%                processing is finished.
%
% See also:
% SegmentSequence, SwitchSegmentation, TrackingGUI

% Parse property/value inputs.
aExitFunction = GetArgs({'ExitFunction'}, {[]}, true, varargin);

mainFigure = figure('Name', 'Replace segmentation',...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Units', 'pixels',...
    'Position', [200 200 400, 300],...
    'Resize', 'off');

% All available tracking versions.
versions = GetVersions(aSeqPaths);
versions = unique([versions{:}]);

% Input data for SettingsPanel, used to create ui-objects.
info.Old_tracks = Setting(...
    'name', 'Old tracks',...
    'type', 'choice',...
    'default', versions{1},...
    'alternatives_basic', versions,...
    'callbackfunction', @OldTrackCallback,...
    'tooltip', ['Old tracking version, for which the segmentation will '...
    'be replaced.']);
info.New_tracks = Setting(...
    'name', 'New tracks',...
    'type', 'char',...
    'default', [versions{1} '_repseg'],...
    'tooltip', ['Name of the tracking version which will be created '...
    'from the new segmentation.']);
info.Redo_matching = Setting(...
    'name', 'Redo matching',...
    'type', 'check',...
    'default', false,...
    'tooltip', ['Perform bipartite matching after the segmentation has '...
    'been switched. Track assignments may change.']);
info.Merge_fragments = Setting(...
    'name', 'Merge fragments',...
    'type', 'check',...
    'default', false,...
    'tooltip', 'Merge false positive fragments into adjacent cells.');
info.Matching_metric = Setting(...
    'name', 'Matching metric',...
    'type', 'choice',...
    'default', 'overlap',...
    'alternatives_basic', {'overlap', 'distance (PTC)'},...
    'tooltip', 'Metric used to match blobs to ground truth cells.');
coreAlts = arrayfun(@num2str, 1:MaxWorkers(), 'UniformOutput', false);
info.Number_of_cores = Setting(...
    'name', 'Number of cores',...
    'tooltip', 'The number of processor cores used for parallel processing.',...
    'type', 'choice',...
    'default', '1',...
    'alternatives_basic', coreAlts);

sPanel = SettingsPanel(info,...
    'Parent', mainFigure,...
    'Position', [0 0.55 1 0.45]);

% Start button.
uicontrol(...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 0.5 0.2],...
    'String', 'Start',...
    'Tooltip', 'Start processing',...
    'Callback', @StartButton_Callback);

% Queue button.
uicontrol(...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0.5 0 0.5 0.2],...
    'String', 'Queue',...
    'Tooltip', 'Put the processing in a queue',...
    'Callback', @QueueButton_Callback);

% Text box where the user can write notes.
uicontrol(...
    'HorizontalAlignment', 'left',...
    'Style', 'text',...
    'Units', 'normalized',...
    'Position', [0 0.5 1 0.05],...
    'String', 'Notes',...
    'Tooltip', 'Notes saved in the log-files of the tracking results');
noteTextbox = uicontrol(...
    'BackgroundColor', 'white',...
    'HorizontalAlignment', 'left',...
    'Style', 'edit',...
    'Min', 0,...
    'Max', 2,...  % Multiple lines.
    'Units', 'normalized',...
    'Position', [0 0.2 1 0.3],...
    'String', '',...
    'Tooltip', 'Notes saved in the log-files of the tracking results');

    function OldTrackCallback(~,~)
        % Copies a version name from the list box to the text box.
        %
        % The suffix '_repseg' is added to the selected version name to
        % show that the results have been corrected, and to avoid
        % overwriting the existing results. The function will also enter
        % user notes from the selected version in the textbox for user
        % notes.
        
        selectedVer = sPanel.GetValue('Old_tracks');
        sPanel.SetValue('New_tracks', [selectedVer '_repseg'])
        
        % Enter user notes in the note textbox.
        note = '';
        for i = 1:length(aSeqPaths)
            if HasVersion(aSeqPaths{i}, selectedVer)
                imData = ImageData(aSeqPaths{i});
                logFile = imData.GetLogPath('Version', selectedVer);
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

    function RunReplacement()
        % Performs all segmentation replacements.
        %
        % The function retrieves settings from the user interface and
        % performs segmentation replacement for all image sequences which
        % have not yet been processed. The replacements are run either in a
        % for-loop or a parfor-loop, depending on how parallel processing
        % is used. If multiple cores are selected when there is a single
        % image sequence, the parallelization is done over the frames in
        % the segmentation step.
        
        errorFiles = {};
        errorStructs = [];
        
        % Get settings from the GUI.
        oldVersion = sPanel.GetValue('Old_tracks');
        newVersion = sPanel.GetValue('New_tracks');
        matching = sPanel.GetValue('Redo_matching');
        merging = sPanel.GetValue('Merge_fragments');
        metric = sPanel.GetValue('Matching_metric');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        notes = EditStrToFileStr(get(noteTextbox, 'String'));
        
        % Check that the entered version name is valid.
        if isempty(newVersion) || ~isvarname(['a' newVersion])
            errordlg(['The tracking version label must not be empty '...
                'and must only contain English letters, numbers, and '...
                'underscores.'], 'Invalid new tracks')
            return
        end
        
        if strcmp(metric, 'overlap')
            gate = nan;
        else
            % A matching gate of 5 pixels is used when the distance metric
            % is selected.
            gate = 5;
        end
        
        if numCores == 1 || length(aSeqPaths) == 1
            % If numCores is larger than 1 and there is a single image
            % sequence, parallelization will be done over frames in the
            % segmentation step.
            wbar = waitbar(0, sprintf(['Processing sequence 1 / %d. '...
                '(Press ctrl+c in the command window to cancel.)'],...
                length(aSeqPaths)), 'Name', 'Replacing segmentation...');
            for i = 1:length(aSeqPaths)
                try
                    if ishandle(wbar)
                        % Update the progress bar.
                        waitbar((i-1)/length(aSeqPaths), wbar,...
                            sprintf(['Processing sequence %d / %d. '...
                            '(Press ctrl+c in the command window to cancel.)'],...
                            i, length(aSeqPaths)))
                    end
                    ReplaceSequence(aSeqPaths{i},...
                        oldVersion,...
                        newVersion,...
                        gate,...
                        matching,...
                        merging,...
                        notes,...
                        'SegmentationCores', numCores)
                catch ME
                    % Allow processing of the other files to continue if an
                    % error occurs.
                    disp(getReport(ME))
                    errorFiles = [errorFiles {FileEnd(aSeqPaths{i})}]; %#ok<AGROW>
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
            StartWorkers(numCores)
            % A progress bar designed to work in parfor-loops.
            wbar_parfor = ParforProgMon(...
                ['Replacing segmentation... (Press ctrl+c in the '...
                'command window to cancel.) '],...
                length(aSeqPaths), 1, 600, 80);
            parfor i = 1:length(aSeqPaths)
                try
                    ReplaceSequence(aSeqPaths{i},...
                        oldVersion,...
                        newVersion,...
                        gate,...
                        matching,...
                        merging,...
                        notes)
                catch ME
                    % Allow processing of the other files to continue if an
                    % error occurs.
                    disp(getReport(ME))
                    errorFiles = [errorFiles {FileEnd(aSeqPaths{i})}];
                    errorStructs = [errorStructs ME];
                end
                % Update the progress bar.
                wbar_parfor.increment(); %#ok<PFBNS>
            end
            wbar_parfor.delete()
        end
        
        fprintf('Done replacing segmentations.\n')
        
        % Display all errors.
        for err = 1:length(errorFiles)
            disp('Unable to process:')
            disp(errorFiles{err})
            disp('The following error occurred:')
            disp(getReport(errorStructs(err)))
        end
        
        if ~isempty(aExitFunction)
            feval(aExitFunction)
        end
    end

    function StartButton_Callback(~, ~)
        % Callback which starts the segmentation replacement right away.
        
        RunReplacement()
    end

    function QueueButton_Callback(~, ~)
        % Callback which puts the segmentation replacement in a queue.
        
        aQueue.Add(@RunReplacement);
    end
end

function ReplaceSequence(...
    aSeqPath,...
    aOldVersion,...
    aNewVersion,...
    aGate,...
    aMatching,...
    aMerging,...
    aNotes,...
    varargin)
% Replaces the segmentation for a single image sequence.
%
% The function will not process image sequences that have been processed
% previously.
%
% Inputs:
% aSeqPath - Full path of the image sequence.
% aOldVersion - Old tracking version that gives information about linking.
% aNewVersion - New tracking version that will be created.
% aGate - The distance gate (in pixels) for matching of objects in the old
%         tracks and the new segmentation. If this is set to nan, the
%         matching will instead be performed based on region overlap.
% aMatching - If this is true, the matching will be redone using bipartite
%             matching.
% aMerging - If this is true, regions without cells will be merged into
%            adjacent regions with cells.
% aNotes - User specified notes about the processing, that will be written
%          to the log file.
%
% Property/Value inputs:
% SegmentationCores - The number of cores to use for parallel processing in
%                     the segmentation step.

% Parse property/value inputs.
aSegmentationCores = GetArgs({'SegmentationCores'}, {1}, true, varargin);

% Do not process image sequences that have been processed previously.
if HasVersion(aSeqPath, aNewVersion)
    return
end

fprintf('Replacing the segmentation for %s.\n', aSeqPath)

imData = ImageData(aSeqPath, 'version', aNewVersion);

cellsOld = LoadCells(aSeqPath, aOldVersion);

if ~isempty(cellsOld)
    % No results are saved if there are no cells in the old tracking
    % version. This should probably be changed.
    
    blobs = SegmentSequence(imData, 'NumCores', aSegmentationCores);
    cellsNew = SwitchSegmentation(imData, cellsOld, blobs,...
        'Gate', aGate,...
        'RedoMatching', aMatching,...
        'MergeWatersheds', aMerging);
    
    SaveCells(cellsNew, aSeqPath, aNewVersion)
    
    % Create a log file.
    logFile = imData.GetLogPath();
    WriteLog(logFile, 'ReplaceSegmentation', aNotes)
end
end