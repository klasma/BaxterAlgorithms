classdef SegmentationPlayer < CTCControlPlayer
    % Interactive GUI for specification of segmentation settings.
    %
    % The GUI lets the user change segmentation parameters interactively
    % and see the segmentation results in real time. The image sequence can
    % be played, and all 3D visualization tools from the ZPlayer class are
    % available for 3D data.
    %
    % The segmented blobs are shown as outlines on top of the original
    % image or on top of an intermediate segmentation result selected by
    % the user.
    %
    % There are 3 settings for visualization of the results. The user can
    % select do display intermediate segmentation results using a
    % popupmenu, select the color of the displayed outlines using a textbox
    % and specify a ground truth segmentation to compare the segmentation
    % results to using a popupmenu. There are a number of segmentation
    % algorithms to choose from. Some of the segmentation settings affect
    % the processing of most segmentation algorithms, and some are specific
    % to the different segmentation algorithms. The general idea is to hide
    % all settings which have no effect on the segmentation, given the
    % selections that have been made. To make it easier to learn the GUI
    % and to find important settings, the settings have been separated into
    % the 3 levels, 'basic', 'advanced' and 'development'. 'basic' settings
    % are important for getting a good segmentation, 'advanced' settings
    % can be used to improve the segmentation results, but are not crucial
    % to finding an initial segmentation to work from. The 'development'
    % settings have been used in different projects, but are expected to
    % have limited utility in other projects. The controls for the settings
    % are implemented using the SettingsPanel class. The verification of
    % allowed values and the visibility of controls are handled in the
    % Setting objects constructed by AllSettings. If a value specified by
    % the user is not an allowed value for the setting, the control will go
    % back to the previous value.
    %
    % There is an update button which can be de-selected, so that the
    % segmentation is not updated. This makes it possible to find a desired
    % image sequence or time point without having to wait for the
    % segmentation. It can also be used to alter multiple settings at the
    % same time, before a very time consuming segmentation is performed.
    %
    % There is a revert button which specifies if settings should be loaded
    % from the setting file when the image sequence is switched. If the
    % toggle-button is up, the user can take the segmentation associated
    % with one image sequence and apply it to a different sequence,
    % provided that the data has the same dimensionality. The button can
    % also be toggled twice to undo all changes that have been made since
    % the segmentation settings were last saved.
    %
    % Messages are displayed as text on top of the images in the GUI, when
    % a segmentation is computed and when the segmentation is not being
    % updated because the update button is not pressed down.
    %
    % Settings can be saved for the current image sequence, for a list of
    % image sequences or for all image sequences in the GUI.
    %
    % See also:
    % Map
    
    properties
        sPanel          % SettingsPanel object with controls for all settings.
        settings        % Map with settings object for all settings.
        gtBlobs         % Cell array with ground truth blobs for all time points.
        blobs           % Array of blobs segmented in the current image.
        images          % Struct for images with intermediate segmentation results.
        
        textXY          % Graphics object with text shown in the xy-axes.
        textXZ          % Graphics object with text shown in the xz-axes.
        textYZ          % Graphics object with text shown in the yz-axes.
        
        updateButton    % Toggle-button specifying if plots should be updated.
        revertButton    % Toggle-button specifying if settings should be re-loaded when a new sequence is opened.
        saveThisButton  % Button saving settings for the current image sequence.
        saveListButton  % Button saving settings for a list of image sequences.
        saveAllButton   % Button saving settings for all image sequences in the GUI.
        
        basicMenu       % Menu selecting basic settings.
        advancedMenu    % Menu selecting advanced settings.
        developmentMenu % Menu selecting development settings.
        
        outlineMenu     % Menu where plotting of outlines can be toggled.
        
        creatingTemplate    % True if the user is creating a matching-template for Segment_template.
        templateSize        % The size in pixels of the matching-template created.
    end
    
    methods
        function this = SegmentationPlayer(aSeqPaths)
            % Creates a GUI for specification of segmentation settings.
            %
            % Inputs:
            % aSeqPaths - Cell array of full paths to a set of image
            %             sequences for which segmentation settings should
            %             be specified.
            
            this = this@CTCControlPlayer(aSeqPaths,...
                'Draw', false,...
                'ControlWidth', 0.15); % The control panel is wider than usual.
            
            set(this.mainFigure,...
                'WindowScrollWheelFcn', @this.WindowScrollWheelFcn,...
                'CloseRequestFcn', @this.Close)
            
            % Add menus to select which level of settings to show.
            levelMenu = uimenu('Label', 'Level');
            this.basicMenu = uimenu(levelMenu,...
                'Label', 'basic',...
                'Callback', @this.LevelCallback);
            this.advancedMenu = uimenu(levelMenu,...
                'Label', 'advanced',...
                'Callback', @this.LevelCallback);
            this.developmentMenu = uimenu(levelMenu,...
                'Label', 'development',...
                'Callback', @this.LevelCallback);
            
            % Set the level of settings to show. The level used when the
            % GUI was closed last time is used if the GUI has been open
            % before. Otherwise, 'basic' is used.
            level = LoadVariable('SegmentationPlayer_level');
            if isempty(level)
                level = 'basic';
            end
            switch level
                case 'basic'
                    set(this.basicMenu, 'Checked', 'on')
                case 'advanced'
                    set(this.advancedMenu, 'Checked', 'on')
                case 'development'
                    set(this.developmentMenu, 'Checked', 'on')
                otherwise
                    error('Unknown level %s.\n', level)
            end
            
            this.creatingTemplate = false;
            this.templateSize = 21;  % Creates 21x21  pixel templates.
            
            % Create the SettingsPanel.
            this.CreatePanel();
            
            % Add buttons to the GUI.
            this.updateButton = uicontrol(...
                'Style', 'togglebutton',...
                'String', 'Update',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0 0.1 1 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Toggles segmentation updates on and off',...
                'Callback', @this.UpdateButton_Callback);
            this.revertButton = uicontrol(...
                'Style', 'togglebutton',...
                'String', 'Revert to saved',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0 0.05 1 0.05],...
                'HorizontalAlignment', 'left',...
                'value', 1,...
                'Tooltip', 'Toggles loading of settings from file on and off',...
                'Callback', @this.RevertButton_Callback);
            this.saveThisButton = uicontrol(...
                'Style', 'pushbutton',...
                'String', 'Save seq',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0 0 1/3 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Saves the settings for this image sequence',...
                'Callback', {@this.SaveButton_Callback, 'this'});
            this.saveListButton = uicontrol(...
                'Style', 'pushbutton',...
                'String', 'Save list',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [1/3 0 1/3 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Saves the settings for a set of image sequences',...
                'Callback', {@this.SaveButton_Callback, 'dialog'});
            this.saveAllButton = uicontrol(...
                'Style', 'pushbutton',...
                'String', 'Save all',...
                'Parent', this.controlPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [2/3 0 1/3 0.05],...
                'HorizontalAlignment', 'left',...
                'Tooltip', 'Saves the settings for all image sequences',...
                'Callback', {@this.SaveButton_Callback, 'all'});
            
            this.ReSizeControls();
            this.ReSizeAxes();
            drawnow()  % Display window before the Draw() is done.
            this.Draw()
            
            % Adds a key-press callback to the main figure and all
            % uicontrols in it. If the key-press callback was added only to
            % the figure, the keyboard short cuts would not be available
            % when a uicontrol has been clicked.
            SetKeyPressCallback(this.mainFigure, @this.KeyPressFcn)
            SetKeyReleaseCallback(this.mainFigure, @this.KeyReleaseFcn)
            
            % Remove the key-callbacks from text boxes, so that typing in
            % them does not activate shortcuts.
            set(this.volumeSettingsPanel.GetControl('line_color'),...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.volumeSettingsPanel.GetControl('x'),...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.volumeSettingsPanel.GetControl('y'),...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.volumeSettingsPanel.GetControl('z'),...
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
            
            % Remove the key-callbacks from all settings controls, so that
            % shortcuts are not activated when the user edits settings.
            controls = this.sPanel.controls;
            for i = 1:length(controls)
                set(controls(i),...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            end
        end
        
        function CreateChannelMenus(this)
            % Creates menus to select channels and toggle outlines.
            %
            % The default is to display the outlines and all the channels.
            % If there are existing menus, they will be removed before the
            % new menus are created. The function extends a function with
            % the same name in a super-class.
            
            % Remove the old outline menu.
            if ~isempty(this.outlineMenu)
                checked = get(this.outlineMenu, 'Checked');
                delete(this.outlineMenu)
            else
                checked = 'on';
            end
            
            % Remove old and create new channel menus.
            this.CreateChannelMenus@CTCControlPlayer()
            
            % Create a new outline menu.
            this.outlineMenu = uimenu(this.channelTab,...
                'Label', 'Outlines (Z)',...
                'Separator', 'on',...
                'Checked', checked,...
                'Callback', @this.OutlineMenu_Callback);
        end
        
        function CreatePanel(this)
            % Generate a SettingsPanel with segmentation settings.
            %
            % The panel has a control object for every setting that is used
            % by the program. There are also 3 settings which affect how
            % the results are displayed.
            
            this.settings = AllSettings();
            
            % Adding visualization settings to the set of settings.
            this.settings.Add('Display', Setting(...
                'name', 'Display',...
                'alternatives_advanced', {'original'},...
                'type', 'choice',...
                'category', 'visualization',...
                'level', 'advanced',...
                'tooltip', ['The image to be displayed. ''original'' is '...
                'the un-processed image and other alternatives are '...
                'intermediate segmentation results.']), 1);
            this.settings.Add('Outline_color', Setting(...
                'name', 'Outline color',...
                'type', 'numeric',...
                'category', 'visualization',...
                'level', 'advanced',...
                'checkfunction', @(x) length(str2num(x)) == 3 &&...
                all(str2num(x) >= 0) && all(str2num(x) <= 1),...
                'tooltip', ['Color to plot region outlines in. '...
                'Toggle plotting using the Z key.']), 2); %#ok<ST2NM>
            oldVersions = ['none'; GetVersions(this.GetImData().seqPath)'];
            this.settings.Add('Ground_truth', Setting(...
                'name', 'Ground truth',...
                'alternatives_advanced', oldVersions,...
                'type', 'choice',...
                'category', 'visualization',...
                'level', 'advanced',...
                'callbackfunction', @this.GroundTruth_Callback,...
                'tooltip', ['If you specify a set of corrected tracks, '...
                'segmentation errors will be color coded.']), 3);
            this.settings.Add('Segment', Setting(...
                'name', 'Segment',...
                'alternatives_advanced', {'everything', 'shown region'},...
                'type', 'choice',...
                'category', 'visualization',...
                'level', 'advanced',...
                'tooltip', 'Specifies how much of the image should be segmented.'), 4);
            
            % Add buttons to create and manage matching-templates for the
            % segmentation function Segment_template.
            this.settings.Add('Create_matching_template', Setting(...
                'name', 'Create matching-template',...
                'type', 'button',...
                'category', 'visualization',...
                'level', 'advanced',...
                'tooltip', ['Lets you create a new matching-template '...
                'for Segment_tempate'],...
                'visiblefunction', @(x)strcmp(x.Get('SegOldVersion'), 'none') &&...
                ~strcmp(x.Get('SegAlgorithm'), 'Segment_import') &&...
                strcmpi(x.Get('SegAlgorithm'), 'Segment_template'),...
                'callbackfunction', @(aObj, aEvent)this.CreateTemplate()))
            this.settings.Add('Manage_matching_templates', Setting(...
                'name', 'Manage matching-templates',...
                'type', 'button',...
                'category', 'visualization',...
                'level', 'advanced',...
                'tooltip', ['Lets you visualize, delete and rename '...
                'matching-templates for Segment_tempate'],...
                'visiblefunction', @(x)strcmp(x.Get('SegOldVersion'), 'none') &&...
                ~strcmp(x.Get('SegAlgorithm'), 'Segment_import') &&...
                strcmpi(x.Get('SegAlgorithm'), 'Segment_template'),...
                'callbackfunction', @this.ManageTemplates))
            
            % Add parameter values for the visualization settings.
            this.GetImData().Add('Display', 'original', 1)
            this.GetImData().Add('Outline_color', [1 0 0], 2)
            this.GetImData().Add('Ground_truth', 'none', 3)
            this.GetImData().Add('Segment', 'everything', 4)
            
            % Add dummy settings that correspond to the template buttons.
            this.GetImData().Add('Create_matching_template', [])
            this.GetImData().Add('Manage_matching_templates', [])
            
            % Generate the panel with all settings.
            this.sPanel = SettingsPanel(this.settings,...
                'Parameters', this.GetImData(),...
                'Categories', {'segmentation' 'visualization'},...
                'Levels', 'basic',...
                'Parent', this.controlPanel,...
                'Position', [0 0.15 1 0.85],...
                'Split', 0.6,...
                'MaxRowHeight', 1/25,...
                'RemoveFocus', true);
            
            % The drawing function is appended after the control object
            % callbacks, so that the image is redrawn every time a
            % parameter is changed. If a visualization setting is changed,
            % the image is redrawn without recomputing the segmentation.
            for i = 1:3
                oldCallBack = get(this.sPanel.controls(i), 'Callback');
                set(this.sPanel.controls(i),...
                    'Callback', {@this.ExtraCallback3D, oldCallBack})
            end
            for i = 4:length(this.sPanel.controls)
                % Given that settings are not cloned by AllSettings, the
                % callbacks can not be added to the Setting objects, in
                % case additional SegmentationPlayers are started.
                if ~strcmp(this.sPanel.labels(i), 'Create_matching_template') &&...
                        ~strcmp(this.sPanel.labels(i), 'Manage_matching_templates')
                    oldCallBack = get(this.sPanel.controls(i), 'Callback');
                    set(this.sPanel.controls(i),...
                        'Callback', {@this.ExtraCallback, oldCallBack})
                end
            end
            
            this.SetVisible();
        end
        
        function CreateTemplate(this, aTemplate)
            % Opens or updates a GUI for creation of matching-templates.
            %
            % The function is a callback for a button which appears among
            % the settings when the segmentation function Segment_template
            % is selected. The function opens a GUI where the user can
            % create matching-templates for Segment_template. The GUI has
            % an axes where the template is shown, a text box where a name
            % for the template is written, and a button where the template
            % can be saved. Templates are selected by clicking in the
            % image. A blue rectangle outlines the region that will be
            % cropped into a template. The template is saved in the same
            % directory as the built in templates. When a template is
            % created it is automatically selected. The GUI is handled
            % using persistent variables instead of class parameters, to
            % avoid creating a lot of class parameters and methods for a
            % purpose that few developers will be interested in.
            %
            % Inputs:
            % aTemplate - Optional input with a new template that was
            %             cropped out by the user. The template should be a
            %             square matrix of double values between 0 and 1.
            %             If this input is omitted, the GUI will show the
            %             previous template, or no template at all.
            %
            % See also:
            % ManageTemplates, Segment_template,
            % WindowButtonDownFcn_template, WindowButtonMotionFcn_template,
            % WindowScrollWheelFcn
            
            persistent templateDialog   % Figure for the GUI.
            persistent template         % Current template that can be saved.
            persistent templateAxes     % Axes where the template is displayed.
            persistent templateTextbox  % Text box for the name of the template.
            persistent templateSaveButton
            
            if nargin == 2
                template = aTemplate;
            end
            
            this.creatingTemplate = true;
            
            if isempty(templateDialog)
                InfoDialog('InfoCreateTemplate',...
                    'Create matching-template',...
                    ['Click in the center of a representative '...
                    'round cell of average size to create a new '...
                    'template. The blue square shows the region '...
                    'that will be used for the template. The size '...
                    'of the template can be adjusted using the '...
                    'scroll wheel of the mouse or by pressing '...
                    '''+'' or ''-''. The template should include a '...
                    'one pixel wide border of background pixels '...
                    'around the cell. The new template is saved by '...
                    'pressing ''Save''. Templates are saved as '...
                    'mat-files in the folder Files\Templates in '...
                    'the program directory. The new template is '...
                    'selected automatically after it has been saved.'])
                
                % The GUI must have the same scroll wheel function as the
                % main figure, so that the function is active when the GUI
                % has focus.
                templateDialog = figure(...
                    'Menubar', 'none',...
                    'NumberTitle', 'off',...
                    'Name', 'Create matching-template',...
                    'Units', 'normalized',...
                    'Position', [0.1 0.1 0.25 0.5],...
                    'WindowScrollWheelFcn', @this.WindowScrollWheelFcn,...
                    'CloseRequestFcn', @CancelTemplate_Callback);
                templateAxes = axes(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0.025 0.175 0.95 0.8]);
                axis(templateAxes, 'off')
                uicontrol(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0.01 0.1 0.24 0.05],...
                    'Style', 'text',...
                    'String', 'Name',...
                    'HorizontalAlignment', 'left',...
                    'Tooltip', 'Name that the template will be saved under');
                % The GUI and the uicontrols that have been created so far
                % should have the same keypress function as the main
                % figure, so that it is active when the GUI has focus. The
                % textbox should not listen to key presses and the buttons
                % close the GUI when they are pressed, so they do not get
                % the keypress callback.
                SetKeyPressCallback(templateDialog, @this.KeyPressFcn)
                SetKeyReleaseCallback(templateDialog, @this.KeyReleaseFcn)
                templateTextbox =  uicontrol(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0.25 0.1 0.75 0.05],...
                    'Style', 'edit',...
                    'String', '',...
                    'HorizontalAlignment', 'left',...
                    'Tooltip', 'Name that the template will be saved under');
                templateSaveButton = uicontrol(...
                    'Enable', 'off',...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0 0 0.5 0.1],...
                    'Style', 'pushbutton',...
                    'String', 'Save',...
                    'Tooltip', 'Saves and uses the template as TMSegTemplate',...
                    'Callback', @SaveTemplate_Callback);
                uicontrol(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0.5 0 0.5 0.1],...
                    'Style', 'pushbutton',...
                    'String', 'Cancel',...
                    'Tooltip', 'Closes the dialog',...
                    'Callback', @CancelTemplate_Callback);
            else
                % Bring the template dialog to the front.
                figure(templateDialog)
            end
            
            if ~isempty(template)
                % Update the displayed template.
                imshow(template, 'Parent', templateAxes)
                set(templateSaveButton, 'Enable', 'on')
            end
            
            function CancelTemplate_Callback(~, ~)
                % Callback which closes the GUI.
                
                delete(templateDialog)
                templateDialog = [];
                this.creatingTemplate = false;
            end
            
            function SaveTemplate_Callback(~, ~)
                % Callback which saves the created template.
                %
                % When the template has been saved, the callback also
                % closes the GUI.
                
                % Save the template.
                name = [get(templateTextbox, 'String') '.mat'];
                templatePath = FindFile('Templates', name);
                save(templatePath, 'template')
                
                % Update the available template alternatives in the
                % dropdown menu, and select the saved template.
                alternatives = this.sPanel.GetAlternatives(...
                    'TMSegTemplate', 'advanced');
                this.sPanel.SetAlternatives(...
                    'TMSegTemplate',...
                    'advanced',...
                    [alternatives; {name}])
                this.sPanel.SetValue('TMSegTemplate', name)
                
                % Closes the GUI.
                delete(templateDialog)
                templateDialog = [];
                this.creatingTemplate = false;
                this.Draw()
            end
        end
        
        function ManageTemplates(this, ~, ~)
            % GUI where the user can select, show and delete templates.
            %
            % The function is a callback for a button which appears among
            % the settings when the segmentation function Segment_template
            % is selected. The function creates a GUI where all available
            % templates are displayed in a listbox. When a template is
            % marked in the listbox, the template is shown as an image at
            % the top of the GUI. The GUI has buttons to select templates
            % for the segmentation and to delete templates. The GUI is
            % handled using persistent variables instead of class
            % parameters, to avoid creating a lot of class parameters and
            % methods for a purpose that few developers will be interested
            % in.
            %
            % See also:
            % ManageTemplates, Segment_template
            
            persistent templateDialog   % Figure for the GUI.
            persistent templateAxes     % Axes where the template is displayed.
            persistent templateList     % Listbox where all templates are listed.
            
            availableTemplates = this.sPanel.GetAlternatives(...
                'TMSegTemplate', 'advanced');
            
            if isempty(templateDialog)
                templateDialog = figure(...
                    'Menubar', 'none',...
                    'NumberTitle', 'off',...
                    'Name', 'Manage matching-templates',...
                    'Units', 'normalized',...
                    'Position', [0.1 0.1 0.25 0.6],...
                    'CloseRequestFcn', @ClosetemplateDialog);
                templateAxes = axes(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0.025 0.325 0.95 0.65]);
                axis(templateAxes, 'off')
                uicontrol(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0 0 0.5 0.1],...
                    'Style', 'pushbutton',...
                    'String', 'Select',...
                    'Tooltip', 'Changes TMSegTemplate to the selected template',...
                    'Callback', @SelectTemplate_Callback);
                uicontrol(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0.5 0 0.5 0.1],...
                    'Style', 'pushbutton',...
                    'String', 'Delete',...
                    'Tooltip', 'Deletes the selected template',...
                    'Callback', @DeleteTemplate_Callback);
                % Setting the keypress callback for the GUI and its
                % controls ensures that the callbacks work when the GUI has
                % focus.
                SetKeyPressCallback(templateDialog, @this.KeyPressFcn)
                SetKeyReleaseCallback(templateDialog, @this.KeyReleaseFcn)
                
                % The list should not listen to the key-callbacks, because
                % pressing the up-key would both change the list entry and
                % start playing the sequence.
                templateList = uicontrol(...
                    'Parent', templateDialog,...
                    'Units', 'normalized',...
                    'Position', [0 0.1 1 0.2],...
                    'Style', 'list',...
                    'String', availableTemplates,...
                    'Value', this.sPanel.GetIndex('TMSegTemplate'),...
                    'Tooltip', 'Available templates',...
                    'Callback', @TemplateList_Callback);
                
                % Draw the template.
                TemplateList_Callback([], [])
            else
                % Reuse the previous dialog.
                figure(templateDialog)  % Bring figure to the front.
                % Update the listbox alternatives in case more templates
                % have been added.
                set(templateList,...
                    'String', availableTemplates,...
                    'Value', this.sPanel.GetIndex('TMSegTemplate'))
            end
            
            function TemplateList_Callback(~, ~)
                % Draws the template when a selection is made in the list.
                
                selectedTemplate = availableTemplates{get(templateList, 'Value')};
                
                % Load the template.
                templatePath = FindFile('Templates', selectedTemplate);
                tmp = load(templatePath);
                templateImage = tmp.template;
                
                imshow(templateImage, 'Parent', templateAxes)
            end
            
            function SelectTemplate_Callback(~, ~)
                % Selects a template for segmentation from the list.
                %
                % This function changes the setting TMSegTemplate to the
                % template that is selected in the listbox. The callback
                % also closes the GUI.
                
                selectedTemplate = availableTemplates{get(templateList, 'Value')};
                this.sPanel.SetValue('TMSegTemplate', selectedTemplate)
                delete(templateDialog)
                templateDialog = [];
                this.Draw()
            end
            
            function DeleteTemplate_Callback(~, ~)
                % Deletes the selected template.
                %
                % This function removes the template that is selected in
                % the listbox, unless that template is used for
                % segmentation. An error dialog is opened if the template
                % is used for segmentation.
                
                deleteIndex = get(templateList, 'Value');
                deleteTemplate = availableTemplates{deleteIndex};
                selectedTemplate = this.sPanel.GetValue('TMSegTemplate');
                if strcmp(deleteTemplate, selectedTemplate)
                    % Opens an error dialog if the template to be deleted
                    % is used for segmentation.
                    errordlg('You cannot delete the selected template')
                else
                    availableTemplates = setdiff(availableTemplates, deleteTemplate);
                    
                    % Remove the template from the listbox.
                    set(templateList,...
                        'String', availableTemplates,...
                        'Value', min(deleteIndex,length(availableTemplates)))
                    TemplateList_Callback([], [])
                    
                    % Remove the template from the dropdown menu in the
                    % settings.
                    this.sPanel.SetAlternatives('TMSegTemplate',...
                        'advanced', availableTemplates)
                    
                    % Delete the template file.
                    delete(FindFile('Templates', deleteTemplate))
                end
            end
            
            function ClosetemplateDialog(~, ~)
                % Closes the GUI.
                
                delete(templateDialog)
                templateDialog = [];
            end
        end
        
        function oParams = PlotParameters(this)
            % Returns a struct with parameters used by plotting functions.
            %
            % Outputs:
            % oParams - Struct where every field is a plotting parameter.
            %           These parameters are only used internally and are
            %           different from the settings specified in the GUI.
            
            oParams = this.PlotParameters@CTCControlPlayer();
            oParams.color = this.sPanel.GetValue('Outline_color');
        end
        
        function [oBlobs, oImages] = Segment(this)
            % Performs segmentation of the current frame.
            %
            % The function returns segmented blobs and intermediate
            % segmentation results. If a tracking version is selected for
            % loading, the function will load the corresponding
            % segmentation instead of performing a segmentation, and then
            % no intermediate segmentation results will be returned. If the
            % 'Segment' option is set to 'shown region', only the zoomed in
            % region will be segmenting to save time.
            %
            % Outputs:
            % oBlobs - Array of segmented blobs.
            % oImages - Struct where every field is an image with an
            %           intermediate result of the segmentation algorithm.
            %           The field names of the structs determine the labels
            %           of the different intermediate results in the
            %           Display popupmenu.
            
            % Get segmentation options which have been specified in the
            % user interface.
            
            imData = this.GetImData();
            
            if any(strcmpi(imData.Get('SegAlgorithm'),...
                    {'Segment_import' 'Segment_import_binary'}))
                % Create an ImageData object for a segmentation that should
                % be loaded.
                imData.LoadSegImData()
            end
            
            oBlobs = [];
            if ~strcmpi(imData.Get('SegOldVersion'), 'none')
                % Read in an old segmentation if one was selected.
                readBlobFile = fullfile(...
                    imData.GetResumePath('Version', imData.Get('SegOldVersion')),...
                    'Segmentation',...
                    sprintf('blobs%04d.mat', this.frame));
                if exist(readBlobFile, 'file')
                    tmp = load(readBlobFile);
                    oBlobs = tmp.blobs;
                else
                    warning(['The selected tracking version does not '...
                        'have a saved segmentation.'])
                end
                oImages = struct();
            else
                [x1, x2, y1, y2, z1, z2] = GetZoom(this);
                % Segmenation using the selected segmentation settings.
                if imData.numZ == 1  % 2D
                    if strcmp(this.sPanel.GetValue('Segment'), 'shown region')
                        [oBlobs, ~, ~, oImages] = Segment_generic(...
                            imData, this.frame,...
                            'X1', x1, 'X2', x2, 'Y1', y1, 'Y2', y2);
                        
                        % Pad the output images to the full size.
                        fields = fieldnames(oImages);
                        for i = 1:length(fields)
                            tmp = zeros(imData.imageHeight,...
                                imData.imageWidth);
                            tmp(y1:y2, x1:x2) = oImages.(fields{i});
                            oImages.(fields{i}) = tmp;
                        end
                        
                        % Shift the blob bounding boxes to the full image.
                        for i = 1:length(oBlobs)
                            oBlobs(i).boundingBox = oBlobs(i).boundingBox +...
                                [x1-1 y1-1 0 0];
                        end
                    else
                        [oBlobs, ~, ~, oImages] = Segment_generic(...
                            imData, this.frame);
                    end
                else  % 3D
                    if strcmp(this.sPanel.GetValue('Segment'), 'shown region')
                        [oBlobs, ~, ~, oImages] = Segment_generic3D(...
                            imData,...
                            this.frame,...
                            'X1', x1,...
                            'X2', x2,...
                            'Y1', y1,...
                            'Y2', y2,...
                            'Z1', z1,...
                            'Z2', z2);
                        
                        % Pad the output images to the full size.
                        fields = fieldnames(oImages);
                        for i = 1:length(fields)
                            tmp = zeros(imData.imageHeight,...
                                imData.imageWidth, imData.numZ);
                            tmp(y1:y2, x1:x2, z1:z2) = oImages.(fields{i});
                            oImages.(fields{i}) = tmp;
                        end
                        
                        % Shift the blob bounding boxes to the full image.
                        for i = 1:length(oBlobs)
                            oBlobs(i).boundingBox = oBlobs(i).boundingBox +...
                                [x1-1 y1-1 z1-1 0 0 0];
                        end
                    else
                        [oBlobs, ~, ~, oImages] = Segment_generic3D(...
                            imData, this.frame);
                    end
                end
            end
        end
        
        function Draw(this, varargin)
            % Draws the segmented outlines on top of an image.
            %
            % The function draws an up to date segmentation on top either
            % the original image, or an intermediate segmentation result.
            % The function executes the segmentation functions, and
            % therefore it can take a while to finish. If the segmentation
            % has already been computed, you should use Draw3D instead,
            % which displays the segmentation computed last. While the
            % segmentation is being computed, the text 'Computing
            % segmentation...' will be displayed on top of the image. The
            % function will draw results in all views if 3D data is
            % visualized. Most of the plotting is done by calling Draw3D.
            % This function usually only computes the segmentation, but if
            % the parameter Linger is set to false, the function will plot
            % the outlines on top of an image already presented by Draw3D,
            % to avoid drawing the image twice.
            %
            % Property/Value inputs:
            % Linger - Normally, the previously displayed image will be
            %          shown until the segmentation has finished. If this
            %          parameter is set to false, the image being segmented
            %          will be displayed instead. This is nice when a new
            %          image sequence is opened, but usually it is better
            %          to be able to look at the previous segmentation
            %          until the new one is ready, so that it is easier to
            %          compare the two segmentations.
            %
            % See also:
            % Draw3D, PlotBlobs, DrawXY, DrawXZ, DrawYZ
            
            aLinger = GetArgs({'Linger'}, {true}, true, varargin);
            
            if ~aLinger
                % Display the unprocessed current image while the
                % segmentation is computed.
                this.blobs = [];
                display = this.sPanel.GetValue('Display');
                this.sPanel.SetValue('Display', 'original');
                this.Draw3D()
                this.sPanel.SetValue('Display', display);
            end
            
            if get(this.updateButton, 'value')
                this.DisplayText('Computing segmentation...', 'y')
                
                % Perform the segmentation.
                [this.blobs, this.images] = this.Segment();
                
                % Update the popupmenu alternatives specifying which image
                % should be displayed under the segmentation, based on
                % which intermediate segmentation results are available.
                newImageNames = [{'original'}; fieldnames(this.images)];
                currentImageName = this.sPanel.GetValue('Display');
                if any(strcmp(newImageNames, currentImageName))
                    % Keep the previously selected image type.
                    this.sPanel.SetAlternatives('Display', 'advanced', newImageNames)
                    this.sPanel.SetValue('Display', currentImageName)
                else
                    % The previously selected image type is no longer
                    % available, so the unprocessed image will be used. The
                    % value needs to be changed before the alternatives are
                    % changed, because otherwise, the selected value will
                    % not be a valid alternative.
                    this.sPanel.SetValue('Display', 'original')
                    this.sPanel.SetAlternatives('Display', 'advanced', newImageNames)
                end
            else
                this.images = struct();
                this.sPanel.SetValue('Display', 'original')
                this.sPanel.SetAlternatives('Display', 'advanced', {'original'})
            end
            
            if aLinger
                % Update everything.
                this.Draw3D()
            elseif get(this.updateButton, 'value')
                % Remove the text 'Computing segmentation...'.
                this.DisplayText('', 'y')
                
                % Display the segmentation.
                this.PlotBlobs()
            end
        end
        
        function Draw3D(this)
            % Draws a pre-computed segmentation on top of an image.
            %
            % The image can either be the original image or an intermediate
            % segmentation result. The function does almost all of the
            % plotting for the function Draw, but without computing a new
            % segmentation. This is useful when only display parameters are
            % changed, so that the segmentation does not need to be
            % altered.
            %
            % See also:
            % Draw
            
            % The functions DrawXY, DrawXZ and DrawYZ have been redefined
            % in this class, so that an intermediate segmentation result
            % can be shown instead of the original image.
            this.Draw3D@CTCControlPlayer()
            
            if get(this.updateButton, 'value')
                this.PlotBlobs()
            else
                this.DisplayText(...
                    'Press the Update button to see up to date segmentation!',...
                    'r')
            end
        end
        
        function DisplayText(this, aText, aColor)
            % Displays a text on top of all plotting axes.
            %
            % The text is meant to give the user an idea about what the
            % program is doing. To remove the text, you can call this
            % function again with '' as the text input. The same text is
            % shown in the xy-, xz-, and yz-axes if 3D data is visualized.
            %
            % Inputs:
            % aText - Character array with the text to be displayed.
            % aColor - Color of the displayed text.
            
            plotParams = this.PlotParameters();
            
            % Remove old text objects.
            if ishandle(this.textXY)
                delete(this.textXY)
            end
            if ishandle(this.textXZ)
                delete(this.textXZ)
            end
            if ishandle(this.textYZ)
                delete(this.textYZ)
            end
            
            if isempty(aText)
                return
            end
            
            [x1, x2, y1, y2, z1, z2] = this.GetZoom();
            
            if this.GetImData().GetDim() == 2 ||...
                    any(strcmp({'xy', 'all'}, plotParams.display))
                this.textXY = text(x1+(x2-x1)/10, y1+(y2-y1)/2,...
                    aText,...
                    'FontSize', 16,...
                    'Color', aColor,...
                    'Parent', this.ax);
            end
            
            if this.GetImData().GetDim() == 3 &&...
                    any(strcmp({'xz', 'all'}, plotParams.display))
                this.textXZ = text(x1+(x2-x1)/10, z1+(z2-z1)/2,...
                    aText,...
                    'FontSize', 16,...
                    'Color', aColor,...
                    'Parent', this.axXZ);
            end
            
            if this.GetImData().GetDim() == 3 &&...
                    any(strcmp({'yz', 'all'}, plotParams.display))
                this.textYZ = text(z1+(z2-z1)/2, y2-(y2-y1)/10,...
                    aText,...
                    'Rotation', 90,...
                    'FontSize', 16,...
                    'Color', aColor,...
                    'Parent', this.axYZ);
            end
            
            % Make sure to display the text right away, as it is a message
            % to the user.
            drawnow()
        end
        
        function PlotBlobs(this)
            % Displays the currently segmented blobs on top of an image.
            %
            % The function will also display ground truth blobs in green,
            % if there is a ground truth segmentation selected. The color
            % of the segmented outlines is red by default, but can be
            % selected in the SettingsPanel. The function plots blobs in
            % all 2D views if 3D data is displayed.
            %
            % See also:
            % PlotBlobsXY, PlotBlobsXZ, PlotBlobsYZ
            
            plotParams = this.PlotParameters();
            
            % Crop out the blobs and parts of blobs that are not shown.
            if this.GetImData().GetDim() == 3
                [x1, x2, y1, y2, z1, z2] = GetZoom(this);
                plotBlobs = CropBlobs(this.blobs, x1, x2, y1, y2, z1, z2);
            else
                plotBlobs = this.blobs;
            end
            
            if this.GetImData().GetDim() == 2 ||...
                    any(strcmp({'xy', 'all'}, plotParams.display))
                hold(this.ax, 'on')
                if ~isempty(this.gtBlobs)
                    this.PlotBlobsXY(this.gtBlobs{this.frame}, [0 0.5 0])
                end
                if strcmp(get(this.outlineMenu, 'checked'), 'on')
                    this.PlotBlobsXY(plotBlobs, plotParams.color)
                end
            end
            
            if this.GetImData().GetDim() == 3 &&...
                    any(strcmp({'xz', 'all'}, plotParams.display))
                hold(this.axXZ, 'on')
                if ~isempty(this.gtBlobs)
                    this.PlotBlobsXZ(this.gtBlobs{this.frame}, [0 0.5 0])
                end
                if strcmp(get(this.outlineMenu, 'checked'), 'on')
                    this.PlotBlobsXZ(plotBlobs, plotParams.color)
                end
            end
            
            if this.GetImData().GetDim() == 3 &&...
                    any(strcmp({'yz', 'all'}, plotParams.display))
                hold(this.axYZ, 'on')
                if ~isempty(this.gtBlobs)
                    this.PlotBlobsYZ(this.gtBlobs{this.frame}, [0 0.5 0])
                end
                if strcmp(get(this.outlineMenu, 'checked'), 'on')
                    this.PlotBlobsYZ(plotBlobs, plotParams.color)
                end
            end
        end
        
        function DrawXY(this, aParams)
            % Displays the appropriate image in the xy-axes.
            %
            % This function overwrites the same function in the
            % super-class, so that intermediate segmentation results can be
            % displayed instead of the original image.
            %
            % Inputs:
            % aParams - Parameters for 3D visualization and other things.
            
            display = this.sPanel.GetValue('Display');
            if strcmp(display, 'original')
                this.DrawXY@CTCControlPlayer(aParams)
            else
                this.DrawXY@CTCControlPlayer(aParams,...
                    'Image', this.images.(display))
            end
        end
        
        function DrawXZ(this, aParams)
            % Displays the appropriate image in the xz-axes.
            %
            % This function overwrites the same function in the
            % super-class, so that intermediate segmentation results can be
            % displayed instead of the original image.
            %
            % Inputs:
            % aParams - Parameters for 3D visualization and other things.
            
            display = this.sPanel.GetValue('Display');
            if strcmp(display, 'original')
                this.DrawXZ@CTCControlPlayer(aParams)
            else
                this.DrawXZ@CTCControlPlayer(aParams,...
                    'Image', this.images.(display))
            end
        end
        
        function DrawYZ(this, aParams)
            % Displays the appropriate image in the yz-axes.
            %
            % This function overwrites the same function in the
            % super-class, so that intermediate segmentation results can be
            % displayed instead of the original image.
            %
            % Inputs:
            % aParams - Parameters for 3D visualization and other things.
            
            display = this.sPanel.GetValue('Display');
            if strcmp(display, 'original')
                this.DrawYZ@CTCControlPlayer(aParams)
            else
                this.DrawYZ@CTCControlPlayer(aParams,...
                    'Image', this.images.(display))
            end
        end
        
        function PlotBlobsXY(this, aBlobs, aColor)
            % Plots the outlines of blobs in the xy-axes.
            %
            % Both 2D and 3D data can be handled. If a 3D z-stack is shown
            % as a maximum intensity projection, the outlines of the blobs
            % seen from above will be displayed. If a single z-slice is
            % shown, the blob outlines in that slice are displayed. Point
            % blobs without regions are not drawn.
            %
            % Inputs:
            % aBlobs - Array of blob objects.
            % aColor - RGB-triplet or letter representing a color.
            %
            % See also:
            % PlotBlobs, PlotBlobsXZ, PlotBlobsYZ, Draw, Draw3D, DrawXY
            
            for bIndex = 1:length(aBlobs)
                bb = aBlobs(bIndex).boundingBox;
                if ~any(isnan(bb))
                    if this.GetImData().GetDim() == 2
                        B = bwboundaries(aBlobs(bIndex).image);
                        for k = 1:length(B)
                            b = B{k};
                            plot(bb(1)-0.5+b(:,2), bb(2)-0.5+b(:,1),...
                                'Color', aColor,...
                                'LineWidth', 1,...
                                'Parent', this.ax)
                        end
                    else  % 3D
                        if this.volumeSettingsPanel.GetValue('z_proj')
                            % Maximum intensity projection -> include a
                            % pixel if any voxel in that xy location is
                            % segmented.
                            slice = sum(aBlobs(bIndex).image,3) > 0;
                        else
                            % A single z-slice -> slice the blobs.
                            if  bb(3) > this.z || bb(3) + bb(6) < this.z
                                % Don't include blobs outside the slice.
                                continue
                            end
                            slice = aBlobs(bIndex).image(:, :, this.z - bb(3) + 0.5);
                        end
                        B = bwboundaries(slice);
                        
                        for k = 1:length(B)
                            b = B{k};
                            plot(bb(1)-0.5+b(:,2), bb(2)-0.5+b(:,1),...
                                'Color', aColor,...
                                'LineWidth', 1,...
                                'Parent', this.ax)
                        end
                    end
                else
                    plot(...
                        aBlobs(bIndex).centroid(1),...
                        aBlobs(bIndex).centroid(2),...
                        'go',...
                        'Parent', this.ax)
                end
            end
        end
        
        function PlotBlobsXZ(this, aBlobs, aColor)
            % Plots the outlines of blobs in the xz-axes.
            %
            % This function is only executed for 3D data. If a z-stack is
            % shown as a maximum intensity projection, the outlines of the
            % blobs seen from the (top/bottom-)side will be displayed. If a
            % single y-slice is shown, the blob outlines in that slice are
            % displayed. Point blobs without regions are not drawn.
            %
            % Inputs:
            % aBlobs - Array of blob objects.
            % aColor - RGB-triplet or letter representing a color.
            %
            % See also:
            % PlotBlobs, PlotBlobsXY, PlotBlobsYZ, Draw, Draw3D, DrawXZ
            
            for bIndex = 1:length(aBlobs)
                bb = aBlobs(bIndex).boundingBox;
                if ~any(isnan(bb))
                    % Permute the dimensions of the z-stack so that a sum
                    % or an indexing produces the desired 2D image.
                    im = permute(aBlobs(bIndex).image, [3 2 1]);
                    
                    if this.volumeSettingsPanel.GetValue('y_proj')
                        % Maximum intensity projection -> include a
                        % pixel if any voxel in that xz location is
                        % segmented.
                        slice = sum(im,3) > 0;
                    else
                        % A single y-slice -> slice the blobs.
                        if  bb(2) > this.y || bb(2) + bb(5) < this.y
                            % Don't include blobs outside the slice.
                            continue
                        end
                        slice = im(:, :, this.y - bb(2) + 0.5);
                    end
                    B = bwboundaries(slice);
                    
                    for k = 1:length(B)
                        b = B{k};
                        plot(bb(1)-0.5+b(:,2), bb(3)-0.5+b(:,1),...
                            'Color', aColor,...
                            'LineWidth', 1,...
                            'Parent', this.axXZ)
                    end
                else
                    plot(...
                        aBlobs(bIndex).centroid(1),...
                        aBlobs(bIndex).centroid(3),...
                        'go',...
                        'Parent', this.ax)
                end
            end
        end
        
        function PlotBlobsYZ(this, aBlobs, aColor)
            % Plots the outlines of blobs in the yz-axes.
            %
            % This function is only executed for 3D data. If a z-stack is
            % shown as a maximum intensity projection, the outlines of the
            % blobs seen from the (left/right-)side will be displayed. If a
            % single x-slice is shown, the blob outlines in that slice are
            % displayed. Point blobs without regions are not drawn.
            %
            % Inputs:
            % aBlobs - Array of blob objects.
            % aColor - RGB-triplet or letter representing a color.
            %
            % See also:
            % PlotBlobs, PlotBlobsXY, PlotBlobsXZ, Draw, Draw3D, DrawYZ
            
            for bIndex = 1:length(aBlobs)
                bb = aBlobs(bIndex).boundingBox;
                if ~any(isnan(bb))
                    % Permute the dimensions of the z-stack so that a sum
                    % or an indexing produces the desired 2D image.
                    im = permute(aBlobs(bIndex).image, [1 3 2]);
                    
                    if this.volumeSettingsPanel.GetValue('x_proj')
                        % Maximum intensity projection -> include a
                        % pixel if any voxel in that yz location is
                        % segmented.
                        slice = sum(im,3) > 0;
                    else
                        % A single x-slice -> slice the blobs.
                        if  bb(1) > this.x || bb(1) + bb(4) < this.x
                            % Don't include blobs outside the slice.
                            continue
                        end
                        slice = im(:, :, this.x - bb(1) + 0.5);
                    end
                    B = bwboundaries(slice);
                    for k = 1:length(B)
                        b = B{k};
                        plot(bb(3)-0.5+b(:,2), bb(2)-0.5+b(:,1),...
                            'Color', aColor,...
                            'LineWidth', 1,...
                            'Parent', this.axYZ)
                    end
                else
                    plot(...
                        aBlobs(bIndex).centroid(3),...
                        aBlobs(bIndex).centroid(2),...
                        'go',...
                        'Parent', this.ax)
                end
            end
        end
        
        function ExtraCallback(this, aObj, aEvent, aFun)
            % Executes a function handle and then executes Draw().
            %
            % The function is used to produce callbacks for uicontrols
            % associated with segmentation settings by adding Draw to an
            % existing callback .
            %
            % Inputs:
            % aObj - The control object that gave rise to the callback.
            % aEvent - Event object associated with the callback event.
            % aFun - A callback to execute before Draw.
            %
            % See also:
            % ExtraCallback3D, Draw
            
            if iscell(aFun)
                feval(aFun{1}, aObj, aEvent, aFun{2:end})
            else
                feval(aFun, aObj, aEvent)
            end
            
            this.SetVisible()
            drawnow()  % Display the figure before Draw() is done.
            
            if get(this.updateButton, 'value')
                this.Draw()
            end
        end
        
        function ExtraCallback3D(this, aObj, aEvent, aFun)
            % Executes a function handle and then executes Draw3D().
            %
            % The function is used to produce callbacks for uicontrols
            % associated with visualization settings by adding Draw3D to an
            % existing callback. This callback never computes a new
            % segmentation and is therefore faster than ExtraCallback, but
            % is not appropriate when a segmentation setting is changed.
            %
            % Inputs:
            % aObj - The control object that gave rise to the callback.
            % aEvent - Event object associated with the callback event.
            % aFun - A callback to execute before Draw3D.
            %
            % See also:
            % ExtraCallback, Draw3D
            
            if iscell(aFun)
                feval(aFun{1}, aObj, aEvent, aFun{2:end})
            else
                feval(aFun, aObj, aEvent)
            end
            
            this.SetVisible()
            drawnow()  % Display the figure before Draw() is done.
            
            if get(this.updateButton, 'value')
                this.Draw3D()
            end
        end
        
        function [oName] = GetName(~)
            % Returns the name of the player.
            %
            % The name will be displayed in the title of the main window
            % together with the path of the current image.
            
            oName = 'Segmentation parameters';
        end
        
        function GroundTruth_Callback(this, ~, ~)
            % Loads ground truth blobs when a new ground truth is selected.
            %
            % The cells associated with the ground truth version are
            % loaded, and then the super-blobs, which are not affected by
            % separation of clusters, are extracted. This function is
            % executed when a ground truth version is selected by the user.
            
            gtVer = this.sPanel.GetValue('Ground_truth');
            if ~strcmp(gtVer, 'none')
                gtCells = LoadCells(this.GetSeqPath(), gtVer);
                this.gtBlobs = Cells2Blobs(gtCells, this.GetImData());
            else
                this.gtBlobs = [];
            end
        end
        
        function SaveButton_Callback(this, aObj, ~, aFor)
            % Saves the selected segmentation settings.
            %
            % The settings are saved to the Settings.csv files
            % corresponding to the image sequences. Which image sequences
            % will get the settings depends on the last input argument.
            % Only the setting which can affect the segmentation results
            % are saved, to keep the number of settings in the settings
            % files small. Settings which are specific to other
            % segmentation algorithms than the one chosen will for example
            % not be saved.
            %
            % Inputs:
            % aObj - Button which triggered the callback.
            % aFor - Specifies for what image sequences the current
            %        settings should be saved. The following 3 options are
            %        allowed:
            %        'all'    = all sequences open in this GUI.
            %        'this'   = the current sequence
            %        'dialog' = opens a dialog box where the user can
            %                   choose sequences.
            
            % Remove focus from the control.
            set(aObj, 'Enable', 'off')
            drawnow()
            set(aObj, 'Enable', 'on')
            
            % Find the sequences that the settings will be saved for.
            switch lower(aFor)
                case 'all'
                    sel = 1:length(this.seqPaths);
                case 'this'
                    sel = this.seqIndex;
                case 'dialog'
                    [sel, ok] = listdlg(...
                        'ListString', this.seqPaths,...
                        'ListSize', [600, 100]);
                    if ~ok
                        return
                    end
            end
            
            % Generate variables for saving of settings.
            spreadSheets = {};
            exPaths = {};
            for i = 1:length(sel)
                exPath = this.GetExPath(sel(i));
                index = find(strcmp(exPaths, exPath));
                if isempty(index)
                    index = length(exPaths) + 1;
                    exPaths{index} = exPath; %#ok<AGROW>
                    spreadSheets{index} = ReadSettings(exPath); %#ok<AGROW>
                end
                
                for j = 1:this.settings.Size()
                    s = this.settings.Get(j);
                    % Save only the settings which affect the results.
                    if strcmp(s.category, 'segmentation') &&...
                            s.Visible(this.GetImData(sel(i)))
                        name = s.name;
                        value = this.sPanel.GetValue(name);
                        this.GetImData(sel(i)).Set(name, value)
                        % num2str on strings return the same strings.
                        spreadSheets{index} = SetSeqSettings(...
                            spreadSheets{index},...
                            this.GetImData(sel(i)).GetSeqDir(),...
                            name,...
                            num2str(value)); %#ok<AGROW>
                    end
                end
            end
            
            % Save the settings to csv-files.
            for i = 1:length(exPaths)
                WriteSettings(exPaths{i}, spreadSheets{i})
            end
            
            fprintf('Done saving segmentation parameters.\n')
        end
        
        function UpdateButton_Callback(this, ~, ~)
            % Executed when the update-button is pressed.
            %
            % The update button is a toggle-button. When it is pressed
            % down, this callback starts showing up to date segmentations.
            % When it is up, the callback keeps whatever is plotted and
            % adds a text to the axes saying that updates are not made.
            
            % Remove focus from the control.
            set(this.updateButton, 'Enable', 'off')
            drawnow()
            set(this.updateButton, 'Enable', 'on')
            
            % Updates the button before the segmentation is done.
            drawnow()
            
            if get(this.updateButton, 'value')
                this.Draw()
            else
                this.DisplayText(...
                    'Press the Update button to see up to date segmentation!',...
                    'r')
            end
        end
        
        function RevertButton_Callback(this, ~, ~)
            % Goes back to the previously saved segmentation parameters.
            %
            % The function reads whatever settings are saved in the
            % settings file and puts them into the GUI controls. The button
            % is a toggle-button, and when it is pressed down, settings
            % will be loaded from the appropriate settings files when the
            % image sequence is replaced. If the button is up, the settings
            % will not be altered, unless the dimensionality of the data is
            % changed.
            
            % Remove focus from the control.
            set(this.revertButton, 'Enable', 'off')
            drawnow()
            set(this.revertButton, 'Enable', 'on')
            
            if ~get(this.revertButton, 'value')
                % Don't do anything when the button is deselected.
                return
            end
            
            oldImData = this.GetImData();
            
            % Overwrite the entire ImageData object to replace the settings
            % with the ones from the settings file.
            this.imDatas{this.seqIndex} = ImageData(this.GetSeqPath());
            
            % Copy visualization settings from the old ImageData object.
            newImData = this.imDatas{this.seqIndex};
            newImData.Add('Display', oldImData.Get('Display'), 1)
            newImData.Add('Outline_color', oldImData.Get('Outline_color'), 2)
            newImData.Add('Ground_truth', oldImData.Get('Ground_truth'), 3)
            newImData.Add('Segment', oldImData.Get('Segment'), 4)
            
            % Copy dummy settings for template buttons from the old
            % ImageData object.
            newImData.Add('Create_matching_template', [])
            newImData.Add('Manage_matching_templates', [])
            
            % Update the controls on the SettingsPanel.
            this.sPanel.SwitchSettings(this.GetImData())
            
            this.SetVisible()
            drawnow() % Update the window before Draw() is done.
            
            this.Draw()
        end
        
        function LevelCallback(this, aObj, ~)
            % Callback executed when one of the level menus is clicked.
            %
            % The callback deselects all other Setting levels and then
            % updates the set of controls displayed.
            
            otherMenus = setdiff(...
                [this.basicMenu,...
                this.advancedMenu,...
                this.developmentMenu], aObj);
            set(aObj, 'Checked', 'on')
            set(otherMenus(1), 'Checked', 'off')
            set(otherMenus(2), 'Checked', 'off')
            this.SetVisible()
        end
        
        function OutlineMenu_Callback(this, ~, ~)
            % Called when the menu for toggling of outlines is pressed.
            %
            % The function toggles the check mark on the menu and updates
            % the plotting.
            
            if strcmp(get(this.outlineMenu, 'checked'), 'on')
                set(this.outlineMenu, 'Checked', 'off')
            else
                set(this.outlineMenu, 'Checked', 'on')
            end
            this.Draw3D()
        end
        
        function SetVisible(this)
            % Makes the selected set of Settings visible.
            %
            % Which settings are displayed in the SettingsPanel depends on
            % which level menu has been selected. If a higher level is
            % selected, settings up to that level are displayed. If for
            % example 'advanced' is selected, settings with the levels
            % 'basic' and 'advanced' will be displayed. This function also
            % hides setting which don't affect the segmentation.
            
            if strcmp(get(this.basicMenu, 'Checked'), 'on')
                levels = {'basic'};
            elseif strcmp(get(this.advancedMenu, 'Checked'), 'on')
                levels = {'basic' 'advanced'};
            elseif strcmp(get(this.developmentMenu, 'Checked'), 'on')
                levels = {'basic' 'advanced' 'development'};
            end
            
            % Visualization and segmentation are the only setting
            % categories.
            this.sPanel.SetVisible({'visualization' 'segmentation'}, levels)
        end
        
        function SwitchSequence(this, aIndex)
            % Switches to displaying a new image sequence in the GUI.
            %
            % If the revert button is down, or if the dimensionality of the
            % data is changed, the segmentation settings for the new image
            % sequence will be loaded from the corresponding settings file.
            % Otherwise the segmentation settings of the previous image
            % sequence will be used. The function also updates the ground
            % truth and plots the segmentation of the new sequence. While
            % the segmentation is computed, the un-processed image from the
            % new sequence is displayed. The function also tries to load a
            % ground truth segmentation if one is selected in the GUI.
            %
            % Inputs:
            % aIndex - The index of the new image sequence in the array of
            %          sequence paths.
            
            oldImData = this.GetImData();
            
            this.SwitchSequence@CTCControlPlayer(aIndex, 'Draw', false);
            
            if get(this.revertButton, 'value') ||...
                    this.GetImData().GetDim() ~= oldImData.GetDim()
                % Overwrite the entire ImageData object to replace the
                % settings with the ones from the settings file.
                this.imDatas{this.seqIndex} = ImageData(this.GetSeqPath());
            end
            
            % Copy visualization settings from the previous image sequence.
            if ~this.GetImData().Has('Display')
                this.GetImData().Add('Display', oldImData.Get('Display'), 1)
                this.GetImData().Add('Outline_color', oldImData.Get('Outline_color'), 2)
                this.GetImData().Add('Ground_truth', oldImData.Get('Ground_truth'), 3)
                this.GetImData().Add('Segment', oldImData.Get('Segment'), 4)
                % Copy dummy settings for template buttons from the
                % previous image sequence.
                this.GetImData().Add('Create_matching_template', [])
                this.GetImData().Add('Manage_matching_templates', [])
            end
            
            if get(this.revertButton, 'value') ||...
                    this.GetImData().GetDim() ~= oldImData.GetDim()
                % Load settings from the settings file if the revert button
                % is down or if the dimensionality of the data changes.
                this.sPanel.SwitchSettings(this.GetImData())
            else
                % Try to keep all the settings from the previous sequence.
                this.sPanel.SwitchSettings(...
                    this.GetImData(),...
                    'KeepSettings',...
                    {'visualization' 'segmentation'})
            end

            this.GroundTruth_Callback([], [])
            
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
            this.Draw('Linger', false);
        end
        
        function Close(this, ~, ~)
            % Callback executed before the figure is closed.
            %
            % The function saves the selected settings level for next time
            % that the GUI is opened, and closes all uicontrols on the
            % SettingsPanel, so that the figure can be closed faster.
            
            % Saves the selected settings level so that it can be
            % recalled the next time the GUI is opened.
            if strcmp(get(this.basicMenu, 'Checked'), 'on')
                level = 'basic';
            elseif strcmp(get(this.advancedMenu, 'Checked'), 'on')
                level = 'advanced';
            elseif strcmp(get(this.developmentMenu, 'Checked'), 'on')
                level = 'development';
            end
            SaveVariable('SegmentationPlayer_level', level)
            
            % Closing the figure takes approximately 27 seconds if the
            % controls are not deleted first.
            controls = this.sPanel.controls;
            for i = 1:length(controls)
                delete(controls(i))
            end
            
            delete(this.mainFigure)
        end
        
        function KeyPressFcn(this, aObj, aEvent)
            % Called when a keyboard key is pressed.
            %
            % This function is redefined to add keyboard shortcuts to
            % increase and decrease the size of segmentation templates
            % created for Segment_template. All other keyboard shortcuts
            % are the same as in the super class.
            
            switch aEvent.Character
                case '+'
                    % Make the template two pixels larger.
                    if this.creatingTemplate
                        this.templateSize = min(this.templateSize + 2,...
                            min(this.GetImData().GetSize()));
                        this.WindowButtonMotionFcn(this.mainFigure, [])
                    end
                case '-'
                    % Make the template two pixels smaller.
                    if this.creatingTemplate
                        this.templateSize = max(this.templateSize - 2, 3);
                        this.WindowButtonMotionFcn(this.mainFigure, [])
                    end
                case 'z'
                    % Toggle plotting of outlines.
                    this.OutlineMenu_Callback([], [])
                otherwise
                    % Use keyboard shortcuts from the super class.
                    this.KeyPressFcn@CTCControlPlayer(aObj, aEvent)
            end
        end
        
        function WindowButtonDownFcn(this, aObj, ~)
            % Performs zooming and selection of planes in 3D volumes.
            %
            % If the user has specified to segment only the displayed
            % region, the segmentation needs to be redone. Therefore, this
            % function is redefined. Executed when the user presses down
            % the mouse button.
            
            if strcmp(get(aObj,'SelectionType'), 'extend')
                this.WindowButtonDownFcn@ZControlPlayer(aObj, [])
            else
                if this.creatingTemplate
                    this.WindowButtonDownFcn_template(aObj, [])
                else
                    this.WindowButtonDownFcn@SequencePlayer(aObj, [])
                    if strcmp(get(aObj,'SelectionType'), 'alt')
                        if strcmp(this.sPanel.GetValue('Segment'), 'everything')
                            % Only redo the plot.
                            this.Draw3D()
                        else
                            % Redo segmentation.
                            this.Draw()
                        end
                    end
                end
            end
        end
        
        function WindowButtonDownFcn_template(this, ~, ~)
            % Callback for mouse clicks during template creation.
            %
            % The function cuts out the region iside the blue square shown
            % during creation of templates for Segment_template, and sends
            % the cut out template to the template creation GUI.
            
            % Get the current cursor coordinates.
            xy = get(this.ax, 'CurrentPoint');
            x = round(xy(1,1));
            y = round(xy(1,2));
            
            % Compute the bounding box of the template to be cropped out.
            ts = floor(this.templateSize/2);
            x1 = x - ts;
            x2 = x + ts;
            y1 = y - ts;
            y2 = y + ts;
            
            [x1zoom, x2zoom, y1zoom, y2zoom] = this.GetZoom();
            if x1 < x1zoom || x2 > x2zoom || y1 < y1zoom || y2 > y2zoom
                % The whole template must be inside the shown image.
                return
            end
            
            % Crop out a template.
            image = this.GetImData.GetDoubleImage(this.frame) / 255;
            template = image(y1:y2, x1:x2);
            
            % Pass the template to the template creation GUI.
            this.CreateTemplate(template)
        end
        
        function WindowButtonMotionFcn(this, aObj, aEvent, varargin)
            % Overloads callback for mouse moves, to handle tempate making.
            
            if this.creatingTemplate
                this.WindowButtonMotionFcn_template(aObj, aEvent)
            else
                this.WindowButtonMotionFcn@CTCControlPlayer(aObj, aEvent, varargin{:})
            end
        end
        
        function WindowButtonMotionFcn_template(this, ~, ~)
            % Callback for mouse moves during template creation.
            %
            % This function displays a blue square around the region that
            % can be cut out to create a template for Segment_template.
            
            % Remove a previously drawn template box if one exists.
            if ~isempty(this.lines)
                for i = 1:length(this.lines)
                    if ishandle(this.lines(i))
                        delete(this.lines(i))
                    end
                end
                this.lines = [];
            end
            
            % Get the current cursor coordinates.
            xy = get(this.ax, 'CurrentPoint');
            x = round(xy(1,1));
            y = round(xy(1,2));
            
            % Get x- and y-coordinates of a bounding box for the template.
            ts = floor(this.templateSize/2);
            x1 = x - ts;
            x2 = x + ts;
            y1 = y - ts;
            y2 = y + ts;
            
            [x1zoom, x2zoom, y1zoom, y2zoom] = this.GetZoom();
            if x1 < x1zoom || x2 > x2zoom || y1 < y1zoom || y2 > y2zoom
                % The whole template must be inside the shown image.
                return
            end
            
            % Move the bounding box from the pixel centers to the pixel
            % borders.
            x1 = x1 - 0.5;
            x2 = x2 + 0.5;
            y1 = y1 - 0.5;
            y2 = y2 + 0.5;
            
            % Draw the box.
            rect = plot(this.ax, [x1 x1 x2 x2 x1], [y1 y2 y2 y1 y1], 'b');
            this.lines = [this.lines rect];
        end
        
        function WindowButtonUpFcn(this, aObj, aEvent)
            % Performs zooming in 3D volumes.
            %
            % If the user has specified to segment only the displayed
            % region, the segmentation needs to be redone. Therefore, this
            % function is redefined. Executed when the user releases the
            % mouse button.
            
            changed = this.WindowButtonUpFcn@SequencePlayer(aObj, aEvent);
            
            if ~changed
                % The axis limits were not changed.
                return
            end
            
            if strcmp(this.sPanel.GetValue('Segment'), 'everything')
                % Only redo the plot.
                this.Draw3D()
            else
                % Redo segmentation.
                this.Draw()
            end
        end
        
        function WindowScrollWheelFcn(this, aObj, aEvent)
            % Executes when the mouse scroll wheel is turned.
            %
            % This function will change the size of the region for creation
            % of segmentation templates if the 'Create matching-template'
            % button is pressed. If you scroll towards you, you make the
            % template bigger and if you scroll away from you, you make it
            % smaller. You can also make it bigger by pressing + and
            % smaller by pressing -. The dimensions of the template are odd
            % numbers. The smallest size is 3x3 pixels and the largest size
            % is constrained by the smallest image dimension.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - Struct with information about how much the user
            %          scrolled.
            %
            % See also:
            % KeyPressFcn
            
            % Do not do anything unless the user is creating a template.
            if ~this.creatingTemplate
                return
            end
            
            % Change the size of the template region to the nearest odd
            % number in the requested direction.
            if aEvent.VerticalScrollCount > 0
                this.templateSize = min(this.templateSize + 2,...
                    min(this.GetImData().GetSize()));
            elseif aEvent.VerticalScrollCount < 0
                this.templateSize = max(this.templateSize - 2, 3);
            end
            
            % Draw the new template region.
            this.WindowButtonMotionFcn(aObj, [])
        end
    end
end