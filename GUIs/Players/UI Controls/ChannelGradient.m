classdef ChannelGradient < handle
    % Axes with a color gradient and sliders to change fluorescence limits.
    %
    % ChannelGradient is an object which resembles a dynamically changing
    % gradient that has two virtual "sliders" to adjust threshold indexes.
    % A ChannelGradient is plotted inside an axes object and forms a
    % gradient from black to a specified color from left to right. The
    % gradient "shifts" as a visual representation of shifting the channel
    % min or max threshold. This is accomplished by drawing a solid black
    % color until the min index, then beginning the actual gradient up to
    % the max index, followed by the solid specified channel color. The
    % thresholds are indicated by vertical lines plotted on top of the
    % gradient.
    %
    % See also:
    % ChannelHistogram, SetFluorescencePlayer
    
    properties
        axes                    % Axes object where the gradient is drawn.
        startColor = [0 0 0]    % Default, no fluorescence is black.
        endColor                % Channel color.
        minIndex = 1;           % Default, gradient begins on the very left.
        maxIndex = 100;         % Default, gradient ends at the very right.
        minSlider               % Line which is plotted to indicate the min threshold.
        maxSlider               % Line which is plotted to indicate the max threshold.
    end
    
    methods
        function this = ChannelGradient(aAxes, aColor)
            % Inputs:
            % aAxes - Axes object where the ChannelGradient is drawn.
            % aColor - Second color of the gradient (color on the right).
            
            this.axes = aAxes;
            this.endColor = aColor;
            this.DrawGradient()
        end
        
        function ShiftStartGradient(this, aIndex)
            % Shifts when the actual gradient begins drawing on the axes.
            %
            % Inputs:
            % aIndex - Refers to the minIndex of the ChannelGradient.
            
            % ShiftStartGradient may be called with an aIndex input of 0
            % since that is a valid channel min threshold value, however
            % the ChannelGradient begins drawing on value 1.
            this.minIndex = max(aIndex,1);
            this.DrawGradient();
        end
        
        function ShiftEndGradient(this, aIndex)
            % Shifts when the actual gradient stops drawing on the axes.
            %
            % Inputs:
            % aIndex - Refers to the maxIndex of the ChannelGradient.
            
            this.maxIndex = aIndex;
            this.DrawGradient();
        end
        
        function PlotMinSlider(this, aIndex)
            % Plots the line representing the min index threshold.
            %
            % This is where the gradient begins.
            %
            % Inputs:
            % aIndex - Refers to the minIndex of the ChannelGradient
            
            % Remove the slider line so that it can be redrawn.
            if ishandle(this.minSlider)
                delete(this.minSlider)
            end
            
            this.minSlider = plot(this.axes,...
                [aIndex aIndex], [3 1E2], ':vw',...
                'LineWidth', 2,...
                'MarkerFaceColor', [0 0 0],...
                'MarkerSize', 7,...
                'MarkerEdgeColor', [1 1 1]);
        end
        
        function PlotMaxSlider(this, aIndex)
            % Plots the line representing the max index threshold.
            %
            % This is were the the gradient ends.
            %
            % Inputs:
            % aIndex - Refers to the maxIndex of the ChannelGradient
            
            % Remove the slider line so that it can be redrawn.
            if ishandle(this.maxSlider)
                delete(this.maxSlider)
                this.maxSlider = [];
            end
            
            this.maxSlider = plot(this.axes,...
                [aIndex aIndex], [3 1E2], ':vw',...
                'LineWidth', 2,...
                'MarkerFaceColor', [0 0 0],...
                'MarkerSize', 7,...
                'MarkerEdgeColor', [1 1 1]);
        end
        
        function DrawGradient(this)
            % Creates a gradient between two colors with up to 100 shades.
            %
            % The gradient is created by generating an image with 100
            % columns of different color shades between two specified
            % colors. The gradient does not necessarily have to stretch the
            % entire span of the image, i.e., the actual gradient part may
            % not start until the middle of the image. This serves the
            % purpose of visually shifting where the min/max of the channel
            % signal is.
            
            hold(this.axes, 'off')
            
            startIndex = ceil(this.minIndex);
            stopIndex = ceil(this.maxIndex);
            
            r = zeros(40, 100);
            g = zeros(40, 100);
            b = zeros(40, 100);
            
            % Set color increments for each RGB component in the gradient.
            dR = (this.endColor(1)-this.startColor(1))/(stopIndex-startIndex);
            dG = (this.endColor(2)-this.startColor(2))/(stopIndex-startIndex);
            dB = (this.endColor(3)-this.startColor(3))/(stopIndex-startIndex);
            
            % Draw startColor until the start index.
            for i = 1 : startIndex
                r(:, i) = this.startColor(1);
                g(:, i) = this.startColor(2);
                b(:, i) = this.startColor(3);
            end
            
            % Draw the gradient by using the set increments.
            for i = startIndex : stopIndex
                r(:, i) = this.startColor(1) + dR*(i-startIndex);
                g(:, i) = this.startColor(2) + dG*(i-startIndex);
                b(:, i) = this.startColor(3) + dB*(i-startIndex);
            end
            
            % Draw endColor until the end.
            for i = stopIndex : 100
                r(:, i) = this.endColor(1);
                g(:, i) = this.endColor(2);
                b(:, i) = this.endColor(3);
            end
            
            % Create and draw image.
            imshow(cat(3, r, g, b), 'Parent', this.axes)
            
            % Plot sliders.
            hold(this.axes, 'on')
            this.PlotMinSlider(this.minIndex)
            this.PlotMaxSlider(this.maxIndex)
            hold(this.axes, 'off')
        end
    end
end