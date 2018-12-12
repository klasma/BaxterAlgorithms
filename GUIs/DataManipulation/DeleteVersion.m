function DeleteVersion(aSeqPath, aVersion)
% Deletes all tracking files of a particular sequence and tracking version.
%
% Inputs:
% aSequence - Full path of the sequence folder.
% aVersion - Tracking version for which files should be removed (not
%            including the CellData prefix).

imData = ImageData(aSeqPath, 'version', aVersion);
cellDataDir = imData.GetCellDataDir();
seqDir = imData.GetSeqDir();

% Delete the file with tracking results.
cellDataFile = fullfile(cellDataDir, [seqDir '.mat']);
if exist(cellDataFile, 'file')
    delete(cellDataFile)
end

% Delete the file with compact tracking results.
compactCellDataFile = fullfile(cellDataDir, 'Compact', [seqDir '.mat']);
if exist(compactCellDataFile, 'file')
    delete(compactCellDataFile)
end

% Delete results for the ISBI 2012 Particle Tracking Challenge.
xmlFile = fullfile(cellDataDir, 'xml', [seqDir '.xml']);
if exist(xmlFile, 'file')
    delete(xmlFile)
end

% Delete results for the ISBI Cell Tracking Challenges.
resFolder = fullfile(cellDataDir, 'RES', [seqDir '_RES']);
if exist(resFolder, 'dir')
    % New naming.
    rmdir(resFolder, 's')
else
    % Old naming.
    resFolder = fullfile(cellDataDir, 'RES', [seqDir(end-1:end) '_RES']);
    if exist(resFolder, 'dir')
        rmdir(resFolder, 's')
    end
end

% Delete intermediate tracking results used to resume processing.
resumeFolder = imData.GetResumePath();
if exist(resumeFolder, 'dir')
    rmdir(resumeFolder, 's')
end

% Copy or move a log file for the track linking.
trackLinkingLog = fullfile(cellDataDir, 'Tracking_log', [seqDir '.txt']);
if exist(trackLinkingLog, 'file')
    delete(trackLinkingLog)
end

% Delete intermediate Viterbi tracking results used to debug track linking.
iterationFolder = fullfile(cellDataDir, 'Iterations', seqDir);
if exist(iterationFolder, 'dir')
    rmdir(iterationFolder, 's')
end

% Delete log file with information about the program that generated the
% results. Removing this allows the tracking version to be overwritten.
logFile = fullfile(cellDataDir, 'Logs', [seqDir '.txt']);
if exist(logFile, 'file')
    delete(logFile)
end

% Delete file used for training of classifiers.
trainingFile = fullfile(cellDataDir, 'TrainingData', [seqDir '.mat']);
if exist(trainingFile, 'file')
    delete(trainingFile)
end

% Delete the settings associated with this version. The settings path is
% faked to make DeleteSettings remove the desired entry in the csv-files.
settPath = fullfile(cellDataDir, seqDir);
DeleteSettings(settPath)
end