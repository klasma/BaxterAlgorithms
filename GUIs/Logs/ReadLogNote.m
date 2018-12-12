function oString = ReadLogNote(aFilename)
% Reads user notes from log-files.
%
% The log files are created when an image sequence has been processed and
% may have a user specified note at the end. The string 'User notes:' marks
% there the user specified note starts. The string is always there, but it
% may not be followed by a note. The file format of log files is txt.
%
% Inputs:
% aFilename - Full path of the log-file. The function generates an error if
%             the file does not exist.
%
% Outputs:
% oString - Character array with the note. Whitespace characters are
%           removed from the beginning and the end of the string. The
%           output is an empty string if the file does not contain a note.
%
% See also:
% WriteLog

if ~exist(aFilename, 'file')
    error('The file %s does not exist.', aFilename)
end

fid = fopen(aFilename, 'r');
content = fscanf(fid, '%c', inf);
oString = regexp(content, '(?<=User notes:).*', 'match', 'once');
oString = strtrim(oString);
fclose(fid);
end