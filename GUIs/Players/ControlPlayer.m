classdef ControlPlayer < SequencePlayer
    % 2D player with a panel for controls.
    %
    % ControlPlayer is a version of SequencePlayer with a uipanel to the
    % right in the figure, where all controls of derived classes can be
    % put. The class itself has the same functionality as SequencePlayer
    % and it is only intended to be a superclass of other players that
    % require uicontrols. The class also has a method ExtraCallback which
    % can be used to execute the Draw function after uicontrol callbacks.
    %
    % See also:
    % SequencePlayer
    
    properties
        controlPanel    % uipanel for all controls.
    end
    methods
        function this = ControlPlayer(aSeqPaths, varargin)
            % Constructs the player object and a figure associated with it.
            %
            % Inputs:
            % aSeqPath - Cell array with all image sequences that can be
            %            played.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            % a the end of the constructor. This allows derived classes to
            % postpone the call to Draw to the end of the derived class
            % constructor. Default is true.
            %
            % ControlWidth - Width of the uipanel for controls, as a
            % fraction of the figure width. Default is 0.1.
            
            
            [aDraw, aControlWidth] = GetArgs(...
                {'Draw', 'ControlWidth'},...
                {true, 0.1},...
                true, varargin);
            
            this = this@SequencePlayer(aSeqPaths, 'Draw', false);
            
            % Make room for a control panel.
            set(this.ax, 'Position', [0 0.07 1-aControlWidth 0.925])
            set(this.slider, 'Position', [0.025 0.045 0.95-aControlWidth 0.015])
            set(this.playbackPanel, 'Position', [0.775-aControlWidth, 0.005, 0.2, 0.035])
            set(this.playButton, 'Position', [0.45-aControlWidth/2, 0.005, 0.1, 0.035])
            set(this.previousButton, 'Position', [0.35-aControlWidth/2, 0.005, 0.1, 0.035])
            set(this.nextButton, 'Position', [0.55-aControlWidth/2, 0.005, 0.1, 0.035])
            
            this.controlPanel = uipanel(...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [1.0025-aControlWidth, 0, aControlWidth-0.0025, 1]);
            
            if aDraw
                this.Draw();
            end
        end
        
        function ExtraCallback(this, aObj, aEvent, aFun)
            % Wrapper function that executes a callback and then draws an
            % updated image.
            %
            % Inputs:
            % aObj - Object that gave rise to the callback.
            %
            % aEvent - Event associated with the callback.
            %
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