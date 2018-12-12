function oType = FileType(aFilename)
% Returns the filetype in a filename.
%
% The function returns all characters that follow after the last dot.
%
% Inputs:
% aFilename - String with filename or cell array of file names.
%
% Outputs:
% oType - String with file type or cella array of file types. The period
%         before the file type is not included. If there is no dot in the
%         filename, '' is returned.
%
% See also:
% FileParts2

if iscell(aFilename)
    % Apply the function to each element of the cell array.
    oType = cellfun(@FileType, aFilename, 'UniformOutput', false);
    return
end

dotPos = strfind(aFilename, '.');
if ~isempty(dotPos)
    dotPos = dotPos(end);
    oType = aFilename(dotPos+1:end);
else
    oType = '';
end
end