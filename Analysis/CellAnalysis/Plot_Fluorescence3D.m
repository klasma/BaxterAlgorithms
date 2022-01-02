function Plot_Fluorescence(aCells, aAxes, aChannel,aChannel2,Color, varargin)
% Plots the fluorescence intensity of cells over time.
%
% The function can be used to plot the maximum intensity, the average
% intensity or the integrated intensity. The function only works for cells
% that come from the same image sequence. The function can only be used on
% tracking results where there is a fluorescent channel. The function is
% meant to be called by CellAnalysisPlayer. The function will only show up
% in the CellAnalysisPlayer GUI if the dataset has one or more
% fluorescence channels. The function PrintStyle is called to make the
% plotting style consistent with other plots.
%
% Inputs:
% aCells - Cells for which the fluorescence will be plotted.
% aAxes - Axes object to plot the data in.
% aChannel - The name of the fluorescence channel to be plotted.
%
% Property/Value inputs:
% XUnit - The time unit used on the x-axis. The options are 'frames' and
%         'hours', and the default is 'hours'.
% YUnit - The length unit used to compute the integrated intensity. The
%         options are 'pixels' and 'microns'. For 2D datasets, the
%         resulting units on the y-axis are intensity * pixels and
%         intensity * square microns respectively. For 3D datasets, the
%         units are intensity * voxels or intensity * cubic microns. The
%         default is 'microns'. Note that this input has an effect only if
%         Metric is 'tot'.
% Metric - What parameter of the fluorescence to plot. The options are
%          'max', 'avg', and 'tot', and they correspond to the maximum,
%          average, and the integrated fluorescence over the cell area. The
%          default is 'max'.
%
% See also:
% CellAnalysisPlayer, Plot_AxisRatio, Plot_CellSize, Plot_LinageTree,
% Plot_TotalDistance, PrintStyle

% Get property/value inputs.
[aXUnit, aYUnit, aMetric] = GetArgs(...
    {'XUnit', 'YUnit', 'Metric'},...
    {'hours', 'microns', 'max'},...
    true, varargin);

% Clear the previous plot.
% cla(aAxes)
% hold(aAxes, 'off')

if isempty(aCells)
    return
end
imData = aCells(1).imageData;

for i = 1:length(aCells)
    c = aCells(i);
    
    % Time (x-coordinates of plot).
    switch aXUnit
        case 'hours'
            t = imData.FrameToT(c.firstFrame : c.lastFrame);
        case 'frames'
            t = c.firstFrame : c.lastFrame;
    end
    
    % Fluorescence (y-coordinates of plot).
    switch lower(aMetric)
        case 'max'
            fluor = c.regionProps.(['FluorMax' aChannel]);
        case 'avg'
            fluor = c.regionProps.(['FluorAvg' aChannel]);
        case 'test'
            fluor = c.regionProps.(['FluorAvg' aChannel]);    
        case 'tot'
            fluor = c.regionProps.(['FluorTot' aChannel]);
            if strcmpi(aYUnit, 'microns')
                if imData.GetDim() == 2
                    fluor = imData.Pixel2ToMicroM2(fluor);
                else
                    fluor = imData.VoxelToMicroM3(fluor);
                end
            end
    end
    % Fluorescence (z-coordinates of plot).
    switch lower(aMetric)
        case 'max'
            fluor2 = c.regionProps.(['FluorMax' aChannel2]);
        case 'avg'
            fluor2 = c.regionProps.(['FluorAvg' aChannel2]);
        case 'test'
            fluor2 = c.regionProps.(['FluorAvg' aChannel2]);    
        case 'tot'
            fluor2 = c.regionProps.(['FluorTot' aChannel2]);
            if strcmpi(aYUnit, 'microns')
                if imData.GetDim() == 2
                    fluor2 = imData.Pixel2ToMicroM2(fluor2);
                else
                    fluor2 = imData.VoxelToMicroM3(fluor2);
                end
            end
    end
    % Plot the fluorescence over time for one cell.
    PlotWithNan3D(aAxes, t, fluor,fluor2,'color',Color,...
        'LineWidth', 2);
%     alpha(.5);
    hold(aAxes, 'on')
%     testing=Color;
end

% Set the limits of the plot.
SetYLimits(aAxes)
xlim(aAxes, imData.GetTLim(aXUnit, 'Margins', [0.01 0.01]))

% x-label.
switch lower(aXUnit)
    case 'frames'
        xlabel(aAxes, 'Time (frames)')
    case 'hours'
        xlabel(aAxes, 'Time (hours)')
end

% y-label and title.
switch lower(aMetric)
    case 'max'
        title(aAxes, sprintf('Maximum fluorescence (%s)',...
            SpecChar(imData.GetSeqDir(), 'matlab')))
        ylabel(aAxes, 'Fluorescence (relative to max)')
    case 'avg'
        title(aAxes, sprintf('Average fluorescence (%s)',...
            SpecChar(imData.GetSeqDir(), 'matlab')))
        ylabel(aAxes, 'Fluorescence (relative to max)')
    case 'tot'
        title(aAxes, sprintf('Integrated fluorescence (%s)',...
            SpecChar(imData.GetSeqDir(), 'matlab')))
        if imData.GetDim() == 2
            switch aYUnit
                case 'pixels'
                    ylabel(aAxes, 'Fluorescence (relative to max) * Area in pixels')
                case 'microns'
                    ylabel(aAxes, 'Fluorescence (relative to max) * Area in \mum^2')
            end
        else
            switch aYUnit
                case 'pixels'
                    ylabel(aAxes, 'Fluorescence (relative to max) * Volume in voxels')
                case 'microns'
                    ylabel(aAxes, 'Fluorescence (relative to max) * Volume in \mum^3')
            end
        end
end

PrintStyle(aAxes)
end