function varargout = GetArgs(aPropNames, aDefaults, aStrict, aArgs)
% Parses property/value pairs and returns the values in a specified order.
%
% Properties that are not specified get default values assigned to them.
% The input parameter aArgs is usually passed to GetArgs from another
% function that takes property value pairs in its varargin input parameter.
% As an example, a function that can take the parameters 'Gate' and
% 'Approximate', can use the function call
%
% [aGate, aApproximate] =...
% GetArgs({'Gate', 'Approximate'}, {5, true}, true, varargin);
%
% to extract the properties into the variables aGate and aApproximate. If
% the parameters are not given, the variables are set to 5 and true
% respectively. The property names are not cases sensitive.
%
% Inptus:
% aPropNames - Cell array with names of the allowed properties.
% aDefaults - Cell array with default values.
% aStrict - If this is set to true, the function generates an error when
%           aArgs contains properties that are not in aPropNames.
%           Otherwise, such properties are ignored.
% aArgs - Cell array with property value pairs. The first cell is the name
%         of the first property, the second cell is the value of the first
%         property, the third cell is the name of the second property, and
%         so forth.
%
% Outputs:
% varargout - Individual output arguments with the values of all
%             properties.
%
% See also:
% SelectArgs

nargs = length(aArgs);

% Start with the defaults and overwrite the ones that are found in aArgs.
varargout = aDefaults;

if mod(nargs,2) ~= 0
    error('GetArgs can only take Property/Value pairs.')
else
    % Process property/value pairs.
    for j = 1 : 2 : nargs
        pname = aArgs{j};
        
        if ~ischar(pname)
            error('Properties have to be character arrays.')
        end
        
        i = find(strcmpi(pname, aPropNames));  % Index in aPropNames.
        if isempty(i)
            if aStrict
                error('The property ''%s'' is not a specified property name.', pname)
            end
        elseif length(i) > 1
            error('Ambiguous parameter name:  %s.', pname);
        else
            varargout{i} = aArgs{j+1};
        end
    end
end