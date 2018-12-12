function oFile = FileEnd(aPath)
% Takes paths to files and returns only the file names.
%
% Inputs:
% aPath - Complete or relative path of a file. The input can also be a cell
%         array of paths, in which case the function is applied to each
%         cell of the array separately.
%
% Outputs:
% oFile - The name of the file, including the extension. If the input is a
%         cell array, the output is a cell array of file names.
%
% See also:
% FileParts2, FileType, GetNames

if iscell(aPath)
    oFile = cellfun(@FileEnd, aPath, 'UniformOutput', false);
    return
end

[~, file, ext] = fileparts(aPath);
oFile = [file ext];
end