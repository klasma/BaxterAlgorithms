classdef ChannelHistogram < handle
    % Control object with histogram, used to change fluorescence settings.
    %
    % ChannelHistogram is an object which draws a histogram representing
    % the distribution of pixel intensities in an image's channel, and has
    % two virtual "sliders" to adjust threshold indexes.
    %
    % A ChannelHistogram is plotted inside an axes object and draws a
    % static histogram of the channel's color representing the distribution
    % of pixel intensities in an image's channel, excluding values below
    % 0.01 and over 0.99 since the high number of values in those ranges
    % will dominate the histogram, rendering everything else negligible.
    % The current min and max thresholds are indicated by vertical lines
    % plotted on top of the histogram.
    %
    % See also:
    % ChannelGradient, SetFluorescencePlayer
    
    properties
        axes                % Axes object where the ChannelHistogram is drawn.
        minIndex = 0.01;    % Default, histogram minimum value.
        maxIndex = 0.99;    % Default, histogram maximum value.
        minSlider           % Line which is plotted to indicate the min threshold.
        maxSlider           % Line which is plotted to indicate the max threshold.
        histHeight          % The histogram's height determined by MATLAB.
        bincounts           % Number of values in each histogram bin.
        binranges = [];     % Edges of the histogram bins.
        histogram           % Bar plot of the histogram.
        color               % Color of the histogram.
    end
    
    methods
        function this = ChannelHistogram(aAxes, aImage, aColor)
            % Inputs:
            % aAxes - Axes object where the histogram is drawn.
            % aImage - Raw image from which the histogram is computed. The
            %          image should have values between 0 and 1.
            % aColor - Color of the histogram, which matches the channel.
            
            this.axes = aAxes;
            this.color = aColor;
            this.CalculateHistogram(aImage)
            this.DrawHistogram()
        end
        
        function CalculateHistogram(this, aImage)
            % Updates the histogram when the image is switched.
            %
            % Inputs:
            % aImage - New raw image with values between 0 and 1.
            
            vector = aImage(:);
            n = 99;
            this.binranges = 1/(n+1) : 1/(n+1) : n/(n+1);
            [this.bincounts] = histc(vector, this.binranges);
        end
        
        function DrawHistogram(this)
            % Draws the histogram and the sliders.
            %
            % Also finds the height of the histogram determined by MATLAB.
            
            if ishandle(this.histogram)
                delete(this.histogram)
            end
            this.histogram = bar(this.axes, this.binranges, this.bincounts);
            axis(this.axes, 'off')
            set(this.histogram, 'BarWidth', 1)
            set(this.histogram, 'FaceColor', this.color)
            set(this.histogram, 'EdgeColor', this.color)
            
            % The histHeight needs to be found so that the min/maxSlider
            % will be plotted exactly up to the histHeight so that the
            % axis limits don't change.
            y = ylim(this.axes);
            this.histHeight = y(2);
            
            this.PlotMinSlider();
            this.PlotMaxSlider();
        end
        
        function PlotMaxSlider(this)
            % Plots the line representing the max index threshold.
            
            if ishandle(this.maxSlider)
                delete(this.maxSlider)
            end
            hold(this.axes, 'on')
            this.maxSlider = plot(this.axes,...
                [this.maxIndex this.maxIndex], [0 this.histHeight], ':w',...
                'LineWidth', 2,...
                'MarkerFaceColor', [0 0 0],...
                'MarkerSize', 7,...
                'MarkerEdgeColor', [1 1 1]);
            axis(this.axes, 'off')
            hold(this.axes, 'off')
        end
        
        function PlotMinSlider(this)
            % Plots the line representing the min index threshold.
            
            if ishandle(this.minSlider)
                delete(this.minSlider)
            end
            hold(this.axes, 'on')
            this.minSlider = plot(this.axes,...
                [this.minIndex this.minIndex], [0 this.histHeight], ':w',...
                'LineWidth', 2,...
                'MarkerFaceColor', [0 0 0],...
                'MarkerSize', 7,...
                'MarkerEdgeColor', [1 1 1]);
            axis(this.axes, 'off')
            hold(this.axes, 'off')
        end
        
        function ShiftMaxSlider(this, aIndex)
            % Changes the max index threshold.
            %
            % Inputs:
            % aIndex - New max index threshold.
            
            this.maxIndex = aIndex;
            this.PlotMaxSlider()
        end
        
        function ShiftMinSlider(this, aIndex)
            % Changes the min index threshold.
            %
            % Inputs:
            % aIndex - New min index threshold.
            
            this.minIndex = aIndex;
            this.PlotMinSlider()
        end
        
        function UpdateHistogram(this, aImage)
            % Update the histogram using a new image.
            %
            % The sliders and the color of the histogram are not changed.
            %
            % Inputs:
            % aImage - New image for which a histogram should be computed
            %          and plotted.
            
            this.CalculateHistogram(aImage)
            this.DrawHistogram()
        end
    end
end