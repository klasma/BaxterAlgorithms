function LoadSettingsImageGUI(aSeqPaths, varargin)
% GUI for loading of settings, which displays sample images.
%
% The GUI lets the user load settings from the settings files that are
% included in the program. The user gets to select a settings file in a
% list box. When a settings file is selected, the GUI shows a sample image
% from the end of one of the image sequences that the settings have been
% used to process. The GUI also displays some information about the dataset
% in a textbox. This GUI is more user friendly than LoadSettingsGUI, which
% lets the user browse for a settings file using the normal dialog for
% opening of files, but it cannot be used to load settings files outside
% the program.
%
% The settings files that can be loaded are located in the folder
% Files/Settings, the corresponding jpg-images are located in the folder
% Files/SettingsImages, and the txt-files with descriptions of the settings
% files are located in the folder Files/SettingsInfo. All 3 folders have
% the same sub-folder structure and the paths of the files inside them can
% be retrieved using the function FindFile.
%
% Inputs:
% aSeqPaths - Cell array with paths of image sequences that the loaded
%             settings can be applied to.
%
% Property/Value inputs:
% CloseFunction - Function handle of a function which will be executed
%                 after the GUI has been closed, if new settings have been
%                 saved. The default is an empty function.
%
% See also:
% LoadSettingsGUI, FindFile

% Parse property/value inputs.
aCloseFunction = GetArgs({'CloseFunction'}, {@()disp([])}, true, varargin);

% Folder containing csv-files with settings.
settingsFolder = FindFile('Settings');
% Folder containing jpg-images corresponding to the settings. The folder
% can also contain txt-files with relative paths to other jpg-images in the
% folder.
imageFolder = FindFile('SettingsImages');
% Folder containing txt-files with information about the settings.
infoFolder = FindFile('SettingsInfo');

mainFigure = figure(...
    'NumberTitle', 'off',...
    'Units', 'normalized',...
    'Position', [0.15 0.05 0.8 0.8],...
    'Name', 'Load Settings');

% Axes where images corresponding to the settings are shown.
ax = axes('Parent', mainFigure,...
    'Position', [0 0 0.75 1]);

% Panel with all control objects.
controlPanel = uipanel(...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Units', 'normalized',...
    'Position', [0.75, 0, 0.25, 1]);

% (Sub-)folders with settings.
folders = [{''}; GetNames(settingsFolder, '')];

% Settings files directly under the settings folder.
files = GetNames(settingsFolder, 'csv');

% Settings used to create controls on a SettingsPanel.
info.Sequences = Setting(...
    'name', 'Sequences',...
    'type', 'list',...
    'default', aSeqPaths,...
    'alternatives_basic', aSeqPaths,...
    'callbackfunction', @FolderCallback,...
    'tooltip', 'Image sequences to apply the settings to.');
info.Folder = Setting(...
    'name', 'Folder',...
    'type', 'list',...
    'default', {''},...
    'alternatives_basic', folders,...
    'callbackfunction', @FolderCallback,...
    'tooltip', 'Sub-folders containing settings files');
info.File = Setting(...
    'name', 'Files',...
    'type', 'list',...
    'default', files(1),...
    'alternatives_basic', files,...
    'callbackfunction', @FileCallback,...
    'tooltip', 'Settings files');

% Create a control panel with all ui-objects.
sPanel = SettingsPanel(info,...
    'Parent', controlPanel,...
    'Position', [0 0.35 1 0.65],...
    'Split', 0.25,...
    'MinList', 10);

% Turn multi-selection off.
set(sPanel.GetControl('Folder'), 'Max', 0)
set(sPanel.GetControl('File'), 'Max', 0)

% Textbox with information about the selected settings file.
textBox = uicontrol(...
    'Parent', controlPanel,...
    'Style', 'edit',...         % 'text' does not let the user scroll.
    'Enable', 'inactive',...    % Editable 'off' does not let the user scroll.
    'Max', 2,...                % Allow multiple lines.
    'HorizontalAlignment', 'left',...
    'Units', 'normalized',...
    'Position', [0 0.1 1 0.25]);

% Button which loads setting for the selected image sequences.
uicontrol(...
    'Parent', controlPanel,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 1 0.1],...
    'String', 'Load',...
    'Callback', @LoadCallback,...
    'Tooltip', 'Load the selected settings.');

Draw()

    function Draw()
        % Updates the displayed image and the textbox with information.
        
        % Get selections from the control panel.
        folder = sPanel.GetValue('Folder');
        folder = folder{1};
        file = sPanel.GetValue('File');
        file = file{1};
        
        % Path of the image corresponding to the selected settings file.
        imagePath = fullfile(imageFolder,...
            folder, strrep(file, '.csv', '.jpg'));
        
        % If the settings file does not exist, there may be a text file
        % with the relative path of a jpg-image.
        if ~exist(imagePath, 'file')
            txtPath = fullfile(imageFolder,...
                folder, strrep(file, '.csv', '.txt'));
            
            if exist(txtPath, 'file')
                % Read the txt-file with the path of the jpg-image.
                fid = fopen(txtPath, 'r');
                imageFile = fscanf(fid, '%c', inf);
                fclose(fid);
                imagePath = fullfile(imageFolder, imageFile);
            end
        end
        
        if exist(imagePath, 'file')
            % Display the jpg-image.
            im = imread(imagePath);
            imshow(im, 'Parent', ax)
        else
            % Remove the old image if the current settings file has no
            % image.
            cla(ax)
        end
        
        % Update the information about the settings file, in the textbox.
        infoPath = fullfile(infoFolder, folder,...
            strrep(file, '.csv', '.txt'));
        if exist(infoPath, 'file')
            fid = fopen(infoPath, 'r');
            infoText = fscanf(fid, '%c', inf);
            infoText = regexp(infoText, '\r\n', 'split');
            fclose(fid);
            set(textBox, 'String', infoText)
        else
            % Clear the textbox if the settings file does not have a
            % txt-file with information.
            set(textBox, 'String', '')
        end
    end

    function FolderCallback(~, ~)
        % Callback for the listbox with folder names.
        %
        % The callback updates the listbox with settings files, to show the
        % settings files inside the selected folder. Then the callback
        % selects the first settings file in the list and calls Draw.
        
        folder = sPanel.GetValue('Folder');
        folder = folder{1};
        files = GetNames(fullfile(settingsFolder, folder), 'csv');
        sPanel.SetAlternatives('File', 'basic', files)
        sPanel.SetValue('File', files(1))
        Draw()
    end

    function FileCallback(~, ~)
        % Updates the GUI when a new settings file is selected.
        
        Draw()
    end

    function LoadCallback(~, ~)
        % Loads settings from the selected settings file.
        %
        % The loaded settings are then saved to the settings files of all
        % the selected image sequences.
        
        % Get selections from the GUI.
        folder = sPanel.GetValue('Folder');
        folder = folder{1};
        file = sPanel.GetValue('File');
        file = file{1};
        sequences = sPanel.GetValue('Sequences');
        
        if isempty(sequences)
            errordlg(['You need to select at least one image sequences '...
                'that you want to apply the settings to.'],...
                'No settings were loaded')
            return
        end
        
        csvPath = fullfile(settingsFolder, folder, file);
        LoadSettingsGUI(sequences,...
            'CsvPath', csvPath,...
            'CloseFunction', aCloseFunction)
    end
end