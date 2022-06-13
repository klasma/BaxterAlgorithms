function RunTracking(aSeqPaths, aVersion, aNumCores, aOverwrite, aNotes, aExitFunction)
% Starts tracking on all the image sequences.
%
% Inputs:
% aSeqPaths - Cell array with paths of image sequences to be tracked.
% aVersion - Name of the tracking version to be created.
% aNumCores - The number of processor cores to use for parallel processing.
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

% Copy all of the settings from the sequences to the
% CellData-folder with the tracking results, so that they can be
% reviewed later. This cannot be done in the parfor-loop, as
% multiple workers could try to access the same file at the same
% time.
for i = 1:length(aSeqPaths)
    [exPath, seqDir] = FileParts2(aSeqPaths{i});
    if ~exist(fullfile(exPath, 'Analysis', ['CellData' aVersion]), 'dir')
        mkdir(fullfile(exPath, 'Analysis', ['CellData' aVersion]))
    end
    logFile = fullfile(exPath, 'Analysis', ['CellData' aVersion],...
        'Logs', [seqDir '.txt']);
    if ~exist(logFile, 'file')
        % Only copy the settings if the sequence has not been tracked. If
        % it has been tracked, it is better to keep the old settings that
        % were used for tracking.
        CopySettings(aSeqPaths{i}, fullfile(exPath, 'Analysis',...
            ['CellData' aVersion], seqDir))
    end
end

errorFiles = {}; % Files where processing errors occurred.
errorStructs = []; % MATLAB structs with information about the errors.

if aNumCores == 1 || length(aSeqPaths) == 1
    % If aNumCores is larger than 1 and there is a single image sequence,
    % parallelization will be done over images in the segmentation.
    wbar = waitbar(0, sprintf(['Processing sequence 1 / %d. '...
        '(Press ctrl+c in the command window to cancel.)'],...
        length(aSeqPaths)), 'Name', 'Tracking...');
    for i = 1:length(aSeqPaths)
        try
            if ishandle(wbar)
                waitbar((i-1)/length(aSeqPaths), wbar,...
                    sprintf(['Processing sequence %d / %d. '...
                    '(Press ctrl+c in the command window to cancel.)'],...
                    i, length(aSeqPaths)))
            end
            TrackSequence(aSeqPaths{i}, aVersion, aNotes,...
                'SegmentationCores', aNumCores)
        catch ME % Allow processing of the other files to continue if an error occurs.
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
    StartWorkers(aNumCores)
    wbar_parfor = ParforProgMon(...
        'Tracking... (Press ctrl+c in the command window to cancel.) ',...
        length(aSeqPaths), 1, 600, 80);
    parfor i = 1:length(aSeqPaths)
        try
            TrackSequence(aSeqPaths{i}, aVersion, aNotes)
        catch ME % Allow processing of the other files to continue if an error occurs.
            disp(getReport(ME))
            errorFiles = [errorFiles {FileEnd(aSeqPaths{i})}];
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