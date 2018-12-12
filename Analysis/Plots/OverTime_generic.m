function OverTime_generic(aCells, aFigure, aProperty)
% Plots average cell properties over time.
%
% The function can plot average speed, size, and axis ratio as a function
% of time. The property values are averaged over all cells in each frame.
% The cells may come from different image sequences. A different curve is
% plotted for each experimental condition. The cell speed is computed using
% a forward difference on the cell coordinates, and therefore there is no
% estimate for the last time point. No smoothing or averaging is done over
% different time points. The function PrintStyle is called to make the
% plotting style consistent with other plots.
%
% Inputs:
% aCells - Array of Cell objects.
% aFigure - Figure to plot in.
% aProperty - The cell property to plot ('speed', 'size', or 'axisratio').
%
% See also:
% PlotGUI, PrintStyle

ax = axes('Parent', aFigure);

if isempty(aCells)
    return
end
imData = aCells(1).imageData;

[pCellVec, pLabels] = PartitionCells(aCells, 'condition');

[numFrames, t] = TimeSpan(aCells);

% Sum the property values of all cells in each frame.
propHist = cell(length(pCellVec),1);  % Summed property values in the frames.
counts = cell(length(pCellVec),1);  % Number of cells in the frames.
for i = 1:length(pCellVec)
    propHist{i} = zeros(numFrames,1);
    counts{i} = zeros(numFrames,1);
    for j = 1:length(pCellVec{i})
        c = pCellVec{i}(j);
        ff = c.firstFrame;
        lf = c.lastFrame;
        
        switch lower(aProperty)
            case 'speed'
                cx = c.cx;
                cy = c.cy;
                d = sqrt(diff(cx).^2 + diff(cy).^2);
                prop = imData.PixelToMicroM(d) / (imData.FramesToHours(1));
                % There is no speed estimate for the last time point.
                lf = lf-1;
            case 'size'
                regionProps = [c.regionProps];
                if imData.GetDim() == 2
                    prop = imData.Pixel2ToMicroM2([regionProps.Area]);
                else
                    prop = imData.VoxelToMicroM3([regionProps.Volume]);
                end
            case 'axisratio'
                regionProps = [c.regionProps];
                prop = [regionProps.MajorAxisLength] ./...
                    [regionProps.MinorAxisLength];
            otherwise
                error(['Unknown cell property %s. The cell property '...
                    'has to be ''speed'', ''size'', or ''axisratio''.'],...
                    aProperty)
        end
        
        % The size and axis ratio of a point blob is NaN. The NaN-values
        % should not be included in the analysis.
        prop = prop(:);
        nans = isnan(prop);
        prop(nans) = 0;
        propHist{i}(ff:lf) = propHist{i}(ff:lf) + prop(:);
        counts{i}(ff:lf) = counts{i}(ff:lf) + ~nans;
    end
end

% Compute the mean property value in each frame by dividing the summed
% property values with the number of cells in the frame.
propHistNorm = cell(size(propHist));
for i = 1:length(pCellVec)
    propHistNorm{i} = propHist{i}./counts{i};
end

% Plot the average property value over time.
for i = 1:length(pCellVec)
    plot(ax, t, propHistNorm{i})
    hold(ax, 'all')
end

% Adjust axis limits.
SetYLimits(ax)
xlim(ax, [t(1) t(end)])

% Create axis labels.
xlabel(ax, 'Time (hours)')
switch lower(aProperty)
    case 'speed'
        ylabel(ax, 'Cell speed (\mum/hr)')
    case 'size'
        if imData.GetDim() == 3
            ylabel(ax, 'Cell size (\mum^3)')
        else
            ylabel(ax, 'Cell size (\mum^2)')
        end
    case 'axisratio'
        ylabel(ax, 'Ratio')
end

% Create a legend.
legendStrings = cell(length(pLabels),1);
for i = 1:length(pLabels)
    legendStrings{i} = sprintf('%s', pLabels{1,i});
end
legend(ax, legendStrings, 'Location', 'Northwest')

PrintStyle(ax)
end