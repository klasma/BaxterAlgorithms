function oCellVec = CopyCellVec(aCellVec)
% Makes a deep copy of an array of Cell objects.
%
% The copying is done using the clone function in the individual Cell
% objects.
%
% Inputs:
% aCellVec - Cell object array to be copied.
%
% Outputs:
% oCellVec - Copy of aCellVec.
%
% See also:
% Cell

if isempty(aCellVec)
    oCellVec = aCellVec;
    return
end

% Clone cells.
oCellVec(length(aCellVec)) = Cell(); % Preallocate.
for i = 1:length(aCellVec)
    oCellVec(i) = aCellVec(i).Clone();
end

% Set up parent-child relationships.
for i = 1:length(aCellVec)
    children = aCellVec(i).children;
    for j = 1:length(children)
        child = oCellVec(aCellVec == children(j));
        if isempty(child)
            warning(['A child is missing in CopyCellVec. '...
                'This could cause problems in your analysis.'])
            continue
        elseif length(child) > 1
            error('A child cell is duplicated in the input to CopyCellVec.')
        end
        oCellVec(i).AddChild(child, 'GapsOk', true);
    end
end
end