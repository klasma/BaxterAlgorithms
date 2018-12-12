function StabilizationGUI(aSeqPaths, aQueue, varargin)
% GUI to start stabilization of image sequences.
%
% The user can specify an output experiment folder, which channel to use
% for stabilization in multi channel experiments, how to treat pixel values
% outside the field of view, and the number of parallel processing cores to
% use. Pixel values outside the field of view can either be reconstructed
% using extrapolation or be removed using cropping. Cropping avoids
% artifacts in the segmentation step at the cost of reducing the size for
% all images. If settings have been specified for the image sequences, the
% settings will be copied to the new stabilized image sequences.
%
% Inputs:
% aSeqPaths - Cell array with the paths of image sequences to stabilize.
% aQueue - Queue object that can be used to queue the execution and start
%          it later.
%
% Property/Value inputs:
% ExitFunction - Function handle that will be executed with the selected
%                output experiment path as input, once the stabilization is
%                finished. This can be used to ask users if they want to
%                switch to the stabilized experiment.
%
% See also:
% StabilizeLK, CropExtrapolatedPixels, CuttingGUI, TrackingGUI

% Parse property/value inputs.
aExitFunction = GetArgs({'ExitFunction'}, {[]}, true, varargin);

mainFigure = figure('Name', 'Stabilization',...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Units', 'pixels',...
    'Position', [200 200 500 150],...
    'Resize', 'off');

exPath = fileparts(aSeqPaths{1});
info.Output = Setting(...
    'name', 'Output',...
    'tooltip', 'Experiment folder where cut sequences will be placed.',...
    'type', 'path',...
    'default', [exPath '_Stabilized']);
imData  = ImageData(aSeqPaths{1});
if length(imData.channelNames) > 1
    info.Reference_channel = Setting(...
        'name', 'Reference channel',...
        'tooltip', 'Channel that should be used to compute offsets.',...
        'type', 'choice',...
        'default', imData.channelNames{1},...
        'alternatives_basic', imData.channelNames);
end
info.Missing_pixels = Setting(...
    'name', 'Missing pixels',...
    'tooltip', 'How to handle missing pixels at the image borders.',...
    'type', 'choice',...
    'default', 'crop',...
    'alternatives_basic', {'crop', 'extrapolate'});
coreAlts = arrayfun(@num2str, 1:MaxWorkers(), 'UniformOutput', false);
info.Number_of_cores = Setting(...
    'name', 'Number of cores',...
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
        % Starts stabilizing the image sequences.
        
        dstExPath = sPanel.GetValue('Output');
        if length(imData.channelNames) > 1
            referenceChannel = sPanel.GetValue('Reference_channel');
        else
            referenceChannel = imData.channelNames{1};
        end
        missingPixels = sPanel.GetValue('Missing_pixels');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        
        RunStabilization(aSeqPaths,...
            dstExPath,...
            numCores,...
            referenceChannel,...
            missingPixels);
        
        if ~isempty(aExitFunction)
            feval(aExitFunction, dstExPath)
        end
    end

    function QueueButton_Callback(~, ~)
        % Puts the execution on a processing queue, to be started later.
        
        dstExPath = sPanel.GetValue('Output');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        
        aQueue.Add(@()RunStabilization(aSeqPaths, dstExPath, numCores))
    end
end

function RunStabilization(aSeqPaths, aDstExPath, aNumCores, aChannel, aMissingPixels)
% Starts stabilization on all image sequences.
%
% Inputs:
% aSeqPaths - Cell array with full paths of image sequences to be
%             stabilized.
% aDstExPath - Full path of experiment folder where the stabilized
%              sequences will be placed.
% aNumCores - The number of parallel processing workers to use.
% aChannel - Index or name of channel that should be used for stabilization
%            of all channels in a multi channel experiment.
% aMissingPixels - If this input is 'crop', the image sequence will be
%                  cropped to remove missing pixel values at the image
%                  borders. If it is 'extrapolate', the pixel values will
%                  be reconstructed using extrapolation.

% Copy all of the settings from the un-stabilized sequences to the
% stabilized sequences. This can not be done in the parfor-loop, as
% multiple workers could try to access the same file at the same
% time.
for i = 1:length(aSeqPaths)
    if ~exist(aDstExPath, 'dir')
        mkdir(aDstExPath)
    end
    CopySettings(aSeqPaths{i}, fullfile(aDstExPath, FileEnd(aSeqPaths{i})))
end

if aNumCores  == 1
    wbar = waitbar(0, sprintf(['Processing sequence 1 / %d. '...
        '(Press ctrl+c in the command window to cancel.)'],...
        length(aSeqPaths)), 'Name', 'Stabilizing...');
    for i = 1:length(aSeqPaths)
        if ishandle(wbar)
            waitbar((i-1)/length(aSeqPaths), wbar,...
                sprintf(['Processing sequence %d / %d. '...
                '(Press ctrl+c in the command window to cancel.)'],...
                i, length(aSeqPaths)))
        end
        StabilizeSequence(aSeqPaths{i}, aDstExPath, aChannel, aMissingPixels)
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
        'Stabilizing... (Press ctrl+c in the command window to cancel.) ',...
        length(aSeqPaths), 1, 600, 80);
    parfor i = 1:length(aSeqPaths)
        StabilizeSequence(aSeqPaths{i}, aDstExPath, aChannel, aMissingPixels)
        wbar_parfor.increment(); %#ok<PFBNS>
    end
    wbar_parfor.delete()
end
fprintf('Done stabilizing image sequences.\n')
end


function StabilizeSequence(aSrcSeqPath, aDstExPath, aChannel, aMissingPixels)
% Runs image stabilization on a single image sequence.
%
% Inputs:
% aSrcSeqPath - Full path of image sequence folder to be stabilized.
% aDstExPath - Full path of the experiment folder where the stabilized
%              image sequence should be saved.
% aChannel - Index or name of channel that should be used for stabilization
%            of all channels in a multi channel experiment.
% aMissingPixels - If this input is 'crop', the image sequence will be
%                  cropped to remove missing pixel values at the image
%                  borders. If it is 'extrapolate', the pixel values will
%                  be reconstructed using extrapolation.

[srcExPath, seqDir] = FileParts2(aSrcSeqPath);
dstSeqPath = fullfile(aDstExPath, seqDir);
logFile = fullfile(...
    aDstExPath,...
    'Analysis',...
    'StabilizationLogs',...
    [seqDir '.txt']);

if exist(dstSeqPath, 'dir')
    if exist(logFile, 'file')
        % The stabilization was finished and does not need to be redone.
        return
    else
        fprintf('Removing the partially created image sequence %s\n', dstSeqPath)
        rmdir(dstSeqPath, 's')
    end
end

StabilizeLK(aSrcSeqPath, dstSeqPath, 'Channel', aChannel);

switch aMissingPixels
    case 'crop'
        CropExtrapolatedPixels(dstSeqPath)
    case 'extrapolate'
        % This has already been done in StabilizeLK.
    otherwise
        error('Unknown option ''%s'' for missing pixels.', aMissingPixels)
end

WriteLog(logFile, 'StabilizationGUI', 'Image stabilization.')

% Transfer the cutting log file if the sequence has been cut.
cutLogFile = fullfile(srcExPath, 'Analysis', 'CuttingLogs', [seqDir '.txt']);
cutLogFileCopy = fullfile(aDstExPath, 'Analysis', 'CuttingLogs', [seqDir '.txt']);
if exist(cutLogFile, 'file')
    if ~exist(fileparts(cutLogFileCopy), 'dir')
        mkdir(fileparts(cutLogFileCopy))
    end
    copyfile(cutLogFile, cutLogFileCopy)
end
end