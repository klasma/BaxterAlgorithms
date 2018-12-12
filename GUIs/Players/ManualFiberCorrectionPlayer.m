classdef ManualFiberCorrectionPlayer < ManualCorrectionPlayer
    % GUI for manual correction of muscle fiber segmentations.
    %
    % This manual correction GUI is a sub-class of ManualCorrectionPlayer.
    % ManualCorrectionPlayer is designed for correction of cell tracking
    % results, and ManualFiberCorrectionPlayer is a modified version of
    % that GUI, designed for manual correction of muscle fiber
    % segmentations. All tools for correction of tracks have been removed
    % and a new tool to specify which fibers are positive and negative for
    % a specific marker has been added. Buttons to show and hide positive
    % and negative fibers have also been added. The lineage tree is not
    % interesting given that there is only a single time point, so that has
    % been removed. The default options for segmentation editing have been
    % optimized for fiber editing. When a fiber is created by either
    % drawing a new region or by separating a region into two, the new
    % fiber will become a real fiber instead of a false positive. When the
    % user draws on multiple fibers using the segmentation editing tool,
    % the fibers will be joined into a single larger fiber. In the
    % ManualCorrectionPlayer, the fibers would have instead formed a
    % cluster. The default coloring is changed to a new coloring scheme,
    % where positive fibers are red and negative fibers are green. The
    % colors of positive and negative fibers can be changed using two
    % checkboxes.
    %
    % See also:
    % ManualCorrectionPlayer, FiberAnalysisGUI
    
    properties
        positiveToggle          % Toggle button which specifies if positive fibers should be displayed.
        positiveColorTextBox    % Textbox where the color of positive fibers can be set as an RGB-triplet.
        negativeToggle          % Toggle button which specifies if negative fibers should be displayed.
        negativeColorTextBox    % Textbox where the color of negative fibers can be set as an RGB-triplet.
        positiveButton          % Tool button for the tool which sets fibers as positive or negative.
    end
    
    methods
        function this = ManualFiberCorrectionPlayer(aSeqPaths)
            % Constructs a fiber correction GUI in a new figure.
            %
            % The constructor calls the constructor of
            % ManualCorrectionPlayer and then removes the lineage tree.
            % Other changes are handled by overloading other functions of
            % ManualCorrectionPlayer.
            %
            % Inputs:
            % aSeqPath - Cell array with the full paths of image folders
            %            that will be available for correction. The first
            %            folder in the array will be displayed when the
            %            figure is first created.
            
            this = this@ManualCorrectionPlayer(aSeqPaths);
            % The ManualCorrectionPlayer constructor will draw a time line
            % in the treeAxes. That is removed using cla.
            cla(this.treeAxes)
            this.tree = 'None';
            this.ReSizeAxes()
        end
        
        function [oName] = GetName(~)
            % Returns the name of the player.
            %
            % The name will be displayed in the title of the main window
            % together with the path of the current image.
            
            oName = 'Fiber correction';
        end
        
        function oOrder = ControlOrder(~)
            % Defines the order of tools and other controls.
            %
            % This function replaces the function with the same name in
            % ManualCorrectionPlayer. The control list contains all of the
            % controls from ManualCorrectionPlayer, plus the new controls
            % that are specific for fiber editing. The controls for editing
            % of tracks are removed in the function ControlPositions by
            % setting their sizes close to 0.
            %
            % Outputs:
            % oOrder - Cell array where each element contains another cell
            %          array with names of the control objects that will be
            %          placed on the corresponding row of the control
            %          panel. The first element contains the controls that
            %          will be placed on the first row from the top. The
            %          controls on each row are ordered from left to right.
            %
            % See also:
            % ControlPositions
            
            oOrder = {{'verPopupMenu'}
                {'displayToolsButton'}
                {'positiveToggle', 'positiveColorTextBox'}
                {'negativeToggle', 'negativeColorTextBox'}
                {'fpToggle', 'fpColorTextBox'}
                {'trajectoryToggle', 'outlineToggle'}
                {'cellEventsToggle', 'currentLineToggle'}
                {'trajectoryTextBox', 'outlineTextBox'}
                {'coloringToolsButton'}
                {'colorButton', 'colorTextBox'}
                {'colorAllButton', 'colorAllTextBox'}
                {'correctionToolsButton'}
                {'connectButton', 'moveButton'}
                {'addButton', 'continuousAddButton'}
                {'splitButton', 'trackSplitButton'}
                {'childButton', 'childSplitButton'}
                {'disappearButton', 'moveMitosisButton'}
                {'positiveButton', 'editSegmentsButton'}
                {'deleteButton', 'removeFpButton'}
                {'jumpButton', 'continuousDrawButton'}
                {'saveButton'}
                {'visualizationToolsButton'}
                {'selectButton', 'zoomButton'}};
        end
        
        function oPositions = ControlPositions(~)
            % Returns a struct with relative positions for all controls.
            %
            % The fields of the struct are the names of the controls and
            % the values of the struct are arrays which represent the
            % positions. The arrays have the format [left margin, top
            % margin, width, height], and the values are given in
            % normalized units of the control panel. Controls from
            % ManualCorrectionPlayer that should be removed are given a
            % width and a height of 1E-8. This function replaces the
            % function with the same name in ManualCorrectionPlayer.
            %
            % See also:
            % ControlOrder
            
            oPositions = struct(...
                'verPopupMenu',             [0.1, 0.01, 0.8 0.02],...
                'displayToolsButton',       [0.05, 0.008, 0.9, 0.03],...
                'trajectoryToggle',         [0.2, 0.008, 0.25, 0.045],...
                'trajectoryTextBox',        [0, 0,  1E-8, 1E-8],...
                'outlineToggle',            [0.1, 0.008, 0.25, 0.045],...
                'outlineTextBox',           [0, 0,  1E-8, 1E-8],...
                'positiveToggle',           [0.2, 0.008, 0.25, 0.045],...
                'positiveColorTextBox',     [0.1, 0.008, 0.25, 0.045],...
                'negativeToggle',           [0.2, 0.008, 0.25, 0.045],...
                'negativeColorTextBox',     [0.1, 0.008, 0.25, 0.045],...
                'fpToggle',                 [0.2, 0.008, 0.25, 0.045],...
                'fpColorTextBox',           [0.1, 0.008, 0.25, 0.045],...
                'cellEventsToggle',         [0, 0,  1E-8, 1E-8],...
                'currentLineToggle',        [0, 0,  1E-8, 1E-8],...
                'coloringToolsButton',      [0.05, 0.008, 0.9, 0.03],...
                'colorButton',              [0.2, 0.008, 0.25, 0.045],...
                'colorTextBox',             [0.1, 0.008, 0.25, 0.045],...
                'colorAllButton',           [0.2, 0.008, 0.25, 0.045],...
                'colorAllTextBox',          [0.1, 0.008, 0.25, 0.045],...
                'correctionToolsButton',    [0.05, 0.008, 0.9, 0.03],...
                'connectButton',            [0, 0,  1E-8, 1E-8],...
                'moveButton',               [0, 0,  1E-8, 1E-8],...
                'disappearButton',          [0, 0,  1E-8, 1E-8],...
                'addButton',                [0, 0,  1E-8, 1E-8],...
                'continuousAddButton',      [0, 0,  1E-8, 1E-8],...
                'splitButton',              [0, 0,  1E-8, 1E-8],...
                'trackSplitButton',         [0, 0,  1E-8, 1E-8],...
                'childButton',              [0, 0,  1E-8, 1E-8],...
                'childSplitButton',         [0, 0,  1E-8, 1E-8],...
                'moveMitosisButton',        [0, 0,  1E-8, 1E-8],...
                'positiveButton',           [0.2, 0.008, 0.25, 0.045],...
                'editSegmentsButton',       [0.1, 0.008, 0.25, 0.045],...
                'deleteButton',             [0.2, 0.008, 0.25, 0.045],...
                'removeFpButton',           [0.1, 0.008, 0.25, 0.045],...
                'jumpButton',               [0, 0,  1E-8, 1E-8],...
                'continuousDrawButton',     [0, 0,  1E-8, 1E-8],...
                'saveButton',               [0.2, 0.008, 0.25, 0.045],...
                'visualizationToolsButton', [0.05, 0.008, 0.9, 0.03],...
                'selectButton',             [0, 0,  1E-8, 1E-8],...
                'zoomButton',               [0.2, 0.008, 0.25, 0.045]);
        end
        
        function CreateControls(this)
            % Creates all controls on the control panel.
            %
            % This function extends the function with the same name in
            % ManualCorrectionPlayer, by adding additional controls. The
            % sizes of the controls are set in PositionControls. There,
            % controls that should be removed are given a size close to
            % zero.
            %
            % See also:
            % PositionControls
            
            % Create the controls defined in ManualCorrectionPlayer.
            this.CreateControls@ManualCorrectionPlayer()
            
            % Create the controls specific to fiber editing.
            this.positiveToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Positive Fibers (P)',...
                'Value', 1,...
                'HorizontalAlignment', 'left',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.positiveColorTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'Color Of Positive Fibers',...
                'BackgroundColor', [.95 .95 .95]',...
                'HorizontalAlignment', 'center',...
                'String', '1 0 0',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_PositiveColorTextBox);
            this.negativeToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Negative Fibers (N)',...
                'Value', 1,...
                'HorizontalAlignment', 'left',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.negativeColorTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'Color Of Positive Fibers',...
                'BackgroundColor', [.95 .95 .95]',...
                'HorizontalAlignment', 'center',...
                'String', '0 1 0',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_NegativeColorTextBox);
            this.positiveButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Positive/Negative (C)',...
                'HorizontalAlignment', 'left',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            
            % Add positiveButton to the list of tool buttons.
            this.toolButtons = [this.toolButtons
                ToggleButton(this.positiveButton,...
                'plusMinusButton.png', 'plusMinusButtonPressed.png', [])];
            
            % Add positiveToggle and negativeToggle to the list of toggle
            % buttons.
            this.toggleButtons = [this.toggleButtons
                ToggleButton(this.positiveToggle,...
                'positiveButton.png',...
                'positiveButtonPressed.png', this.positiveColorTextBox)
                ToggleButton(this.negativeToggle,...
                'negativeButton.png',...
                'negativeButtonPressed.png', this.negativeColorTextBox)];
        end
        
        function Callback_PositiveColorTextBox(this, aObj, ~)
            % Called when the user changes the color of positive fibers.
            %
            % The function checks that the string entered in the textbox
            % is a valid RGB-triplet with values between 0 and 1. Then,
            % the colors of the fibers are changed and the image is
            % redrawn. If the string is not a valid RGB-triplet, the color
            % is set to red.
            
            % Check that the entered string is a valid RGB-triplet.
            num = str2num(get(aObj, 'String')); %#ok<ST2NM>
            if ~isempty(num) && all(num >= 0) && all(num <= 1)
                this.Draw()
            else
                set(aObj, 'String', '1 0 0')
            end
            
            this.ColorCells()
            this.Draw()
        end
        
        function Callback_NegativeColorTextBox(this, aObj, ~)
            % Called when the user changes the color of negative fibers.
            %
            % The function checks that the string entered in the text box
            % is a valid RGB-triplet with values between 0 and 1. Then,
            % the colors of the fibers are changed and the image is
            % redrawn. If the string is not a valid RGB-triplet, the color
            % is set to green.
            
            % Check that the entered string is a valid RGB-triplet.
            num = str2num(get(aObj, 'String')); %#ok<ST2NM>
            if ~isempty(num) && all(num >= 0) && all(num <= 1)
                this.Draw()
            else
                set(aObj, 'String', '0 1 0')
            end
            
            this.ColorCells()
            this.Draw()
        end
        
        function CreateMenus(this)
            % Creates the dropdown menus at the top of the figure.
            %
            % The function overwrites the function with the same name in
            % ManulaCorrectionPlayer. Some of the values selected from the
            % start are changed to work better for fiber editing.
            %
            % The selection of menu options must be done here, because this
            % function is executed by the ManualCorrectionPlayer
            % constructor. It would be too late to make the selections in
            % the constructor of ManualFiberCorrectionPlayer.
            
            % Color the positive and negative fibers in different colors.
            this.coloring = 'Positive/Negative';
            % Create new fibers when a region is split using segmentation
            % editing.
            this.drawBreak = 'Create TP (CTRL+T)';
            % Merge multiple fibers into a single region if they are joined
            % during segmentation editing.
            this.drawMerge = 'Combine (CRTL+M)';
            
            % User menu options.
            this.styleAlts = {'ISBI'; 'Default'; 'Save'};
            this.coloringAlts = {'Positive/Negative'; 'Rainbow'; 'Random Hues'; 'Random Colors'};
            this.drawBreakAlts = {'Create TP (CTRL+T)'; 'Create FP (CTRL+F)'};
            this.drawMergeAlts = {'Re-break (CRTL+R)'; 'Combine (CRTL+M)'; 'Overwrite (CTRL+O)'};
            this.drawHoleAlts = {'Allow Holes (CTRL+A)'; 'Fill Holes (CRTL+I)'};
            this.drawBrushAlts = {'Disk (CTRL+D)'; 'Ball (CTRL+B)'};
            
            % Create menus for style and coloring options.
            this.stylesMenu = uimenu(this.mainFigure, 'Label', 'Style');
            for i = 1:length(this.styleAlts)
                m = uimenu(this.stylesMenu,...
                    'Label', this.styleAlts{i},...
                    'Callback', @this.MenuCallback_StyleChange);
                if strcmp(this.styleAlts{i}, this.style)
                    set(m, 'Checked', 'on')
                end
            end
            this.coloringMenu = uimenu(this.mainFigure, 'Label', 'Coloring');
            for i = 1:length(this.coloringAlts)
                m = uimenu(this.coloringMenu,...
                    'Label', this.coloringAlts{i},...
                    'Callback', @this.MenuCallback_ColoringChange);
                if strcmp(this.coloringAlts{i}, this.coloring)
                    set(m, 'Checked', 'on')
                end
            end
            
            % Create menus for different segmentation editing options.
            this.drawMenu = uimenu(this.mainFigure, 'Label', 'Drawing');
            drawBreakMenu = uimenu(this.drawMenu, 'Label', 'Create');
            for i = 1:length(this.drawBreakAlts)
                m = uimenu(drawBreakMenu,...
                    'Label', this.drawBreakAlts{i},...
                    'Callback', @this.MenuCallback_DrawChange);
                if strcmp(this.drawBreakAlts{i}, this.drawBreak)
                    set(m, 'Checked', 'on')
                end
            end
            drawMergeMenu = uimenu(this.drawMenu, 'Label', 'Merging');
            for i = 1:length(this.drawMergeAlts)
                m = uimenu(drawMergeMenu,...
                    'Label', this.drawMergeAlts{i},...
                    'Callback', @this.MenuCallback_DrawChange);
                if strcmp(this.drawMergeAlts{i}, this.drawMerge)
                    set(m, 'Checked', 'on')
                end
            end
            drawHoleMenu = uimenu(this.drawMenu, 'Label', 'Holes');
            for i = 1:length(this.drawHoleAlts)
                m = uimenu(drawHoleMenu,...
                    'Label', this.drawHoleAlts{i},...
                    'Callback', @this.MenuCallback_DrawChange);
                if strcmp(this.drawHoleAlts{i}, this.drawHole)
                    set(m, 'Checked', 'on')
                end
            end
            drawBrushMenu = uimenu(this.drawMenu, 'Label', 'Brush');
            for i = 1:length(this.drawBrushAlts)
                m = uimenu(drawBrushMenu,...
                    'Label', this.drawBrushAlts{i},...
                    'Callback', @this.MenuCallback_DrawChange);
                if strcmp(this.drawBrushAlts{i}, this.drawBrush)
                    set(m, 'Checked', 'on')
                end
            end
            if this.GetImData.GetDim() == 2
                % Hide the brush shape option for 2D data.
                set(drawBrushMenu, 'visible', 'off')
            end
        end
        
        function Draw3D(this, varargin)
            % Update the displayed fiber image.
            %
            % The function overwrites the function with the same name in
            % ManualCorrectionPlayer. The contents of the function are the
            % same, except that this function removes positive/negative
            % fibers if the corresponding toggle buttons have not been
            % pressed. Unfortunately, I have not fond a way to select the
            % fibers to be plotted and at the same time reuse the function
            % from ManualCorrectionPlayer. Therefore the code from
            % ManualCorrectionPlayer is duplicated here.
            %
            % Property/Value inputs:
            % EditedCells - A vector of cells which need to be re-drawn. If
            %               this input is specified, only the specified
            %               cells will be re-drawn. Other cells and the
            %               image will not be re-drawn. This normally
            %               speeds up the drawing significantly when there
            %               are a lot of cells. This function will remove
            %               the old graphics objects associated with the
            %               specified cells, and the functions DrawXY will
            %               create the new graphics objects.
            
            aEditedCells = GetArgs({'EditedCells'}, {0}, true, varargin);
            
            % Make the slider move.
            set(this.slider, 'Value', this.frame)
            
            % Display current frame number.
            set(this.frameTextbox, 'String', num2str(this.frame))
            set(this.frameLabel, 'String', ['/' num2str(this.GetNumImages())])
            
            plotParams = this.PlotParameters();
            
            if isequaln(aEditedCells, 0)
                % Everything needs to be re-drawn.
                updateGraphics = false;
            else
                % Only the specified cells need to be re-drawn.
                
                % Remove the old graphics object associated with the cells
                % that need to be re-drawn.
                if ~isempty(aEditedCells)
                    graphics = [aEditedCells.graphics];
                    delete(graphics(ishandle(graphics)))
                    for i = 1:length(aEditedCells)
                        aEditedCells(i).graphics = [];
                    end
                end
                
                % Tell DrawXY, DrawXZ and DrawYZ that only the specified
                % cells should be drawn.
                if get(this.fpToggle, 'Value')
                    plotParams.plotCells = aEditedCells;
                else
                    plotParams.plotCells = AreCells(aEditedCells);
                end
                updateGraphics = true;
            end
            
            % Remove old pointers to graphics objects associated with the
            % cells to be plotted. If the existing plots are updated, the
            % objects have been deleted above and otherwise they will be
            % deleted when the axes are cleared in DrawXY.
            for i = 1:length(plotParams.plotCells)
                plotParams.plotCells(i).graphics = [];
            end
            
            % This section selects which fibers should be drawn, based on
            % the selection made with the positive/negative toggle buttons.
            % This is the part that has been added, compared to the Draw3D
            % function in ManualCorrectionPlayer.
            if ~get(this.positiveToggle, 'Value') &&...
                    ~get(this.negativeToggle, 'Value')
                % Do not plot any fibers.
                plotParams.plotCells = [];
            elseif get(this.positiveToggle, 'Value') &&...
                    ~get(this.negativeToggle, 'Value')
                % Plot positive but not negative fibers.
                plotParams.plotCells =...
                    plotParams.plotCells([plotParams.plotCells.positive]);
            elseif ~get(this.positiveToggle, 'Value') &&...
                    get(this.negativeToggle, 'Value')
                % Plot negative but not positive fibers.
                plotParams.plotCells =...
                    plotParams.plotCells(~[plotParams.plotCells.positive]);
            end  % All fibers are plotted if none of the conditions hold.
            
            % Only the xy-plotting function is used for 2D data.
            if this.GetImData().numZ == 1 ||...
                    any(strcmp({'xy', 'all'}, plotParams.display))
                this.DrawXY(plotParams, 'Update', updateGraphics)
            end
            
            if this.GetImData().numZ > 1 &&...
                    any(strcmp({'xz', 'all'}, plotParams.display))
                this.DrawXZ(plotParams, 'Update', updateGraphics)
            end
            
            if this.GetImData().numZ > 1 &&...
                    any(strcmp({'yz', 'all'}, plotParams.display))
                this.DrawYZ(plotParams, 'Update', updateGraphics)
            end
        end
        
        function KeyPressFcn(this, aObj, aEvent)
            % Defines keyboard shortcuts.
            %
            % This function is be the key-press callback of the main
            % figure and of all uicontrols in it, except the text boxes.
            % The function overwrites the function with the same name in
            % ManualCorrectionPlayer. This function removes the callbacks
            % for tools that have been removed and adds callbacks for tools
            % that are specific to editing of fibers, but otherwise the
            % callbacks are the same as those in ManualCorrectionPlayer.
            % Mouse buttons can be linked to functions in the GUI if the
            % mouse buttons are linked to keys on the keyboard using third
            % party software.
            %
            % Inputs:
            % aObj - The object that had focus when the button was
            %        pressed.
            % aEvent - Event structure with information about the key
            %          press.
            
            if ~isempty(aEvent.Modifier) &&...
                    strcmp(aEvent.Modifier{1}, 'control') &&...
                    ~strcmp(aEvent.Key, 'control')
                % Shortcuts where the CTRL-key is held down.
                switch aEvent.Key
                    case 'leftarrow'
                        % Switch to the previous image sequence.
                        this.PreviousButton_Callback(this.previousButton)
                    case 'c'
                        % Select the tool for coloring of a single cell.
                        this.Callback_ToolButton(this.colorButton, 'key')
                    case 'rightarrow'
                        % Switch to the next image sequence.
                        this.NextButton_Callback(this.nextButton)
                    case 's'
                        % Save the edited cells.
                        this.Callback_SaveButton(this.saveButton, [])
                    case 't'
                        % Newly drawn objects become real cells.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Create', 'Create TP (CTRL+T)'), [])
                    case 'f'
                        % Newly drawn objects become false positives.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Create', 'Create FP (CTRL+F)'), [])
                    case 'r'
                        % Break merged objects using k-means.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Merging', 'Re-break (CRTL+R)'), [])
                    case 'm'
                        % Combine merged objects into a single object.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Merging', 'Combine (CRTL+M)'), [])
                    case 'o'
                        % Erase from other objects instead of merging.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Merging', 'Overwrite (CTRL+O)'), [])
                    case 'a'
                        % Allow holes in segmentation editing.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Holes', 'Allow Holes (CTRL+A)'), [])
                    case 'i'
                        % Do not allow holes in segmentation editing.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Holes', 'Fill Holes (CRTL+I)'), [])
                    case 'b'
                        % Change the 3D brush shape to a ball.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Brush', 'Ball (CTRL+B)'), [])
                    case 'd'
                        % Change the 3D brush shape to a disk.
                        this.MenuCallback_DrawChange(GetMenu(this.drawMenu,...
                            'Brush', 'Disk (CTRL+D)'), [])
                end
            else
                % Shortcuts where a single key is pressed.
                switch aEvent.Key
                    case 'c'
                        % Select the tool to change the positive/negative
                        % property of fibers.
                        this.Callback_ToolButton(this.positiveButton, 'key')
                    case 'd'
                        % Select the delete tool.
                        this.Callback_ToolButton(this.deleteButton, 'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'e'
                        % Select the tool to edit segments.
                        this.Callback_ToolButton(this.editSegmentsButton, 'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'end'
                        % Switch to the last frame.
                        this.frame = this.GetNumImages();
                        this.Draw();
                    case 'f'
                        % Snow/hide false positives.
                        this.Callback_ToggleButton(this.fpToggle, 'key')
                    case 'home'
                        % Switch to the first frame.
                        this.frame = 1;
                        this.Draw();
                    case 'leftarrow'
                        % Go to the previous image.
                        this.frame = max(1, this.frame - this.step);
                        this.Draw();
                    case 'n'
                        % Snow/hide negative fibers.
                        this.Callback_ToggleButton(this.negativeToggle, 'key')
                    case 'p'
                        % Snow/hide positive fibers.
                        this.Callback_ToggleButton(this.positiveToggle, 'key')
                    case 'r'
                        % Removes false positives without segments.
                        this.Callback_RemoveFpButton(this.removeFpButton, []);
                    case 'rightarrow'
                        % Go to the next image.
                        this.frame = min(this.GetNumImages(), this.frame + this.step);
                        this.Draw();
                    case 'space'
                        % Turn panning on.
                        if ~this.panning
                            % KeyPressFcn is called repeatedly when the
                            % space bar is held down, and the cursor should
                            % only change on the first call.
                            this.panning = true;
                            setptr(this.mainFigure, 'hand')
                        end
                    case 'm'
                        % Toggle panning.
                        if ~this.panning
                            this.panning = true;
                            setptr(this.mainFigure, 'hand')
                        else
                            this.panning = false;
                            setptr(this.mainFigure, this.currentCursor)
                        end
                    case 'x'
                        % Toggle plotting of trajectories.
                        this.Callback_ToggleButton(this.trajectoryToggle, 'key')
                    case 'v'
                        % Turn on the zoom tool.
                        this.Callback_ToolButton(this.zoomButton, 'key')
                        setptr(this.mainFigure, 'glass')
                    case 'z'
                        % Toggle plotting of outlines.
                        this.Callback_ToggleButton(this.outlineToggle, 'key')
                    otherwise
                        % These shortcuts can be accessed using multiple
                        % keys, which all have the same character.
                        
                        switch aEvent.Character
                            case '+'
                                % Increase brush size.
                                this.WindowScrollWheelFcn(aObj,...
                                    struct('VerticalScrollCount', 1))
                            case '-'
                                % Decrease brush size.
                                this.WindowScrollWheelFcn(aObj,...
                                    struct('VerticalScrollCount', -1))
                        end
                end
            end
        end
        
        function Callback_CategoryToggle(this, aObj, ~)
            % Callback which shows/hides categories of buttons/tools.
            %
            % The function sets the sizes of tools that should be hidden
            % very close to 0, and the sizes of tools that should be shown
            % to their normal values. Then PositionToolbar is called to
            % re-draw the controls. This function overwrites the function
            % with the same name in ManualCorrection.
            %
            % Inputs:
            % aObj - The toggle button which triggered the callback.
            % aEvent - Unused.
            %
            % See also:
            % PositionToolbar
            
            % Choose which tools to resize based on which toggle button was
            % pressed.
            switch aObj
                case this.correctionToolsButton
                    tools = {
                        'deleteButton'
                        'editSegmentsButton'
                        'positiveButton'
                        'removeFpButton'
                        'saveButton'};
                case this.coloringToolsButton
                    tools = {...
                        'colorButton'
                        'colorTextBox'
                        'colorAllButton'
                        'colorAllTextBox'};
                case this.displayToolsButton
                    tools = {...
                        'positiveToggle'
                        'positiveColorTextBox'
                        'negativeToggle'
                        'negativeColorTextBox'
                        'fpToggle'
                        'fpColorTextBox'
                        'trajectoryToggle'
                        'outlineToggle'};
                case this.visualizationToolsButton
                    tools = {'zoomButton'};
            end
            
            if get(aObj, 'Value')
                this.toggleButtons([this.toggleButtons.uicontrol] == aObj).Select();
                
                % Maximize all controls in the group.
                for i = 1:length(tools)
                    this.controlPositions.(tools{i})(2) = 0.008;
                    this.controlPositions.(tools{i})(4) = 0.045;
                    eval(sprintf('set(this.%s, ''Visible'', ''on'')', tools{i}))
                end
            else
                this.toggleButtons([this.toggleButtons.uicontrol] == aObj).Unselect();
                
                % Minimize all controls in the group.
                for i = 1:length(tools)
                    % Approximately 0, since not allowed to be == 0.
                    this.controlPositions.(tools{i})(2) = 0.00000001;
                    this.controlPositions.(tools{i})(4) = 0.00000001;
                    eval(sprintf('set(this.%s, ''Visible'', ''off'')', tools{i}))
                end
            end
            
            this.PositionTools();
            % Only needs to resize when maximizing/showing icons.
            if get(aObj, 'Value')
                this.ResizeButtons();
            end
        end
        
        function ColorCells(this)
            % Changes the cell colors based on the selected coloring.
            %
            % If the Positive/Negative coloring is selected, the function
            % changes the colors of the cells internally. Otherwise the
            % function calls the ColorCells function in
            % ManualCorrectionPlayer.
            
            if strcmp(this.coloring, 'Positive/Negative')
                positiveColor = str2num(get(this.positiveColorTextBox, 'String')); %#ok<ST2NM>
                negativeColor = str2num(get(this.negativeColorTextBox, 'String')); %#ok<ST2NM>
                for i = 1:length(this.cells)
                    c = this.cells(i);
                    if c.positive
                        c.color = positiveColor;
                    else
                        c.color = negativeColor;
                    end
                    c.coloring = 'Positive/Negative';
                end
            else
                this.ColorCells@ManualCorrectionPlayer();
            end
        end
        
        function oEditedCells = EditTracks_Positive(this, aClosestCell)
            % Changes positive fibers to negative and the other way around.
            %
            % The function also changes the colors of the cells to the
            % positive or the negative color. That is done even if the
            % selected coloring is not Positive/Negative, so that the user
            % can see if the clicked fibers are positive or negative after
            % the operation.
            %
            % Inputs:
            % aClosestCell - Cell that the positive-property will be
            %                toggled for.
            
            % Toggle the positive-property of the cell.
            aClosestCell.positive = ~aClosestCell.positive;
            
            % Update the color of the cell.
            positiveColor = str2num(get(this.positiveColorTextBox, 'String')); %#ok<ST2NM>
            negativeColor = str2num(get(this.negativeColorTextBox, 'String')); %#ok<ST2NM>
            if aClosestCell.positive
                aClosestCell.color = positiveColor;
            else
                aClosestCell.color = negativeColor;
            end
            
            oEditedCells = aClosestCell;
        end
        
        function ReSizeAxes(this, varargin)
            % Resizes the axes used for plotting.
            %
            % The function extends the function with the same name in
            % ManualCorrectionPlayer, by making the tree axes invisible.
            
            set(this.treeAxes, 'Visible', 'off')
            this.ReSizeAxes@ZControlPlayer(varargin{:})
        end
        
        function WindowButtonDownFcn(this, aObj, aEvent)
            % Executes when the user clicks somewhere in the figure.
            %
            % The function extends the same function in
            % ManualCorrectionPlayer by calling the button-down-function
            % for track changes when the positiveButton is selected.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            clickedAx = gca;
            
            if clickedAx == this.ax && get(this.positiveButton, 'Value') && ~this.panning
                this.WindowButtonDownFcn_Tracks(aObj, aEvent)
            else
                this.WindowButtonDownFcn@ManualCorrectionPlayer(aObj, aEvent)
            end
        end
        
        function WindowButtonDownFcn_Tracks(this, aObj, ~)
            % Executes when the user clicks to edit the tracks of cells.
            %
            % This function extends the same function in
            % ManualCorrectionPlayer with a case for the positiveButton. If
            % the positiveButton is selected, the function will find the
            % cell closest to the click and send it to EditTracks_Positive
            % which will toggle its positive-property. Otherwise the
            % button-down-function of ManualCorrectionPlayer is called.
            %
            % See also:
            % EditTracks_Positive
            
            if get(this.positiveButton, 'Value')
                % Get the coordinate of the click.
                xy = get(this.ax, 'CurrentPoint');
                x = xy(1,1);
                y = xy(1,2);
                
                if ~InsideAxes(this.ax, x, y)
                    % Do not do anything if the user clicked outside the
                    % axes.
                    return
                end
                
                % Find the fiber closest to the click.
                closestCell = [];
                minDist = inf;
                for cellNum = 1:length(this.cells)
                    dist = norm([x y] -...
                        [this.cells(cellNum).GetCx(1) this.cells(cellNum).GetCy(1)]);
                    if dist < minDist
                        closestCell = this.cells(cellNum);
                        minDist = dist;
                    end
                end
                
                % Do not alter cells far from the clicked point.
                if minDist > 10
                    return
                end
                editedCells = this.EditTracks_Positive(closestCell);
                
                % Update the figure.
                this.Draw('EditedCells', editedCells)
                this.edited = true;
            else
                this.WindowButtonDownFcn_Tracks@ManualCorrectionPlayer(aObj, [])
            end
        end
    end
end