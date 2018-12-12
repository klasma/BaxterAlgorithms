function WriteDelimMat(aFilename, aMatrix, aDelimiter)
% Writes a table to a text file.
%
% WriteDelimMat writes a 2D cell array table to a text file where the table
% columns are delimited by a special character. Normally, the function is
% used to write tables of the same type as those created by ReadSettings,
% to csv-files, where ',' is used as the delimiting character.
%
% Inputs:
% aFilename - Full path of the text file that will be created (the file
%             extension does NOT have to be txt).
% aMatrix - 2D cell array representing a table of strings.
% Delimiter - The delimiting character used to separate the columns of the
%             table, when the table is written to the text file.
%
% See also:
% ReadDelimMat, ReadSettings, WriteSettings

% Open the text file where the table will be stored.
[fid, message] = fopen(aFilename, 'w');

if fid == -1
    % If the opening of the file fails, it is usually open in Excel.
    warning('Unable to write to %s, the file might be open elsewhere.', aFilename)
    fprintf(message)
    choise = questdlg(...
        sprintf('Unable to write to %s, the file might be open elsewhere.', aFilename),...
        message,...
        'Try again', 'Cancel',...
        'Try again');
    if strcmp(choise, 'Try again')  % Aborted, don't change settings
        WriteDelimMat(aFilename, aMatrix, aDelimiter)
    end
    return
end

% Construct a character array with the entire file content.
str = '';
for i = 1:size(aMatrix, 1)
    for j = 1:size(aMatrix, 2)
        str = [str aMatrix{i,j}(:)']; %#ok<AGROW>
        if j == size(aMatrix, 2)
            str = sprintf('%s\r\n', str);
        else
            str = [str aDelimiter]; %#ok<AGROW>
        end
    end
end

% '\' will be interpreted as the beginning of a special character by
% fprintf and '\\' comes through as '\'.
str = strrep(str, '\', '\\');
fprintf(fid, str);
fclose(fid);
end