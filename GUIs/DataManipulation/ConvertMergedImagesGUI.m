function ConvertMergedImagesGUI()
% Creates a GUI for making an experiment from merged images.
%
% Uses either ColorImages2Sequences or SeparateMerge to convert 24 bit
% color images to image sequence folders with 8 bit gray scale tifs for the
% different channels. Channels of interest and channel names can be entered
% through the GUI's uicontrols. These will be used as varargin inputs for
% ColorImages2Sequences, or aLabels for SeparateMerge, and for creating the
% experiment's settings file with the channel colors and names
% automatically entered in. The function can handle images with the file
% extensions tif, tiff, png, jpg, and jpeg.
%
% See also:
% BaxterAlgorithms

% Path of the merged experiment that will be created.
experimentFolder = [];

mainFigure = figure(...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Convert Merged Images GUI',...
    'Units', 'normalized',...
    'Position', [0.3 0.1 0.4 0.4]);

% uicontrols
uicontrol('Style', 'text',...
    'String', 'Select the folder that contains the multi-color images.',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.86, 0.9, 0.1]);
uicontrol('Style', 'pushbutton',...
    'String', 'Open',...
    'Units', 'normalized',...
    'Position', [0.05, 0.85, 0.15, 0.05],...
    'Callback', @Cb_ChooseFolderGUI);
experimentDir = uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'Position', [0.25, 0.85, 0.7, 0.05]);
uicontrol('Style', 'text',...
    'String', 'Check channel colors of interest and provide channel names (Ex: Pax7)',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.65, 0.9, 0.1]);
redCheckbox = uicontrol('Style', 'checkbox',...
    'Units', 'normalized',...
    'Value', 1,...
    'Enable', 'off',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.63, 0.03, 0.05],...
    'Callback', @Cb_Checkbox);
uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'String', 'Red',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.09, 0.62, 0.05, 0.05]);
redChannelName = uicontrol('Style', 'edit',...
    'Units', 'normalized',...
    'String', 'Red',...
    'Enable', 'off',...
    'HorizontalAlignment', 'left',...
    'Position', [0.15, 0.63, 0.3, 0.05]);
greenCheckbox = uicontrol('Style', 'checkbox',...
    'Units', 'normalized',...
    'Value', 1,...
    'Enable', 'off',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.56, 0.05, 0.05],...
    'Callback', @Cb_Checkbox);
uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'String', 'Green',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.09, 0.55, 0.05, 0.05]);
greenChannelName = uicontrol('Style', 'edit',...
    'Units', 'normalized',...
    'String', 'Green',...
    'Enable', 'off',...
    'HorizontalAlignment', 'left',...
    'Position', [0.15, 0.56, 0.3, 0.05]);
blueCheckbox = uicontrol('Style', 'checkbox',...
    'Units', 'normalized',...
    'Value', 1,...
    'Enable', 'off',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.49, 0.05, 0.05],...
    'Callback', @Cb_Checkbox);
uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'String', 'Blue',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.09, 0.48, 0.05, 0.05]);
blueChannelName = uicontrol('Style', 'edit',...
    'Units', 'normalized',...
    'String', 'Blue',...
    'Enable', 'off',...
    'HorizontalAlignment', 'left',...
    'Position', [0.15, 0.49, 0.3, 0.05]);
uicontrol('Style', 'text',...
    'String', 'How are the images merged?',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.33, 0.9, 0.1]);
mergedImage = uicontrol('Style', 'radiobutton',...
    'Units', 'normalized',...
    'Enable', 'off',...
    'Value', 1,...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.05, 0.33, 0.05, 0.05],...
    'Callback', @Cb_MergeOption);
uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'String', 'All the channels are merged into a single image',...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.09, 0.32, 0.6, 0.05]);
fourPanels = uicontrol('Style', 'radiobutton',...
    'Units', 'normalized',...
    'Enable', 'off',...
    'Position', [0.05, 0.27, 0.05, 0.05],...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Callback', @Cb_MergeOption);
uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'String', ['The channels are displayed in four separate panels '...
    '(bottom left = blue, top left = green, and top right = red)'],...
    'HorizontalAlignment', 'left',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.09, 0.26, 0.9, 0.05]);
processButton = uicontrol('Style', 'pushbutton',...
    'String', 'Process',...
    'Units', 'normalized',...
    'Enable', 'off',...
    'Position', [0.35, 0.10, 0.3, 0.1],...
    'Callback', @Cb_Process);
processStatus = uicontrol('Style', 'text',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'String', '',...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Position', [0.35, 0.02, 0.4, 0.05]);

    function Cb_Checkbox(aObj, ~)
        % Enables or disables the "Channel Name" edit uicontrol.
        
        if aObj == redCheckbox
            if strcmp(get(redChannelName, 'Enable'), 'on')
                set(redChannelName, 'Enable', 'off')
            else
                set(redChannelName, 'Enable', 'on')
            end
        end
        if aObj == greenCheckbox
            if strcmp(get(greenChannelName, 'Enable'), 'on')
                set(greenChannelName, 'Enable', 'off')
            else
                set(greenChannelName, 'Enable', 'on')
            end
        end
        if aObj == blueCheckbox
            if strcmp(get(blueChannelName, 'Enable'), 'on')
                set(blueChannelName, 'Enable', 'off')
            else
                set(blueChannelName, 'Enable', 'on')
            end
        end
    end

    function Cb_ChooseFolderGUI(~, ~)
        % Opens a dialog box for selection of the experiment folder.
        
        % For some reason, selecting the folder can take up to ~5 seconds
        % to update, so the cursor is set to look busy as to not confuse
        % the user.
        setptr(mainFigure, 'watch')
        drawnow()
        
        % If a folder was selected previously, UiGetMultipleDirs will begin
        % in that directory.
        if isempty(experimentFolder)
            tmpExPath = UiGetMultipleDirs(...
                'Title', 'Select Folder with Images',...
                'MultiSelect', false);
        else
            tmpExPath = UiGetMultipleDirs(...
                'Title', 'Select Folder with Images',...
                'Path', fileparts(experimentFolder),...
                'MultiSelect', false);
        end
        
        % Display the experiment directory path and enable the process
        % button if selecting the experiment folder was successful.
        if ~isempty(tmpExPath)
            experimentFolder = tmpExPath;
            set(experimentDir, 'String', experimentFolder)
            set(processButton, 'Enable', 'on')
            set(processButton, 'BackgroundColor', 'g')
            set(redCheckbox, 'Enable', 'on')
            set(greenCheckbox, 'Enable', 'on')
            set(blueCheckbox, 'Enable', 'on')
            set(redChannelName, 'Enable', 'on')
            set(greenChannelName, 'Enable', 'on')
            set(blueChannelName, 'Enable', 'on')
            set(mergedImage, 'Enable', 'on')
            set(fourPanels, 'Enable', 'on')
            drawnow()
        end
        
        % Selecting folder complete, set cursor to normal.
        setptr(mainFigure, 'arrow')
        drawnow()
    end

    function Cb_MergeOption(aObj, ~)
        % Selects the script for splitting the merged image.
        %
        % The other option is deselected.
        %
        % Inputs:
        % aObj - Radio button which triggered the callback.
        
        if aObj == mergedImage
            if get(mergedImage, 'Value')
                set(fourPanels, 'Value', 0)
                drawnow()
            end
        elseif aObj == fourPanels
            if get(fourPanels, 'Value')
                set(mergedImage, 'Value', 0)
                drawnow()
            end
        end
    end

    function Cb_Process(~, ~)
        % Runs ColorImages2Sequences and creates a settings file.
        %
        % Parameters taken include the experiment folder directory,
        % fluorescence channel checkbox values, and channel names.
        
        setptr(mainFigure, 'watch')
        drawnow()
        
        varColors = {};     % varargin input for ColorImages2Sequences 'Colors'
        colorStr = '';      % input for WriteSeqSettings, stores RGB triplets
        varLabels = {};     % varargin input for ColorTifs2Sequencs 'Labels'
        channelNames = '';  % input for WriteSeqSettings, stores name of channels
        
        % Adds the channel to the input if the checkbox is checked.
        if get(redCheckbox, 'Value')
            varColors = [varColors, {'red'}];
            varLabels = [varLabels, {get(redChannelName, 'String')}];
            colorStr = sprintf('%s%s', colorStr, '1 0 0');
            channelNames = sprintf('%s%s',...
                channelNames, get(redChannelName, 'String'));
        end
        if get(greenCheckbox, 'Value')
            varColors = [varColors, {'green'}];
            varLabels = [varLabels, {get(greenChannelName, 'String')}];
            % In case red is not selected, green's RGB triplet and channel
            % name will be the first value in the settings file so no colon
            % needs to be added.
            if strcmp(colorStr, '')
                colorStr = sprintf('%s%s', colorStr, '0 1 0');
                channelNames = sprintf('%s%s',...
                    channelNames, get(greenChannelName, 'String'));
            else
                colorStr = sprintf('%s:%s', colorStr, '0 1 0');
                channelNames = sprintf('%s:%s',...
                    channelNames, get(greenChannelName, 'String'));
            end
        end
        if get(blueCheckbox, 'Value')
            varColors = [varColors, {'blue'}];
            varLabels = [varLabels, {get(blueChannelName, 'String')}];
            % This should only happen if blue is the only color selected.
            if strcmp(colorStr, '')
                colorStr = sprintf('%s%s', colorStr, '0 0 1');
                channelNames = sprintf('%s%s',...
                    channelNames, get(blueChannelName, 'String'));
            else
                colorStr = sprintf('%s:%s', colorStr, '0 0 1');
                channelNames = sprintf('%s:%s',...
                    channelNames, get(blueChannelName, 'String'));
            end
        end
        
        % Convert the images.
        if get(mergedImage, 'Value')
            ColorImages2Sequences(experimentFolder,...
                'Colors', varColors, 'Labels', varLabels)
        elseif get(fourPanels, 'Value')
            SeparateMerge(experimentFolder, varLabels)
        end
        
        % Write settings.
        newSeqDirs = GetSeqDirs(experimentFolder);
        newSeqPaths = strcat(experimentFolder, filesep, newSeqDirs);
        exPaths = GetSeqDirs(experimentFolder);
        
        for i = 1:length(exPaths)
            WriteSeqSettings(newSeqPaths{i},...
                'ChannelColors', colorStr,...
                'channelNames', channelNames,...
                'channelTags', channelNames)
        end
        
        set(processStatus, 'String',...
            sprintf('Processing: (%d/%d) Complete',...
            length(exPaths),...
            length(exPaths)))
        
        setptr(mainFigure, 'arrow')
        drawnow()
        
        % Instructions
        InfoDialog('InfoConvertMergedImagesGUI', 'Next Step...',...
            ['Return to the main Baxter Algorithms program and open '...
            'your ORIGINAL experiment folder with the multi-color '...
            'images using File > Open Experiment'])
    end

    function ColorImages2Sequences(aExPath, varargin)
        % Converts 24 bit color images to image sequence folders.
        %
        % The sequence folders will contain 8 bit gray scale tifs for the
        % different channels.
        %
        % Inputs:
        % aExPath - Full path of folder with RGB-images to be converted.
        %
        % Property/Value inputs:
        % Colors - Cell array of strings, specifying what channels should
        %          be saved as tifs. The input {'gray', 'red'} tells the
        %          function to save only the gray and the red channels.
        % Labels - Cell array of channel labels. The image names will be
        %          tagged at the end with these labels. By default, the
        %          colors are used as labels.
        
        
        % Get property/value inputs.
        [aColors, aLabels] = GetArgs(...
            {'Colors', 'Labels'},...
            {{'gray', 'red', 'green', 'blue'}, {}},...
            true,...
            varargin);
        if isempty(aLabels)
            aLabels = aColors;
        end
        
        % Get the paths of all images to convert.
        if exist(aExPath, 'dir')
            files = GetNames(aExPath, {'tif' 'tiff' 'png' 'jpg' 'jpeg'});
        else
            error('There exists no directory named %s\n', aExPath)
        end
        
        for i = 1:length(files)
            fprintf('Processing image %d / %d.\n', i, length(files))
            set(processStatus, 'String',...
                sprintf('Processing image (%d/%d)',...
                i, length(files)))
            drawnow()
            
            % Remove the extension from the filename.
            [~, seqDir] = fileparts(files{i});
            
            im_color = imread(fullfile(aExPath, files{i}));
            
            % Light microscopy channel.
            if any(strcmp(aColors, 'gray'))
                im_gray = min(im_color, [], 3);  % Gray component.
            else
                im_gray = zeros(size(im_color,1), size(im_color,2),...
                    'like', im_color);
            end
            
            for c = 1:length(aColors)
                switch aColors{c}
                    case 'gray'
                        im = im_gray;
                    case 'red'
                        im = im_color(:,:,1) - im_gray;
                    case 'green'
                        im = im_color(:,:,2) - im_gray;
                    case 'blue'
                        im = im_color(:,:,3) - im_gray;
                end
                
                savePath = fullfile(aExPath, seqDir,...
                    sprintf('%s_%s.tif', seqDir, aLabels{c}));
                
                % Create folders to save in.
                if ~exist(fileparts(savePath), 'dir')
                    mkdir(fileparts(savePath))
                end
                
                % Save to a .tif with lossless compression.
                imwrite(im, savePath, 'Compression', 'lzw');
            end
        end
        fprintf('Done\n')
    end

    function SeparateMerge(aExPath, aLabels)
        % Separates a 4-panel fluorescence merge into 3 8-bit tifs.
        %
        % The RGB-image consists of a 2x2 image grid where there is a merge
        % image in the lower right corner and channel images in the other
        % corners. There are gray single pixel lines separating the 4
        % images. The separate monochrome tifs are saved in folders with
        % the same names as the original images. The red channel is assumed
        % to be in the upper right corner, the green channel is assumed to
        % be in the upper left corner and the blue channel is assumed to be
        % in the lower right corner.
        %
        % Inputs:
        % aExPath - Full path of the folder containing the merged images.
        % aLabels - Cell array with names of the red, green and blue
        %           channels (in that order). The file names of the images
        %           will end with an underscore followed by the respective
        %           channel names.
        
        files = GetNames(aExPath, {'tif' 'tiff' 'png' 'jpg' 'jpeg'});
        
        for i = 1:length(files)
            set(processStatus, 'String',...
                sprintf('Processing image (%d/%d)', i, length(files)))
            drawnow()
            im = imread(fullfile(aExPath, files{i}));
            
            % Size of the merged image.
            [h_full, w_full, ~] = size(im);
            
            % Size of the individual channel images.
            w = floor(w_full/2);
            h = floor(h_full/2);
            
            % Cut out the monochrome information.
            red = im(1:h, w+2:end, 1);
            if size(red,2) ~= w
                % Missing columns.
                red = imresize(red, [h w]);
            end
            green = im(1:h, 1:w, 2);
            blue = im(h+2:end, 1:w, 3);
            if size(blue,1) ~= h
                % Missing rows.
                blue = imresize(blue, [h w]);
            end
            
            % Remove the extension from the filename.
            [~, fileName] = fileparts(files{i});
            
            % Create a directory to put the monochrome images in.
            saveFolder = fullfile(aExPath, fileName);
            if ~exist(saveFolder, 'dir')
                mkdir(saveFolder)
            end
            
            % Save the monochrome images.
            imwrite(red, fullfile(saveFolder,...
                sprintf('%s_%s.tif', fileName, aLabels{1})))
            imwrite(green, fullfile(saveFolder,...
                sprintf('%s_%s.tif', fileName, aLabels{2})))
            imwrite(blue, fullfile(saveFolder,...
                sprintf('%s_%s.tif', fileName, aLabels{3})))
        end
    end
end