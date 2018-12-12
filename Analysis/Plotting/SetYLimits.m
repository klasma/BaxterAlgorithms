function SetYLimits(aAxes, varargin)
% Sets y-limits to go from 0 and the maximum plotted value plus a margin.
%
% The function goes through all graphics components that have been drawn in
% an axes, to determine the maximum value. If the maximum value is
% positive, the upper limit of the axes is set to the maximum value plus a
% margin. If the maximum value is 0 or negative, the upper limit is set to
% 1. The lower limit is set to 0.
%
% Inputs:
% aAxes - Axes object to adjust the limits of.
%
% Property/Value inputs:
% Margin - Margin above the maximum value, as a fraction of the maximum
%          value. The default value is 0.1, meaning that the axis limits
%          will be between 0 and 10% over the maximum value.

% Parse property/value inputs.
aMargin = GetArgs({'Margin'}, {0.1}, true, varargin);

% Go through all plotted values to find the maximum value.
ch = get(aAxes, 'children');
maxY = -inf;
for i = 1:length(ch)
    if isprop(ch(i), 'Ydata')
        yData = get(ch(i), 'Ydata');
        yData(isnan(yData)) = [];
        maxY = max([maxY yData]);
    end
end

if maxY > 0
    ylim(aAxes, [0 maxY*(1+aMargin)])
else
    ylim(aAxes, [0 1])
end
end