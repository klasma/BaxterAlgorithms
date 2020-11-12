function CuttingGUI(aSeqPaths, aQueue, varargin)
% GUI to start automated cutting of round microwells.
%
% To run the GUI, he user must specify the settings minWellR and maxWellR.
%
% The user can specify an output experiment folder, and the number of
% parallel processing cores to use. Settings that have been specified for
% the image sequences will be copied to the new cut image sequences.
%
% Inputs:
% aSeqPaths - Cell array with the paths of image sequences to cut.
% aQueue - Queue object that can be used to queue the execution and start
%          it later.
%
% Property/Value inputs:
% ExitFunction - Function handle that will be executed with the selected
%                output experiment path as input, once the cutting is
%                finished. This can be used to ask users if they want to
%                switch to the cut experiment.
%
% See also:
% Stabilize, StabilizationGUI, TrackingGUI

% Parse property/value inputs.
aExitFunction = GetArgs({'ExitFunction'}, {[]}, true, varargin);

% Check that minWellR and maxWellR have been specified.
for seq = 1:length(aSeqPaths)
    imParams = ImageParameters(aSeqPaths{seq});
    if isnan(imParams.Get('minWellR')) || isnan(imParams.Get('maxWellR'))
        errordlg(['The settings minWellR and maxWellR must not be NaN '...
            'for any sequences.'], 'Processing error')
        return
    end
end

mainFigure = figure('Name', 'Microwell Cutting',...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Units', 'pixels',...
    'Position', [200 200 500 150],...
    'Resize', 'off');

exPath = FileParts2(aSeqPaths{1});
info.Output = Setting(...
    'name', 'Output',...
    'tooltip', 'Experiment folder where cut sequences will be placed.',...
    'type', 'path',...
    'default', [exPath '_Cut']);
coreAlts = arrayfun(@num2str, 1:MaxWorkers(), 'UniformOutput', false);
info.Number_of_cores = Setting(...
    'name', 'number of cores',...
    'tooltip', 'The number of processor cores used for parallel processing.',...
    'type', 'choice',...
    'default', coreAlts(end),...
    'alternatives_basic', coreAlts);

sPanel = SettingsPanel(info,...
    'Parent', mainFigure,...
    'Position', [0 0.5 1 0.5],...
    'Split', 0.3);

uicontrol(...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 0.5 0.5],...
    'String', 'Start',...
    'Tooltip', 'Start processing',...
    'Callback', @StartButton_Callback);
uicontrol(...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0.5 0 0.5 0.5],...
    'String', 'Queue',...
    'Tooltip', 'Put the processing in a queue',...
    'Callback', @QueueButton_Callback);

    function StartButton_Callback(~, ~)
        % Starts cutting of the image sequences right away.
        
        dstExPath = sPanel.GetValue('Output');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        
        RunCutting(aSeqPaths, dstExPath, numCores);
        
        if ~isempty(aExitFunction)
            feval(aExitFunction, dstExPath)
        end
    end

    function QueueButton_Callback(~, ~)
        % Puts the execution on a processing queue, to be started later.
        
        dstExPath = sPanel.GetValue('Output');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        
        aQueue.Add(@()RunCutting(aSeqPaths, dstExPath, numCores))
    end
end

function RunCutting(aSeqPaths, aDstExPath, aNumCores)
% Runs cutting on all of the image sequences.
%
% Inputs:
% aSeqPaths - Cell array with paths of image sequences to process.
% aDstExPath - Full path of the experiment where the cut image sequences
%              will be placed.
% aNumCores - The number of processor cores to use for parallel processing.

if aNumCores == 1
    wbar = waitbar(0, sprintf(['Processing sequence 1 / %d. '...
        '(Press ctrl+c in the command window to cancel.)'],...
        length(aSeqPaths)), 'Name', 'Cutting...');
    for i = 1:length(aSeqPaths)
        if ishandle(wbar)
            waitbar((i-1)/length(aSeqPaths), wbar,...
                sprintf(['Processing sequence %d / %d. '...
                '(Press ctrl+c in the command window to cancel.)'],...
                i, length(aSeqPaths)))
        end
        CutSequence(aSeqPaths{i}, aDstExPath)
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
        'Cutting... (Press ctrl+c in the command window to cancel.) ',...
        length(aSeqPaths), 1, 600, 80);
    parfor i = 1:length(aSeqPaths)
        CutSequence(aSeqPaths{i}, aDstExPath)
        wbar_parfor.increment(); %#ok<PFBNS>
    end
    wbar_parfor.delete()
end

% Copy all of the settings from the uncut sequences to the cut
% sequences. This cannot be done in the parfor-loop, as  multiple
% workers could try to access the same file at the same time.
dstDirs = GetNames(aDstExPath, '');
for i = 1:length(aSeqPaths)
    dstSeqDirs = regexp(dstDirs, [FileEnd(aSeqPaths{i}) '_w\d+$'], 'match', 'once');
    dstSeqDirs(cellfun(@isempty,dstSeqDirs)) = [];
    dstSeqPaths = strcat(aDstExPath, filesep, dstSeqDirs);
    for j = 1:length(dstSeqPaths)
        CopySettings(aSeqPaths{i}, dstSeqPaths{j})
    end
end

fprintf('Done cutting image sequences.\n')
end

function CutSequence(aSrcSeqPath, aDstExPath)
% Runs cutting on a single image sequence.
%
% Inputs:
% aSrcSeqPath - Full path of image sequence to be cut.
% aDstExPath - Full path of for the experiment of the cut image sequence to
%              be created.

[srcExPath, seqDir] = FileParts2(aSrcSeqPath);

% Look for existing cut out image sequences. If all of the sequences have
% finished saving, the function returns. If there are unfinished sequences,
% they will be removed. A setting is considered saved if it has the setting
% 'use' defined in the settings file.
dstDirs = GetNames(aDstExPath, '');
dstSeqDirs = regexp(dstDirs, [FileEnd(aSrcSeqPath) '_w\d+$'], 'match', 'once');
dstSeqDirs(cellfun(@isempty,dstSeqDirs)) = [];
dstSeqPaths = strcat(aDstExPath, filesep, dstSeqDirs);
if ~isempty(dstSeqPaths)
    numFinished = 0;  % The number of sequences that have finished saving.
    for i = 1:length(dstSeqPaths)
        if ~isnan(ReadSeqSettings(dstSeqPaths{i}, 'use'))
            numFinished = numFinished + 1;
        end
    end
    if numFinished == length(dstSeqPaths)
        % All of the image sequences have been cut properly.
        fprintf('All cut out image sequences have already been saved for %s\n',...
            aSrcSeqPath)
        return
    else
        % At least one image sequence is not finished so the processing is
        % redone.
        fprintf('Removing the partially created image sequence associated with %s\n',...
            aSrcSeqPath)
        DeleteSequences(dstSeqPaths)
    end
end

Cut(aSrcSeqPath, aDstExPath);

logFile = fullfile(aDstExPath, 'Analysis', 'CuttingLogs', [seqDir '.txt']);
WriteLog(logFile, 'CuttingGUI', 'Cutting of round microwells.')

% Transfer the stabilization log file if the sequence has been stabilized.
stabilizeLogFile = fullfile(...
    srcExPath,...
    'Analysis',...
    'StabilizationLogs',...
    [seqDir '.txt']);
stabilizeLogFileCopy = fullfile(...
    aDstExPath,...
    'Analysis',...
    'StabilizationLogs',...
    [seqDir '.txt']);
if exist(stabilizeLogFile, 'file')
    if ~exist(fileparts(stabilizeLogFileCopy), 'dir')
        mkdir(fileparts(stabilizeLogFileCopy))
    end
    copyfile(stabilizeLogFile, stabilizeLogFileCopy)
end
end