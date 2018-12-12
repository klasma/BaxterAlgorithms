function DeleteSequences(aSeqPaths)
% Deletes a set of image sequences and all data associated with them.
%
% Inputs:
% aSeqPaths - Full path of an image sequence or a cell array of paths.
%
% See also:
% DeleteVersion, CopyOrMoveSequences, CopySequences, MoveSequences

% Handle inputs with a single image sequence path.
if ischar(aSeqPaths)
    aSeqPaths = {aSeqPaths};
end

wbar = waitbar(0,...
    sprintf('Deleting sequence %d / %d', 1, length(aSeqPaths)),...
    'Name', 'Deleting');

for seq = 1:length(aSeqPaths)
    waitbar((seq-1)/length(aSeqPaths), wbar,...
        sprintf('Deleting sequence %d / %d', seq, length(aSeqPaths)));
    
    seqPath = aSeqPaths{seq};
    
    % Delete all tracking data.
    vers = GetVersions(seqPath);
    for i = 1:length(vers)
        DeleteVersion(seqPath, vers{i})
    end
    
    % Delete the image sequence.
    rmdir(seqPath, 's')
    
    % Delete the settings of the sequence.
    DeleteSettings(seqPath)
    
    % Delete microwell information.
    [exPath, seqDir] = FileParts2(seqPath);
    microwellFile = fullfile(...
        exPath,...
        'Analysis',...
        'Microwells',...
        [seqDir, '.mat']);
    if exist(microwellFile, 'file')
        delete(microwellFile)
    end
end
delete(wbar)
end