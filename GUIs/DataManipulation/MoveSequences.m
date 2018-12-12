function MoveSequences(aSeqPaths, aExPath)
% Moves a set of image sequences to another experiment folder.
%
% All data associated with the image sequences are also moved. The function
% is just a wrapper for CopyOrMoveSequences.
%
% Inputs:
% aSeqPaths - Full path of an image sequence or a cell array of paths.
% aExPath - Path of the experiment that the sequences will be moved to.
%
% See also:
% CopySequences, CopyOrMoveSequences, DeleteSequences

CopyOrMoveSequences(aSeqPaths, aExPath, 'move')
end