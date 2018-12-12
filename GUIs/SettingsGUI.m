function SettingsGUI(aExPaths, varargin)
% Opens a GUI where all processing settings can be changed.
%
% The GUI allows the user to review and change all settings associated with
% the open experiments. The settings are separated into the categories
% 'image', 'segmentation', 'tracking' and 'analysis'. There is a popupmenu
% where the user can select which category to display settings from. In the
% same way, the settings belong to one of the levels 'basic', 'advanced'
% and 'development'. If the user selects a level in the corresponding menu,
% settings from all levels up to and including that level will be
% displayed. The 'basic' settings should be sufficient to process most
% image sequences, the 'advanced'  settings can be important in order to
% get better performance, and the 'development' settings are only meant for
% development and should not be altered by users unless instructed to do
% so. The GUI generates all control objects associated with settings using
% the SettingsPanel class, which checks that settings values are valid and
% sets the visibility of the controls automatically.
%
% The GUI has a listbox to the left with the names of all image sequences
% and control objects to the right which display the settings of the
% selected images. If there are multiple values for the same setting in a
% selection of image sequences, the value of the setting will be displayed
% as *****MIXED***** in the GUI.
%
% There is a button to revert all settings values to the values stored in
% the settings files. The settings in the GUI can be saved to the settings
% files by pressing a 'Save' button. Only the settings which are currently
% visible in the GUI are saved. Settings from all categories are saved, but
% the settings which are hidden because they don't have an effect on the
% processing are omitted. If the 'development' level is selected,
% there is also a 'Save clean' button which remove all preexisting settings
% from the setting file before the displayed settings are saved. This can
% be useful when the user wants to share small settings files without
% redundant settings, for example for publication.
%
% The GUI will show all image sequences in the experiment folders,
% including the sequences for which the 'use' property has been set to 0.
% This is to allow the user to change the 'use' property back to 1.
%
% Inputs:
% aExPaths - Cell array with the paths of the experiments for which
%            settings need to be reviewed or changed.
%
% Property/Value inputs:
% CloseFunction - Function handle of a function which will be executed
%                 after the GUI has been closed, if new settings have been
%                 saved. The default is an empty function.
% Selection - Cell array with full path names of image sequences that
%             should be selected in the image sequence listbox when the GUI
%             is opened. All image sequences will be selected if this
%             parameter is omitted or if it is set to an empty cell.
%
% See also:
% BaxterAlgorithms, SettingsPanel, SegmentationPlayer

% Parse property/value inputs.
[aCloseFunction, aSelection] = GetArgs(...
    {'CloseFunction', 'Selection'},...
    {@()disp(''), {}},...
    true, varargin);

seqDirs = {};  % Names of the image sequence folders.
seqPaths = {};  % Full path names of the image sequence folders.
ex = [];  % Vector specifying what experiments the sequence folders belong to.
data = cell(size(aExPaths));  % Store all spread sheets in a cell array.
imParams = [];  % Store all settings structures in an array.
for ep = 1:length(aExPaths)
    newSeqDirs = GetSeqDirs(aExPaths{ep});
    newSeqPaths = strcat(aExPaths{ep}, filesep, newSeqDirs);
    
    seqDirs = [seqDirs; newSeqDirs]; %#ok<AGROW>
    seqPaths = [seqPaths; newSeqPaths]; %#ok<AGROW>
    ex = [ex; ones(length(newSeqDirs),1)*ep]; %#ok<AGROW>
    data{ep} = ReadSettings(aExPaths{ep});
    
    
    wbar = waitbar(0,...
        sprintf('Experiment %d / %d', ep, length(aExPaths)),...
        'Name', 'Loading settings');
    for seq = 1:length(newSeqPaths)
        imParams = [imParams
            ImageParameters(newSeqPaths{seq}, 'SpreadSheet', data{ep})]; %#ok<AGROW>
        waitbar(seq/length(newSeqPaths), wbar)
    end
    delete(wbar)
end
% By default, all image sequences are selected.
if isempty(aSelection)
    aSelection = seqPaths;
end

% Indices of the image sequences that are selected from the start.
selectionIndices = find(ismember(seqPaths, aSelection));

if isempty(seqPaths)
    errordlg(['You need to open an experiment with at least one image '...
        'sequence to open the settings dialog.'], 'No image sequences')
    return
end

settings = AllSettings();

mainFigure = figure(...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Settings',...
    'Units', 'normalized',...
    'Position', [0.3 0.1 0.4 0.8],...
    'CloseRequestFcn', @(aObj, aEvent)Close(aObj, aEvent));

% Create menus where the user can select different settings categories.
categoryMenu = uimenu('Parent', mainFigure, 'Label', 'Category');
imageMenu = uimenu(...
    'Parent', categoryMenu,...
    'Label', 'image',...
    'Callback', @CategoryCallback);
segmentationMenu = uimenu(...
    'Parent', categoryMenu,...
    'Label', 'segmentation',...
    'Callback', @CategoryCallback);
trackingMenu = uimenu(...
    'Parent', categoryMenu,...
    'Label', 'tracking',...
    'Callback', @CategoryCallback);
analysisMenu = uimenu(...
    'Parent', categoryMenu,...
    'Label', 'analysis',...
    'Callback', @CategoryCallback);

% Display the category which was displayed the last time the GUI was open,
% or the 'image' category if the GUI has not been open before.
category = LoadVariable('SettingsGUI_category');
if isempty(category)
    category = 'image';
end

% Check the correct category menu.
switch category
    case 'image'
        set(imageMenu, 'Checked', 'on')
    case 'segmentation'
        set(segmentationMenu, 'Checked', 'on')
    case 'tracking'
        set(trackingMenu, 'Checked', 'on')
    case 'analysis'
        set(analysisMenu, 'Checked', 'on')
    otherwise
        error('Unknown category %s.\n', category)
end

% Create menus where the user can select what settings levels to display.
levelMenu = uimenu('Parent', mainFigure, 'Label', 'Level');
basicMenu = uimenu(...
    'Parent', levelMenu,...
    'Label', 'basic',...
    'Callback', @LevelCallback);
advancedMenu = uimenu(...
    'Parent', levelMenu,...
    'Label', 'advanced',...
    'Callback', @LevelCallback);
developmentMenu = uimenu(...
    'Parent', levelMenu,...
    'Label', 'development',...
    'Callback', @LevelCallback);

% List box with the names of all image sequences.
nameListBox = uicontrol(...
    'Style', 'listbox',...
    'Value', selectionIndices,...
    'Min', 0,...
    'Max', 2,...
    'Units', 'normalized',...
    'String', seqDirs,...
    'Position', [0 0.05 0.5 0.95],...
    'Callback', @NameListBox_Callback);

% Panel with all settings.
sPanel = SettingsPanel(settings,...
    'Parameters', imParams(selectionIndices),...
    'Categories', 'image',...
    'Levels', 'basic',...
    'Parent', mainFigure,...
    'Position', [0.5 0.05 0.5 0.95],...
    'Split', 0.4,...
    'MaxRowHeight', 1/25);

% Reverts to saved settings for the selected image sequences.
revertButton = uicontrol('Style', 'pushbutton',...
    'String', 'Revert to saved',...
    'Units', 'normalized',...
    'Position', [0 0 0.5 0.05],...
    'Tooltip', 'Revert all changes that have not been saved to file',...
    'Callback', @RevertButton_Callback);

% Saves settings.
saveButton = uicontrol('Style', 'pushbutton',...
    'String', 'Save',...
    'Units', 'normalized',...
    'Position', [0.5 0 0.5 0.05],...
    'Tooltip', 'Save all changes to file',...
    'Callback', @SaveButton_Callback);

% Creates a new settings file with only the necessary settings.
saveCleanButton = uicontrol('Style', 'pushbutton',...
    'String', 'Save clean',...
    'Units', 'normalized',...
    'visible', 'off',...
    'Position', [2/3 0 1/3 0.05],...
    'Tooltip', 'Save changes to file and remove unused settings',...
    'Callback', {@SaveButton_Callback, 'Clean', true});

% Display the settings levels which were displayed last time the GUI was
% open, or the 'basic' settings if the GUI has not been open before.
level = LoadVariable('SettingsGUI_level');
if isempty(level)
    level = 'basic';
end

% Check the correct level menu.
switch level
    case 'basic'
        set(basicMenu, 'Checked', 'on')
        LevelCallback(basicMenu)
    case 'advanced'
        set(advancedMenu, 'Checked', 'on')
        LevelCallback(advancedMenu)
    case 'development'
        set(developmentMenu, 'Checked', 'on')
        LevelCallback(developmentMenu)
    otherwise
        error('Unknown level %s.\n', level)
end

    function SaveButton_Callback(~, ~, varargin)
        % Called when the user presses 'Save' or 'Save clean'.
        %
        % This function saves the settings which have been selected in the
        % GUI to the appropriate settings files. Only the settings which
        % can affect the processing results are saved. Other settings are
        % omitted, even if they were edited and then hidden. This is to
        % reduce the number of settings in the settings files. Settings
        % are saved for image sequences even if they are not selected.
        %
        % Property/Value inputs:
        % Clean - If this is set to true, the function will remove all
        %         preexisting settings from the settings file before the
        %         necessary settings are saved. This will remove settings
        %         which are no longer used and can thereby create smaller
        %         settings files.
        
        aClean = GetArgs({'Clean'}, {false}, true, varargin);
        
        if aClean
            % Remove all of the contents from the spreadsheets before the
            % new settings are entered.
            data = cell(size(data));
            for i = 1:length(data)
                data{i} = {'file'};
            end
        end
        
        % Cell array with the settings before they were changed.
        oldData = data;
        
        % Add all of the settings shown in the GUI (at the 'development'
        % level) to the spreadsheets.
        wbar = waitbar(0, 'Saving settings');
        for i = 1:length(imParams)
            % Create a cell array of input arguments for SetSeqSettings.
            inputs = {};
            for j = 1:settings.Size()
                s = settings.Get(j);
                if s.Visible(imParams(i))
                    inputs = [inputs
                        {s.name; num2str(imParams(i).Get(j))}]; %#ok<AGROW>
                end
            end
            
            data{ex(i)} = SetSeqSettings(data{ex(i)}, seqDirs{i}, inputs{:});
            
            waitbar(i/length(imParams), wbar)
        end
        delete(wbar)
        
        % Write the settings to the appropriate csv-files.
        for exIndex = 1:length(aExPaths)
            WriteSettings(aExPaths{exIndex}, data{exIndex})
            fprintf('Wrote to file %s\n',...
                fullfile(aExPaths{exIndex}, 'Settings.csv'));
        end
        
        % If any of the following settings have been changed, the closing
        % function has to be executed.
        updateSettings = {
            'numZ'
            'zStacked'
            'bits'
            'channelNames'
            'channelTags'
            'channelColors'
            'channelMin'
            'channelMax'
            'use'
            };
        % Check if any of the above settings have been changed.
        update = false;
        for j = 1:length(updateSettings)
            for i = 1:length(imParams)
                oldValue = GetSeqSettings(...
                    oldData{ex(i)}, seqDirs{i}, updateSettings{j});
                newValue = GetSeqSettings(...
                    data{ex(i)}, seqDirs{i}, updateSettings{j});
                if ~strcmp(newValue, oldValue)
                    update = true;
                    break
                end
            end
            if update
                break
            end
        end
        
        if update
            Close([], [], 'CloseFunction', aCloseFunction)
        else
            Close([], [])
        end
    end

    function RevertButton_Callback(~, ~)
        % Revert all settings values to the values in the settings files.
        %
        % This takes back all changes for the selected image sequences by
        % going back to the settings from the csv-files.
        
        marked = get(nameListBox, 'Value');  % Selected sequences.
        for i = 1:length(marked)
            % Replace the parameter objects instead of modifying them.
            imParams(marked(i)) = ImageParameters(seqPaths{marked(i)},...
                'SpreadSheet', data{ex(marked(i))});
        end
        
        % Associate the new parameter objects with the SettingsPanel. This
        % will also update the values of the control objects.
        sPanel.SwitchSettings(imParams(marked));
    end

    function CategoryCallback(aObj, ~)
        % Callback executed when the user selects a settings category.
        %
        % The function deselects all of the other settings categories and
        % switches which settings are displayed.
        %
        % Inputs:
        % aObj - The menu that triggered the callback.
        
        % Select the clicked menu.
        set(aObj, 'Checked', 'on')
        
        % Deselect all the other menus.
        otherMenus = setdiff(...
            [imageMenu,...
            segmentationMenu,...
            trackingMenu,...
            analysisMenu], aObj);
        for i = 1:length(otherMenus)
            set(otherMenus(i), 'Checked', 'off')
        end
        
        SetVisible()
    end

    function LevelCallback(aObj, ~)
        % Callback executed when the user selects a settings level.
        %
        % The function deselects all of the other settings levels and
        % switches which settings are displayed. The lower levels will also
        % be displayed when a level is selected, but the corresponding
        % menus will still be deselected.
        %
        % Inputs:
        % aObj - The menu that triggered the callback.
        
        % Select the clicked menu.
        set(aObj, 'Checked', 'on')
        
        % Deselect all other menus.
        otherMenus = setdiff(...
            [basicMenu,...
            advancedMenu,...
            developmentMenu], aObj);
        for i = 1:length(otherMenus)
            set(otherMenus(i), 'Checked', 'off')
        end
        
        % Display the 'Save clean' button if the level is 'development' and
        % hide it otherwise.
        if strcmp(get(developmentMenu, 'checked'), 'on')
            set(revertButton, 'Position', [0 0 1/3 0.05])
            set(saveButton, 'Position', [1/3 0 1/3 0.05])
            set(saveCleanButton, 'Visible', 'on')
        else
            set(revertButton, 'Position', [0 0 0.5 0.05])
            set(saveButton, 'Position', [0.5 0 0.5 0.05])
            set(saveCleanButton, 'Visible', 'off')
        end
        
        SetVisible()
    end

    function SetVisible()
        % Function updating the visibilities and positions of controls.
        %
        % The visibilities of the controls are controlled by the selected
        % category, the selected level, and which other settings have been
        % selected.
        %
        % See also:
        % CategoryCallback, LevelCallback
        
        % Find the selected level.
        if strcmp(get(basicMenu, 'Checked'), 'on')
            levels = {'basic'};
        elseif strcmp(get(advancedMenu, 'Checked'), 'on')
            levels = {'basic' 'advanced'};
        elseif strcmp(get(developmentMenu, 'Checked'), 'on')
            levels = {'basic' 'advanced' 'development'};
        end
        
        % Find the selected categories.
        if strcmp(get(imageMenu, 'Checked'), 'on')
            categories = 'image';
        end
        if strcmp(get(segmentationMenu, 'Checked'), 'on')
            categories = 'segmentation';
        end
        if strcmp(get(trackingMenu, 'Checked'), 'on')
            categories = 'tracking';
        end
        if strcmp(get(analysisMenu, 'Checked'), 'on')
            categories = 'analysis';
        end
        
        sPanel.SetVisible(categories, levels)
    end

    function NameListBox_Callback(~, ~)
        % Callback executed when the user selects a set of image sequences.
        %
        % The function updates the settings values, and the set of settings
        % displayed to visualize the settings of the selected image
        % sequences.
        
        marked = get(nameListBox, 'Value');  % Selected sequences.
        sPanel.SwitchSettings(imParams(marked));
    end

    function Close(~, ~, varargin)
        % Callback executed when the GUI is closed.
        %
        % Before the GUI is closed, the function saves the category and the
        % level currently selected, so that they can be recalled the next
        % time the GUI is opened. The function also removes the control
        % objects associated with the settings, to make the figure close
        % faster. Finally, the function can execute a function handle which
        % can been given to SettingGUI as an input argument, to allow
        % additional execution based on the settings selected.
        %
        % Property/Value inputs:
        % CloseFunction - Function handle of a function which will be
        %                 executed after the GUI has been closed. The
        %                 default is an empty function.
        
        % Parse property/value inputs.
        aCloseFunction = GetArgs(...
            {'CloseFunction'},...
            {@()disp('')},...
            true, varargin);
        
        % Save the category.
        if strcmp(get(imageMenu, 'Checked'), 'on')
            category = 'image';
        elseif strcmp(get(segmentationMenu, 'Checked'), 'on')
            category = 'segmentation';
        elseif strcmp(get(trackingMenu, 'Checked'), 'on')
            category = 'tracking';
        elseif strcmp(get(analysisMenu, 'Checked'), 'on')
            category = 'analysis';
        end
        SaveVariable('SettingsGUI_category', category)
        
        % Save the level.
        if strcmp(get(basicMenu, 'Checked'), 'on')
            level = 'basic';
        elseif strcmp(get(advancedMenu, 'Checked'), 'on')
            level = 'advanced';
        elseif strcmp(get(developmentMenu, 'Checked'), 'on')
            level = 'development';
        end
        SaveVariable('SettingsGUI_level', level)
        
        % Remove control object to make the figure close faster.
        controls = sPanel.controls;
        for i = 1:length(controls)
            delete(controls(i))
        end
        delete(mainFigure)
        
        % Execute function handle to do additional execution after the GUI
        % has been closed.
        feval(aCloseFunction)
    end
end