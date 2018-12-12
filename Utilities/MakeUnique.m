function oStrings = MakeUnique(aStrings)
% Appends numbers to the ends of strings to make them unique.
%
% If there are duplicated entries, all of the copies are given numbers from
% 1 to the number of copies. The numbers are appended to the ends to the
% strings. Numbers are skipped if appending them would create new
% collisions.
%
% Inputs:
% aStrings - Cell array of strings where entries may be duplicated.
%
% Outputs:
% oStrings - Cell array of strings where no entries are duplicated.

oStrings = aStrings;

% The strings need to be ordered so that longer strings are processed
% before shorter. Otherwise, blocking strings may change in subsequent
% iterations. For example, if the strings are {test test test1 test1}, the
% output would have become {test2 test3 test11 test11}, when it should be
% {test1 test2 test11 test12}. This ensures that the replacements do not
% depend on the order of the strings in the original input.
stringLengths = cellfun(@length, oStrings);
[~, order] = sort(stringLengths, 'descend');
inverseOrder(order) = 1:length(order);

% Sort the strings from longest to shortest.
oStrings = oStrings(order);

for i = 1:length(oStrings)
    % Indices of identical strings.
    collisions = find(strcmp(oStrings, oStrings{i}));
    if length(collisions) > 1
        % Number to be added at the end of the next copy.
        index = 1;
        for j = 1:length(collisions)
            % Append numbers to the strings to make them unique.
            while any(strcmp(oStrings, [oStrings{collisions(j)} num2str(index)]))
                % Skip names that would create new collisions.
                index = index + 1;
            end
            oStrings{collisions(j)} = [oStrings{collisions(j)} num2str(index)];
            index = index + 1;
        end
    end
end

% Go back to the original string ordering.
oStrings = oStrings(inverseOrder);
end