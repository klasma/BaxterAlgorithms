function oString = FileStrToEditStr(aString)
% Converts strings from files to strings for multi-line textboxes.
%
% The function will remove whitespace characters at the beginning and the
% end of the string.
%
% Inputs:
% oString - Character array where the lines of text are separated by
%           '\r\n', '\n', or '\r'.
%
% Outputs:
% aString - Cell array where each cell contains a line of text.
%
% See also:
% EditStrToFileStr

oString = strtrim(aString);
oString = regexp(oString, '\r\n|\n|\r', 'split');
end