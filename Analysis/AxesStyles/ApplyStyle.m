function ApplyStyle(...
    aAx,...
    aAxFuns,...
    aAxProps,...
    aTitleProps,...
    aLabelProps,...
    aLineProps,...
    aLegendProps,...
    aLegendPatchProps)
% Applies a plotting style to an axes after a plot has been created.
%
% This is a generic function which is used to change the plotting style in
% a plot. All inputs which end with 'Props' are cell arrays with
% property/value input arguments to set functions of different graphics
% objects.
%
% Inputs:
% aAx - Axes object with an existing plot.
% aAxFuns - Cell array with function handles that should be executed with
%           the axes object as input.
% aAxProps - Inputs for the set function of the axes object.
% aTitleProps - Inputs for the set function of the title.
% aLabelProps - Inputs for the set functions of the x-, y-, and z-labels.
% aLineProps - Inputs for the set functions of plotted lines.
% aLegendProps - Inputs for the set function of the legend.
% aLegendPatchProps - Inputs for the set functions of patches (colored
%                     rectangles) in the legend.
%
% See also:
% FormatFigure, NoStyle, ScreenStyle, PrintStyle, PublicationStyle

% Execute functions with the axes object as input.
for i = 1:size(aAxFuns,1)
    feval(aAxFuns{i}, aAx)
end

% Change axes properties.
if ~isempty(aAxProps)
    set(aAx, aAxProps{:})
end

% Change title properties.
if ~isempty(aTitleProps)
    title = get(aAx, 'title');
    if ~isempty(title)
        set(title, aTitleProps{:})
    end
end

% Change properties of the x-, y-, and z-labels.
if ~isempty(aLabelProps)
    xLabel = get(aAx, 'xLabel');
    if ~isempty(xLabel)
        set(xLabel, aLabelProps{:})
    end
    yLabel = get(aAx, 'yLabel');
    if ~isempty(yLabel)
        set(yLabel, aLabelProps{:})
    end
    zLabel = get(aAx, 'zLabel');
    if ~isempty(zLabel)
        set(zLabel, aLabelProps{:})
    end
end

% Change properties of line objects in the plot.
if ~isempty(aLineProps)
    lines = findobj(aAx, 'Type','line');
    if ~isempty(lines)
        set(lines, aLineProps{:})
    end
end

% Change legend properties.
if isprop(aAx, 'legend')
    % Syntax in 2018b.
    leg = get(aAx, 'legend');
else
    % Syntax in 2015b. Creates a legend in 2018b.
    leg = legend(aAx);
end
if ~isempty(leg)
    if ~isempty(aLegendProps)
        set(leg, aLegendProps{:})
    end
    if ~isempty(aLegendPatchProps)
        patches = findobj(leg, 'Type','patch');
        if ~isempty(patches)
            set(patches, aLegendPatchProps{:})
        end
    end
end
end