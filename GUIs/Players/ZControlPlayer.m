classdef ZControlPlayer < ZPlayer
    % 3D player with a panel for controls.
    %
    % ZControlPlayer is a version of ZPlayer with a uipanel to the right in
    % the figure, where all controls of derived classes can be put. The 3D
    % panel is placed to the left of the control panel, but is only visible
    % for 3D data. The class itself has the same functionality as ZPlayer
    % and it is only intended to be a superclass of other players that
    % require uicontrols. The class also has a method ExtraCallback which
    % can be used to execute the Draw function after uicontrol callbacks.
    %
    % See also:
    % ZPlayer
    
    
    properties
        controlPanel = [];   % uipanel for all controls.
        controlWidth = 0.1;  % Width of the control panel in normalized figure units.
    end
    methods
        function this = ZControlPlayer(aSeqPaths, varargin)
            % Constructs the player object and a figure associated with it.
            %
            % Inputs:
            % aSeqPath - Cell array with all image sequences that can be
            %            played.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        at the end of the constructor. This allows derived
            %        classes to postpone the call to Draw to the end of the
            %        derived class constructor. The default is true.
            % ControlWidth - Width of the uipanel for controls, as a
            %                fraction of the figure width. The default is
            %                0.1.
            
            % Get additional inputs.
            [aDraw, aControlWidth] = GetArgs(...
                {'Draw', 'ControlWidth'}, {true, 0.1}, true, varargin);
            
            % Create the ZPlayer.
            this = this@ZPlayer(aSeqPaths, 'Draw', false);
            
            this.controlWidth = aControlWidth;
            
            % Create the empty control panel.
            this.controlPanel = uipanel(...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [1.0025-this.controlWidth, 0, this.controlWidth-0.0025, 1]);
            
            % Move the 3D panel to the left.
            set(this.volumePanel,...
                'Position',...
                [1.0025-this.controlWidth-this.volumePanelWidth,...
                0,...
                this.volumePanelWidth,...
                1])
            
            if aDraw
                this.ReSizeAxes()
                this.ReSizeControls()
                this.Draw();
            end
        end
        
        function ReSizeControls(this)
            % Changes sizes and positions of controls outside the panels.
            %
            % This function overrides the corresponding function of
            % ZPlayer.
            
            if this.GetImData().numZ > 1  % 3D data.
                % Make room for a control panel and a 3D panel.
                set(this.volumePanel, 'Visible', 'on')
                ReSizeControlsMargin(this, this.volumePanelWidth+this.controlWidth)
            else  % 2D data.
                % Make room for a control panel.
                set(this.volumePanel, 'Visible', 'off')
                ReSizeControlsMargin(this, this.controlWidth)
            end
        end
        
        
        function ReSizeAxes(this, varargin)
            % Changes the sizes of the axes objects to match the sample.
            %
            % This function overrides the corresponding function of
            % ZPlayer.
            %
            % Property/Value inputs:
            % KeepAxisLimits - If this parameter is set to true, the
            %                  dimensions of the displayed region of the
            %                  sample will be determined from the axis
            %                  limits. By default, it is assumed that the
            %                  entire sample is shown. In that case, the
            %                  dimensions of the sample are determined
            %                  from the ImageData object. The parameter
            %                  needs to be set to true to arrange the axes
            %                  properly when zooming is used together with
            %                  the 'all' layout.
            
            layout = this.volumeSettingsPanel.GetValue('display');
            if this.GetImData().numZ > 1
                this.ReSizeAxesMargin(layout,...
                    [0 this.volumePanelWidth+this.controlWidth], varargin{:})
            else
                this.ReSizeAxesMargin('xy', [0 this.controlWidth], varargin{:})
            end
        end
        
        function ExtraCallback(this, aObj, aEvent, aFun)
            % Wrapper function that executes a callback and then draws an
            % updated image.
            %
            % Inputs:
            % aObj - Object that gave rise to the callback.
            % aEvent - Event associated with the callback.
            % aFun - Callback that should be executed before the Draw
            %        function is executed.
            
            if iscell(aFun)
                feval(aFun{1}, aObj, aEvent, aFun{2:end})
            else
                feval(aFun, aObj, aEvent)
            end
            this.Draw()
        end
    end
end