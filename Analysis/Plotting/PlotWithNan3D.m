function PlotWithNan3D(aAxes, aX, aY,aZ, varargin)
% Plots a curve and fills in gaps of NaNs with dotted lines.
%
% The built in plot function in MATLAB will create gaps in the lines in
% places where there are NaN-values. This function will instead connect the
% end-points around the gaps with dotted lines. NaNs in the beginning and
% at the end of an array are not plotted.
%
% Inputs:
% aAxes - Axes object to plot in.
% aX - Array of x-values.
% aY - Array of y-values, that may contain NaN-values.
% varargin - Extra input arguments passed to the built in function plot.

% Make the function work for both row- and column vectors.
aX = aX(:);
aY = aY(:);
aZ = aZ(:);
if isempty(aX)
    return
end

% Get the original hold-setting.
hSet = ishold(aAxes);

% Find breakpoints between NaN-values and other values. There will be 1s at
% each start of a new interval and at the first and the last element.
bp = [1; find(abs(diff(isnan(aY))))+1; length(aY)+1];

for i = 1:length(bp) - 1
    if isnan(aY(bp(i)))
        if i ~= 1 && i ~= length(bp) - 1
            % Plot a dotted line over a NaN-gap.
            start = bp(i)-1;
            stop = bp(i + 1);
            plot3(aAxes,...
                [aX(start);  aX(stop)],...
                [aY(start);  aY(stop)],...
                [aZ(start);  aZ(stop)],...
                varargin{:},...
                'LineStyle', ':')
            alpha(.1);
            hold(aAxes, 'on')
        end
    else
        % Plot a normal line.
        start = bp(i);
        stop = bp(i + 1) - 1;
        plot3(aAxes, aX(start : stop), aY(start : stop),aZ(start : stop),varargin{:})
        alpha(.1);
        grid on
        hold(aAxes, 'on')
    end
end

% Restore the original hold-setting.
if ~hSet
    hold(aAxes, 'off')
end
end