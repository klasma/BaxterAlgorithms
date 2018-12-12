function oString = EditStrToFileStr(aString)
% Converts strings from multi-line textboxes to strings to save in files.
%
% The function will remove whitespace characters at the beginning and the
% end of the string.
%
% Inputs:
% aString - A cell array or a matrix of characters containing the text. If
%           the input is a cell array, each cell should contain a line of
%           text. If the input is a matrix of characters, each row contains
%           a line of text which may be padded with whitespaces at the end.
%           I have seen both output formats from multi-line textboxes and I
%           do not know when each format is used.
%
% Outputs:
% oString - Character array where the lines of text have been concatenated
%           into a single string. The lines are separated by '\r\n'.
%
% See also:
% FileStrToEditStr

if iscell(aString)
    oString = strtrim(aString{1});
    for i = 2:length(aString)
        oString = sprintf('%s\r\n%s', oString, strtrim(aString{i}));
    end
else
    if isempty(aString)
        oString = aString;
    else
        oString = strtrim(aString(1,:));
        for i = 2:size(aString,1)
            oString = sprintf('%s\r\n%s', oString, strtrim(aString(i,:)));
        end
    end
end
end