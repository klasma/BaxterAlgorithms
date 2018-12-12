function oMatrix = ReadDelimMat(aFilename, aDelimiter)
% Reads a table from a text file.
%
% ReadDelimMat reads a table from a text file where the columns are
% delimited using a special character. Normally, the function is used to
% read csv-files, where ',' is used as the delimiting character. The table
% is returned as a 2D cell array of strings. Most of the run time is
% associated with converting the text into the cell array of strings. We
% therefore store all text and cell array pairs in persistent variables so
% that we can avoid recomputing the cell array when the same file is read
% twice, and the text has not changed since the first read.
%
% Inputs:
% aFilename - Full path of to the text file (the file extension does NOT
%             have to be txt).
% Delimiter - The delimiting character used to separate the columns of the
%             table.
%
% Outputs:
% oMatrix - 2D cell array where every element contains the characters from
%           the corresponding element of the table. The character '"' is
%           assumed to be a string marker and is therefore removed.

persistent outputs    % Cell array of previously returned outputs.
persistent contents   % Strings with the contents of previously read files.
persistent filenames  % Paths of previously read files.

if ~exist(aFilename, 'file')
    error('The file %s does not exist\n', aFilename)
end

% Find the index of the file in the list of previously read files. If the
% file has not been read before, the index will be empty.
index = find(strcmp(filenames, aFilename));

% Read the entire file content.
fid = fopen(aFilename, 'r');
content = fscanf(fid, '%c', inf);

if ~isempty(index) && strcmp(content, contents{index})
    % The file content matched an earlier read of the file and we can
    % return an already computed output.
    oMatrix = outputs{index};
    fclose(fid);
else
    % Rewind the file and read it line by line, converting it into a cell
    % array of strings.
    frewind(fid)
    oMatrix = {};
    while ~feof(fid)
        tline = fgetl(fid);
        if isequal(tline, -1)
            break
        end
        line = strtrim(tline);
        line = regexp(line, aDelimiter, 'split');
        line = strrep(line, '"', '');  % Remove string markers.
        oMatrix = [oMatrix; line repmat({''}, 1, size(oMatrix,2)-length(line))]; %#ok<AGROW>
    end
    
    fclose(fid);
    
    % Store the output so that it does not have to be recomputed next time.
    if ~isempty(index)
        % The file has been read before but the contents have changed.
        outputs{index} = oMatrix;
        contents{index} = content;
    else
        % The file has not been read before.
        outputs = [outputs; {oMatrix}];
        contents = [contents; {content}];
        filenames = [filenames; {aFilename}];
    end
end
end