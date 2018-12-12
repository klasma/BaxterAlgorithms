classdef SetFluorescencePlayer < ZControlPlayer
    % GUI to select how different channels are displayed.
    %
    % SetFluorescencePlayer is a player that lets the user sets parameters
    % for how different channels are displayed. Normally this means
    % specifying colors for different fluorescent channels. In addition to
    % selecting colors, the user can specify how pixel values should be
    % mapped to displayed image intensities. This is done by selecting a
    % lower limit, below which all values are displayed as black, and an
    % upper limit above which all values are saturated. Pixel values
    % between the two limits are mapped to image intensities using a linear
    % mapping. All the specified parameters only change the display and the
    % data analysis and does not change how the images are processed.
    %
    % See also:
    % ZControlPlayer
    
    properties
        saveButton                  % Button that saves the settings for the current sequence.
        saveAllButton               % Button that saves the settings for all sequences.
        revertButton                % Goes back to whatever settings are saved in the settings file.
        channelCheckboxes           % Checkboxes which display and hide the different channels.
        colorPickers                % Dropdown menus where colors for the channels can be selected.
        channelGradients            % Gradients showing how pixels values are matched to colors.
        channelMins                 % Labels with the highest pixel values mapped to 0.
        channelMaxes                % Labels with the lowest pixel values mapped to 1 (saturated).
        channelHistograms           % Histograms of pixel intensities.
        gradientPressed = false;    % True if the user is dragging in a gradient.
        histogramPressed = false;   % True if the user is dragging in a histogram.
        channelIndex                % Index of the channel which is being changed.
        sliderObject                % 1 or 2 if the lower or upper limit is changed.
        changed = false;            % Is true if there are un-saved changes.
        closeFunction               % Function executed after closing if new settings have been saved.
        runCloseFunction = false;   % This is set to true when new settings are saved.
        lastDrawnFrame = nan;       % The frame that was drawn last. Used to avoid redrawing histograms.
    end
    
    methods
        function this = SetFluorescencePlayer(aSeqPaths, varargin)
            % Constructs the player object and a figure associated with it.
            %
            % Inputs:
            % aSeqPath - Cell array with all image sequences that can be
            %            played.
            %
            % Property/Value inputs:
            % CloseFunction - Function handle of a function which will be
            %                 executed after the GUI has been closed, if
            %                 new settings have been saved. The default is
            %                 an empty function.
            
            this = this@ZControlPlayer(aSeqPaths, 'Draw', false);
            
            % Parse property/value inputs.
            [this.closeFunction] = GetArgs(...
                {'CloseFunction'},...
                {@()disp([])},...
                true, varargin);
            
            this.CreateGUIPanel();
            
            this.revertButton = uicontrol(...
                'Style', 'togglebutton',...
                'String', 'Revert to Saved',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0 0.1 1 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Toggles loading of settings from file on and off',...
                'Callback', @this.RevertButton_Callback);
            this.saveButton = uicontrol(...
                'Style', 'pushbutton',...
                'String', 'Save for This Sequence',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0 0.05 1 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Saves the settings for this image sequence',...
                'Callback', @this.SaveButton_Callback);
            this.saveAllButton = uicontrol(...
                'Style', 'pushbutton',...
                'String', 'Save for All Sequences',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0 0 1 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Saves the settings for all image sequences',...
                'Callback', @this.SaveAllButton_Callback);
            
            set(this.mainFigure,...
                'WindowButtonDownFcn',      @this.WindowButtonDownFcn,...
                'WindowButtonMotionFcn',    @this.WindowButtonMotionFcn,...
                'WindowButtonUpFcn',        @this.WindowButtonUpFcn,...
                'CloseRequestFcn',          @this.CloseRequestFcn)
            
            this.ReSizeControls();
            this.ReSizeAxes();
            drawnow()  % Display window before the Draw() is done.
            this.Draw()
        end
        
        function ChannelCheckbox_Callback(this, aObj, ~)
            % Checkbox callback that toggles channel visibility.
            %
            % The function ensures that at least one microscope channel is
            % selected and redraws the image when the user clicks one of
            % the channel checkboxes. The function also updates the menu
            % options for selection of channels.
            %
            % Inputs:
            % aObj - Checkbox that was clicked.
            %
            % See also:
            % ChannelMenu_Callback
            
            % The menu that corresponds to the checkbox.
            channelMenu = this.channelMenus([this.channelCheckboxes] == aObj);
            
            if strcmp(get(channelMenu, 'Checked'), 'off')
                % Turn the channel on.
                set(channelMenu, 'Checked', 'on')
            elseif sum(strcmp(get(this.channelMenus, 'Checked'), 'on')) > 1
                % Turn the channel off.
                set(channelMenu, 'Checked', 'off')
            else
                % The last channel cannot be turned off.
                set(aObj, 'Value', true)
            end
            this.Draw()
        end
        
        function ChannelMenu_Callback(this, aObj, ~)
            % Called when the user selects microscope channels.
            %
            % The function ensures that at least one microscope channel is
            % selected and redraws the image when the user clicks one of
            % the channel selection menus. The function has been overloaded
            % here, to update the channel checkboxes on the control panel.
            %
            % Inputs:
            % aObj - Menu object which was clicked.
            %
            % See also:
            % ChannelCheckbox_Callback
            
            % The checkbox that corresponds to the menu.
            channelCheckbox = this.channelCheckboxes([this.channelMenus] == aObj);
            
            if strcmp(get(aObj, 'Checked'), 'off')
                % Turn the channel on.
                set(aObj, 'Checked', 'on')
                set(channelCheckbox, 'Value', true)
            elseif sum(strcmp(get(this.channelMenus, 'Checked'), 'on')) > 1
                % Turn the channel off.
                set(aObj, 'Checked', 'off')
                set(channelCheckbox, 'Value', false)
            end
            this.Draw()
        end
        
        function CloseRequestFcn(this, ~, ~)
            % Prompts the user to save settings when the figure is closed.
            
            if this.changed
                answer = questdlg(...
                    'Settings have been changed. Do you want to save your settings?',...
                    'Fluorescence Settings',...
                    'Yes', 'No', 'Cancel', 'No');
                if isempty(answer)
                    answer = 'Cancel';
                end
                switch answer
                    case 'Yes'
                        this.SaveButton_Callback();
                        delete(this.mainFigure)
                    case 'No'
                        delete(this.mainFigure)
                    case 'Cancel'
                        % Don't close the figure.
                end
            else
                % No settings had been changed.
                delete(this.mainFigure)
            end
            if this.runCloseFunction
                feval(this.closeFunction)
            end
        end
        
        function Color_Picker(this, aObj, ~, aIndex)
            % Callback for the color picking dropdown menu.
            %
            % Inputs:
            % aObj - Handle of the dropdown menu.
            % aIndex - Index of the channel for which the color will be
            %          changed.
            
            this.changed = true;
            
            imData = this.GetImData();
            switch get(aObj, 'Value')
                case 1 % red
                    imData.channelColors{aIndex} = [1 0 0];
                case 2 % orange
                    imData.channelColors{aIndex} = [1 0.5 0];
                case 3 % yellow
                    imData.channelColors{aIndex} = [1 1 0];
                case 4' % green
                    imData.channelColors{aIndex} = [0 1 0];
                case 5 % blue
                    imData.channelColors{aIndex} = [0 0 1];
                case 6 % cyan
                    imData.channelColors{aIndex} = [0 1 1];
                case 7 % magenta
                    imData.channelColors{aIndex} = [1 0 1];
                case 8 %white
                    imData.channelColors{aIndex} = [1 1 1];
                otherwise
                    fprintf('Value out of range')
            end
            this.UpdateGUIPanel();
            this.Draw();
        end
        
        function CreateGUIPanel(this, ~, ~)
            % Generates the control objects for the different channels.
            %
            % The method will remove existing controls associated with
            % channels, if there are any.
            
            % Remove existing controls from the GUI panel.
            % The save and revert buttons are kept.
            children = get(this.controlPanel, 'children');
            for i = 1:length(children)
                if children(i) ~= this.saveButton &&...
                        children(i) ~= this.saveAllButton &&...
                        children(i) ~= this.revertButton &&...
                        ishandle(children(i))
                    delete(children(i))
                end
            end
            
            imData = this.GetImData();
            
            % Clear variables that hold old controls.
            this.channelCheckboxes = [];
            this.channelMins = [];
            this.channelMaxes = [];
            this.colorPickers = [];
            this.channelGradients = cell(1, length(imData.channelNames));
            this.channelHistograms = cell(1, length(imData.channelNames));
            
            % Create new controls.
            for i = 1:length(imData.channelNames)
                this.channelCheckboxes(i) = uicontrol(...
                    'Style', 'checkbox',...
                    'Parent', this.controlPanel,...
                    'Units', 'normalized',...
                    'BackgroundColor', get(this.mainFigure, 'color'),...
                    'Position', [0 0.96-(i-1)*0.2 0.1 0.02],...
                    'Callback', @this.ChannelCheckbox_Callback);
                uicontrol(...
                    'Style', 'text',...
                    'Parent', this.controlPanel,...
                    'Units', 'normalized',...
                    'HorizontalAlignment', 'left',...
                    'BackgroundColor', get(this.mainFigure, 'color'),...
                    'Position', [0.15 0.96-(i-1)*0.2 0.35 0.02],...
                    'String', imData.channelNames{i});
                % Gradients
                ax = axes('Parent', this.controlPanel,...
                    'Units', 'normalized',...
                    'Position', [0.025 0.88-(i-1)*0.2 0.95 0.08]);
                this.channelGradients{i} = ChannelGradient(ax, imData.channelColors{i});
                this.channelMins(i) = uicontrol(...
                    'Style', 'text',...
                    'Parent', this.controlPanel,...
                    'Units', 'normalized',...
                    'BackgroundColor', get(this.mainFigure, 'color'),...
                    'HorizontalAlignment', 'left',...
                    'Position', [0 0.86-(i-1)*0.2 0.5 0.02],...
                    'String', sprintf('Min: %.2f', imData.channelMin(i)));
                this.channelMaxes(i) = uicontrol(...
                    'Style', 'text',...
                    'Parent', this.controlPanel,...
                    'Units', 'normalized',...
                    'BackgroundColor', get(this.mainFigure, 'color'),...
                    'HorizontalAlignment', 'right',...
                    'Position', [0.5 0.86-(i-1)*0.2 0.5 0.02],...
                    'String', sprintf('Max: %.2f ', imData.channelMax(i)));
                % Histograms
                hist = axes('Parent', this.controlPanel,...
                    'Units', 'normalized',...
                    'Position', [0.025 0.80-(i-1)*0.2 0.95 0.08],...
                    'Color', 'none');
                im = imData.GetDoubleImage(this.frame, 'Channel', i)/255;
                this.channelHistograms{i} =...
                    ChannelHistogram(hist, im, imData.channelColors{i});
                this.colorPickers(i) = uicontrol(...
                    'Style', 'popupmenu',...
                    'Parent', this.controlPanel,...
                    'String', 'red|orange|yellow|green|blue|cyan|magenta|white',...
                    'Units', 'normalized',...
                    'Position', [0.5 0.9675-(i-1)*0.2 0.5 0.02],...
                    'Callback', {@this.Color_Picker, i});
                
                
                % Set default values for controls.
                
                % Set default value for checkboxes.
                if strcmp(get(this.channelMenus(i), 'Checked'), 'off')
                    set(this.channelCheckBoxes(i), 'Value', 0)
                else
                    set(this.channelCheckboxes(i), 'Value', 1)
                end
                
                % Set default value for the color picker dropdown menu.
                if isequal(imData.channelColors{i}, [1 0 0])
                    set(this.colorPickers(i), 'Value', 1)
                elseif isequal(imData.channelColors{i}, [1 0.5 0])
                    set(this.colorPickers(i), 'Value', 2)
                elseif isequal(imData.channelColors{i}, [1 1 0])
                    set(this.colorPickers(i), 'Value', 3)
                elseif isequal(imData.channelColors{i}, [0 1 0])
                    set(this.colorPickers(i), 'Value', 4)
                elseif isequal(imData.channelColors{i}, [0 0 1])
                    set(this.colorPickers(i), 'Value', 5)
                elseif isequal(imData.channelColors{i}, [0 1 1])
                    set(this.colorPickers(i), 'Value', 6)
                elseif isequal(imData.channelColors{i}, [1 0 1])
                    set(this.colorPickers(i), 'Value', 7)
                elseif isequal(imData.channelColors{i}, [1 1 1])
                    set(this.colorPickers(i), 'Value', 8)
                else
                    set(this.colorPickers(i), 'Value', i)
                end
                
                % Set default values for the gradient controls.
                this.channelGradients{i}.ShiftStartGradient(imData.channelMin(i)*100)
                this.channelGradients{i}.ShiftEndGradient(imData.channelMax(i)*100)
                
                % Set default values for the histogram controls.
                this.channelHistograms{i}.ShiftMinSlider(imData.channelMin(i))
                this.channelHistograms{i}.ShiftMaxSlider(imData.channelMax(i))
            end
        end
        
        function Draw(this)
            % Displays an image with up to date fluorescence settings.
            
            this.Draw@ZControlPlayer()
            if this.lastDrawnFrame ~= this.frame
                for i = 1:length(this.GetImData().channelNames)
                    im = this.GetImData().GetDoubleImage(this.frame, 'Channel', i)/255;
                    this.channelHistograms{i}.UpdateHistogram(im);
                end
                this.lastDrawnFrame = this.frame;
            end
        end
        
        function [oName] = GetName(~)
            % Returns the name of the player.
            %
            % The name will be displayed in the title of the main window
            % together with the path of the current image.
            
            oName = 'Fluorescence display';
        end
        
        function RevertButton_Callback(this, ~, ~)
            % Reverts to saved settings when the revert button is pressed.
            
            % Remove focus from the control.
            set(this.revertButton, 'Enable', 'off')
            drawnow()
            set(this.revertButton, 'Enable', 'on')
            
            if ~get(this.revertButton, 'value')
                % Don't do anything when the button is deselected.
                return
            end
            
            this.imDatas{this.seqIndex} = ImageData(this.seqPaths{this.seqIndex});
            this.changed = false;
            this.UpdateGUIPanel();
            this.Draw();
        end
        
        function SaveAllButton_Callback(this, ~, ~)
            % Saves the current settings for all sequences.
            
            % Remove focus from the control.
            set(this.saveAllButton, 'Enable', 'off')
            drawnow()
            set(this.saveAllButton, 'Enable', 'on')
            
            setptr(this.mainFigure, 'watch')
            drawnow()
            
            imData = this.GetImData();
            
            % Create colon separated strings for colors, mins and maxes.
            colorStr = num2str(imData.channelColors{1});
            minStr = num2str(imData.channelMin(1));
            maxStr = num2str(imData.channelMax(1));
            for i = 2:length(imData.channelNames)
                colorStr = sprintf('%s:%s', colorStr, num2str(imData.channelColors{i}));
                minStr = sprintf('%s:%s', minStr, num2str(imData.channelMin(i)));
                maxStr = sprintf('%s:%s', maxStr, num2str(imData.channelMax(i)));
            end
            
            % Generate variables for saving of settings.
            spreadSheets = {};
            exPaths = {};
            skippedSequences = {};
            for i = 1:length(this.seqPaths)
                if ~isequal(this.GetImData(i).channelNames, imData.channelNames)
                    skippedSequences = [skippedSequences, this.GetSeqDir(i)]; %#ok<AGROW>
                    continue
                end
                
                exPath = this.GetExPath(i);
                index = find(strcmp(exPaths, exPath));
                if isempty(index)
                    index = length(exPaths) + 1;
                    exPaths{index} = exPath; %#ok<AGROW>
                    spreadSheets{index} = ReadSettings(exPath); %#ok<AGROW>
                end
                
                spreadSheets{index} = SetSeqSettings(...
                    spreadSheets{index},...
                    this.GetSeqDir(i),...
                    'ChannelColors', colorStr,...
                    'ChannelMin', minStr,...
                    'ChannelMax', maxStr); %#ok<AGROW>
                
                % Update the ImageData objects accordingly.
                if ~isempty(this.imDatas{i})
                    this.imDatas{i} = ImageData(this.seqPaths{i});
                end
            end
            
            % Save the settings to csv-files.
            for i = 1:length(exPaths)
                WriteSettings(exPaths{i}, spreadSheets{i})
            end
            
            this.changed = false;
            this.runCloseFunction = true;
            fprintf('Done saving fluorescence parameters\n')
            setptr(this.mainFigure, 'arrow')
            
            % Display a warning message if sequences were skipped.
            if ~isempty(skippedSequences)
                warndlg([
                    skippedSequences,...
                    {''},...
                    {['The new settings were not applied to the above '...
                    'sequences, because they do not have the same '...
                    'channel names as the current sequence.']}
                    ],...
                    'Skipped saving settings for sequences')
            end
        end
        
        function SaveButton_Callback(this, ~, ~)
            % Saves the current settings for the current sequence.
            
            % Remove focus from the control.
            set(this.saveButton, 'Enable', 'off')
            drawnow()
            set(this.saveButton, 'Enable', 'on')
            
            setptr(this.mainFigure, 'watch')
            drawnow()
            
            % Create colon separated strings for colors, mins and maxes.
            imData = this.GetImData();
            colorStr = num2str(imData.channelColors{1});
            minStr = num2str(imData.channelMin(1));
            maxStr = num2str(imData.channelMax(1));
            for i = 2:length(imData.channelNames)
                colorStr = sprintf('%s:%s', colorStr, num2str(imData.channelColors{i}));
                minStr = sprintf('%s:%s', minStr, num2str(imData.channelMin(i)));
                maxStr = sprintf('%s:%s', maxStr, num2str(imData.channelMax(i)));
            end
            
            % Write all settings to the settings files.
            WriteSeqSettings(imData.seqPath,...
                'ChannelColors', colorStr,...
                'ChannelMin', minStr,...
                'ChannelMax', maxStr)
            
            this.changed = false;
            this.runCloseFunction = true;
            fprintf('Done saving fluorescence parameters\n')
            setptr(this.mainFigure, 'arrow')
        end
        
        function SwitchSequence(this, aIndex)
            % Called when a new image sequence is opened.
            %
            % The function is overloaded here to update the controls for
            % fluorescence settings. When appropriate, the settings from
            % the previous image sequence are transferred to the new
            % sequence. The user will have the opportunity to save unsaved
            % settings.
            %
            % Inputs:
            % aIndex - Index of the image sequence that the user is
            %          switching to.
            
            % All histograms need to be redrawn.
            this.lastDrawnFrame = nan;
            
            % If the previous and the new image sequence have different
            % channels defined, all the controls need to be recreated.
            recreateControls = ~isequal(this.GetImData().channelNames,...
                this.GetImData(aIndex).channelNames);
            
            if recreateControls || get(this.revertButton, 'value')
                % Ask if the user wants to save unsaved changes.
                if this.changed
                    answer = questdlg(...
                        ['Settings are about to be loaded from a file. '...
                        'Do you want to save your settings?'],...
                        'Fluorescence Settings',...
                        'Yes', 'No', 'Cancel', 'No');
                    if isempty(answer)
                        answer = 'Cancel';
                    end
                    switch answer
                        case 'Yes'
                            this.SaveButton_Callback();
                            this.changed = false;
                        case 'No'
                            this.changed = false;
                        case 'Cancel'
                            return
                    end
                end
            end
            
            oldImData = this.GetImData();
            this.SwitchSequence@ZControlPlayer(aIndex, 'Draw', false);
            
            if recreateControls
                % All controls need to be redrawn because the channels are
                % not the same for the two image sequences.
                this.imDatas{this.seqIndex} = ImageData(this.GetSeqPath());
                this.CreateGUIPanel()
            elseif get(this.revertButton, 'value')
                % Settings are loaded from file, but the controls are kept.
                this.imDatas{this.seqIndex} = ImageData(this.GetSeqPath());
                this.UpdateGUIPanel();
            else
                % The channels are the same for both sequences and the
                % settings are copied from the previous sequence to the new
                % sequence.
                imData = this.GetImData();
                for i = 1:length(imData.channelNames)
                    imData.channelColors{i} = oldImData.channelColors{i};
                    imData.channelMin(i) = oldImData.channelMin(i);
                    imData.channelMax(i) = oldImData.channelMax(i);
                end
            end
            
            % Necessary to allow the image size to change between
            % sequences.
            xlim(this.ax, [0 this.GetImData().imageWidth]+0.5)
            ylim(this.ax, [0 this.GetImData().imageHeight]+0.5)
            xlim(this.axXZ, [0 this.GetImData().imageWidth]+0.5)
            ylim(this.axXZ, [0 this.GetImData().numZ]+0.5)
            xlim(this.axYZ, [0 this.GetImData().numZ]+0.5)
            ylim(this.axYZ, [0 this.GetImData().imageHeight]+0.5)
            
            this.ReSizeAxes()
            this.ReSizeControls()
            this.Draw()
        end
        
        function UpdateGUIPanel(this, ~, ~)
            % Updates UI controls to match the current ImageData object.
            
            imData = this.GetImData();
            for i = 1:length(imData.channelNames)
                this.channelGradients{i}.endColor = imData.channelColors{i};
                this.channelGradients{i}.ShiftStartGradient(imData.channelMin(i)*100)
                this.channelGradients{i}.ShiftEndGradient(imData.channelMax(i)*100);
                
                set(this.channelMins(i),...
                    'String', sprintf('Min: %.2f', imData.channelMin(i)))
                set(this.channelMaxes(i),...
                    'String', sprintf('Max: %.2f ', imData.channelMax(i)))
                
                im = imData.GetDoubleImage(this.frame, 'Channel', i)/255;
                
                this.channelHistograms{i}.color = imData.channelColors{i};
                this.channelHistograms{i}.UpdateHistogram(im);
                this.channelHistograms{i}.ShiftMinSlider(imData.channelMin(i))
                this.channelHistograms{i}.ShiftMaxSlider(imData.channelMax(i))
                
                if isequal(imData.channelColors{i}, [1 0 0])
                    set(this.colorPickers(i), 'Value', 1)
                elseif isequal(imData.channelColors{i}, [1 0.5 0])
                    set(this.colorPickers(i), 'Value', 2)
                elseif isequal(imData.channelColors{i}, [1 1 0])
                    set(this.colorPickers(i), 'Value', 3)
                elseif isequal(imData.channelColors{i}, [0 1 0])
                    set(this.colorPickers(i), 'Value', 4)
                elseif isequal(imData.channelColors{i}, [0 0 1])
                    set(this.colorPickers(i), 'Value', 5)
                elseif isequal(imData.channelColors{i}, [0 1 1])
                    set(this.colorPickers(i), 'Value', 6)
                elseif isequal(imData.channelColors{i}, [1 0 1])
                    set(this.colorPickers(i), 'Value', 7)
                elseif isequal(imData.channelColors{i}, [1 1 1])
                    set(this.colorPickers(i), 'Value', 8)
                else
                    set(this.colorPickers(i), 'Value', i)
                end
            end
        end
        
        function WindowButtonDownFcn(this, aObj, ~)
            % Called when the user clicks either a gradient or a histogram.
            %
            % The function only figures out which axes is pressed and sets
            % properties so that the WindowButtonMotionFcn will change and
            % redraw the UI controls and the image properly.
            
            clickedAx = gca;
            
            % Check if the user clicked in one of the image axes.
            if clickedAx == this.ax ||...
                    clickedAx == this.axXZ || clickedAx == this.axYZ
                this.WindowButtonDownFcn@ZControlPlayer(aObj, [])
                return
            end
            
            % Check if user clicked in a gradient.
            for i = 1:length(this.channelGradients)
                xy = get(this.channelGradients{i}.axes, 'CurrentPoint');
                x = xy(1,1);
                y = xy(1,2);
                if ~InsideAxes(this.channelGradients{i}.axes, x, y)
                    continue
                end
                
                if abs(x - this.channelGradients{i}.minIndex) <...
                        abs(x - this.channelGradients{i}.maxIndex)
                    % Refers to the min index slider
                    this.sliderObject = 1;
                else
                    % Refers to the max index slider
                    this.sliderObject = 2;
                end
                this.gradientPressed = true;
                setptr(this.mainFigure, 'left')
                this.channelIndex = i;
                this.WindowButtonMotionFcn();
                this.changed = true;
                return
            end
            
            % Check if user clicked in a histogram.
            for i = 1:length(this.channelHistograms)
                xy = get(this.channelHistograms{i}.axes, 'CurrentPoint');
                x = xy(1,1);
                y = xy(1,2);
                if ~InsideAxes(this.channelHistograms{i}.axes, x, y)
                    continue
                end
                
                if abs(x - this.channelHistograms{i}.minIndex) <...
                        abs(x - this.channelHistograms{i}.maxIndex)
                    % Refers to the min index slider
                    this.sliderObject = 1;
                    
                else
                    % Refers to the max index slider
                    this.sliderObject = 2;
                end
                this.histogramPressed = true;
                setptr(this.mainFigure, 'left')
                this.channelIndex = i;
                this.WindowButtonMotionFcn();
                this.changed = true;
                return
            end
        end
        
        function WindowButtonMotionFcn(this, ~, ~)
            % Called when users click or drag in a gradient or histogram.
            %
            % The gradient itself dynamically changes as the slider moves,
            % and it will also move the slider of the histogram, and vice
            % versa.
            
            % Check if the user clicked in one of the image axes.
            clickedAx = gca;
            if clickedAx == this.ax ||...
                    clickedAx == this.axXZ || clickedAx == this.axYZ
                this.WindowButtonMotionFcn@ZControlPlayer([], [])
                return
            end
            
            % Makes sure the user already clicked inside either the
            % gradient or histogram axes.
            if this.gradientPressed || this.histogramPressed
                % Find mouse location.
                if this.gradientPressed
                    xy = get(this.channelGradients{this.channelIndex}.axes,...
                        'CurrentPoint');
                elseif this.histogramPressed
                    xy = get(this.channelHistograms{this.channelIndex}.axes,...
                        'CurrentPoint');
                end
                x = xy(1,1);
                y = xy(1,2);
                
                imData = this.GetImData();
                % Multiplier is necessary because the gradient is plotted
                % from a 1 to 100 scale, while the histogram is plotted
                % from a 0 to 1 scale.
                if this.gradientPressed
                    multiplier = 1;
                elseif this.histogramPressed
                    multiplier = 100;
                end
                
                % If the min index slider is being dragged.
                if this.sliderObject == 1
                    % If the mouse is no longer inside the axes, snap the
                    % min index to 0.
                    if ~InsideAxes(this.channelGradients{this.channelIndex}.axes, x, y) &&...
                            ~InsideAxes(this.channelHistograms{this.channelIndex}.axes, x, y)
                        % 1 is the minimum value for the gradient.
                        this.channelGradients{this.channelIndex}.ShiftStartGradient(1)
                        % 0.1 is the minimum value for the histogram.
                        this.channelHistograms{this.channelIndex}.ShiftMinSlider(0.01)
                        imData.channelMin(this.channelIndex) = 0;
                    elseif x*multiplier < this.channelGradients{this.channelIndex}.maxIndex
                        % Multiplier is necessary to sync the gradient and
                        % histogram sliders.
                        this.channelGradients{this.channelIndex}.ShiftStartGradient(x*multiplier)
                        this.channelHistograms{this.channelIndex}.ShiftMinSlider(x/(100/multiplier))
                        imData.channelMin(this.channelIndex) = x/(100/multiplier);
                    end
                    set(this.channelMins(this.channelIndex),...
                        'String', sprintf('Min: %.2f', imData.channelMin(this.channelIndex)))
                    % If the max index slider is being dragged.
                elseif this.sliderObject == 2
                    % If the mouse is no longer inside the axes, snap the
                    % max index to 1.
                    if ~InsideAxes(this.channelGradients{this.channelIndex}.axes, x, y) &&...
                            ~InsideAxes(this.channelHistograms{this.channelIndex}.axes, x, y)
                        % 100 is the maximum value for the gradient.
                        this.channelGradients{this.channelIndex}.ShiftEndGradient(100)
                        % .99 is the maximum value for the histogram.
                        this.channelHistograms{this.channelIndex}.ShiftMaxSlider(.99)
                        imData.channelMax(this.channelIndex) = 1;
                    elseif x*multiplier > this.channelGradients{this.channelIndex}.minIndex
                        this.channelGradients{this.channelIndex}.ShiftEndGradient(x*multiplier)
                        this.channelHistograms{this.channelIndex}.ShiftMaxSlider(x/(100/multiplier))
                        imData.channelMax(this.channelIndex) = x/(100/multiplier);
                    end
                    set(this.channelMaxes(this.channelIndex),...
                        'String', sprintf('Max: %.2f ', imData.channelMax(this.channelIndex)))
                else
                    warning('The property sliderObject is not 1 or 2.')
                end
                this.Draw();
            end
        end
        
        function WindowButtonUpFcn(this, ~, ~)
            % Called when the user releases the mouse button.
            %
            % This stops the process of changing fluorescence limits for a
            % channel.
            
            % Check if the user clicked in one of the image axes.
            clickedAx = gca;
            if clickedAx == this.ax ||...
                    clickedAx == this.axXZ || clickedAx == this.axYZ
                this.WindowButtonUpFcn@ZControlPlayer([], [])
                return
            end
            
            % The user no longer is holding down the mouse in either axes.
            this.gradientPressed = false;
            this.histogramPressed = false;
            setptr(this.mainFigure, 'arrow')
        end
    end
end