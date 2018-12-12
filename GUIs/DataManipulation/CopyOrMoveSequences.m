function CopyOrMoveSequences(aSeqPaths, aExPath, aCopyOrMove)
% Copies or moves a set of image sequences to an experiment folder.
%
% All data associated with the image sequences are also copied.
%
% Inputs:
% aSeqPaths - Full path of an image sequence or a cell array of paths.
% aExPath - Path of experiment that the sequences are copied or moved to.
% aCopyOrMove - Specifies if the sequence is copied or moved ('copy' or
%               'move').
%
% See also:
% CopySequences, MoveSequences, DeleteSequences

% Handle character array input with a single path.
if ischar(aSeqPaths)
    aSeqPaths = {aSeqPaths};
end

% Specify what function to use for moving or copying and the word to print
% in status updates.
switch aCopyOrMove
    case 'copy'
        fun = @copyfile;
        str = 'Copying';
    case 'move'
        fun = @movefile;
        str = 'Moving';
end

if ~exist(aExPath, 'dir')
    mkdir(aExPath)
end

if exist(fullfile(aExPath, 'SettingsLinks.csv'), 'file')
    error(['It is not possible to copy or move sequences to '...
        'experiments with linked settings.'])
end

wbar = waitbar(0,...
    sprintf('%s sequence %d / %d', str, 1, length(aSeqPaths)),...
    'Name', str);

for seq = 1:length(aSeqPaths)
    waitbar((seq-1)/length(aSeqPaths), wbar,...
        sprintf('%s sequence %d / %d', str, seq, length(aSeqPaths)));

    oldSeqPath = aSeqPaths{seq};  % Old path of sequence.
    seqDir = FileEnd(oldSeqPath);
    newSeqPath = fullfile(aExPath, seqDir);  % New path of sequence.
    
    % Copy or move all tracking data.
    vers = GetVersions(oldSeqPath);
    for i = 1:length(vers)
        CopyOrMoveVersion(oldSeqPath, vers{i}, aExPath, aCopyOrMove)
    end
    
    % Copy of move the image sequence.
    feval(fun, oldSeqPath, newSeqPath, 'f')
    
    % Copy the settings to the new experiment.
    CopySettings(oldSeqPath, newSeqPath)
    
    % Remove settings from old experiment if the sequence is moved.
    if strcmpi(aCopyOrMove, 'move')
        DeleteSettings(oldSeqPath)
    end
end
delete(wbar)
end