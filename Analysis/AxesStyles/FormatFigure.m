function FormatFigure(aFig, aFmt)
% Applies a formatting function to all axes objects in a figure.
%
% Inputs:
% aFig - Figure object.
% aFmt - Function handle which takes an axes object as input and applies
%        formatting changes to the axes. The function can for example
%        change font sizes, add a grid, or change line thicknesses.
%
% See also:
% ApplyStyle

% Find all the axes in the figure.
children = get(aFig, 'children');
axVec = [];
for i = 1:length(children)
    if strcmp(get(children(i), 'Type'), 'axes')
        axVec = [axVec children(i)]; %#ok<AGROW>
    end
end

% Apply the formatting function to all axes objects.
for i = 1:length(axVec)
    feval(aFmt, axVec(i))
end
end