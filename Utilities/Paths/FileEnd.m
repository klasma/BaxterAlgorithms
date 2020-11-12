function oFile = FileEnd(aPath)
% Takes paths to files or folders and returns only their names.
%
% Inputs:
% aPath - Complete or relative path of a file. The input can also be a cell
%         array of paths, in which case the function is applied to each
%         cell of the array separately.
%
% Outputs:
% oFile - The name of the file or folder, including the extension. If the
%         input is a cell array, the output is a cell array of file or
%         folder names.
%
% See also:
% FileParts2, FileType, GetNames

[~, oFile] = FileParts2(aPath);
end