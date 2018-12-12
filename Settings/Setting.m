classdef Setting < handle
    % Class used to represent processing settings and settings in GUIs.
    %
    % This class is used to represent processing settings of the program.
    % The settings objects contain information about the name of the
    % setting, the default values, allowed values and other information
    % which is required to have a user set values for the settings in a
    % GUI, such as SettingsGUI. The class does not store the settings
    % values of individual image sequences. That is done by the classes
    % ImageParameters and ImageData. Objects of this class can also be used
    % to define a set of control objects in an arbitrary GUI which asks the
    % user for input.
    %
    % The properties of the settings objects are specified as
    % Property/Value arguments to the constructor and most of them can not
    % be changed after that. There is public get-access to all properties
    % except a few which are used for cashing of values, but set-access is
    % only available through methods. The only properties which can be
    % changed are those which are associated with the alternatives in lists
    % and popupmenus, as these alternatives sometimes need to be changed in
    % GUIs.
    %
    % The settings objects have a property called 'type', which specifies
    % which type of uicontrol object should be used in GUIs where the
    % settings are modified. The types that can be used are:
    % 'char' - Textbox with strings.
    % 'numeric' - Textbox with numeric data.
    % 'check- Checkbox.
    % 'choice' - Popupmenu.
    % 'list' - List where multiple strings can be selected.
    % 'button' - Pushbutton (not used to represent a processing setting).
    %
    % The settings have free-text categories, which make it possible to
    % display subsets of them in GUIs, and they also have a level property
    % which can be set to 'basic', 'advanced', 'development' and 'hidden'.
    % The 'basic' settings should be sufficient to process most image
    % sequences, the 'advanced'  settings can be important in order to get
    % better performance, and the 'development' settings are only meant for
    % development and should not be altered by users unless instructed to
    % do so. The 'hidden level is for settings which should not be changed
    % by a user, but which have been used in the processing of specific
    % datasets. For the 'choice' and 'list' type, the 3 properties
    % alternatives_basic, alternatives_advanced and
    % alternatives_development can are used to specify alternatives of
    % different levels for the corresponding control object. This makes it
    % possible to adjust which alternatives are shown, based on the level
    % of experience that the user has. For hidden settings of these types,
    % the alternatives should be put in alternatives_advanced. The default
    % category is 'unspecified' and the default level is 'basic'.
    %
    % The visibility of a setting is normally determined based on its
    % category and level, but it is also possible to specify the property
    % visiblefunction, which is a function handle of a function that takes
    % a Map with values of other settings and returns true if the
    % setting should be visible. This is normally used with objects of the
    % ImageParameters class as input, which makes it possible to decide if
    % a processing setting should be made available based on the values of
    % all other processing settings.
    %
    % The set of valid values for a setting are specified using the
    % property checkfunction, which is a function handle to a function that
    % takes a string as input and returns true if the string represents a
    % valid value.
    %
    % It is possible to define a callback function associated with the
    % setting, by setting the property callbackfunction to a handle of the
    % callback function. Then the callback will be executed whenever the
    % setting is changed in a GUI.
    %
    % See also:
    % SettingsPanel, AllSettings, SettingsGUI, ImageParameters, ImageData
    
    properties (SetAccess = private)
        name = {};                      % String shown next to the setting.
        default = [];                   % Default value of the setting.
        alternatives_basic = {};        % Basic alternatives for popupmenus and lists.
        alternatives_advanced = {};     % Advanced alternatives for popupmenus and lists.
        alternatives_development = {};  % Development alternatives for popupmenus and lists.
        type = {};                      % The type of control object used for the setting.
        category = 'unspecified';       % Category of the setting, the default is 'unspecified'.
        level = 'basic';                % Level of the setting ('basic', 'advanced' or 'development'), the default is 'basic'.
        tooltip = '';                   % String shown when the cursor is above the control object.
        aliases = {};                   % Old names of the settings which are still recognized in settings files.
        alters = {};                    % Identifiers of other settings which can be altered when the setting is changed.
        visiblefunction = @(x) true;    % Function handle taking a Map. Determines the visibility of the settings.
        checkfunction = @(x) true;      % Function handle checking if a string represents a valid value of for the setting.
        callbackfunction =...
            @(aObj, aEvent) disp([]);   % Function handle with callback for the control object of the setting.
    end
    
    % Binary variables saying whether or not the properties default,
    % alternatives_basic, alternatives_advanced and
    % alternatives_development are function handles. These variables are
    % precomputed in the constructor, to avoid calling the expensive
    % function isa in GetDefault and GetAlternatives.
    properties (Access = private)
        default_func = false;
        alt_basic_func = false;
        alt_advanced_func = false;
        alt_development_func = false;
    end
    
    methods
        function this = Setting(varargin)
            % Generates a new settings object.
            %
            % All of the properties of the class except the private ones
            % can be specified as Property/Value inputs to the constructor.
            % If a property is left out, the default property value is
            % used. The default values are specified after the declarations
            % of the properties, and should not be confused with the
            % property named 'default'.
            
            % Set properties using Property/Value inputs.
            for i = 1 : 2 : length(varargin)
                this.(varargin{i}) = varargin{i+1};
            end
            
            % Check if properties are function handles and store that info.
            this.default_func = isa(this.default, 'function_handle');
            this.alt_basic_func = isa(this.alternatives_basic, 'function_handle');
            this.alt_advanced_func = isa(this.alternatives_advanced, 'function_handle');
            this.alt_development_func = isa(this.alternatives_development, 'function_handle');
        end
        
        function oSetting = Clone(this)
            % Returns a deep copy of the Setting object.
            
            oSetting = Setting();
            props = properties(Setting);
            for i = 1:length(props)
                oSetting.(props{i}) = this.(props{i});
            end
        end
        
        function oDefault = GetDefault(this, aParams)
            % Returns the default value of a setting.
            %
            % Inputs:
            % aParams - Map of other settings values, on which the
            %           default value may depend. Usually, the sub-classes
            %           of Map, ImageParameters and ImageData will
            %           be used as input. The input can be [], if the
            %           default value is known to be a fixed value.
            %
            % oDefault:
            % The default settings value.
            
            if this.default_func
                oDefault = feval(this.default, aParams);
            else
                oDefault = this.default;
            end
        end
        
        function oAlts = GetAlternatives(this, aParams, aLevel)
            % Returns alternatives for 'choice' and 'list' settings.
            %
            % This function can only be used with settings of the types
            % 'choice' and 'list'.
            %
            % Inputs:
            % aParams - Map of settings values, on which the set of
            %           alternatives may depend. Usually, the sub-classes
            %           of Map, ImageParameters and ImageData will
            %           be used as input. The input can be [], if the set
            %           of alternatives is known to be a fixed cell array
            %           of strings.
            % aLevel - The level for which alternatives will be returned.
            %          aLevel can be 'basic', 'advanced', 'development', or
            %          a cell array containing one or more of the strings.
            %          The option 'all' will return alternatives for all 3
            %          levels.
            
            % Handle cell arrays with multiple inputs recursively.
            if iscell(aLevel)
                oAlts = {};
                for i = 1:length(aLevel)
                    oAlts = [oAlts; this.GetAlternatives(aParams, aLevel{i})]; %#ok<AGROW>
                end
                return
            end
            
            switch lower(aLevel)
                case 'basic'
                    if this.alt_basic_func
                        oAlts = feval(this.alternatives_basic, aParams);
                    else
                        oAlts = this.alternatives_basic;
                    end
                case 'advanced'
                    if this.alt_advanced_func
                        oAlts = feval(this.alternatives_advanced, aParams);
                    else
                        oAlts = this.alternatives_advanced;
                    end
                case 'development'
                    if this.alt_development_func
                        oAlts = feval(this.alternatives_development, aParams);
                    else
                        oAlts = this.alternatives_development;
                    end
                case 'all'
                    oAlts = [this.GetAlternatives(aParams, 'basic')
                        this.GetAlternatives(aParams, 'advanced')
                        this.GetAlternatives(aParams, 'development')];
                otherwise
                    error('Unknown settings level %s.', aLevel)
            end
        end
        
        function SetAlternatives(this, aLevel, aAlternatives)
            % Specifies alternatives for 'choice' and 'list' settings.
            %
            % This function only has an effect for settings of the types
            % 'choice' and 'list'.
            %
            % Inputs:
            % aLevel - The settings level for which alternatives are
            %          specified. The level can be 'basic', 'advanced' or
            %          'development'. The alternatives for other levels
            %          will not be altered.
            % aAlternatives - Cell array of strings with alternatives, or a
            %                 function handle of a function which takes a
            %                 Map of values for other settings and
            %                 returns alternatives in the form of a cell
            %                 array of strings.
            
            switch aLevel
                case 'basic'
                    this.alternatives_basic = aAlternatives;
                    this.alt_basic_func =...
                        isa(this.alternatives_basic, 'function_handle');
                case 'advanced'
                    this.alternatives_advanced = aAlternatives;
                    this.alt_advanced_func =...
                        isa(this.alternatives_advanced, 'function_handle');
                case 'development'
                    this.alternatives_development = aAlternatives;
                    this.alt_development_func =...
                        isa(this.alternatives_development, 'function_handle');
                otherwise
                    error('Unknown settings level %s\n', aLevel)
            end
        end
        
        function oOk = Check(this, aValue)
            % Checks if a string represents a valid value for the setting.
            %
            % All the function does is to apply the checkfunction of the
            % setting to a string proposed by the user.
            %
            % Inputs:
            % aValue - String with the value selected by a user in a
            %          uicontrol. When the control object is a textbox for
            %          numeric values, the input to this function should
            %          still be the string entered in the textbox, and not
            %          the numeric value.
            %
            % Outputs:
            % oOk - Binary output which is true if the value is valid.
            
            oOk = feval(this.checkfunction, aValue);
        end
        
        function oVisible = Visible(this, aParams)
            % Checks if the setting should be visible to the user.
            %
            % This function uses the visiblefunction of the settings object
            % to check if the control object associated with the setting
            % should be made visible to the user.
            %
            % Inputs:
            % aParams - Generic set with the values of other settings,
            %           which will be used as an input to the
            %           visiblefunction of the setting, to determine if the
            %           setting should be visible.
            %
            % Outputs:
            % oVisible - Binary output which is true if the setting should
            %            be visible.
            
            oVisible = feval(this.visiblefunction, aParams);
        end
        
        function Callback(this, aObj, aEvent)
            % Executes the callback associated with the setting.
            %
            % This function is meant to execute the callbackfunction of the
            % setting after the user has altered the value of the setting.
            % If callbackfunction is not specified when the settings
            % object is created, a function which does nothing is executed.
            %
            % Inputs:
            % aObj - uicontrol object which gave rise to the callback.
            % aEvent - Event data associated with the callback event.
            
            if iscell(this.callbackfunction)
                feval(this.callbackfunction{1}, aObj, aEvent,...
                    this.callbackfunction{2:end})
            else
                feval(this.callbackfunction, aObj, aEvent)
            end
        end
    end
end