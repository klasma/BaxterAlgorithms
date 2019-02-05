classdef SettingsPanel < handle
    % Panel with control objects where the user can specify settings.
    %
    % The settings panel generates a set of control objects, such as
    % textboxes, popupmenus and checkboxes, where the user can specify
    % values for a set of settings.
    %
    % The settings panel takes a Map with Setting objects as input.
    % The the values for the settings can either be taken as the default
    % values of the Setting objects, or be specified using a Map
    % object with the same fields as the Map with settings, but with
    % values instead of Setting objects. One can also replace the
    % Map object by objects of the sub-classes ImageParameters and
    % ImageData to let the user adjust all settings associated with an
    % image sequence. The panel can also handle arrays of ImageParameters
    % or ImageData objects, so that settings can be specified for multiple
    % image sequences at the same time. If a setting is different for
    % different image sequences, the corresponding value in the settings
    % panel will be '*****MIXED*****'. Checkboxes can currently not be used
    % when there are multiple sets of values. The settings of most GUIs can
    % be displayed in a SettingsPanel, by defining a Map with
    % Setting objects which represent the different controls.
    %
    % The types of the different control objects are specified in the type
    % properties of the Setting objects. The types that can be used are the
    % following:
    % 'char' - Textbox with strings.
    % 'numeric' - Textbox with numeric data.
    % 'path' - Textbox with the path of a directory. The text box has a
    %          browse button next to it which opens a directory selection
    %          GUI.
    % 'check - Checkbox (does not work for arrays of parameter sets).
    % 'choice' - Popupmenu.
    % 'list' - List where multiple strings can be selected.
    % 'button' - Pushbutton (not used to represent a setting).
    %
    % Different settings can be give different levels (for example 'basic',
    % 'advanced' and 'development'), so that subsets of the settings, with
    % different levels of complexity, can be displayed.In the same way,
    % settings can be given different categories, so that settings which
    % are not of interest to the user can be hidden. For popupmenus and
    % lists, the alternatives can also have different levels of complexity.
    % The alternatives do not have categories though. Depending on the
    % visiblefunction property of the settings option, settings can be
    % hidden when other settings have certain values. The idea is to hide
    % all setting which don't affect the processing. Invisible controls
    % are not updated and may contain old values, but the Map
    % objects of parameter values will always have up to date values. If
    % the checkfunction properties of the settings are defined properly,
    % it will not be possible to input invalid values for the setting. When
    % an invalid setting is specified, the SettingsPanel returns the
    % setting to its previous value.
    %
    % See also:
    % Setting, Map, ImageSetting, ImageData, SettingsGUI,
    % SegmentationPlayer, AllSettings
    
    properties
        panel               % uipanel where the controls are put.
        controls            % Array of control objects for settings.
        browseButtons       % Array of push buttons for selection of paths.
        texts               % Array of text labels for settings.
        types               % Cell array of control object types.
        labels              % Cell array of strings with settings id:s.
        split               % Fraction of the panel width used for text labels.
        minList             % Minimum number of rows in a list box.
        maxList             % Maximum number of rows in a list box.
        maxRowHeight        % Maximum fraction of panel height used by a control row.
        settings            % Map with Setting objects.
        parameters          % Map with values for the settings.
        shownLevels         % The settings levels currently displayed.
        shownCategories     % The setting categories currently displayed.
        removeFocus         % If this is true, the controls will never get focus.
    end
    
    methods
        function this = SettingsPanel(aSettings, varargin)
            % Generates a SettingsPanel ready for user input.
            %
            % There is no need to call any other functions when a
            % SettingsPanel is created.
            %
            % Inputs:
            % aSettings - Map with Setting objects, or a struct where
            %             each field is a Setting. The struct is directly
            %             converted to a Map.
            %
            % Property/Value inputs (defaults in parenthesis):
            % Parent - Parent object where the panel will be placed
            %          (the current figure).
            % Position - Position of panel in the parent object
            %            ([0 0 1 1]).
            % Parameters - Map or struct with values for the
            %              settings in aSettings (Map with the
            %              default values of the settings).
            % Categories - The setting categories shown at creation
            %              ('unspecified' which is the default category for
            %              a Setting object).
            % Levels - The setting levels shown at creation ('basic').
            % Split - Fraction of the panel width used for text label
            %         (0.5).
            % MinList - Minimum number of rows in a list box (1).
            % MaxList - Maximum number of rows in a list box (10).
            % MaxRowHeight - Maximum fraction of panel height used by a
            %                control row (1).
            % RemoveFocus - If this is set to true, the controls will not
            %               get focus when the user enters new values. This
            %               prevents keyboard keys from affecting the
            %               controls. This is necessary if keys that affect
            %               controls are used as shortcuts. The controls
            %               will flicker when the new values are entered,
            %               and therefore this feature is not used by
            %               default.
            
            % Get additional inputs.
            [this.parameters, this.shownCategories, this.shownLevels,...
                this.split, this.minList, this.maxList,...
                this.maxRowHeight, aParent, aPosition, this.removeFocus] =...
                GetArgs({'Parameters', 'Categories', 'Levels', 'Split',...
                'MinList', 'MaxList', 'MaxRowHeight', 'Parent',...
                'Position', 'RemoveFocus'},...
                {[], 'unspecified', 'basic', 0.5, 1, 10, 1, gcf(),...
                [0 0 1 1], false},...
                true, varargin);
            
            this.panel = uipanel(...
                'Parent', aParent,...
                'Units', 'normalized',...
                'Position', aPosition,...
                'BackgroundColor', [0.8 0.8 0.8]);
            
            if isstruct(aSettings)
                % Convert a struct input to a Map.
                this.settings = Map(aSettings);
            else
                this.settings = aSettings;
            end
            
            if isempty(this.parameters)
                % If settings values are not specified, the default
                % settings are used.
                this.parameters = Map();
                for i = 1:this.settings.Size()
                    s = this.settings.Get(i);
                    this.parameters.Add(this.settings.GetLabel(i), s.default);
                end
            elseif isstruct(this.parameters)
                % Convert a struct input to a Map.
                this.parameters = Map(this.parameters);
            end
            
            this.labels = this.settings.GetLabels();
            
            this.types = cell(this.settings.Size(),1);
            for i = 1:this.settings.Size()
                this.types{i} = this.settings.Get(i).type;
            end
            
            % Generate control objects for all settings. The visibilities
            % and positions are set in SetVisible.
            for i = 1:length(this.labels)
                value = this.GetParameter(this.labels{i});
                s = this.settings.Get(this.labels{i});
                
                % Create a text label explaining the setting.
                this.texts(i) = uicontrol(....
                    'Parent', this.panel,...
                    'BackgroundColor', [0.8 0.8 0.8],...
                    'HorizontalAlignment', 'left',...
                    'Units', 'Normalized',...
                    'Style', 'Text',...
                    'String', s.name,...
                    'TooltipString', s.tooltip);
                
                switch this.types{i}
                    case {'char', 'numeric'}
                        this.controls(i) = uicontrol(...
                            'Parent', this.panel,...
                            'BackgroundColor', 'white',...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Style', 'Edit',...
                            'String', num2str(value),...
                            'Interruptible', 'off',...
                            'TooltipString', s.tooltip,...
                            'Callback', {@this.CheckCallback,...
                            @s.Check, @s.Callback});
                    case 'check'
                        this.controls(i) = uicontrol(...
                            'Parent', this.panel,...
                            'BackgroundColor', get(this.panel, 'BackgroundColor'),...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Style', 'checkbox',...
                            'Value', value,...
                            'Interruptible', 'off',...
                            'TooltipString', s.tooltip,...
                            'Callback', {@this.CheckCallback,...
                            @s.Check, @s.Callback});
                    case 'choice'
                        alts = this.GetAlternatives(this.labels{i}, this.shownLevels);
                        this.controls(i) = uicontrol(...
                            'Parent', this.panel,...
                            'BackgroundColor', 'white',...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Style', 'popupmenu',...
                            'String', alts,...
                            'Value', find(strcmp(alts, value),1),...
                            'Interruptible', 'off',...
                            'TooltipString', s.tooltip,...
                            'Callback', {@this.CheckCallback,...
                            @s.Check, @s.Callback});
                    case 'list'
                        alts = this.GetAlternatives(this.labels{i}, this.shownLevels);
                        sel = find(ismember(alts, value));
                        this.controls(i) = uicontrol(...
                            'Min', 0,...
                            'Max', 2,...
                            'Parent', this.panel,...
                            'BackgroundColor', 'white',...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Style', 'listbox',...
                            'String', alts,...
                            'Value', sel,...
                            'Interruptible', 'off',...
                            'TooltipString', s.tooltip,...
                            'Callback', {@this.CheckCallback,...
                            @s.Check, @s.Callback});
                    case 'button'
                        this.controls(i) = uicontrol(...
                            'Parent', this.panel,...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Style', 'pushbutton',...
                            'String', s.name,...
                            'Interruptible', 'off',...
                            'TooltipString', s.tooltip,...
                            'Callback', @s.Callback);
                    case 'path'
                        this.controls(i) = uicontrol(...
                            'Parent', this.panel,...
                            'BackgroundColor', 'white',...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Style', 'Edit',...
                            'String', num2str(value),...
                            'Interruptible', 'off',...
                            'TooltipString', s.tooltip,...
                            'Callback', {@this.CheckCallback,...
                            @s.Check, @s.Callback});
                        this.browseButtons(i) = uicontrol(...
                            'Parent', this.panel,...
                            'Style', 'pushbutton',...
                            'String', 'browse',...
                            'HorizontalAlignment', 'left',...
                            'Units', 'Normalized',...
                            'Interruptible', 'off',...
                            'Callback', {@this.BrowseCallback, this.labels{i}});
                    otherwise
                        error(['The inputed control type ''%s'' is not '...
                            'recognized by SettingsPanel'], this.types{i})
                end
            end
            
            this.SetVisible(this.shownCategories, this.shownLevels);
        end
        
        function BrowseCallback(this, ~, ~, aLabel)
            % Called when the browse button of a path textbox is pushed.
            %
            % The function opens a folder selection GUI.
            %
            % Inputs:
            % aLabel - Label of the 'path' field that the browse button is
            %          associated with.
            
            % Start in whatever directory is currently selected. The
            % selected directory may not exist though and therefore we
            % start in the lowest super-directory which exists. If even the
            % drive letter is incorrect, we will end up in the current
            % directory.
            startPath = this.GetValue(aLabel);
            while ~exist(startPath, 'dir') &&...
                    ~strcmpi(fileparts(startPath), startPath)
                startPath = fileparts(startPath);
            end
            
            % Let the user select a directory.
            selectedPath = UiGetMultipleDirs(...
                'Title', 'Select a directory',...
                'Path', startPath,...
                'MultiSelect', false);
            
            % Change to the selected directory.
            if ~isempty(selectedPath)
                this.SetParameter(aLabel, selectedPath)
                this.SetVisible(this.shownCategories, this.shownLevels);
            end
        end
        
        function Enable(this, aLabel, aState)
            % Sets the 'Enable' property of a control and its label.
            %
            % This function can be used to enable or disable settings
            % without hiding them. For settings of the 'path' type, the
            % 'Enable' property will also be set for the browse-button.
            %
            % Inputs:
            % aLabel - Setting id.
            % aState - The value that the 'Enable' property of the control
            %          and its label will be set to. The valid alternatives
            %          are 'on', 'off', and 'inactive'.
            
            index = find(strcmpi(this.labels, aLabel), 1);
            set(this.texts(index), 'Enable', aState)
            set(this.controls(index), 'Enable', aState)
            if strcmpi(this.types{index}, 'path')
                set(this.browseButtons(index), 'Enable', aState)
            end
        end
        
        function oAlternatives = GetAlternatives(this, aLabel, aLevel)
            % Returns all alternatives of a popupmenu or list setting.
            %
            % The alternative '*****MIXED*****' will be included if the
            % SettingsPanel has multiple parameter sets with different
            % values for this particular setting. If the different
            % parameter sets result in different alternatives, only the
            % alternatives common to all of them will be returned.
            %
            % Inputs:
            % aLabel - Setting id.
            % aLevel - The complexity level(s) for which to return
            %          alternatives. If this input is 'all', alternatives
            %          from all complexity levels will be returned. The
            %          input can be a cell array with multiple levels.
            
            if length(this.parameters) == 1
                % Just return the alternatives if there is a single
                % parameter set.
                oAlternatives = this.settings.Get(aLabel).GetAlternatives(...
                    this.parameters, aLevel);
            else
                % Find all alternatives for all parameter sets.
                allAlternatives = {};
                for i = 1:length(this.parameters)
                    allAlternatives = [allAlternatives
                        this.settings.Get(aLabel).GetAlternatives(this.parameters(i), aLevel)]; %#ok<AGROW>
                end
                
                % Determine which alternatives are included for all parameter
                % sets, by counting the number of occurrences of each
                % alternative. This assumes that alternatives can not be
                % repeated.
                oAlternatives = {};
                candidates = this.settings.Get(aLabel).GetAlternatives(this.parameters(1), aLevel);
                for i = 1:length(candidates)
                    if sum(strcmp(allAlternatives, candidates{i})) == length(this.parameters)
                        oAlternatives = [oAlternatives; candidates(i)]; %#ok<AGROW>
                    end
                end
                
                % Add the mixed alternative if the parameter sets have
                % different values for the setting.
                if strcmp(this.GetParameter(aLabel), '*****MIXED*****')
                    oAlternatives = [oAlternatives; {'*****MIXED*****'}];
                end
            end
        end
        
        function oControl = GetControl(this, aLabel)
            % Returns the control object corresponding to a setting.
            %
            % Inputs:
            % aLabel - Setting id.
            
            index = find(strcmpi(this.labels, aLabel), 1);
            assert(~isempty(index), 'There is no such label in the SettingsPanel')
            oControl = this.controls(index);
        end
        
        function oIndex = GetIndex(this, aLabel)
            % Get the selected indices for a popupmenu or list setting.
            %
            % The outputted index does not necessarily correspond to an
            % index in the alternatives for a setting. If only a subset of
            % the settings are shown, you need to get the set of shown
            % alternatives using GetAlternatives.
            %
            % Inputs:
            % aLabel - Setting id.
            %
            % Outputs:
            % oIndex - Array of selected indices. popupmenus will only have
            %          one index, but lists can have multiple.
            %
            % See also:
            % GetAlternatives, GetValue
            
            index = find(strcmpi(this.labels, aLabel), 1);
            assert(~isempty(index), 'There is no such label in the SettingsPanel')
            assert(strcmp(this.types{index}, 'choice') || strcmp(this.types{index}, 'list'),...
                'GetIndex is only available for popupmenus and listboxes')
            oIndex = sort(get(this.controls(index), 'Value'));
        end
        
        function oValue = GetValue(this, aLabel)
            % Returns the selected value for a setting.
            %
            % Returns the current value selected for a setting. The
            % function can be called even if the setting is not displayed.
            %
            % Inputs:
            % aLabel - Setting id.
            %
            % Outputs:
            % oValue - The selected value. For numeric text boxes, the
            %          number will be returned instead of the textbox
            %          string. If the SettingsPanel has multiple parameter
            %          objects, the output will be a cell array of values.
            %
            % See also:
            % GetIndex, GetControlValue, GetParameter
            
            index = find(strcmpi(this.labels, aLabel), 1);
            
            assert(~isempty(index), 'There is no such label in the SettingsPanel')
            
            if length(this.parameters) == 1
                oValue = this.parameters.Get(aLabel);
            else
                oValue = {this.parameters.Get(aLabel)};
            end
        end
        
        function SetAlternatives(this, aLabel, aLevel, aAlternatives)
            % Sets the alternatives of a popupmenu or list setting.
            %
            % The function edits the corresponding settings object, and
            % then the control objects are updated accordingly.
            %
            % Inputs:
            % aLabel - Setting id.
            % aLevel - The complexity level of the specified alternatives.
            %          Alternatives at other levels are not altered.
            % aAlternatives - New alternatives for the setting. The input
            %                 can be either a cell array of strings or a
            %                 function which takes a parameter set as input
            %                 and returns a cell array of strings.
            %
            % See also:
            % GetAlternaives, Setting
            
            this.settings.Get(aLabel).SetAlternatives(aLevel, aAlternatives);
            this.SetVisible(this.shownCategories, this.shownLevels)
        end
        
        function SetIndex(this, aLabel, aIndex)
            % Sets the selected indices for a popupmenu or list setting.
            %
            % Inputs:
            % aLabel - Setting id.
            % aIndex - The new selected indices. For popupmenus it has to
            %          be a single index but for lists it can be an array.
            %
            % See also:
            % SetValue
            
            index = find(strcmpi(this.labels, aLabel), 1);
            
            assert(~isempty(index), 'There is no such label in the SettingsPanel')
            assert(strcmp(this.types{index}, 'choice') || strcmp(this.types{index}, 'list'),...
                'GetIndex is only available for popupmenus and listboxes')
            
            set(this.controls(index), 'Value', aIndex)
        end
        
        function SetValue(this, aLabel, aValue)
            % Sets the value of a setting for all parameter sets.
            %
            % The control objects are updated accordingly.
            %
            % Inputs:
            % aLabel - Setting id.
            % aValue - New value for the setting.
            
            index = find(strcmpi(this.labels, aLabel), 1);
            
            assert(~isempty(index), 'There is no such label in the SettingsPanel')
            
            this.parameters.Set(aLabel, aValue)
            this.SetVisible(this.shownCategories, this.shownLevels)
        end
        
        function SetVisible(this, aCategories, aLevels)
            % Updates the values, visibility and positions of controls.
            %
            % For efficiency, the values of controls which are not shown
            % are not updated.
            %
            % Inputs:
            % aCategories - Setting categories which should be shown.
            % aLevels - Setting levels that should be shown.
            
            this.shownLevels = aLevels;
            this.shownCategories = aCategories;
            
            for i = 1:length(this.labels)
                % Set the visibility based on level and category.
                if this.GetVisible(this.labels{i})
                    set(this.controls(i), 'Visible', 'on')
                    set(this.texts(i), 'Visible', 'on')
                else
                    % Don't update controls which are not shown.
                    set(this.controls(i), 'Visible', 'off')
                    set(this.texts(i), 'Visible', 'off')
                    continue
                end
                
                % Update the value of the control.
                value = this.GetParameter(this.labels{i});
                switch this.types{i}
                    case {'char' 'path'}
                        set(this.controls(i), 'String', value);
                    case 'numeric'
                        set(this.controls(i), 'String', num2str(value));
                    case 'check'
                        set(this.controls(i), 'Value', value);
                    case {'choice' 'list'}
                        % Show only options of the correct level.
                        shownAlternatives = this.GetAlternatives(...
                            this.labels{i}, this.shownLevels);
                        if ~iscell(value)
                            value = {value};
                        end
                        for j = 1:length(value)
                            if ~any(strcmp(shownAlternatives, value{j}))
                                shownAlternatives = [shownAlternatives; value{j}]; %#ok<AGROW>
                            end
                        end
                        % The update selects the first match in a
                        % popupmenu.
                        if strcmpi(this.types{i}, 'choice')
                            sel = find(strcmp(shownAlternatives, value), 1);
                        else
                            sel = find(ismember(shownAlternatives, value));
                        end
                        set(this.controls(i),...
                            'String', shownAlternatives,...
                            'Value', sel)
                end
            end
            
            this.PositionControls();
        end
        
        function SwitchSettings(this, aParams, varargin)
            % Replaces the parameter sets corresponding to all settings.
            %
            % Inputs:
            % aParams - The new parameters in the form of an array of
            %           Map objects, ImageParameters objects or
            %           ImageData objects.
            %
            % Property/Value inputs:
            % KeepSettings - If this is true, the values of the settings
            %                new parameter object will be changed to the
            %                values of the old parameter object. This
            %                option can only be used for a single parameter
            %                object and not for an array of objects. For
            %                popupmenus and lists, the values are not
            %                changed if the new value is not one of the
            %                alternatives, when the updating loop gets to
            %                that setting. The order of the settings can
            %                therefore matter.
            
            aKeepSettings = GetArgs({'KeepSettings'}, {{}}, true, varargin);
            
            if ~isempty(aKeepSettings)
                assert(length(this.parameters) == 1,...
                    'KeepSettings can not be true when there are multiple parameter sets.')
                
                for i = 1:length(this.labels)
                    label = this.labels{i};
                    s = this.settings.Get(label);
                    
                    if ~any(strcmp(aKeepSettings, s.category))
                        continue
                    end
                    
                    value = this.parameters.Get(label);
                    
                    % Do not use the old value if it is not one of the
                    % alternatives for the new parameter
                    if any(strcmp({'choice' 'list'}, this.types{i}))
                        if ~any(strcmp(this.settings.Get(label).GetAlternatives(...
                                aParams, 'all'), value))
                            continue
                        end
                    end
                    
                    aParams.Set(label, value)
                end
            end
            
            this.parameters = aParams;
            
            this.SetVisible(this.shownCategories, this.shownLevels);
        end
    end
    
    methods (Access = private)
        function CheckCallback(this, aObj, aEvent, aFun, aAfterCallback)
            % Callback executed when the value of a control is altered.
            %
            % The function first checks if the new value is allowed for the
            % specified setting. Then the values of all parameter objects
            % are updated. Finally, the control objects are all updated,
            % and then the callback associated with the setting is
            % executed.
            %
            % Inputs:
            % aObj - The control object giving rise to the function call.
            % aEvent - Event object associated with the control object.
            % aFun - Function which takes the string of the control object
            %        as input and returns true if the specified value is
            %        alowed for the setting.
            % aAfterCallback - Callback associated with the Setting object
            %                  corresponding to the control object.
            
            % Remove focus from the control.
            if this.removeFocus
                set(aObj, 'Enable', 'off')
                drawnow()
                set(aObj, 'Enable', 'on')
            end
            
            % Get the setting which corresponds to the uicontrol.
            label = this.labels{this.controls == aObj};
            
            % Check if the proposed value is valid and go back to the old
            % value if it is not.
            if strcmp(get(aObj, 'Style'), 'edit')
                if ~feval(aFun, get(aObj, 'String'))
                    % num2str is used to handle parameters with numeric
                    % values. If the parameter is not numeric, it just
                    % returns the string itself.
                    set(aObj, 'String', num2str(this.GetParameter(label)));
                    return
                else
                    this.SetParameter(label, this.GetControlValue(label))
                end
            elseif strcmp(get(aObj, 'Style'), 'listbox')
                if ~feval(aFun, this.GetControlValue(label))
                    this.SetVisible(this.shownCategories, this.shownLevels);
                    return
                else
                    this.SetParameter(label, this.GetControlValue(label))
                end
            else
                value = this.GetControlValue(label);
                if ~isequal(value, '*****MIXED*****')
                    this.SetParameter(label, value)
                end
            end
            
            this.SetVisible(this.shownCategories, this.shownLevels)
            
            % Execute the callback associated with the setting.
            if ~isempty(aAfterCallback)
                if iscell(aAfterCallback)
                    feval(aAfterCallback{1}, aObj, aEvent, aAfterCallback{2:end})
                else
                    feval(aAfterCallback, aObj, aEvent)
                end
            end
        end
        
        function oValue = GetControlValue(this, aLabel)
            % Returns the value specified in a control object.
            %
            % Controls which are not shown may not be up to date, and
            % therefore you should use GetValue instead if you want to get
            % the value of a setting.
            %
            % Inputs:
            % aLabel - Setting id.
            %
            % Outputs:
            % oValue - The value selected on the control. If the setting is
            %          numeric, the function returns a number, otherwise it
            %          returns a string. For lists, the output will be a
            %          cell array of strings.
            %
            % See also:
            % GetValue, GetParameter
            
            index = find(strcmpi(this.labels, aLabel), 1);
            switch this.types{index}
                case {'char' 'path'}
                    oValue = get(this.controls(index), 'String');
                case 'numeric'
                    oValue = str2num(get(this.controls(index), 'String')); %#ok<ST2NM>
                case 'check'
                    oValue = get(this.controls(index), 'Value');
                case 'choice'
                    selection = get(this.controls(index), 'Value');
                    strings = get(this.controls(index), 'String');
                    if isempty(selection)
                        % strings{[]} does not give an output and therefore
                        % causes an error.
                        oValue = [];
                    else
                        oValue = strings{selection};
                    end
                case 'list'
                    selection = get(this.controls(index), 'Value');
                    strings = get(this.controls(index), 'String');
                    oValue = strings(selection);
            end
        end
        
        function oSetting = GetParameter(this, aLabel)
            % Returns a parameter value for a control object.
            %
            % This function is used internally to find the value that
            % should be put on a control. If there is a single parameter
            % object, this function is identical to GetValue.
            %
            % Inputs:
            % aLabel - Setting id.
            %
            % Outputs:
            % oLabel - The parameter value corresponding to the setting. If
            %          there are multiple parameter objects with different
            %          values, the function returns '*****MIXED*****'.
            %
            % See also:
            % GetValue, GetControlValue
            
            oSetting = this.parameters(1).Get(aLabel);
            for i = 2:length(this.parameters)
                if ~isequaln(oSetting, this.parameters(i).Get(aLabel))
                    oSetting = '*****MIXED*****';
                    return
                end
            end
        end
        
        function oVisible = GetVisible(this, aLabel)
            % Determines if the control of a setting should be visible.
            %
            % The setting is visible if all parameter objects has it as
            % visible. The visibility of a setting is determined based on
            % its, category, its level and the values of other settings.
            %
            % Inputs:
            % aLabel - Setting id.
            %
            % See also:
            % SetVisible
            
            s = this.settings.Get(aLabel);
            
            for i = 1:length(this.parameters)
                oVisible = any(strcmpi(this.shownLevels, s.level)) &&...
                    any(strcmpi(this.shownCategories, s.category)) &&...
                    s.Visible(this.parameters(i));
                if ~oVisible
                    return
                end
            end
        end
        
        function PositionControls(this)
            % Sets the sizes and the positions of all control objects.
            %
            % The sizes of controls are determined based on which controls
            % are visible. The function arranges all the visible controls
            % and their text labels in a column, where each control has the
            % same height. Lists will take up one row per alternative
            % shown. The number of rows in a list is determined by the
            % number of alternatives, but lower and upper bounds can be set
            % using the properties minList and maxList. The property
            % maxRowHeight sets a maximum height for a control row, so that
            % a small number of controls are never stretched over a tall
            % panel.
            %
            % See also:
            % SetVisible
            
            % Determine the number of rows taken up by each control object.
            dRows = zeros(length(this.labels),1);
            for i = 1:length(this.labels)
                % A control is assumed to be visible whenever its text is.
                if strcmp(get(this.texts(i), 'Visible'), 'on')
                    if strcmp(this.types{i}, 'list')
                        dRows(i) = length(this.GetAlternatives(this.labels{i}, 'all'));
                        dRows(i) = max(this.minList, dRows(i));
                        dRows(i) = min(this.maxList, dRows(i));
                    else
                        dRows(i) = 1;
                    end
                end
            end
            
            % The height of one control row in normalized units.
            rowHeight = min(1/sum(dRows), this.maxRowHeight);
            
            % Set the heights and positions of all controls.
            row = 0;
            for i = 1:length(this.labels)
                % A control is assumed to be visible whenever its text is.
                if strcmp(get(this.texts(i), 'Visible'), 'on')
                    row = row + dRows(i);
                    
                    set(this.texts(i),...
                        'Position', [0 1-row*rowHeight 1 dRows(i)*rowHeight])
                    
                    switch this.types{i}
                        case 'check'
                            set(this.controls(i), 'Position',...
                                [this.split 1-row*rowHeight...
                                1-this.split (dRows(i)*rowHeight)*0.9])
                        case 'button'
                            % Buttons are stretched to cover their labels.
                            set(this.controls(i), 'Position',...
                                [0 1-row*rowHeight...
                                1 (dRows(i)*rowHeight)*0.9])
                        case 'path'
                            set(this.controls(i), 'Position',...
                                [this.split 1-row*rowHeight...
                                (1-this.split)*0.8 dRows(i)*rowHeight])
                            set(this.browseButtons(i), 'Position',...
                                [this.split+(1-this.split)*0.8 1-row*rowHeight...
                                (1-this.split)*0.2 dRows(i)*rowHeight])
                        otherwise
                            set(this.controls(i), 'Position',...
                                [this.split 1-row*rowHeight...
                                1-this.split dRows(i)*rowHeight])
                    end
                end
            end
        end
        
        function SetParameter(this, aLabel, aValue)
            % Alters the values of a setting and its downstream settings.
            %
            % This function is called when the user alters a setting in the
            % GUI. The function goes through all downstream settings which
            % depend on the altered setting and changes their values if
            % their default values are altered by the change or if the
            % selected value in a popupmenu or a list becomes unavailable.
            % Downstream settings are always set to their default values if
            % they are changed. If downstream settings are changed, the
            % user will be asked if the whole set of changes should be made
            % or if it should be taken back.
            %
            % Inputs:
            % aLabel - Setting id.
            % aValue - The new value for the setting.
            %
            % See also:
            % SetValue
            
            % The following 3 variables have one element for each
            % setting/parameter pair which is changed. The variables are
            % used when changes are taken back.
            
            % Indices of all altered parameters including the primary one.
            alteredImages = [];
            % Indices of the altered settings.
            alteredSettings = [];
            % Cell array with old values of all changed parameters.
            oldValues = {};
            
            % The names of all setting which are downstream of aLabel.
            altered = [aLabel; this.settings.Get(aLabel).alters];
            
            for i = 1:length(this.parameters)
                p = this.parameters(i);
                
                % Find the default values before the change.
                oldDefaults = cell(length(altered),1);
                for j = 2:length(altered)
                    oldDefaults{j} = this.settings.Get(altered{j}).GetDefault(p);
                end
                
                % Store information about the change of the primary
                % setting, so that it can be reverted.
                alteredImages = [alteredImages; i]; %#ok<AGROW>
                alteredSettings = [alteredSettings; 1]; %#ok<AGROW>
                oldValues = [oldValues; {p.Get(aLabel)}]; %#ok<AGROW>
                
                % Perform the change.
                p.Set(aLabel, aValue)
                
                for j = 2:length(altered)
                    alt = altered{j};
                    s = this.settings.Get(alt);
                    
                    % Check if the new default value matches the old one.
                    % If not, the setting is set to the new default.
                    newDefault = s.GetDefault(p);
                    if ~isequaln(newDefault, oldDefaults{j})
                        % Store information about the change so that it can
                        % be reverted.
                        alteredImages = [alteredImages; i]; %#ok<AGROW>
                        alteredSettings = [alteredSettings; j]; %#ok<AGROW>
                        oldValues = [oldValues; {p.Get(alt)}]; %#ok<AGROW>
                        
                        p.Set(alt, newDefault)
                        continue
                    end
                    
                    % Check if the selected values of popupmenus and lists
                    % are still available after the changes done so far. If
                    % not, the setting is set to the new default.
                    if any(strcmp({'choice' 'list'}, s.type))
                        alternatives = s.GetAlternatives(p, 'all');
                        if ~any(strcmp(alternatives, p.Get(alt)))
                            % Store information about the change so that it
                            % can be reverted.
                            alteredImages = [alteredImages; i]; %#ok<AGROW>
                            alteredSettings = [alteredSettings; j]; %#ok<AGROW>
                            oldValues = [oldValues; {p.Get(alt)}]; %#ok<AGROW>
                            
                            p.Set(alt, newDefault)
                            continue
                        end
                    end
                end
            end
            
            % List of all altered settings.
            alteredSettingsNames = altered(unique(alteredSettings));
            if length(alteredSettingsNames) > 1
                % Ask the user if it is ok to perform the changes, if
                % settings downstream of the primary setting were changed.
                message = sprintf('This change alters the following settings:\n');
                for i = 1:length(alteredSettingsNames)
                    message = [message sprintf('%s\n', alteredSettingsNames{i})]; %#ok<AGROW>
                end
                answer = questdlg(message,...
                    'Other settings affected', 'Ok', 'Cancel', 'Ok');
                
                if any(strcmp({'Cancel' ''}, answer))
                    % Revert all the changes.
                    for i = 1:length(alteredImages)
                        this.parameters(alteredImages(i)).Set(...
                            altered{alteredSettings(i)}, oldValues{i})
                    end
                end
            end
        end
    end
end