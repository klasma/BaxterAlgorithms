function CopySequences(aSeqPaths, aExPath)
% Copies a set of image sequences to an experiment folder.
%
% All data associated with the image sequences are also copied. The
% function is just a wrapper for CopyOrMoveSequences.
%
% Inputs:
% aSeqPaths - Full path of an image sequence or a cell array of paths.
% aExPath - Path of the experiment that the sequences will be copied to.
%
% See also:
% MoveSequences, CopyOrMoveSequences, DeleteSequences

CopyOrMoveSequences(aSeqPaths, aExPath, 'copy')
end