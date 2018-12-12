function CopyOrMoveVersion(aSeqPath, aVersion, aExPath, aCopyOrMove)
% Copies or moves a tracking result from one experiment to another.
%
% All files associated with a tracking result will be copied or moved to
% the specified experiment. This can be useful when a dataset has been
% copied and processed on many different computers, or when an image
% sequence is moved from one experiment to another.
%
% Inputs:
% aSeqPath - Full path of an image sequence for which to move results.
% aVersion - Name of the tracking version (not including the CellData
%            prefix).
% aExPath - Full path of the experiment folder to which the results should
%           be moved.
% aCopyOrMove - Specifies if the results are copied or moved ('copy' or
%               'move').

% Specify what function to use for moving or copying.
switch aCopyOrMove
    case 'copy'
        fun = @copyfile;
    case 'move'
        fun = @movefile;
end

% Source folders.
[exPath_src, seqDir] = FileParts2(aSeqPath);
cellDataDir_src = fullfile(exPath_src, 'Analysis',  ['CellData' aVersion]);

% Destination folders.
exPath_dst = aExPath;
cellDataDir_dst = fullfile(exPath_dst, 'Analysis',  ['CellData' aVersion]);

% Copy or move the file with tracking results.
cellDataFile_src = fullfile(cellDataDir_src, [seqDir '.mat']);
cellDataFile_dst = fullfile(cellDataDir_dst, [seqDir '.mat']);
if exist(cellDataFile_src, 'file')
    if ~exist(fileparts(cellDataFile_dst), 'dir')
        mkdir(fileparts(cellDataFile_dst))
    end
    feval(fun, cellDataFile_src, cellDataFile_dst, 'f')
end

% Copy or move the file with compact tracking results.
compactCellDataFile_src = fullfile(cellDataDir_src, 'Compact', [seqDir '.mat']);
compactCellDataFile_dst = fullfile(cellDataDir_dst, 'Compact', [seqDir '.mat']);
if exist(compactCellDataFile_src, 'file')
    if ~exist(fileparts(compactCellDataFile_dst), 'dir')
        mkdir(fileparts(compactCellDataFile_dst))
    end
    feval(fun, compactCellDataFile_src, compactCellDataFile_dst, 'f')
end

% Copy or move results for the ISBI 2012 Particle Tracking Challenge.
xmlFile_src = fullfile(cellDataDir_src, 'xml', [seqDir '.xml']);
xmlFile_dst = fullfile(cellDataDir_dst, 'xml', [seqDir '.xml']);
if exist(xmlFile_src, 'file')
    if ~exist(fileparts(xmlFile_dst), 'dir')
        mkdir(fileparts(xmlFile_dst))
    end
    feval(fun, xmlFile_src, xmlFile_dst, 'f')
end

% Copy or move results for the ISBI Cell Tracking Challenges.
resFolder_src = fullfile(cellDataDir_src, 'RES', [seqDir '_RES']);
resFolder_dst = fullfile(cellDataDir_dst, 'RES', [seqDir '_RES']);
if exist(resFolder_src, 'dir')  % New naming.
    if ~exist(fileparts(resFolder_dst), 'dir')
        mkdir(fileparts(resFolder_dst))
    end
    feval(fun, resFolder_src, resFolder_dst, 'f')
else  % Old naming.
    resFolder_src = fullfile(cellDataDir_src, 'RES', [seqDir(end-1:end) '_RES']);
    resFolder_dst = fullfile(cellDataDir_dst, 'RES', [seqDir(end-1:end) '_RES']);
    if exist(resFolder_src, 'dir')
        if ~exist(fileparts(resFolder_dst), 'dir')
            mkdir(fileparts(resFolder_dst))
        end
        feval(fun, resFolder_src, resFolder_dst, 'f')
    end
end

% Copy or move intermediate tracking results used to resume processing.
resumeFolder_src = fullfile(cellDataDir_src, 'Resume', seqDir);
resumeFolder_dst = fullfile(cellDataDir_dst, 'Resume', seqDir);
if exist(resumeFolder_src, 'dir')
    if ~exist(fileparts(resumeFolder_dst), 'dir')
        mkdir(fileparts(resumeFolder_dst))
    end
    feval(fun, resumeFolder_src, resumeFolder_dst, 'f')
end

% Copy or move a log file for the track linking.
trackLinkingLog_src = fullfile(cellDataDir_src, 'Tracking_log', [seqDir '.txt']);
trackLinkingLog_dst = fullfile(cellDataDir_dst, 'Tracking_log', [seqDir '.txt']);
if exist(trackLinkingLog_src, 'file')
    if ~exist(fileparts(trackLinkingLog_dst), 'dir')
        mkdir(fileparts(trackLinkingLog_dst))
    end
    feval(fun, trackLinkingLog_src, trackLinkingLog_dst, 'f')
end

% Copy or move intermediate Viterbi tracking results used for debugging.
iterationFolder_src = fullfile(cellDataDir_src, 'Iterations', seqDir);
iterationFolder_dst = fullfile(cellDataDir_dst, 'Iterations', seqDir);
if exist(iterationFolder_src, 'dir')
    if ~exist(fileparts(iterationFolder_dst), 'dir')
        mkdir(fileparts(iterationFolder_dst))
    end
    feval(fun, iterationFolder_src, iterationFolder_dst, 'f')
end

% Copy or move a log file with information about the program that generated
% the results.
logFile_src = fullfile(cellDataDir_src, 'Logs', [seqDir '.txt']);
logFile_dst = fullfile(cellDataDir_dst, 'Logs', [seqDir '.txt']);
if exist(logFile_src, 'file')
    if ~exist(fileparts(logFile_dst), 'dir')
        mkdir(fileparts(logFile_dst))
    end
    feval(fun, logFile_src, logFile_dst, 'f')
end

% Copy old NOTES.txt file (such files are no longer created).
notes_src = fullfile(cellDataDir_src, 'NOTES.txt');
notes_dst = fullfile(cellDataDir_dst, 'NOTES.txt');
if exist(notes_src, 'file')
    if ~exist(fileparts(notes_dst), 'dir')
        mkdir(fileparts(notes_dst))
    end
    if ~exist(notes_dst, 'file')  % Don't overwrite existing files.
        feval(fun, notes_src, notes_dst, 'f')
    end
end

% Copy settings. The settings paths are faked to make CopySettings copy the
% desired entries in the csv-files.
settPath_src = fullfile(cellDataDir_src, seqDir);
settPath_dst = fullfile(cellDataDir_dst, seqDir);
CopySettings(settPath_src, settPath_dst)
if strcmpi(aCopyOrMove, 'move')
    DeleteSettings(settPath_src)
end
end