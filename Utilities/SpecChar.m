function oString = SpecChar(aString, aInterpreter)
% Replaces special characters by their syntaxes in different interpreters.
%
% Special characters are read as commands by string interpreters. To get
% the actual character, and not the command, one has to use an interpreter
% specific syntax for the character. For example, '_' creates a subscript
% in latex, and to get an underscore in the text one uses the syntax '\_'.
%
% This function takes a string and replaces all special characters by their
% syntaxes, so that the string is read into the interpreter as text without
% any commands. The function can handle latex syntax, the syntax used in
% MATLAB titles (which seems to be a subset of latex), and sprintf.
%
% Inputs:
% aString - String that may contain special characters which are
%           interpreted as commands. The input can also be a cell array of
%           strings.
% aInterpreter - The interpreter to which the string will be passed.
%
% Outputs:
% oString - String where all special characters have been replaced by their
%           corresponding syntax in the interpreter. This makes the
%           interpreter take in the original string as plain text.

% If the input is a cell array, the function is applied to each cell.
if iscell(aString)
    oString = cellfun(@(x)SpecChar(x,aInterpreter), aString,...
        'UniformOutput', false);
    return
end

% Create a cell array where the first column has special characters and the
% second column has the corresponding syntaxes in the given interpreter.
switch aInterpreter
    case 'latex'
        specChars = {'\', '$\backslash$'
            '{', '\{'
            '}', '\}'
            '$', '\$'
            '%', '\%'
            '&', '\&'
            '_', '\_'
            '#', '\#'
            '~', '$\sim$'
            '^', '$\wedge$'
            '<', '$<$'
            '>', '$>$'};
    case 'matlab'
        specChars = {'\', '$\\$'
            '{', '\{'
            '}', '\}'
            '_', '\_'
            '^', '$\^$'};
    case 'sprintf'
        specChars = {'\', '\\'
            '''', '\'''''
            '%', '%%'};
    otherwise
        error('Unknown interpreter')
end

strings = {aString};

% Replace special characters by their syntax in the given interpreter. The
% string is broken into a cell array of fragments, where every other
% fragment is the syntax for a special character. No replacements are
% performed inside the special characters. This makes it possible to have
% special characters in the syntaxes of other special characters.
for i = 1:size(specChars, 1)
    stringsNew = {};
    % Perform replacements in each fragment separately. Every other
    % fragment is special character where nothing should be replaced.
    for j = 1 : 2 : length(strings) - mod(length(strings) + 1, 2)
        % Cut out the special characters and keep surrounding fragments.
        fragments = regexp(strings{j}, specChars{i,1}, 'split');
        % Replace the cut out special characters by the syntax for it.
        stringsNew = [stringsNew Blend(fragments, specChars{i, 2})]; %#ok<AGROW>
        if j < length(strings)
            % Append the following fragment which contains a special
            % character syntax that was inserted in an earlier iteration of
            % the outer loop.
            stringsNew = [stringsNew strings(j + 1)]; %#ok<AGROW>
        end
    end
    strings = stringsNew;
end

% Assemble the fragments into an output string.
oString = cat(2, strings{:});

    function oStrings = Blend(aStrings, aSep)
        % Puts a special character syntax in gaps between text fragments.
        %
        % Inputs:
        % aStrings - Cell array with text fragments.
        % aSep - The special character syntax that should be inserted in
        %        the gaps between the text fragments.
        %
        % Outputs:
        % oStrings - Cell array where every other cell contains one of the
        %            original text fragments and the other cells contain
        %            the specified special character syntax. The first and
        %            the last cells contain text fragments.
        
        oStrings = cell(1,2*length(aStrings)-1);
        for k = 1:length(aStrings) - 1
            oStrings(2*k-1) = aStrings(k);
            oStrings{2*k} = aSep;
        end
        oStrings(end) = aStrings(end);
    end
end