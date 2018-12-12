function PlotConditionProperty(...
    aAxes,...
    aCells,...
    aProperty,...
    aIs3D,...
    aPlot,...
    aSeparateGenerations,...
    aMarkDead,...
    aMarkSurvived)
% Plots time averaged cell properties using different plotting functions.
%
% The properties to be plotted have to be properties of the Cell class.
% There function PopulationAnalysisGUI is a graphical user interface for
% this function.
%
% Inputs:
% aAxes - Cell array with axes objects. If aSeparateGernations is true,
%         there should be one axes object for each experimental condition.
%         Otherwise there should be a single axes object.
% aCells - Array with all cell objects that will be processed. The cells
%          are grouped by experimental conditions and possibly generations,
%          inside this function.
% aProperty - The name of the cell property to be plotted.
% aIs3D - True if the properties come from a 3D dataset.
% aPlot - Different plot types (plotting functions). The different
%         alternatives are described in detail below.
% aSeparateGernations - If this input is true, different cell generations
%                       are plotted in different colors, or in different
%                       locations on the x-axis (if the plot type is
%                       'scatter'). Different experimental conditions are
%                       plotted in different axes objects. If the input is
%                       false, different experimental conditions are
%                       plotted in different colors in the same axes. All
%                       cell generations are plotted in the same way.
% aMarkDead - If this input is true, cells that die during the experiment
%             are colored red in scatter plots. The input has no effect on
%             other plotting functions.
% aMarkSurvived - If this input is true, cells that are present in the last
%                 frame of the experiment are colored blue in scatter
%                 plots. The input has no effect on other plotting
%                 functions.
%
% Plot types (aPlot):
% scatter - Scatter plot where dead cells and cells present in the last
%           frame can be colored red and blue respectively.
% histogram - Histogram plotted as a line.
% kernelSmoothingDensity - Kernel smoothing density.
% sorted - Plot of all values in descending order.
% cdf - Cumulative distribution function.
% symmetry - Dot plot showing the symmetry between daughter cells. The
%            daughter with the lowest value is plotted on the x-axis and
%            the other daughter is plotted on the y-axis.
% parentVsAllChildren - Dot plot showing the connections between cells
%                       present in the first frame and their progeny. The
%                       cells in the first frame are plotted on they x-axis
%                       and the progeny are plotted on the y-axis. The dots
%                       for the progeny of one cell are connected by a
%                       line.
% parentVsChildren - Dot plot showing the connections between mother cells
%                    and their daughters. The mother cell is plotted on
%                    the x-axis and the daughter cells are plotted on the
%                    y-axis. The daughter cells are connected by a line.
% overTime - Plots the parameter against the time points when the cells
%            appear. The appearance times are binned into intervals of 1
%            hour, and average parameter values for the time intervals are
%            computed and plotted against time.
%
% See also:
% PopulationAnalysisGUI, Scatter, Sorted, CDF, Histogram, OverTime
% KernelSmoothingDensity, Symmetry, ParentVsChildren, ParentVsAllChildren

% Clear all axes before plotting.
for i = 1:length(aAxes)
    cla(aAxes{i})
    hold(aAxes{i}, 'off')
end

if aSeparateGenerations && ~strcmp(aPlot, 'tree')
    % Group the cells based both on condition and generation.
    [cellVec, labels] = PartitionCells(aCells, 'condition', 'generation');
else
    % Group the cells based only on condition.
    [cellVec, labels] = PartitionCells(aCells, 'condition');
end

% Struct which gives correspondences between aPlot and plotting functions.
plotFunctions = struct(...
    'scatter',                  @Scatter,...
    'sorted',                   @Sorted,...
    'cdf',                      @CDF,...
    'histogram',                @Histogram,...
    'kernelSmoothingDensity',   @KernelSmoothingDensity,...
    'symmetry',                 @Symmetry,...
    'parentVsChildren',         @ParentVsChildren,...
    'parentVsAllChildren',      @ParentVsAllChildren,...
    'overTime',                 @OverTime);

propertyLabel = GetLabel(aProperty, aIs3D);
plotTitle = GetTitle(aProperty, aIs3D);

if aSeparateGenerations
    % Different cell generations are plotted in different colors, or in
    % different locations on the x-axis (if the plot type is scatter).
    % Different experimental conditions are plotted in different axes
    % objects.
    
    % Minimum and maximum axis limits.
    xMin = inf;
    xMax = -inf;
    yMin = inf;
    yMax = -inf;
    
    for i = 1:length(cellVec)
        if strcmp(aPlot, 'symmetry')
            % In the function Symmetry, properties of the daughters of the
            % input cells are plotted. Therefore, the generation labels
            % need to be incremented by 1, and there is no reason to
            % process the last generation, as those cell have no daughters.
            feval(plotFunctions.(aPlot),...
                aAxes{i},...
                cellVec{i}(1:end-1),...
                labels{2,i}(2:end),...
                aProperty,...
                plotTitle,...
                propertyLabel,...
                aMarkDead,...
                aMarkSurvived)
        else
            feval(plotFunctions.(aPlot),...
                aAxes{i},...
                cellVec{i},...
                labels{2,i},...
                aProperty,...
                plotTitle,...
                propertyLabel,...
                aMarkDead,...
                aMarkSurvived)
        end
        
        % Update minimum and maximum axis limits.
        xlim = get(aAxes{i}, 'xlim');
        ylim = get(aAxes{i}, 'ylim');
        xMin = min([xMin xlim]);
        xMax = max([xMax xlim]);
        yMin = min([yMin ylim]);
        yMax = max([yMax ylim]);
    end
    
    for i = 1:length(cellVec)
        % Use the minimum and maximum axis limits on all axes.
        set(aAxes{i}, 'xlim', [xMin xMax])
        set(aAxes{i}, 'ylim', [yMin yMax])
        
        title(aAxes{i}, labels{1,i})
        
        if strcmp(aPlot, 'scatter')
            xlabel(aAxes{i}, 'Generation')
        end
        
        PrintStyle(aAxes{i})
    end
else
    % Different experimental conditions are plotted in different colors in
    % the same axes. All cell generations are plotted in the same way.
    
    feval(plotFunctions.(aPlot),...
        aAxes{1},...
        cellVec,...
        labels,...
        aProperty,...
        plotTitle,...
        propertyLabel,...
        aMarkDead,...
        aMarkSurvived)
    PrintStyle(aAxes{1})
end
end