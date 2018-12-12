function PlotFilled(aX, aY, aC, varargin)
% Plots curves and colors the regions between them in different colors.
%
% The first curve should be nonnegative and the curves should not
% intersect. The second curve should be above the first curve, the third
% curve should be above the second curve, and so forth. The regions between
% the curves are colored in different colors. The region between the x-axis
% and the first curve is colored in the first color.
%
% Inputs:
% aX - Row vector of x-values.
% aY - Matrix with the same number of columns as aX, and one row for each
%      curve. The first row is the curve plotted at the bottom.
% aC - Cell array with letters or RGB-triplets defining colors.
%
% Property/Value inputs:
% Parent - Axes object to plot in. The default is to plot in the axes
%          returned by gca.

aAxes = GetArgs({'Parent'}, {gca}, true, varargin);

% Add the x-axis as a dummy curve so that the region between the x-axis and
% the bottom curve is colored in the first color.
aY = [zeros(1,size(aY,2)); aY];

% Get the original hold-setting.
hSet = ishold(aAxes);

for i = 1:size(aY,1)-1
    if all(aY(i+1,:) == aY(i,:))
        % The region has no height.
        continue
    end
    
    % Create a polygon between the previous and the current curves.
    x = [aX fliplr(aX)];
    y = [aY(i+1,:) fliplr(aY(i,:))];
    
    fill(x, y, aC{i}, 'LineWidth', 0.5, 'Parent', aAxes)
    hold(aAxes, 'on')
end

% Restore the original hold-setting.
if ~hSet
    hold(aAxes, 'off')
end
end