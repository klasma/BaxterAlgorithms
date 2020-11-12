classdef CellAnalysisPlayer < ControlPlayer
    % Player used to plot parameters of individual cells over time.
    %
    % The player lets the user plot different parameters of the cells, such
    % as the area and axis ratio over time. Each plot can either include
    % all cells in an image sequence or the cells from a single clone. The
    % user can switch to a different cell or image using the Previous/Next
    % buttons or the image sequence dropdown menu. It is also possible to
    % switch to other image sequences or cells using the slider or using
    % the play button. It is not possible to play temporal information.
    % Instead the player switches between different plots at the requested
    % frame rate, or slower if the plotting takes too long.
    
    properties
        cellVec         % Cell array where each cell has Cells objects in a clone or a sequence.
        cloneParents    % Cells which do not have any parent cell in the sequence.
        ver             % Label of the tracking version currently analyzed.
        versions        % Cell array with all available tracking version labels.
        yLimMax         % Matrix with upper limits of the y-axis. Rows are plots,
        % first column is in microns, second column is in pixels.
        channels        % Names of fluorescence channels.
        plotFunctions   % Cell array of functions that generate plots.
        plotNames       % Cell array with names of the plots.
        
        % uicontrols
        
        versionPopupMenu    % Popup menu where the user can select a tracking version label.
        versionLabel        % Label for the tracking version popup menu.
        xLabel              % Label for the x unit.
        xFrameRadioButton   % Radio button which sets the x unit to frames.
        xFrameLabel         % Label to the frame x-unit radio button.
        xHourRadioButton    % Radio button which sets the x unit to hours.
        xHourLabel          % Label to the hour x-unit radio button.
        yLabel              % Label for the y-unit.
        yPixelRadioButton   % Radio button which sets the y-unit to pixels.
        yPixelLabel         % Label to the pixel y-unit radio button.
        yMicronRadioButton  % Radio button which sets the y unit to microns.
        yMicronLabel        % Label to the micron y-unit radio button.
        yMaxTextBox         % Text box where the user can set a maximum y-value in plots.
        yMaxLabel           % Label for the y-maximum textbox.
        verticalCheckBox    % Check box for vertical tree plots.
        verticalLabel       % Label for vertical tree plots.
        cloneImageLabel     % Label which says 'Per Clone/Image'
        cloneRadioButton    % Radio button where plotting per clone is selected.
        cloneLabel          % Label for plotting per clone.
        imageRadiobutton    % Radio button for plotting per image.
        imageLabel          % Label for plotting per image.
        functionListBox     % List box where the plotting function can be selected.
        parameterLabel      % Label for the list box with plotting functions.
    end
    
    methods
        function this = CellAnalysisPlayer(aSeqPaths)
            % Constructor which creates the user interface.
            %
            % The constructor first opens a list dialog where the user
            % selects a tracking version. Then the player loads all cells
            % in the image sequences and creates a plot for the first
            % image sequence.
            
            this = this@ControlPlayer(aSeqPaths,...
                'Draw', false,...
                'ControlWidth', 0.1);
            
            % Remove channel menus.
            delete(this.channelTab)
            
            % Remove old export menus.
            childMenus = get(this.exportMenu, 'children');
            for i = 1:length(childMenus)
                delete(childMenus(i))
            end
            
            % Create new export menu options.
            uimenu(this.exportMenu,...
                'Label', 'Export Plot',...
                'Callback', @this.Save);
            uimenu(this.exportMenu,...
                'Label', 'Export All Plots',...
                'Callback', {@this.Save, 'All', true});
            uimenu(this.exportMenu,...
                'Label', 'Export Overview',...
                'Callback', @this.SaveOverview);
            
            seqVers = GetVersions(aSeqPaths);
            this.versions = unique([seqVers{:}])';
            
            % Ask the user to select a tracking version label.
            if ~this.SelectTrackingVersion()
                % The user did not select a tracking version.
                delete(this.mainFigure)
                return
            end
            
            setptr(this.mainFigure, 'watch')
            % Loading data will take a while, so we display an hourglass.
            this.LoadData()
            setptr(this.mainFigure, 'arrow')
            
            this.yLimMax = nan(length(this.plotFunctions),2);
            
            % Make room for labels.
            set(this.ax, 'Position', [0.075 0.15 0.775 0.80])
            
            this.CreateControls()
            
            % Call the function listbox callback instead of Draw, so that
            % the correct checkboxes are enabled and disabled
            % automatically.
            this.FunctionListBox_Callback()
        end
        
        function cloneRadioButton_Callback(this, ~, ~)
            % Executed when the user selects plotting per clone.
            
            % Remove focus from the control.
            set(this.cloneRadioButton, 'Enable', 'off')
            drawnow()
            set(this.cloneRadioButton, 'Enable', 'on')
            
            % Update radio buttons.
            set(this.imageRadiobutton, 'Value', 0)
            set(this.cloneRadioButton, 'Value', 1)
            
            % Update partitioning of cells.
            [this.cellVec, parents] =...
                PartitionCells([this.cellVec{:}], 'cloneParent');
            this.cloneParents = [parents{:}];
            
            % Go to plot 1.
            set(this.slider, 'Value', 1)
            feval(get(this.slider, 'Callback'), this.slider, [])
            set(this.seqPopupMenu,...
                'String', FileEnd({this.cloneParents.seqPath}),...
                'Value', 1)
            
            if this.GetNumImages() > 1
                set(this.playButton, 'Enable', 'on')
                set(this.slider,...
                    'Enable', 'on',...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Max', this.GetNumImages()+0.1)
            else
                set(this.playButton, 'Enable', 'off')
                % Max has to be larger than Min for the slider to be
                % displayed, therefore 0.1 is added to Max.
                set(this.slider,...
                    'Enable', 'off',...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Max', this.GetNumImages())
            end
        end
        
        function CreateControls(this)
            % Crates all controls and labels on the control panel.
            
            % Control order from top to bottom. Each cell is one row.
            order = [...
                {{'versionLabel'}}
                {{'versionPopupMenu'}}
                {{'parameterLabel'}}
                {{'functionListBox'}}
                {{'cloneImageLabel'}}
                {{'imageRadiobutton' 'imageLabel'}}
                {{'cloneRadioButton' 'cloneLabel'}}
                {{'xLabel'}}
                {{'xFrameRadioButton' 'xFrameLabel'}}
                {{'xHourRadioButton' 'xHourLabel'}}
                {{'yLabel'}}
                {{'yPixelRadioButton' 'yPixelLabel'}}
                {{'yMicronRadioButton' 'yMicronLabel'}}
                {{'yMaxLabel'}}
                {{'yMaxTextBox'}}
                {{'verticalCheckBox' 'verticalLabel'}}];
            
            % Relative positions given in the format
            % [left margin, top margin, width, height].
            positions = struct(...
                'versionLabel',         [0.05, 0.01, 0.9,  0.02],...
                'versionPopupMenu',     [0.05, 0.01, 0.9,  0.02],...
                'parameterLabel',       [0.05, 0.03, 0.9,  0.02],...
                'cloneImageLabel',      [0.05, 0.03, 0.9,  0.02],...
                'imageLabel',           [0.05, 0.03, 0.88, 0.02],...
                'imageRadiobutton',     [0.05, 0.01, 0.12, 0.02],...
                'cloneLabel',           [0.05, 0.01, 0.88, 0.02],...
                'xLabel',               [0.05, 0.03, 0.9,  0.02],...
                'xFrameRadioButton',    [0.05, 0.01, 0.12, 0.02],...
                'xFrameLabel',          [0.05, 0.01, 0.88, 0.02],...
                'xHourRadioButton',     [0.05, 0.01, 0.12, 0.02],...
                'xHourLabel',           [0.05, 0.01, 0.88, 0.02],...
                'yLabel',               [0.05, 0.03, 0.9,  0.02],...
                'yPixelRadioButton',    [0.05, 0.01, 0.12, 0.02],...
                'yPixelLabel',          [0.05, 0.01, 0.88, 0.02],...
                'yMicronRadioButton',   [0.05, 0.01, 0.12, 0.02],...
                'yMicronLabel',         [0.05, 0.01, 0.88, 0.02],...
                'cloneRadioButton',     [0.05, 0.01, 0.12, 0.02],...
                'functionListBox',      [0.05, 0.01, 0.9,  0.3],...
                'yMaxLabel',            [0.05, 0.03, 0.9,  0.02],...
                'yMaxTextBox',          [0.05, 0.01, 0.9,  0.02],...
                'verticalCheckBox',     [0.05, 0.01, 0.12, 0.02],...
                'verticalLabel',        [0.05, 0.01, 0.88, 0.02]);
            
            % Compute absolute positions.
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
            
            % Make the controls have the same color as the figure.
            figureColor = get(this.mainFigure, 'color');
            
            this.versionLabel = uicontrol(...
                'Style', 'text',...
                'FontWeight', 'bold',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Tracking Version',...
                'Units', 'normalized',...
                'Tooltip', 'Tracking version to be analyzed.');
            this.versionPopupMenu =  uicontrol(...
                'Style', 'popupmenu',...
                'Parent', this.controlPanel,...
                'BackgroundColor', 'white',...
                'HorizontalAlignment', 'left',...
                'String', this.versions,...
                'Value', find(strcmpi(this.versions, this.ver)),...
                'Units', 'normalized',...
                'Callback', @this.VersionPopupMenu_Callback,...
                'Tooltip', 'Tracking version to be analyzed.');
            this.parameterLabel = uicontrol(...
                'Style', 'text',...
                'FontWeight', 'bold',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Parameters',...
                'Units', 'normalized',...
                'Tooltip', 'What to plot.');
            this.xLabel = uicontrol(...
                'Style', 'text',...
                'FontWeight', 'bold',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Time Unit',...
                'Units', 'normalized',...
                'Tooltip', 'Unit used on time axes.');
            this.xFrameRadioButton = uicontrol(...
                'Style', 'radiobutton',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.XFrameRadioButton_Callback,...
                'Tooltip', 'Use frames on time axes.');
            this.xFrameLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Frames',...
                'Units', 'normalized',...
                'Tooltip', 'Use frames on time axes.');
            this.xHourRadioButton = uicontrol(...
                'Style', 'radiobutton',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.XHourRadioButton_Callback,...
                'Tooltip', 'Use hours on time axes.');
            this.xHourLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Hours',...
                'Units', 'normalized',...
                'Tooltip', 'Use hours on time axes.');
            
            this.yLabel = uicontrol(...
                'Style', 'text',...
                'FontWeight', 'bold',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Length Unit',...
                'Units', 'normalized',...
                'Tooltip', 'Unit used on length axes.');
            this.yPixelRadioButton = uicontrol(...
                'Style', 'radiobutton',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.YPixelRadioButton_Callback,...
                'Tooltip', 'Use pixels on length axes.');
            this.yPixelLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Pixels',...
                'Units', 'normalized',...
                'Tooltip', 'Use pixels on length axes.');
            this.yMicronRadioButton = uicontrol(...
                'Style', 'radiobutton',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.YMicronRadioButton_Callback,...
                'Tooltip', 'Use micrometers on length axes.');
            this.yMicronLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Microns',...
                'Units', 'normalized',...
                'Tooltip', 'Use micrometers on length axes.');
            this.yMaxLabel = uicontrol(...
                'Style', 'text',...
                'FontWeight', 'bold',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Y-max',...
                'Units', 'normalized',...
                'Tooltip', 'Fixes the maximum value of the y-axis.');
            this.yMaxTextBox = uicontrol(...
                'Style', 'edit',...
                'BackgroundColor', 'w',...
                'Parent', this.controlPanel,...
                'HorizontalAlignment', 'left',...
                'Units', 'normalized',...
                'Callback', @this.YMaxTextBox_Callback,...
                'Tooltip', 'Fixes the maximum value of the y-axis.');
            this.verticalCheckBox = uicontrol(...
                'Style', 'checkbox',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.YMicronRadioButton_Callback,...
                'Tooltip', 'Use micrometers on length axes.');
            this.verticalLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Vertical trees',...
                'Units', 'normalized',...
                'Tooltip', 'Gives vertical tree plots.');
            
            this.cloneImageLabel = uicontrol(...
                'Style', 'text',...
                'FontWeight', 'bold',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Per Clone/Image',...
                'Units', 'normalized',...
                'Tooltip', 'Makes separate plots for image sequences or clones.');
            this.cloneRadioButton = uicontrol(...
                'Style', 'radiobutton',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.cloneRadioButton_Callback,...
                'Tooltip', 'A separate plot for each lineage tree.');
            this.cloneLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Clones',...
                'Units', 'normalized',...
                'Tooltip', 'A separate plot for each lineage tree.');
            this.imageRadiobutton = uicontrol(...
                'Style', 'radiobutton',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'Units', 'normalized',...
                'Callback', @this.ImageRadiobutton_Callback,...
                'Tooltip', 'A separate plot for each image sequence.');
            this.imageLabel = uicontrol(...
                'Style', 'text',...
                'Parent', this.controlPanel,...
                'BackgroundColor', figureColor,...
                'HorizontalAlignment', 'left',...
                'String', 'Images',...
                'Units', 'normalized',...
                'Tooltip', 'A separate plot for each image sequence.');
            
            this.functionListBox = uicontrol(...
                'Style', 'listbox',...
                'Parent', this.controlPanel,...
                'String', this.plotNames,...
                'Units', 'normalized',...
                'Callback', @this.FunctionListBox_Callback,...
                'Tooltip', 'What to plot.');
            
            % Position controls.
            for i = 1:length(order)
                for j = 1:length(order{i})
                    eval(['set(this.' order{i}{j} ,...
                        ',''Position'', ['...
                        num2str([p1.(order{i}{j}),...
                        p2.(order{i}{j}),...
                        positions.(order{i}{j})(3),...
                        positions.(order{i}{j})(4)]) '])'])
                end
            end
            
            % Adds a key-press callback to the main figure and all
            % uicontrols in it. If the key-press callback was added only to
            % the figure, the keyboard short cuts would not be available
            % when a uicontrol has been clicked.
            SetKeyPressCallback(this.mainFigure, @this.KeyPressFcn)
            SetKeyReleaseCallback(this.mainFigure, @this.KeyReleaseFcn)
            
            % Remove the key-callbacks from text boxes, so that typing in
            % them does not activate shortcuts.
            set(this.yMaxTextBox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.frameTextbox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.stepTextbox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.fpsTextbox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            
        end
        
        function Draw(this)
            % Calls the selected plotting function.
            %
            % The input arguments to the plotting functions are taken from
            % the controls on the control panel.
            
            % The safest way to ensure that the image sequence corresponds
            % to the plotted data is to set the image sequence before
            % plotting.
            if get(this.cloneRadioButton, 'Value')
                this.seqIndex = find(strcmp(this.seqPaths, this.cloneParents(this.frame).seqPath));
            else
                this.seqIndex = this.frame;
            end
            
            cla(this.ax)  % Avoids accumulation.
            set(this.slider, 'Value', this.frame)  % Make slider move.
            set(this.mainFigure, 'Name', [this.GetName() ': ' this.GetSeqPath()])
            set(this.seqPopupMenu, 'Value', this.frame)
            
            % Display current frame number.
            set(this.frameTextbox, 'String', num2str(this.frame))
            set(this.frameLabel, 'String', ['/' num2str(this.GetNumImages())])
            
            if get(this.xFrameRadioButton, 'Value')
                xUnit = 'frames';
            else
                xUnit = 'hours';
            end
            
            if get(this.yPixelRadioButton, 'Value')
                yUnit = 'pixels';
            else
                yUnit = 'microns';
            end
            
            if any(strcmp(...
                    {'Lineage tree' 'Cell size tree' 'Axis ratio tree'},...
                    this.plotNames{get(this.functionListBox, 'Value')}))
                feval(...
                this.plotFunctions{get(this.functionListBox, 'Value')},...
                this.cellVec{this.frame},...
                this.ax,...
                'XUnit', xUnit,...
                'YUnit', yUnit,...
                'Vertical', get(this.verticalCheckBox, 'Value'))
            else
                feval(...
                this.plotFunctions{get(this.functionListBox, 'Value')},...
                this.cellVec{this.frame},...
                this.ax,...
                'XUnit', xUnit,...
                'YUnit', yUnit)
            end
            
            fIndex = get(this.functionListBox, 'Value');
            pixIndex = get(this.yPixelRadioButton, 'Value')+1;
            
            % Set the limits on the y-axis based on the maximum y-value.
            ymax = this.yLimMax(fIndex,pixIndex);
            if ~isnan(this.yLimMax(fIndex,pixIndex))
                set(this.yMaxTextBox, 'String', ymax);
                set(this.ax, 'yLim', [0 ymax])
            else
                set(this.yMaxTextBox, 'String', '');
            end
            
            % Clear zoom information for each new plot.
            this.zoomAxes = {};
            this.zoomLimits = {};
        end
        
        function FunctionListBox_Callback(this, ~, ~)
            % Updates the figure when a new plotting parameter is selected.
            %
            % The function will enable or disable the radio buttons for
            % selection of time and length units, depending on which
            % alternatives are available for the selected plotting
            % parameter. Then the function creates a new plot in the
            % plotting axes.
            
            % Remove focus from the listbox to allow key-callbacks on
            % arrow keys.
            set(this.functionListBox, 'Enable', 'off')
            drawnow()
            set(this.functionListBox, 'Enable', 'on')
            
            fIndex = get(this.functionListBox, 'Value');
            functionName = this.plotNames{fIndex};
            
            % Enable or disable the radio buttons for time units.
            if any(strcmp(functionName,...
                    {'Average axis ratio tree',...
                    'Average size tree',...
                    'Trajectories'}))
                set(this.xLabel, 'Enable', 'off')
                set(this.xFrameRadioButton, 'Enable', 'off')
                set(this.xFrameLabel, 'Enable', 'off')
                set(this.xHourRadioButton, 'Enable', 'off')
                set(this.xHourLabel, 'Enable', 'off')
            else
                set(this.xLabel, 'Enable', 'on')
                set(this.xFrameRadioButton, 'Enable', 'on')
                set(this.xFrameLabel, 'Enable', 'on')
                set(this.xHourRadioButton, 'Enable', 'on')
                set(this.xHourLabel, 'Enable', 'on')
            end
            
            % Enable or disable radio buttons for length units.
            if any(strcmp(functionName,...
                    {'Axis ratio',...
                    'Lineage tree',...
                    'Cell count',...
                    'Axis ratio tree',...
                    'Average axis ratio tree'}))
                set(this.yLabel, 'Enable', 'off')
                set(this.yPixelRadioButton, 'Enable', 'off')
                set(this.yPixelLabel, 'Enable', 'off')
                set(this.yMicronRadioButton, 'Enable', 'off')
                set(this.yMicronLabel, 'Enable', 'off')
            else
                set(this.yLabel, 'Enable', 'on')
                set(this.yPixelRadioButton, 'Enable', 'on')
                set(this.yPixelLabel, 'Enable', 'on')
                set(this.yMicronRadioButton, 'Enable', 'on')
                set(this.yMicronLabel, 'Enable', 'on')
            end
            
            % Enable or disable the text box for maximum y-values.
            if any(strcmp(functionName,...
                    {'Lineage tree',...
                    'Trajectories',...
                    'Cell size tree',...
                    'Axis ratio tree'}))
                set(this.yMaxTextBox, 'Enable', 'off')
                set(this.yMaxLabel, 'Enable', 'off')
            else
                set(this.yMaxTextBox, 'Enable', 'on')
                set(this.yMaxLabel, 'Enable', 'on')
            end
            
            % Enable or disable check box for vertical trees.
            if any(strcmp(functionName,...
                    {'Lineage tree',...
                    'Cell size tree',...
                    'Axis ratio tree'}))
                set(this.verticalLabel, 'Enable', 'on')
                set(this.verticalCheckBox, 'Enable', 'on')
            else
                set(this.verticalLabel, 'Enable', 'off')
                set(this.verticalCheckBox, 'Enable', 'off')
            end
            
            this.Draw()
        end
        
        function [oXmin, oXmax, oYmin, oYmax] = GetMaxAxisLimits(this, aAxes)
            % Gets the maximum allowed axis limits for an axes objects.
            %
            % The maximum allowed axis limits are the limits which display
            % all of the graphics in the axes without empty space
            % surrounding them. This is how the data is displayed by
            % default, and the user is not allowed to zoom out further.
            %
            % This method overrides the corresponding method in
            % ControlPlayer, so that the maximum limits are given by the
            % limits of the original plots instead of the image size.
            %
            % Inputs:
            % aAxes - Handle of the axes object.
            %
            % Outputs:
            % oXmin - Lower limit on x-axis when fully zoomed out.
            % oXmax - Upper limit on x-axis when fully zoomed out.
            % oYmin - Lower limit on y-axis when fully zoomed out.
            % oYmax - Upper limit on y-axis when fully zoomed out.
           
            index = find(this.zoomAxes == aAxes);
            
            if ~isempty(index) && ~isempty(this.zoomLimits{index})
                % Axes are zoomed in. Use original plot limits.
                limits = this.zoomLimits{index};
                oXmin = limits(1).xmin;
                oXmax = limits(1).xmax;
                oYmin = limits(1).ymin;
                oYmax = limits(1).ymax;
            else
                % Axes are not zoomed in. Use current plot limits.
                currentLimits = axis(aAxes);
                oXmin = currentLimits(1);
                oXmax = currentLimits(2);
                oYmin = currentLimits(3);
                oYmax = currentLimits(4);
            end
        end
        
        function [oName] = GetName(~)
            % Returns the name of the player.
            %
            % The name will be displayed in the title of the main window
            % together with the path of the current image.
            
            oName = 'Cell analysis';
        end
        
        function oNumImages = GetNumImages(this)
            % Returns the number of cell groups that can be plotted.
            %
            % This can be equal to either the number of image sequences or
            % to the number of clones (lineage trees), depending on which
            % option has been selected under 'Per Clone/Image'.
            
            % SequencePlayer will call GetNumImages before cellVec has been
            % created, and then the number of images must be set to 1.
            oNumImages = max(1,length(this.cellVec));
        end
        
        function ImageRadiobutton_Callback(this, ~, ~)
            % Executed when the user selects plotting per image.
            
                        
            % Remove focus from the control.
            set(this.imageRadiobutton, 'Enable', 'off')
            drawnow()
            set(this.imageRadiobutton, 'Enable', 'on')
            
            % Update radio buttons.
            set(this.imageRadiobutton, 'Value', 1)
            set(this.cloneRadioButton, 'Value', 0)
            
            % Update partitioning of cells.
            [this.cellVec, filenames] = PartitionCells([this.cellVec{:}], 'seqPath');
            
            % Go to plot 1.
            set(this.slider, 'Value', 1)
            feval(get(this.slider, 'Callback'), this.slider, [])
            set(this.seqPopupMenu,...
                'String', FileEnd(filenames),...
                'Value', 1)
            
            if this.GetNumImages() > 1
                set(this.playButton, 'Enable', 'on')
                set(this.slider,...
                    'Enable', 'on',...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Max', this.GetNumImages())
            else
                set(this.playButton, 'Enable', 'off')
                % Max has to be larger than Min for the slider to be
                % displayed, therefore 0.1 is added to Max.
                set(this.slider,...
                    'Enable', 'off',...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Max', this.GetNumImages()+0.1)
            end
        end
        
        function LoadData(this)
            % Loads the tracking results for all image sequences.
            %
            % First, all of the Cell objects are read into a single array
            % and then the objects are partitioned into cells in a cell
            % array using the function PartitionCells. The function also
            % determines which plotting functions can be used with the new
            % data. Plotting functions for all fluorescence channels are
            % included.
            
            % Load the Cell objects. If no cells are found, the user gets
            % to select a different tracking version.
            tmpCells = [];
            while isempty(tmpCells)
                tmpCells = LoadCells(this.seqPaths, this.ver,...
                    'AreCells', true, 'Compact', true);
                if isempty(tmpCells)
                    dialog = errordlg('The selected tracking version had no cells.',...
                        'Error loading cells', 'modal');
                    waitfor(dialog)
                    this.SelectTrackingVersion()
                end
            end
            
            % Partition the cells into either clones or images.
            if get(this.cloneRadioButton, 'Value')
                [this.cellVec, parents] =...
                    PartitionCells(tmpCells, 'cloneParent');
                this.cloneParents = [parents{:}];
                set(this.seqPopupMenu, 'String', FileEnd({this.cloneParents.seqPath}))
            else
                [this.cellVec, filenames] = PartitionCells(tmpCells, 'seqPath');
                set(this.seqPopupMenu, 'String', FileEnd(filenames))
            end
            
            % Find the names of all fluorescence channels. This cannot be
            % taken from the ImageData object, as the channel names might
            % have changed.
            allCells = [this.cellVec{:}];
            propNames = {allCells.regionProps};
            % Remove empty cells so that fieldnames does not give an error.
            propNames(cellfun(@isempty, propNames)) = [];
            if isempty(propNames)
                this.channels = {};
            else
                propNames = cellfun(@fieldnames, propNames, 'UniformOutput', false);
                propNames = unique(cat(1,propNames{:}));
                this.channels = regexp(propNames, '(?<=FluorAvg).*', 'match', 'once');
                this.channels(cellfun(@isempty, this.channels)) = [];
            end
            
            % Loading new data will take you back to the first frame.
            this.frame = 1;
            
            if this.GetNumImages() > 1
                set(this.playButton, 'Enable', 'on')
                set(this.slider,...
                    'Enable', 'on',...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Max', this.GetNumImages())
            else
                set(this.playButton, 'Enable', 'off')
                % Max has to be larger than Min for the slider to be
                % displayed, therefore 0.1 is added to Max.
                set(this.slider,...
                    'Enable', 'off',...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Max', this.GetNumImages()+0.1)
            end
            
            % Available plotting functions.
            this.plotFunctions = {...
                @(aCells, aAxes, varargin)Plot_LineageTree(aCells, aAxes,...
                'StyleFunction', @PrintStyle, varargin{:}),...
                @Plot_AllTrajectories,...
                @Plot_CellCount,...
                @Plot_TotalDistance,...
                @Plot_CellSize,...
                @Plot_AxisRatio,...
                @(aCells, aAxes, varargin)Plot_ParameterTree(...
                aCells, aAxes, 'Size', varargin{:}),...
                @(aCells, aAxes, varargin)Plot_ParameterTree(...
                aCells, aAxes, 'AxisRatio', varargin{:}),...
                @Tree_AvgSize,...
                @Tree_AvgAxisRatio,...
                @Tree_AvgSpeed};
            
            % Displayed names of the plotting functions.
            this.plotNames = {...
                'Lineage tree',...
                'Trajectories',...
                'Cell count',...
                'Total distance traveled',...
                'Cell size',...
                'Axis ratio',...
                'Cell size tree',...
                'Axis ratio tree',...
                'Average size tree',...
                'Average axis ratio tree',...
                'Average speed tree'};
            
            % Add functions for plotting of fluorescence, and the
            % corresponding names.
            for i = 1:length(this.channels)
                this.plotFunctions = [this.plotFunctions...
                    {@(aCells, aAxes, a1, a2, a3, a4)Plot_Fluorescence(...
                    aCells, aAxes, this.channels{i}, a1, a2, a3, a4, 'Metric', 'max'),...
                    @(aCells, aAxes, a1, a2, a3, a4)Plot_Fluorescence(...
                    aCells, aAxes, this.channels{i}, a1, a2, a3, a4, 'Metric', 'avg'),...
                    @(aCells, aAxes, a1, a2, a3, a4)Plot_Fluorescence(...
                    aCells, aAxes, this.channels{i}, a1, a2, a3, a4, 'Metric', 'tot')}];
                
                this.plotNames = [this.plotNames,...
                    {sprintf('%s maximum fluorescence intensity', this.channels{i}),...
                    sprintf('%s average fluorescence intensity', this.channels{i}),...
                    sprintf('%s total fluorescence', this.channels{i})}];
            end
        end
        
        function NextButton_Callback(this, ~, ~)
            % Callback for button which goes to the next clone/image.
            
            % Remove focus from the control.
            set(this.nextButton, 'Enable', 'off')
            drawnow()
            set(this.nextButton, 'Enable', 'on')
            
            this.frame = mod(this.frame, this.GetNumImages) + 1;
            this.Draw()
        end
        
        function PreviousButton_Callback(this, ~, ~)
            % Callback for button which goes to the previous clone/image.
            
            % Remove focus from the control.
            set(this.previousButton, 'Enable', 'off')
            drawnow()
            set(this.previousButton, 'Enable', 'on')
            
            this.frame = mod(this.frame-2, this.GetNumImages())+1;
            this.Draw()
        end
        
        function Save(this, ~, ~, varargin)
            % Saves plots to graphics files.
            %
            % The function creates a cell array of function handles which
            % can be used to generate the different plots. Then, the
            % function opens the SavePlotsGUI where settings for the saving
            % to files can be specified.
            %
            % Property/Value inputs:
            % All - If this is set to true, the function will save plots
            %       for all of the clones/images. Otherwise, only the
            %       displayed plot will be saved.
            
            aAll = GetArgs({'All'}, {false}, true, varargin);
            
            fIndex = get(this.functionListBox, 'Value');
            pixIndex = get(this.yPixelRadioButton, 'Value')+1;
            
            xunits = {'hours', 'frames'};
            yunits = {'microns', 'pixels'};
            
            % Create function handles for all plots to be saved.
            if aAll
                % Save plots for all clones/images.
                func = cell(size(this.cellVec));
                for i = 1:length(this.cellVec)
                    axFunc = @(aAx)this.plotFunctions{fIndex}(...
                        this.cellVec{i},...
                        aAx,...
                        'XUnit', xunits{get(this.xFrameRadioButton, 'Value')+1},...
                        'YUnit', yunits{get(this.yPixelRadioButton, 'Value')+1});
                    func{i} = @(aFig)SingleAxFig(aFig, axFunc);
                end
            else
                % Save plots for the displayed clone/image.
                axFunc = @(aAx)this.plotFunctions{fIndex}(...
                    this.cellVec{this.frame},...
                    aAx,...
                    'XUnit', xunits{get(this.xFrameRadioButton, 'Value')+1},...
                    'YUnit', yunits{get(this.yPixelRadioButton, 'Value')+1});
                func = {@(aFig)SingleAxFig(aFig, axFunc)};
            end
            
            % Use the image sequence names as figure captions.
            captions = cell(size(this.cellVec));
            for i = 1:length(this.cellVec)
                captions{i} = FileEnd(this.cellVec{i}(1).seqPath);
            end
            
            % Arguments which change the y-limits in SavePlotsGUI.
            if ~isnan(this.yLimMax(fIndex,pixIndex))
                yLimits = [0 this.yLimMax(fIndex,pixIndex)];
                yLimArgs = {'Ylim', yLimits};
            else
                yLimArgs = {};
            end
            
            % Create figure names for the plots to be saved.
            if aAll
                if get(this.cloneRadioButton, 'Value')
                    figNames = arrayfun(@(x)sprintf('clone%03d', x),...
                        1:length(this.cellVec),...
                        'UniformOutput', false);
                else
                    figNames = arrayfun(@(x)sprintf('image%03d', x),...
                        1:length(this.cellVec),...
                        'UniformOutput', false);
                end
            else
                if get(this.cloneRadioButton, 'Value')
                    figNames = {sprintf('clone%03d', this.frame)};
                else
                    figNames = {sprintf('image%03d', this.frame)};
                end
            end
            
            % Open a dialog box where the user can decide how the plotting
            % should be done, and how the plots should be saved to files.
            SavePlotsGUI('Plots', func,...
                'Directory', fullfile(FileParts2(this.GetSeqPath()), 'Analysis'),...
                'Title', this.plotNames{fIndex},...
                'Captions', captions,...
                'AuthorStr', this.GetImData(1).Get('authorStr'),...
                'FigUnits', 'normalized',...
                'FigPosition', [0.15 0.05 0.8 0.8],...
                'FigNames', figNames,...
                yLimArgs{:})
        end
        
        function SaveOverview(this, ~, ~)
            % Creates figures with thumbnail sized plots for exporting.
            %
            % The selected parameter is plotted for all of the
            % clones/images. The plots are ordered by experimental
            % condition, and at most 12 plots are made in the same figure.
            % The plots can be useful to quickly get an overview of a large
            % dataset. The exporting to graphics files is performed using
            % SavePlotsGUI.
            
            fIndex = get(this.functionListBox, 'Value');
            pixIndex = get(this.yPixelRadioButton, 'Value') + 1;
            
            % Partition the cells both based on experimental condition and
            % on clone/image.
            if get(this.cloneRadioButton, 'Value')
                [overviewCellVec, overviewLabels] =...
                    PartitionCells([this.cellVec{:}], 'condition', 'cloneParent');
            else
                [overviewCellVec, overviewLabels] =...
                    PartitionCells([this.cellVec{:}], 'condition', 'seqPath');
            end
            
            figCnt = 1;  % The index of the figure to be created.
            overviewFigs = [];
            for eIndex = 1:length(overviewCellVec)  % Loop over conditions.
                cellVecTmp = SortClones(overviewCellVec{eIndex});
                caption = sprintf('%s for %s.',...
                    this.plotNames{fIndex}, overviewLabels{1,eIndex});
                f = figure(...
                    'Name', sprintf('Overview figure %d', figCnt),...
                    'Units', 'normalized',...
                    'Position', [0.15 0.05 0.8 0.8],...
                    'Color', 'w',...
                    'UserData', caption);
                figCnt = figCnt + 1;
                overviewFigs = [overviewFigs f]; %#ok<AGROW>
                axIndex = 1;
                for clIndex = 1:length(cellVecTmp);  % Loop over plots.
                    if axIndex == 13
                        % There are 12 axes per figure, so on 13 a new
                        % figure is opened, and the counter is reset.
                        caption = sprintf('%s for %s.',...
                            this.plotNames{fIndex}, overviewLabels{1,eIndex});
                        f = figure(...
                            'Name', sprintf('Overview figure %d', figCnt),...
                            'Units', 'normalized',...
                            'Position', [0.15 0.05 0.8 0.8],...
                            'Color', 'w',...
                            'UserData', caption);
                        figCnt = figCnt + 1;
                        overviewFigs = [overviewFigs f]; %#ok<AGROW>
                        axIndex = 1;
                    end
                    
                    xunits = {'hours', 'frames'};
                    yunits = {'microns', 'pixels'};
                    
                    % Execute the plotting function for one plot.
                    cells = cellVecTmp{clIndex};
                    ax = subplot(3, 4, axIndex, 'Parent', f);
                    plotFun = this.plotFunctions{fIndex};
                    if strcmp(func2str(plotFun), 'Plot_LineageTree')
                        feval(...
                            plotFun,...
                            cells,...
                            ax,...
                            'XUnit', xunits{get(this.xFrameRadioButton, 'Value')+1},...
                            'YUnit', yunits{get(this.yPixelRadioButton, 'Value')+1},...
                            'Vertical', true,...
                            'Black', true)
                        title(ax, SpecChar(FileEnd(cells(1).seqPath), 'matlab'))
                    else
                        feval(...
                            plotFun,...
                            cells,...
                            ax,...
                            'XUnit', xunits{get(this.xFrameRadioButton, 'Value')+1},...
                            'YUnit', yunits{get(this.yPixelRadioButton, 'Value')+1});
                        title(ax, SpecChar(FileEnd(cells(1).seqPath), 'matlab'))
                        set(ax, 'XTickLabelRotation', 90)
                    end
                    
                    ymax = this.yLimMax(fIndex,pixIndex);
                    if ~isnan(this.yLimMax(fIndex,pixIndex))
                        set(ax, 'yLim', [0 ymax])
                    end
                    
                    axIndex = axIndex + 1;
                end
            end
            
            if isempty(overviewFigs)
                return
            end
            
            % Open a dialog from which the figures can be exported.
            captions = arrayfun(@(x)get(x, 'UserData'), overviewFigs,...
                'UniformOutput', false);
            name = ['Overview of ' this.plotNames{get(this.functionListBox, 'Value')}];
            SavePlotsGUI('Plots', num2cell(overviewFigs),...
                'Directory', fullfile(FileParts2(this.GetSeqPath()), 'Analysis'),...
                'Title', name,...
                'AuthorStr', this.GetImData(1).Get('authorStr'),...
                'Captions', captions)
        end
        
        function oOk = SelectTrackingVersion(this)
            % Lets the user select a tracking version on startup.
            %
            % Outputs:
            % oOk - True if the user selected a tracking version.
            
            [sel, oOk] = listdlg('PromptString', 'Select tracking version:',...
                'SelectionMode', 'single',...
                'ListString', this.versions);
            if oOk
                this.ver = this.versions{sel};
            end
        end
        
        function SwitchSequence(this, aIndex)
            % Switches to displaying a particular clone/image.
            %
            % Inputs:
            % aIndex - Index of the clone/image to be displayed.
            
            this.frame = aIndex;
            this.Draw()
        end
        
        function VersionPopupMenu_Callback(this, ~, ~)
            % Executed when the user switches to a new tracking label.
            %
            % Data for the new tracking label is loaded and the list of
            % available plotting functions is updated.
            
            % Remove focus from the popupmenu to allow key-callbacks on
            % arrow keys.
            set(this.versionPopupMenu, 'Enable', 'off')
            drawnow()
            set(this.versionPopupMenu, 'Enable', 'on')
            
            this.ver = this.versions{get(this.versionPopupMenu, 'Value')};
            
            oldPlotNames = this.plotNames;
            selectedPlot = this.plotNames{get(this.functionListBox, 'Value')};
            
            % Load data and set the cursor to an hourglass while loading.
            setptr(this.mainFigure, 'watch')
            this.LoadData()
            setptr(this.mainFigure, 'arrow')
            
            % Try to select the same function in the listbox after loading
            % new data. If the old function is not available for the new
            % data, the first function is selected.
            newValue = find(strcmp(this.plotNames, selectedPlot),1);
            if isempty(newValue)
                newValue = 1;
            end
            
            % Put the names of the plotting functions for the new data into
            % the listbox.
            set(this.functionListBox,...
                'String', this.plotNames,...
                'Value', newValue)
            
            % Keep the maximum y-values for all functions that are
            % available for both the old and the new data.
            oldYLimMax = this.yLimMax;
            this.yLimMax = nan(length(this.plotFunctions),2);
            for i = 1:length(oldPlotNames)
                newIndex = find(strcmp(this.plotNames, oldPlotNames{i}), 1);
                if ~isempty(newIndex)
                    this.yLimMax(newIndex) = oldYLimMax(i);
                end
            end
            
            this.Draw()
        end
        
        function XFrameRadioButton_Callback(this, ~, ~)
            % Executed when the user sets the x-axis unit to frames.
            
            % Remove focus from the control.
            set(this.xFrameRadioButton, 'Enable', 'off')
            drawnow()
            set(this.xFrameRadioButton, 'Enable', 'on')
            
            set(this.xFrameRadioButton, 'Value', true)
            set(this.xHourRadioButton, 'Value', false)
            this.Draw()
        end
        
        function XHourRadioButton_Callback(this, ~, ~)
            % Executed when the user sets the x-axis unit to hours.
            
            % Remove focus from the control.
            set(this.xHourRadioButton, 'Enable', 'off')
            drawnow()
            set(this.xHourRadioButton, 'Enable', 'on')
            
            set(this.xFrameRadioButton, 'Value', false)
            set(this.xHourRadioButton, 'Value', true)
            this.Draw()
        end
        
        function YMaxTextBox_Callback(this, ~, ~)
            % Callback for the text box with maximum y-values.
            %
            % The maximum y-values are set independently for different
            % plots and for pixels and microns. If an empty string or a
            % string which is not a nonnegative number is entered, the
            % maximum value is removed.
            
            number = str2double(get(this.yMaxTextBox, 'String'));
            fIndex = get(this.functionListBox, 'Value');
            pixIndex = get(this.yPixelRadioButton, 'Value')+1;
            if isnan(number) || number <= 0
                this.yLimMax(fIndex, pixIndex) = nan;  % Go back to default.
            else
                this.yLimMax(fIndex, pixIndex) = number;
            end
            this.Draw()
        end
        
        function YMicronRadioButton_Callback(this, ~, ~)
            % Executed when the user sets the y-axis unit to microns.
            %
            % The unit will be microns if the displayed parameter is a
            % length, and square microns if it is an area.
            
            % Remove focus from the control.
            set(this.yMicronRadioButton, 'Enable', 'off')
            drawnow()
            set(this.yMicronRadioButton, 'Enable', 'on')
            
            set(this.yPixelRadioButton, 'Value', false)
            set(this.yMicronRadioButton, 'Value', true)
            this.Draw()
        end
        
        function YPixelRadioButton_Callback(this, ~, ~)
            % Executed when the user sets the y-axis unit to pixels.
            
            % Remove focus from the control.
            set(this.yPixelRadioButton, 'Enable', 'off')
            drawnow()
            set(this.yPixelRadioButton, 'Enable', 'on')
            
            set(this.yPixelRadioButton, 'Value', true)
            set(this.yMicronRadioButton, 'Value', false)
            this.Draw()
        end
        
        function VerticalCheckBox_Callback(this, ~, ~)
            % Executes when the user clicks the box for vertical trees.
            
            % Remove focus from the control.
            set(this.verticalCheckBox, 'Enable', 'off')
            drawnow()
            set(this.verticalCheckBox, 'Enable', 'on')
            
            this.Draw()
        end
        
        function WindowButtonMotionFcn(this, aObj, aEvent)
            % Executes when the mouse cursor is moved.
            %
            % This method overrides the corresponding method in
            % ControlPlayer so that zoom boxes are not rounded to integer
            % values.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - []
            
            this.WindowButtonMotionFcn@ControlPlayer(aObj, aEvent,...
                'PixelAxes', false)
        end
        
        function WindowButtonUpFcn(this, aObj, aEvent)
            % Executes when a mouse button is released.
            %
            % This method overrides the corresponding method in
            % ControlPlayer so that zoom boxes are not rounded to integer
            % values.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - []
            
            this.WindowButtonUpFcn@ControlPlayer(aObj, aEvent,...
                'PixelAxes', false);
        end
    end
end