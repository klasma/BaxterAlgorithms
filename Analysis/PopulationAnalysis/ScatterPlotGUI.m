function ScatterPlotGUI(aSeqPaths)
% GUI for scatter-potting of different cell parameters against each other.
%
% When the GUI is opened, the user gets to select a tracking version from a
% list dialog. The tracking version can be changed later in a dropdown
% menu. The GUI lets the user plot properties of the cells against each
% other in a 2D scatter plot. The cell properties that can be plotted are
% speed, axis ratio, size, time between division, and time of birth. There
% are two list boxes where the parameters for the x- and y-axis can be
% selected. The cells are plotted as dots. The coloring of the dots can be
% specified in a dropdown menu where the following alternatives are
% available:
%
% black - All cells are black.
% fate - Cells that died and cells that survived to the end of the image
%        sequence are colored red and blue respectively, if the
%        corresponding checkboxes are checked. Other cells are black.
% original - The cell colors for visualization of tracks and outlines are
%            used. These colors can be changed in the manual correction
%            user interface.
% generation - Different cell generations are colored differently.
% condition - The cells are colored based on the experimental condition
%             that they belong to. In this case, all cells are plotted in
%             the same axes. With all other coloring options, the cells
%             from different experimental conditions are plotted in
%             different axes, which are stacked vertically.
%
% The plots can be exported by pressing a button labeled 'Save'. This will
% open the SavePlotsGUI. SavePlotsGUI is given function handles as input,
% and the plots that are saved are generated in a temporary figure. It is
% possible to select multiple parameters for both the x- and y-axis. Plots
% where the same parameter is plotted on both axes are removed from the
% export.
%
% Inputs:
% aSeqPaths - Cell array with full paths of folders with image sequences.
%
% See also:
% PopulationAnalysisGUI, SavePlotsGUI

% Open dialog to select tracking version.
versions = GetVersions(aSeqPaths);
versions = unique([versions{:}])';
[sel,ok] = listdlg('PromptString', 'Select tracking version:',...
    'SelectionMode', 'single',...
    'ListString', versions);
if ok
    ver = versions{sel};
else
    return
end

mainFigure = figure(...
    'NumberTitle', 'off',...
    'Units', 'normalized',...
    'Position', [0.15 0.05 0.8 0.8],...
    'Name', 'Scatter plot analysis');

% Different ways to color the cell dots.
colorings = {'black', 'fate', 'original', 'condition', 'generation'};

% Load all cells. The cells will not be loaded again unless the tracking
% version is changed.
cells = LoadCells(aSeqPaths, ver, 'AreCells', true, 'Compact', true);
[pCells, pLabels] = PartitionCells(cells, 'condition');
numCond = length(pCells);

% Cell parameters that can be plotted.
parameters = {...
    'avgSpeed',...
    'avgAxisRatio',...
    'avgSize',...
    'divisionTime',...
    'lifeSpan',...
    'timeOfBirth'};

% Names displayed to the user instead of parameters.
parameterLabels = {...
    'Speed',...
    'Axis ratio',...
    'Size',...
    'Time between divisions',...
    'Life span',...
    'Time of birth'};

% Add fluorescence properties.
fluorProps = {cells.regionProps};
fluorProps = cellfun(@fieldnames, fluorProps, 'UniformOutput', false);
fluorProps = unique(cat(1,fluorProps{:}))';
fluorProps = regexp(fluorProps, '^Fluor.*', 'match', 'once');
fluorProps(cellfun(@isempty, fluorProps)) = [];
parameters = [parameters fluorProps];
parameterLabels = [parameterLabels fluorProps];

% Create a big axes for all conditions.
ax = axes('Position', [0.05 0.1 0.8 0.85]);

% Create a grid of sub-axes for the different conditions.
ax_multi = cell(1,numCond);
axHeight = (1-0.1*numCond-0.05)/numCond;
for cond = 1:numCond
    ax_multi{numCond-cond+1} = axes(...
        'Position', [0.05 axHeight*(cond-1)+0.1*cond 0.8 axHeight],...
        'Visible', 'off');
end
linkaxes([ax_multi{:}], 'xy')

% Panel with all control objects.
ControlPanel = uipanel(...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Units', 'normalized',...
    'Position', [0.9025, 0, 0.0975, 1]);

% Order of control objects. Each cell contains the controls on one row.
order = [...
    {{'versionLabel'}}
    {{'versionPopupMenu'}}
    {{'xLabel'}}
    {{'xListBox'}}
    {{'yLabel'}}
    {{'yListBox'}}
    {{'coloringLabel'}}
    {{'coloringPopupMenu'}}
    {{'deadCheckBox' 'deadLabel'}}
    {{'survivedCheckBox' 'survivedLabel'}}
    {{'saveButton'}}];

% Relative positions formatted as [left margin, top margin, width, height].
positions = struct(...
    'versionLabel',         [0.05, 0.01,  0.9,  0.02],...
    'versionPopupMenu',     [0.05, 0.01,  0.9,  0.02],...
    'xLabel',               [0.05, 0.015, 0.9,  0.02],...
    'xListBox',             [0.05, 0.01,  0.9,  0.2],...
    'yLabel',               [0.05, 0.01,  0.9,  0.02],...
    'yListBox',             [0.05, 0.01,  0.9,  0.2],...
    'coloringLabel',        [0.05, 0.01,  0.9,  0.02],...
    'coloringPopupMenu',    [0.05, 0.01,  0.9,  0.02],...
    'deadCheckBox',         [0.05, 0.02,  0.12, 0.02],...
    'deadLabel',            [0.05, 0.02,  0.75, 0.02],...
    'survivedCheckBox',     [0.05, 0.01,  0.12, 0.02],...
    'survivedLabel',        [0.05, 0.01,  0.75, 0.02],...
    'saveButton',           [0.05, 0.01,  0.9,  0.05]);

% Convert the relative positions to absolute positions.
top = 1;
for i = 1:length(order)
    field1 = order{i}{1};
    pos1 = positions.(field1);
    deltaH = pos1(2) + pos1(4);
    left = 0;
    for j = 1:length(order{i})
        field2 = order{i}{j};
        pos2 = positions.(field2);
        p1.(field2) = left + pos2(1);
        p2.(field2) = top - deltaH;
        left = left + pos2(1) + pos2(3);
    end
    top = top - deltaH;
end

% Create all control objects. The objects are positioned using
% eval-statements, and therefore they all need to be assigned to variable
% names.

versionLabel = uicontrol('Style', 'text',...
    'FontWeight', 'bold',...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Tracking Version',...
    'Units', 'normalized',...
    'Tooltip', 'Tracking version to be analyzed.'); %#ok<NASGU>
versionPopupMenu =  uicontrol(...
    'Parent', ControlPanel,...
    'BackgroundColor', 'white',...
    'HorizontalAlignment', 'left',...
    'Style', 'popupmenu',...
    'String', versions,...
    'Value', find(strcmpi(versions, ver)),...
    'Units', 'normalized',...
    'Callback', @VersionPopupMenu_Callback,...
    'Tooltip', 'Tracking version to be analyzed.');


xLabel = uicontrol('Style', 'text',...
    'FontWeight', 'bold',...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'X-axis',...
    'Units', 'normalized',...
    'Tooltip', 'Parameter to plot on the x-axis.'); %#ok<NASGU>
xListBox = uicontrol('Style', 'listbox',...
    'Min', 0,...
    'Max', 2,...
    'Parent', ControlPanel,...
    'String', parameterLabels,...
    'Value', find(strcmpi(parameterLabels, 'Time of birth')),...
    'Units', 'normalized',...
    'Callback', @(aObj, aEvent)Draw(),...
    'Tooltip', 'Parameter to plot on the x-axis.');

yLabel = uicontrol('Style', 'text',...
    'FontWeight', 'bold',...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Y-axis',...
    'Units', 'normalized',...
    'Tooltip', 'Parameter to plot on the y-axis.'); %#ok<NASGU>
yListBox = uicontrol('Style', 'listbox',...
    'Min', 0,...
    'Max', 2,...
    'Parent', ControlPanel,...
    'String', parameterLabels,...
    'Value', find(strcmpi(parameterLabels, 'Time between divisions')),...
    'Units', 'normalized',...
    'Callback', @(aObj, aEvent)Draw(),...
    'Tooltip', 'Parameter to plot on the y-axis.');

deadCheckBox = uicontrol('Style', 'checkbox',...
    'Enable', 'off',...
    'Value', 1,...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Units', 'normalized',...
    'Callback', @(aObj, aEvent)Draw(),...
    'Tooltip', 'Make dead cells red.');
deadLabel = uicontrol('Style', 'text',...
    'Enable', 'off',...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Mark Dead Cells',...
    'Units', 'normalized',...
    'Tooltip', 'Make dead cells red.');

survivedCheckBox = uicontrol('Style', 'checkbox',...
    'Enable', 'off',...
    'Value', 1,...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Units', 'normalized',...
    'Callback', @(aObj, aEvent)Draw(),...
    'Tooltip', 'Make cells in the last frame blue.');
survivedLabel = uicontrol('Style', 'text',...
    'Enable', 'off',...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Mark Survived Cells',...
    'Units', 'normalized',...
    'Tooltip', 'Make cells in the last frame blue.');

coloringLabel = uicontrol('Style', 'text',...
    'FontWeight', 'bold',...
    'Parent', ControlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'HorizontalAlignment', 'left',...
    'String', 'Coloring',...
    'Units', 'normalized',...
    'Tooltip', 'Specifies how to color the dots.'); %#ok<NASGU>
coloringPopupMenu =  uicontrol(...
    'Parent', ControlPanel,...
    'BackgroundColor', 'white',...
    'HorizontalAlignment', 'left',...
    'Style', 'popupmenu',...
    'String', colorings,...
    'Value', 1,...
    'Units', 'normalized',...
    'Callback', @Coloring_Callback,...
    'Tooltip', 'Specifies how to color the dots.');

saveButton = uicontrol(...
    'Style', 'pushbutton',...
    'String', 'Save Plots',...
    'Parent', ControlPanel,...
    'Units', 'normalized',...
    'Callback', @SaveButton_Callback,...
    'Tooltip', 'Export plots for the selected parameters to files.'); %#ok<NASGU>

% Position controls.
for i = 1:length(order)
    for j = 1:length(order{i})
        eval(['set(' order{i}{j} ,...
            ',''Position'', ['...
            num2str([p1.(order{i}{j}),...
            p2.(order{i}{j}),...
            positions.(order{i}{j})(3),...
            positions.(order{i}{j})(4)]) '])'])
    end
end

Draw()

    function Draw()
        % Updates the scatter plots based on the users selections.
        %
        % The function also prepares the axes where the plotting will be
        % done and hides all other axes.
        
        % Get user selections from the ui-controls.
        coloring = colorings{get(coloringPopupMenu, 'value')};
        xParameter = parameters{get(xListBox, 'value')};
        yParameter = parameters{get(yListBox, 'value')};
        
        if strcmpi(coloring, 'condition')
            % Prepare main axes for plotting and hide sub-axes.
            cla(ax)
            legend(ax, 'off')
            set(ax, 'Visible', 'on')
            for p = 1:numCond
                set(ax_multi{p}, 'Visible', 'off')
                cla(ax_multi{p})
                legend(ax_multi{p}, 'off')
            end
        else
            % Prepare sub-axes for plotting and hide main axes.
            cla(ax)
            legend(ax, 'off')
            set(ax, 'Visible', 'off')
            for p = 1:numCond
                set(ax_multi{p}, 'Visible', 'on')
                cla(ax_multi{p})
                legend(ax_multi{p}, 'off')
            end
        end
        
        DrawScatterPlot(xParameter, yParameter)
    end

    function DrawScatterPlot(aXParameter, aYParameter, varargin)
        % Creates scatter plots of the selected cell properties.
        %
        % By default, the function will plot all cell dots in the main
        % plotting axes (ax) if the coloring is set to 'condition', and in
        % the sub-axes for different conditions (ax_multi) if the coloring
        % is set to something else. The caller can however specify
        % alternative axes to plot in. This makes it possible to export
        % plots using SavePlotsGUI.
        %
        % Inputs:
        % aXParameter - Name of the Cell parameter to plot on the x-axis.
        % aYParameter - Name of the Cell parameter to plot on the y-axis.
        %
        % Property/Value inputs:
        % Ax - Axes object to plot in when the coloring is set to
        %      'condition'.
        % Ax_multi - Cell array of axes objects to plot in when the
        %            coloring is not set to 'condition'.
        
        
        % Parse property/value inputs.
        [aAx, aAx_multi] = GetArgs(...
            {'Ax', 'Ax_multi'}, {ax, ax_multi}, true, varargin);
        
        % Get user selections from the ui-controls.
        coloring = colorings{get(coloringPopupMenu, 'value')};
        markDead = get(deadCheckBox, 'value');
        markSurvived = get(survivedCheckBox, 'value');
        
        % Create a cell array with colors from the default color order.
        colors = get(0, 'DefaultAxesColorOrder');
        colors = mat2cell(colors, ones(size(colors,1),1), 3);
        
        % Create legends before the data is plotted. If this was not done,
        % a separate legend entry would be added for each cell when the
        % cells are plotted one by one. To add the correct markers to the
        % legend, invisible markers with the correct colors are placed in
        % the origin before the legend is created.
        switch coloring
            case 'fate'
                % Dividing cells, dead cells, and cells that survive to the
                % end of the sequence can be colored differently.
                
                % Create different legend strings depending on which cells
                % are colored differently. The same legend is used in all
                % sub-plots.
                if markDead && markSurvived
                    legendStrings = {'dividing', 'non-dividing', 'dead'};
                elseif markDead
                    legendStrings = {'dividing or non-dividing', 'dead'};
                elseif markSurvived
                    legendStrings = {'dead or dividing', 'non-dividing'};
                else
                    legendStrings = {'cells'};
                end
                
                for p = 1:numCond
                    % Cells that divide, and other types of cells if they
                    % are not given other colors.
                    plot(aAx_multi{p}, nan, nan,...
                        'Marker', 'o',...
                        'LineStyle', 'none',...
                        'MarkerEdgeColor', 'k',...
                        'MarkerFaceColor', 'k')
                    hold(aAx_multi{p}, 'on')
                    
                    % Cells that made it to the end of the image sequence.
                    if markSurvived
                        plot(aAx_multi{p}, nan, nan,...
                            'Marker', 'o',...
                            'LineStyle', 'none',...
                            'MarkerEdgeColor', 'b',...
                            'MarkerFaceColor', 'b')
                    end
                    
                    % Cells that died.
                    if markDead
                        plot(aAx_multi{p}, nan, nan,...
                            'Marker', 'o',...
                            'LineStyle', 'none',...
                            'MarkerEdgeColor', 'r',...
                            'MarkerFaceColor', 'r')
                    end
                    
                    if verLessThan('matlab', '9.2')
                        legend(aAx_multi{p}, legendStrings)
                    else
                        legend(aAx_multi{p}, legendStrings, 'AutoUpdate', 'off')
                    end
                end
            case 'generation'
                % The cell generations are color coded.
                for p = 1:numCond
                    maxGen = max([pCells{p}.generation]);
                    for g = 1:maxGen
                        plot(aAx_multi{p}, nan, nan,...
                            'Marker', 'o',...
                            'LineStyle', 'none',...
                            'MarkerEdgeColor', ModIndex(colors, g),...
                            'MarkerFaceColor', ModIndex(colors, g))
                        hold(aAx_multi{p}, 'on')
                    end
                    
                    str = arrayfun(@(x)sprintf('Generation %d',x), 1:maxGen,...
                        'UniformOutput', false);
                    if verLessThan('matlab', '9.2')
                        legend(aAx_multi{p}, str)
                    else
                        legend(aAx_multi{p}, str, 'AutoUpdate', 'off')
                    end
                end
            case 'condition'
                % The different experimental conditions are given different
                % colors. All cells are plotted in the same axes.
                for p = 1:numCond
                    plot(aAx, nan, nan,...
                        'Marker', 'o',...
                        'LineStyle', 'none',...
                        'MarkerEdgeColor', ModIndex(colors, p),...
                        'MarkerFaceColor', ModIndex(colors, p))
                    hold(aAx, 'on')
                end
                
                if verLessThan('matlab', '9.2')
                    legend(aAx, pLabels)
                else
                    legend(aAx, pLabels, 'AutoUpdate', 'off')
                end
        end
        
        % Pre-compute axis limits with a 5% margin on each side.
        
        xParam = ExtractProperty(cells, aXParameter);
        yParam = ExtractProperty(cells, aYParameter);
        
        xMin = min(xParam(~isnan(xParam)));
        xMax = max(xParam(~isnan(xParam)));
        xRange = max(xMax-xMin, eps);
        xLimits = [xMin-0.05*xRange xMax+0.05*xRange];
        
        yMin = min(yParam(~isnan(yParam)));
        yMax = max(yParam(~isnan(yParam)));
        yRange = max(yMax-yMin, eps);
        yLimits = [yMin-0.05*yRange yMax+0.05*yRange];
        
        % Plot a dot for each cell. The coordinates of the dot are given by
        % the x- and y-properties of the cell. The dot is colored using the
        % coloring option selected by the user.
        for p = 1:numCond
            xProperties = ExtractProperty(pCells{p}, aXParameter);
            yProperties = ExtractProperty(pCells{p}, aYParameter);
            for cellIndex = 1:length(pCells{p})
                c = pCells{p}(cellIndex);
                
                % Coordinates of the dot.
                x = xProperties(cellIndex);
                y = yProperties(cellIndex);
                
                % Select the color for the cell, and the axes object for
                % plotting based on the coloring option.
                switch coloring
                    case 'black'
                        % All cells are black.
                        color = 'k';
                        plotAxes = aAx_multi{p};
                    case 'fate'
                        % Cells that died and cells that survived to the
                        % end of the image sequence may be colored red and
                        % blue. Other cells are black.
                        if c.died
                            if markDead
                                color = 'r';
                            else
                                color = 'k';
                            end
                        elseif c.survived
                            if markSurvived
                                color = 'b';
                            else
                                color = 'k';
                            end
                        else
                            color = 'k';
                        end
                        plotAxes = aAx_multi{p};
                    case 'original'
                        % Use the cell colors used for trajectory plots.
                        color = c.color;
                        plotAxes = aAx_multi{p};
                    case 'generation'
                        % Use different colors for different generations.
                        color = ModIndex(colors, c.generation);
                        plotAxes = aAx_multi{p};
                    case 'condition'
                        % The different experimental conditions are given
                        % different colors. All cells are plotted in the
                        % same axes.
                        color = ModIndex(colors, p);
                        plotAxes = aAx;
                    otherwise
                        error('Unknown coloring %s', coloring)
                end
                
                % Plot the dot.
                plot(plotAxes, x, y,...
                    'Marker', 'o',...
                    'MarkerEdgeColor', color,...
                    'MarkerFaceColor', color)
                hold(plotAxes, 'on')
            end
            
            if ~isempty(xLimits)
                xlim(plotAxes, xLimits)
            end
            if ~isempty(yLimits)
                ylim(plotAxes, yLimits)
            end
            
            imData = ImageData(aSeqPaths{1});
            is3D = imData.GetDim() == 3;
            
            xlabel(plotAxes, GetLabel(aXParameter, is3D, 'Short', false))
            ylabel(plotAxes, GetLabel(aYParameter, is3D, 'Short', false))
            if ~strcmpi(coloring, 'condition')
                title(plotAxes, pLabels{p})
            end
            
            PrintStyle(plotAxes)
        end
    end

    function Coloring_Callback(~, ~)
        % Callback which updates the plot when the coloring is changed.
        %
        % The callback also makes sure that the options for coloring of
        % dead cells and cells that survived to the end of the image
        % sequence are enabled only when the coloring is set to 'fate'.
        
        coloring = colorings{get(coloringPopupMenu, 'value')};
        if strcmp(coloring, 'fate')
            set(deadCheckBox, 'Enable', 'on')
            set(deadLabel, 'Enable', 'on')
            set(survivedCheckBox, 'Enable', 'on')
            set(survivedLabel, 'Enable', 'on')
        else
            set(deadCheckBox, 'Enable', 'off')
            set(deadLabel, 'Enable', 'off')
            set(survivedCheckBox, 'Enable', 'off')
            set(survivedLabel, 'Enable', 'off')
        end
        
        Draw()
    end

    function SaveButton_Callback(~, ~)
        % Opens a GUI where plots can be exported to graphics files.
        %
        % The function is called when the user presses the Save button.
        
        % Title used for pdf-document if all plots are compiled into a pdf.
        pdfTitle = '2D scatter plots of cell parameters';
        
        % Get user selections from the ui-controls.
        coloring = colorings{get(coloringPopupMenu, 'value')};
        xParameters = parameters(get(xListBox, 'value'));
        xLabels = parameterLabels(get(xListBox, 'value'));
        yParameters = parameters(get(yListBox, 'value'));
        yLabels = parameterLabels(get(yListBox, 'value'));
        
        % The number of sub-panels (axes) in the plots to be exported.
        if strcmp(coloring, 'condition')
            numPlots = 1;
        else
            numPlots = numCond;
        end
        
        % Generate function handles, captions, and figure names for the
        % different plots.
        funcs = {};
        captions = {};
        figureNames = {};
        for xIndex = 1:length(xParameters)
            for yIndex = 1:length(yParameters)
                if strcmp(xParameters(xIndex), yParameters(yIndex))
                    % Do not plot the same parameter on both axes.
                    continue
                end
                
                % Create plotting functions that take a figure as input.
                if strcmp(coloring, 'condition')
                    axFunc = @(aAx)DrawScatterPlot(xParameters{xIndex},...
                        yParameters{yIndex}, 'Ax', aAx);
                    funcs = [funcs; {@(aFig)SingleAxFig(aFig, axFunc)}]; %#ok<AGROW>
                else
                    axFunc = @(aAx)DrawScatterPlot(xParameters{xIndex},...
                        yParameters{yIndex}, 'Ax_multi', aAx);
                    funcs = [funcs; {@(aFig)MultiAxFig(aFig, axFunc, numPlots, 1)}]; %#ok<AGROW>
                end
                
                captions = [captions
                    {sprintf('%s plotted against %s.',...
                    yLabels{yIndex}, lower(xLabels{xIndex}))}]; %#ok<AGROW>
                
                figureNames = [figureNames
                    {sprintf('%s vs %s',...
                    yLabels{yIndex}, lower(xLabels{xIndex}))}]; %#ok<AGROW>
            end
        end
        
        % Take the author string from the first image sequence.
        imData = ImageData(aSeqPaths{1});
        
        % Open a GUI where the plots can be exported.
        SavePlotsGUI('Plots', funcs,...
            'Directory', fullfile(FileParts2(aSeqPaths{1}), 'Analysis'),...
            'Title', pdfTitle,...
            'Captions', captions,...
            'FigNames', figureNames,...
            'AuthorStr', imData.Get('authorStr'),...
            'FigUnits', 'normalized',...
            'FigPosition', [0.15 0.05 0.8 0.8])
    end

    function VersionPopupMenu_Callback(~, ~)
        % Loads data and updates plots when a tracking version is selected.
        %
        % The callback also updates the list of parameters that can be
        % plotted, as that can change if fluorescence data is available in
        % one tracking version but not in another.
        
        % Load cells.
        ver = versions{get(versionPopupMenu, 'Value')};
        cells = LoadCells(aSeqPaths, ver,...
            'AreCells', true, 'Compact', true);
        [pCells, pLabels] = PartitionCells(cells, 'condition');
        numCond = length(pCells);
        
        % Cell parameters that can be plotted.
        parameters = {...
            'avgSpeed',...
            'avgAxisRatio',...
            'avgSize',...
            'divisionTime',...
            'lifeSpan',...
            'timeOfBirth'};
        
        % Names displayed to the user instead of parameters.
        parameterLabels = {...
            'Speed',...
            'Axis ratio',...
            'Size',...
            'Time between divisions',...
            'Life span',...
            'Time of birth'};
        
        % Add fluorescence properties.
        fluorProps = {cells.regionProps};
        fluorProps = cellfun(@fieldnames, fluorProps, 'UniformOutput', false);
        fluorProps = unique(cat(1,fluorProps{:}))';
        fluorProps = regexp(fluorProps, '^Fluor.*', 'match', 'once');
        fluorProps(cellfun(@isempty, fluorProps)) = [];
        parameters = [parameters fluorProps];
        parameterLabels = [parameterLabels fluorProps];
        
        % The parameters selected for the old data.
        selectedXParameter = parameters{get(xListBox, 'Value')};
        selectedYParameter = parameters{get(yListBox, 'Value')};
        
        % Try to select the same parameters in the listboxes after loading
        % new data. If the old parameters are not available for the new
        % data, the first parameter is selected.
        newXValue = find(strcmp(parameters, selectedXParameter),1);
        if isempty(newXValue)
            newXValue = 1;
        end
        newYValue = find(strcmp(parameters, selectedYParameter),1);
        if isempty(newYValue)
            newYValue = 1;
        end
        
        % Put the names of the parameters for the new data into the
        % listboxes.
        set(xListBox,...
            'String', parameterLabels,...
            'Value', newXValue)
        set(yListBox,...
            'String', parameterLabels,...
            'Value', newYValue)
        
        % Update the plot.
        Draw()
    end
end