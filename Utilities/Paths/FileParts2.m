function [oExPath, oSeqDir] = FileParts2(aSeqPath)
% Splits image sequence paths into experiment paths and the sequence names.
%
% For a single image sequence, the function does the same thing as the
% built in function fileparts, with two output arguments. This function
% does however not discard characters which come after the last period in
% the sequence (folder) name, making it possible to use image sequence
% names with periods in them.
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
    n = length(aSeqPath);
    oExPath = cell(n, 1);
    oSeqDir = cell(n, 1);
    for i = 1:n
        oExPath{i} = fileparts(aSeqPath{i});
        oSeqDir{i} = aSeqPath{i}(length(oExPath{i})+2:end);
    end
else
    oExPath = fileparts(aSeqPath);
    oSeqDir = aSeqPath(length(oExPath)+2:end);
end
end