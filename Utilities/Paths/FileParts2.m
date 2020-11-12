function [oExPath, oSeqDir] = FileParts2(aSeqPath)
% Splits image sequence paths into experiment paths and the sequence names.
%
% For a single image sequence, the function does the same thing as the
% built in function fileparts, with two output arguments. This function
% does however not discard characters which come after the last period in
% the sequence (folder) name, making it possible to use image sequence
% names with periods in them. In contrast to fileparts, FileParts2 is not
% affected by path separators at the end of the input.
%
% Inputs:
% aSeqPath - Full or relative path of an image sequence. The input can also
%            be a cell array of paths.
%
% Outputs:
% oExPath - Experiment path or a cell array of experiment paths.
% oSeqDir - Image sequence name of a cell array of image sequence names.
%           The image sequence name is the name of the folder containing
%           the images.
%
% See also:
% fileparts, GetNames, FileEnd, FileType

if iscell(aSeqPath)
    [oExPath, oSeqDir] = cellfun(@FileParts2, aSeqPath,...
        'UniformOutput', false);
else
    [oExPath, file, ext]= fileparts(aSeqPath);
    oSeqDir = [file ext];
    
    if isempty(oSeqDir) &&... % Handles trailing / and \.
            length(oExPath) < length(aSeqPath) % Handles aSeqPath = 'C:\' and ''.
        [oExPath, oSeqDir] = FileParts2(oExPath);
    end
end
end