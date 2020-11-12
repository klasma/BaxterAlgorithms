classdef SequencePlayer < handle
    % Super class of all players. This player can play a 2D image sequence.
    %
    % SequencePlayer is a class with a figure where an image sequence can
    % be played. The object can keep track of a number of image sequences
    % that the user can switch between. All classes that involve playing an
    % image sequence should inherit from this class. The player has menus
    % to export images and to select which microscope channels to display.
    %
    % See also:
    % ZPlayer, ZControlPlayer, SetFluorescencePlayer,
    % ManualCorrectionPlayer
    
    properties
        mainFigure      % The figure.
        ax              % The axes object where the image is displayed.
        seqIndex        % Index of the image sequence currently displayed.
        seqPaths        % Cell array with paths to all image sequences that can be displayed.
        imDatas         % Cell arrays with ImageData objects for all sequences. % Sequences that have not been displayed have empty cells.
        frame           % Index of the image currently displayed.
        step            % The interval between played images. step=1 -> every image is played.
        fps             % Frame rate in frames per second during playing.
        play            % True if an image sequence is currently played.
        
        slider          % Slider used to jump to a different image.
        playButton      % Button that starts or stops playing of an image sequence.
        previousButton  % Button that opens the previous image sequence in the list.
        nextButton      % Button that opens the next image sequence in the list.
        seqPopupMenu    % Popup menu where any of the image sequences in seqPaths can be selected.
        playbackPanel   % A small panel in the lower right corner of the figure, showing playback information.
        stepTextbox     % Text box where the interval between displayed images is set.
        fpsTextbox      % Text box where the frame rate is set.
        frameTextbox    % Text box where the current frame index is displayed and set.
        frameLabel      % Label where the total number of frames is displayed.
        fpsLabel        % Label where the achieved frame rate is displayed.
        channelTab      % Menu tab that the channel menus lie under.
        channelMenus    % uimenus where the user can set what channels to display.
        exportMenu      % Menu tab where the user can export the displayed images.
        
        zoomCorner      % Image coordinate where the user clicked to start dragging a zoom box.
        lines           % Temporary lines drawn during user operations.
        
        panning         % True during panning.
        panCoordinates  % 2 element array with x- and y-coordinates where the user clicked to start panning.
        
        zoomAxes        % Array of axes objects that the user has zoomed in.
        zoomLimits      % Cell array with previous axis limits for zoomed axes. % Each cell has structs with the fields xmin, xmax, ymin, and ymax.
    end
    
    methods
        function this = SequencePlayer(aSeqPaths, varargin)
            % Constructor which sets variables and creates controls.
            %
            % Inputs:
            % aSeqPaths - Cell array with full paths to all image sequences
            %             that should be playable. The player will display
            %             the first sequence in the array after
            %             construction. The function can also take a string
            %             with a single image sequence path.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        a the end of the constructor. This allows derived
            %        classes to postpone the call to Draw to the end of the
            %        derived class constructor.
            
            aDraw = GetArgs({'Draw'}, {true}, true, varargin);
            
            if iscell(aSeqPaths)
                this.seqPaths = aSeqPaths;
            else
                this.seqPaths = {aSeqPaths};
            end
            
            this.imDatas = cell(size(this.seqPaths));
            this.seqIndex = 1;  % Start on the first sequence.
            this.frame = 1;  % Start on the first image.
            
            this.play = false;
            this.fps = 10;
            this.step = 1;
            
            this.mainFigure = figure(...
                'Menubar',                  'none',...
                'NumberTitle',              'off',...
                'Name',                     [this.GetName() ': ' this.GetSeqPath()],...
                'Units',                    'normalized',...
                'Position',                 [0.15 0.05 0.8 0.8],...
                'WindowButtonDownFcn',      @this.WindowButtonDownFcn,...
                'WindowButtonUpFcn',        @this.WindowButtonUpFcn,...
                'WindowButtonMotionFcn',    @this.WindowButtonMotionFcn,...
                'KeyPressFcn',              @this.KeyPressFcn,...
                'KeyReleaseFcn',            @this.KeyReleaseFcn);
            
            this.ax = axes('Parent', this.mainFigure,...
                'Position', [0 0.07 1 0.925]);
            
            this.panning = false;
            this.panCoordinates = [];
            this.zoomCorner = [];
            this.lines = [];
            
            % Create menus for export of images and image sequences.
            this.exportMenu = uimenu(this.mainFigure, 'Label', 'Export');
            uimenu(this.exportMenu,...
                'Label', 'Export image',...
                'Callback', @this.SaveImage_Callback);
            uimenu(this.exportMenu,...
                'Label', 'Export image sequence',...
                'Callback', @this.RecordSequence_Callback);
            uimenu(this.exportMenu,...
                'Label', 'Export all image sequences',...
                'Callback', @this.RecordAllSequences_Callback);
            
            this.CreateChannelMenus();
            
            % Create all uicontrols.
            
            if this.GetNumImages() > 1
                % Setting Interruptible = 'off' and 'BusyAction' = 'cancel'
                % makes it possible to hold down the scroll arrows without
                % crashing the program.
                this.slider = uicontrol('Style', 'slider',...
                    'Min', 1,...
                    'Max', this.GetNumImages(),...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Units', 'normalized',...
                    'Interruptible', 'off',...
                    'BusyAction', 'cancel',...
                    'Position', [0.025 0.045 0.95 0.015],...
                    'Tooltip', 'Slide to the desired frame',...
                    'Callback', @this.Slider_Callback);
            else
                % Max has to be larger than min for the slider to be
                % displayed, therefore 0.1 is added to Max.
                this.slider = uicontrol('Style', 'slider',...
                    'Enable', 'off',...
                    'Min', 1,...
                    'Max', this.GetNumImages()+0.1,...
                    'Value', this.frame,...
                    'SliderStep', this.GetSliderSteps(),...
                    'Units', 'normalized',...
                    'Interruptible', 'off',...
                    'BusyAction', 'cancel',...
                    'Position', [0.025 0.045 0.95 0.015],...
                    'Callback', @this.Slider_Callback);
            end
            
            % Create control buttons.
            this.playButton = uicontrol('Style', 'pushbutton',...
                'String', 'Start (uparrow)',...
                'Units', 'normalized',...
                'Position', [0.45, 0.005, 0.1, 0.035],...
                'Tooltip', 'Start/stop playing the image sequence',...
                'Callback', @this.PlayButton_Callback);
            if this.GetNumImages() <= 1
                set(this.playButton, 'Enable', 'off')
            end
            this.previousButton = uicontrol('Style', 'pushbutton',...
                'String', 'Previous',...
                'Units', 'normalized',...
                'Position', [0.35, 0.005, 0.1, 0.035],...
                'Tooltip', 'Switch to the previous image sequence',...
                'Callback', @this.PreviousButton_Callback);
            this.nextButton = uicontrol('Style', 'pushbutton',...
                'String', 'Next',...
                'Units', 'normalized',...
                'Position', [0.55, 0.005, 0.1, 0.035],...
                'Tooltip', 'Switch to the next image sequence',...
                'Callback', @this.NextButton_Callback);
            
            % Create the popupmenu to select sequences.
            this.seqPopupMenu = uicontrol('Style', 'popupmenu',...
                'String', this.GetSeqDirs(),...
                'Value', this.seqIndex,...
                'Units', 'normalized',...
                'Position', [0.025, 0.005, 0.25, 0.035],...
                'Tooltip', 'Switch to a different image sequence',...
                'Callback', @this.SeqPopupMenu_Callback);
            
            % Create the panel with playback information.
            this.playbackPanel = uipanel(...
                'Parent', this.mainFigure,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Units', 'normalized',...
                'Position', [0.775, 0.005, 0.2, 0.035]);
            uicontrol(...
                'Parent', this.playbackPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Style', 'text',...
                'Horizontalalignment', 'Right',...
                'String', 'Frame : ',...
                'Units', 'normalized',...
                'Position', [0, 0, 0.2, 0.8]);
            this.frameTextbox = uicontrol(...
                'Parent', this.playbackPanel,...
                'Style', 'edit',...
                'BackgroundColor', 'w',...
                'Horizontalalignment', 'Right',...
                'String', num2str(this.frame),...
                'Units', 'normalized',...
                'Position', [0.2, 0.1, 0.095, 0.8],...
                'Tooltip', 'Index of the displayed frame',...
                'Callback', @this.FrameTextbox_Callback);
            this.frameLabel = uicontrol(...
                'Parent', this.playbackPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Style', 'text',...
                'Horizontalalignment', 'Left',...
                'String', ['/' num2str(this.GetNumImages())],...
                'Units', 'normalized',...
                'Tooltip', 'Total number of frames',...
                'Position', [0.3, 0, 0.1, 0.8]);
            uicontrol(...
                'Parent', this.playbackPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Style', 'text',...
                'Horizontalalignment', 'Right',...
                'String', 'Step : ',...
                'Units', 'normalized',...
                'Position', [0.4, 0, 0.15, 0.8]);
            this.stepTextbox = uicontrol(...
                'Parent', this.playbackPanel,...
                'Style', 'edit',...
                'BackgroundColor', 'w',...
                'Horizontalalignment', 'Left',...
                'String', num2str(this.step),...
                'Units', 'normalized',...
                'Position', [0.55, 0.1, 0.095, 0.8],...
                'Tooltip', 'Interval between played frames',...
                'Callback', @this.StepTextbox_Callback);
            uicontrol(...
                'Parent', this.playbackPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Style', 'text',...
                'Horizontalalignment', 'Right',...
                'String', 'Fps : ',...
                'Units', 'normalized',...
                'Position', [0.65, 0, 0.15, 0.8]);
            this.fpsLabel = uicontrol(...
                'Parent', this.playbackPanel,...
                'BackgroundColor', get(this.mainFigure, 'color'),...
                'Style', 'text',...
                'Horizontalalignment', 'Right',...
                'String', '0 / ',...
                'Units', 'normalized',...
                'Tooltip', 'Actual frame rate in frames per second',...
                'Position', [0.8, 0, 0.1, 0.8]);
            this.fpsTextbox = uicontrol(...
                'Parent', this.playbackPanel,...
                'Style', 'edit',...
                'BackgroundColor', 'w',...
                'Horizontalalignment', 'Left',...
                'String', num2str(this.fps),...
                'Units', 'normalized',...
                'Position', [0.9, 0.1, 0.095, 0.8],...
                'Tooltip', 'Desired frame rate in frames per second',...
                'Callback', @this.FpsTextbox_Callback);
            
            % Make the keyboard callbacks work after an uicontrol object
            % has been selected.
            SetKeyPressCallback(this.mainFigure, @this.KeyPressFcn)
            SetKeyReleaseCallback(this.mainFigure, @this.KeyReleaseFcn)
            
            % Remove the key-callbacks from text boxes, so that typing in
            % them does not activate shortcuts.
            set(this.frameTextbox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.stepTextbox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.fpsTextbox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            
            if aDraw
                this.Draw();
            end
        end
        
        function CreateChannelMenus(this)
            % Creates menus to select what channels should be displayed.
            %
            % All channels are displayed by default. If there are already
            % channel menus, the existing ones will be removed.
            
            if ~isempty(this.channelTab)
                % Removes old channel menus if such menus exist.
                for i = 1:length(this.channelMenus)
                    delete(this.channelMenus(i));
                end
                this.channelMenus = [];
            else
                % Create channels menus for the first time.
                this.channelTab = uimenu('Label', 'Channels');
            end
            
            % Create new channel menus.
            for i = 1:length(this.GetImData().channelNames)
                this.channelMenus = [this.channelMenus;...
                    uimenu(this.channelTab,...
                    'Label', this.GetImData().channelNames{i},...
                    'Callback', @this.ChannelMenu_Callback,...
                    'Checked', 'on')];
            end
        end
        
        function PlayButton_Callback(this, ~, ~)
            % Called when the playButton is pressed.
            %
            % The function either starts or stops the playing of an image
            % sequence. If the playing has stopped at the last frame,
            % pressing the playButton will go back to the first frame
            % without starting the video.
            
            % Remove focus from the button to allow key-callbacks on space.
            set(this.playButton, 'Enable', 'off')
            drawnow()
            set(this.playButton, 'Enable', 'on')
            
            if ~this.play
                if this.frame == this.GetNumImages()  % Rewind video
                    this.frame = 1;
                    this.Draw();
                    return
                else
                    set(this.playButton, 'String', 'Stop (uparrow)')
                    this.Play()
                end
            else
                this.Stop();
            end
            
            % Someone pressed stop, or the video has played to the end.
            if ishandle(this.playButton)
                % The button does not exist if the user has closed the
                % figure.
                set(this.playButton, 'String', 'Start (uparrow)')
                set(this.slider, 'Enable', 'on')
            end
        end
        
        function Slider_Callback(this, ~, ~)
            % Jumps to the frame specified on the slider.
            %
            % The 'BusyAction' and 'Interruptible' properties of the slider
            % are set so that callbacks are dropped when they are created
            % faster than Draw can execute.
            
            % Necessary to make callbacks work if the user clicks on the
            % slider and then starts playing the sequence using the
            % up-arrow.
            set(this.slider, 'Enable', 'off')
            drawnow()
            set(this.slider, 'Enable', 'on')
            
            this.frame = round(get(this.slider, 'Value'));
            this.Draw()
        end
        
        function Play(this)
            % Starts playing the current sequence.
            %
            % Plays the current image sequence until the end of the
            % sequence is reached or until the user stops the playback.
            
            this.play = true;
            tic
            % All handles disappear when the figure is closed and to avoid
            % "invalid handle"-errors, the play loop is put in a try-catch
            % block.
            try
                while this.play && this.frame < this.GetNumImages()
                    this.frame = min(this.frame + this.step, this.GetNumImages);
                    this.Draw()
                    drawnow()
                    
                    % The drawing is timed, so that the actual frame rate
                    % can be displayed in the playback panel.
                    t = toc;
                    if t < 1/this.fps
                        pause(1/this.fps - t)
                        set(this.fpsLabel, 'String', [num2str(this.fps) ' / '])
                    else
                        set(this.fpsLabel, 'String', sprintf('%.1f / ', 1/t))
                    end
                    tic
                end
            catch ME  % Catch error thrown when the figure is closed.
                if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
                    rethrow(ME) % Do not catch other errors
                end
            end
            this.play = false;
        end
        
        function Draw(this)
            % Displays images.
            %
            % Draw displays the current image of the current image
            % sequence, updates the slider, and updates the frame counter.
            
            cla(this.ax)  % Avoids accumulation.
            set(this.slider, 'Value', this.frame)  % Make slider move.
            
            % Display current frame number.
            set(this.frameTextbox, 'String', num2str(this.frame))
            set(this.frameLabel, 'String', ['/' num2str(this.GetNumImages())])
            
            % Display the image.
            chs = find(strcmp(get(this.channelMenus, 'Checked'), 'on'));
            im = this.GetImData().GetShownImage(this.frame, 'Channels', chs); %#ok<FNDSB>
            image(im, 'Parent', this.ax)
            colormap(this.ax, gray(256))
            axis(this.ax, 'image', 'off')
            
            hold(this.ax, 'on')
        end
        
        function PreviousButton_Callback(this, ~, ~)
            % Switches to the previous image sequence in seqPaths.
            %
            % If the current image sequence is the first, the function
            % switches to the last sequence.
            
            % Remove focus from the button to allow key-callbacks on space.
            set(this.previousButton, 'Enable', 'off')
            drawnow()
            set(this.previousButton, 'Enable', 'on')
            
            this.SwitchSequence(mod(this.seqIndex-2,length(this.seqPaths))+1);
        end
        
        function NextButton_Callback(this, ~, ~)
            % Switches to the next image sequence in seqPaths.
            %
            % If the current image sequence is the last, the function
            % switches to the first sequence.
            
            % Remove focus from the button to allow key-callbacks on space.
            set(this.nextButton, 'Enable', 'off')
            drawnow()
            set(this.nextButton, 'Enable', 'on')
            
            this.SwitchSequence(mod(this.seqIndex, length(this.seqPaths))+1);
        end
        
        function SeqPopupMenu_Callback(this, ~, ~)
            % Switches to the image sequence selected in the popupmenu.
            
            % Avoid having key- and mouse-callbacks affect the popupmenu.
            set(this.seqPopupMenu, 'Enable', 'off')
            drawnow()
            set(this.seqPopupMenu, 'Enable', 'on')
            
            this.SwitchSequence(get(this.seqPopupMenu, 'Value'));
        end
        
        function SwitchSequence(this, aIndex, varargin)
            % Switches to a specified image sequence.
            %
            % The function makes all changes to the figure that are
            % necessary to play the new image sequence and also calls Draw
            % so that the correct image is displayed.
            %
            % Inputs:
            % aIndex - Index of the image sequence to switch to.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        a the end of the function. This allows derived classes
            %        to postpone the call to Draw to the end of an
            %        overloaded SwitchSequence function.
            
            aDraw = GetArgs({'Draw'}, {true}, true, varargin);
            
            oldIndex = this.seqIndex;
            this.seqIndex = aIndex;
            
            % Update the channel menus if the different image sequences
            % have different channels defined.
            if ~isempty(setxor(this.GetImData().channelNames,...
                    this.GetImData(oldIndex).channelNames))
                this.CreateChannelMenus()
            end
            
            % The current image sequence could be longer than the one we
            % are switching to.
            this.frame = min(this.frame, this.GetNumImages());
            set(this.seqPopupMenu, 'Value', this.seqIndex)
            set(this.mainFigure, 'Name', [this.GetName() ': ' this.GetSeqPath()])
            
            if this.GetNumImages() > 1
                set(this.playButton, 'Enable', 'on')
                set(this.slider,...
                    'Max', this.GetNumImages(),...
                    'Value', this.frame,...
                    'Enable', 'on',...
                    'SliderStep', this.GetSliderSteps())
            else
                set(this.playButton, 'Enable', 'off')
                set(this.slider,...
                    'Max', 1.1,...
                    'Value', this.frame,...
                    'Enable', 'off')
            end
            
            if aDraw
                % Necessary to let the image size change between sequences.
                xlim(this.ax, [0 this.GetImData().imageWidth]+0.5)
                ylim(this.ax, [0 this.GetImData().imageHeight]+0.5)
                
                this.Draw()
            end
        end
        
        function FpsTextbox_Callback(this, ~, ~)
            % Executed when the user sets the frame rate.
            %
            % If the user specifies an invalid frame rate, the last valid
            % frame rate is selected.
            
            s = get(this.fpsTextbox, 'String');
            num = str2double(s);
            if ~isnan(num) && num > 0
                this.fps = num;
            else
                set(this.fpsTextbox, 'String', num2str(this.fps))
            end
        end
        
        function FrameTextbox_Callback(this, ~, ~)
            % Executed when the user specifies a frame in the text box.
            %
            % If the user specifies an invalid frame, the last valid frame
            % is selected.
            
            s = get(this.frameTextbox, 'String');
            num = str2double(s);
            if ~isnan(num) && num == round(num) &&...
                    num > 0 && num <= this.GetNumImages()
                this.frame = num;
                this.Draw()
            else
                set(this.frameTextbox, 'String', num2str(this.frame))
            end
        end
        
        function StepTextbox_Callback(this, ~, ~)
            % Called when the user sets the interval between played images.
            %
            % If the user specifies an invalid step length, the last valid
            % step length is selected. The step length has to be a positive
            % integer.
            
            s = get(this.stepTextbox, 'String');
            num = str2double(s);
            if ~isnan(num) && num > 0 && round(num) == num
                this.step = num;
            else
                set(this.stepTextbox, 'String', num2str(this.step))
            end
        end
        
        function Stop(this)
            % Stop stops the playing if an image sequence is played.
            
            this.play = false;
        end
        
        function oImData = GetImData(this, aIndex)
            % Returns the ImageData object of one of the image sequences.
            %
            % GetImData returns the ImageData object associated with one of
            % the playable image sequences. The ImageData object is created
            % only if it has not been created before, otherwise a cached
            % object is returned.
            %
            % Inputs:
            % aIndex - The index of the image sequence for which the
            %          ImageData object should be returned. If this input
            %          is left out, the function returns the ImageData
            %          object associated with the image sequence currently
            %          displayed.
            %
            % Outputs:
            % oImData - ImageData object.
            
            if nargin == 1
                oImData = this.GetImData(this.seqIndex);
                return
            end
            
            if isempty(this.imDatas{aIndex})
                this.imDatas{aIndex} = ImageData(this.seqPaths{aIndex});
            end
            oImData = this.imDatas{aIndex};
        end
        
        function oExPath = GetExPath(this, aIndex)
            % Returns the full path of the experiment of an image sequence.
            %
            % Inputs:
            % aIndex - Index of the image sequence for which to return the
            %          experiment path. If this input is left out, the
            %          function returns the experiment of the image
            %          sequence currently displayed.
            
            if nargin == 1
                oExPath = GetExPath(this, this.seqIndex);
            else
                oExPath = FileParts2(this.seqPaths{aIndex});
            end
        end
        
        function [oXmin, oXmax, oYmin, oYmax] = GetMaxAxisLimits(this, ~)
            % Gets the maximum allowed axis limits for an axes objects.
            %
            % The maximum allowed axis limits are the limits which display
            % all of the graphics in the axes without empty space
            % surrounding them. This is how the data is displayed by
            % default, and the user is not allowed to zoom out further.
            %
            % Inputs:
            % aAxes - Handle of the axes object.
            %
            % Outputs:
            % oXmin - Lower limit on x-axis when fully zoomed out.
            % oXmax - Upper limit on x-axis when fully zoomed out.
            % oYmin - Lower limit on y-axis when fully zoomed out.
            % oYmax - Upper limit on y-axis when fully zoomed out.
            
            oXmin = 0.5;
            oXmax = this.GetImData().imageWidth + 0.5;
            oYmin = 0.5;
            oYmax = this.GetImData().imageHeight + 0.5;
        end
        
        function [oName] = GetName(~)
            % Returns the name of the player.
            %
            % The name will be displayed in the title of the main window
            % together with the path of the current image.
            
            oName = 'Play';
        end
        
        function oSeqPath = GetSeqPath(this, aIndex)
            % Returns the full path of an image sequence folder.
            %
            % Inputs:
            % aIndex - Index of the image sequence for which to return the
            %          path. If this input is left out, the function
            %          returns the path of the image sequence currently
            %          displayed.
            
            if nargin == 1
                oSeqPath = GetSeqPath(this, this.seqIndex);
                return
            end
            
            oSeqPath = this.seqPaths{aIndex};
        end
        
        function oSeqDirs = GetSeqDirs(this)
            % Returns the names of the folders of all image sequences.
            
            [~, oSeqDirs] = FileParts2(this.seqPaths);
        end
        
        function oSeqDir = GetSeqDir(this, aIndex)
            % Returns the name of an image sequence folder.
            %
            % Inputs:
            % aIndex - Index of the image sequence for which to return the
            %          folder name. If this input is left out, the function
            %          returns the folder name of the image sequence
            %          currently displayed.
            
            if nargin == 1
                oSeqDir = GetSeqDir(this, this.seqIndex);
                return
            end
            
            [~, oSeqDir] = FileParts2(this.seqPaths{aIndex});
        end
        
        function oSteps = GetSliderSteps(this)
            % Computes step sizes for the frame slider.
            %
            % The steps are used for the SliderStep property of the frame
            % slider. There are two step sizes. The first step size
            % corresponds to 1 image and is used when the user clicks on
            % the arrows at the ends of the slider. The second step size
            % corresponds to 10 percent of the image sequence and is used
            % when the user clicks in front of or behind the bar in the
            % slider.
            %
            % Outputs:
            % oSteps - Row vector with the two slider steps.
            
            frameStep = 1/max(this.GetNumImages()-1,1);
            tenPercent = ceil(max(this.GetNumImages()-1,1)/10);
            oSteps = [frameStep tenPercent*frameStep];
        end
        
        function KeyPressFcn(this, ~, aEvent)
            % Defines keyboard shortcuts.
            %
            % The keyboard shortcuts allow the user to navigate in the
            % video using the arrow keys.
            
            if ~isempty(aEvent.Modifier) &&...
                    strcmp(aEvent.Modifier{1}, 'control') &&...
                    ~strcmp(aEvent.Key, 'control')
                % Control was held down together with the key.
                switch aEvent.Key
                    case 'leftarrow'
                        % Switch to the previous image sequence.
                        this.PreviousButton_Callback(this.previousButton)
                    case 'rightarrow'
                        % Switch to the next image sequence.
                        this.NextButton_Callback(this.nextButton)
                end
            else
                switch aEvent.Key
                    case 'uparrow' %{'numpad8', '8'}
                        this.PlayButton_Callback(this.playButton)
                    case 'leftarrow' %{'numpad4', '4'}
                        if(this.play)
                            this.Stop()
                        end
                        this.frame = max(1, this.frame - this.step);
                        this.Draw();
                    case 'rightarrow' %{'numpad6', '6'}
                        if(this.play)
                            this.Stop()
                        end
                        this.frame = min(this.GetNumImages(),...
                            this.frame + this.step);
                        this.Draw();
                    case 'home'
                        % Switch to the first frame.
                        this.frame = 1;
                        this.Draw();
                    case 'end'
                        % Switch to the last frame.
                        this.frame = this.GetNumImages();
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
                            setptr(this.mainFigure, 'arrow')
                        end
                end
            end
        end
        
        function KeyReleaseFcn(this, ~, aEvent)
            % Executed when a keyboard key is released.
            %
            % The function is used to turn panning off when the user
            % releases the space bar. The user can continue to pan while
            % the mouse button is held down, but a new panning operation
            % cannot be started.
            
            if strcmp(aEvent.Key, 'space')
                this.panning = false;
                setptr(this.mainFigure, 'arrow')
            end
        end
        
        function ChannelMenu_Callback(this, aObj, ~)
            % Called when the user selects microscope channels.
            %
            % The function ensures that at least one microscope channel is
            % selected and redraws the image when the user clicks one of
            % the channel selection menus.
            %
            % Inputs:
            % aObj - Menu object which was clicked.
            
            if strcmp(get(aObj, 'Checked'), 'off')
                set(aObj, 'Checked', 'on')
            elseif sum(strcmp(get(this.channelMenus, 'Checked'), 'on')) > 1
                set(aObj, 'Checked', 'off')
            end
            this.Draw()
        end
        
        function SaveImage_Callback(this, ~, ~)
            % Executed when the user presses the menu to export an image.
            %
            % The function opens a file name selection dialog and then does
            % a screen capture to save the displayed image. The extension
            % of the e selected file name specifies what file format to
            % save the image to. If no extension is specified, tif is used.
            
            % Open dialog for saving files.
            defaultFile = sprintf('%s_t%05d_capture.tif',...
                this.GetSeqDir(), this.frame);
            [saveFile, saveDir] = uiputfile(...
                {'*.jpg;*.tif;*.bmp;*.png;*.gif','All Image Files';...
                '*.*','All Files' },'Save Image',...
                fullfile(this.GetExPath(), 'Analysis', defaultFile));
            
            if isequal(saveFile, 0)
                % The user canceled the dialog.
                return
            end
            
            % The default file type is tif.
            if isempty(FileType(saveFile))
                saveFile = [saveFile '.tif'];
            end
            
            imSave = this.GetFrame();
            
            % Convert to gray scale if the displayed image only has shades
            % of gray.
            if IsGrayRGB(imSave)
                imSave = rgb2gray(imSave);
            end
            
            % Write the image to a file.
            if strcmp(FileType(saveFile), 'tif')
                % Use lossless compression on tifs.
                imwrite(imSave, fullfile(saveDir, saveFile),...
                    'Compression', 'lzw')
            else
                imwrite(imSave, fullfile(saveDir, saveFile))
            end
        end
        
        function oIm = GetFrame(this, varargin)
            % Performs screen capture and returns the displayed image.
            %
            % This function should be redefined in derived classes so that
            % the displayed data is saved correctly when images and image
            % sequences are exported. The background color is changed to
            % black (or a gray scale padding color defined by the user)
            % during the screen capture, so that pixels outside the image
            % get the right color in case the axes boundary coordinates are
            % slightly off.
            %
            % Property/Value inputs:
            % FFDshow - If this is set to true, the image will be padded
            %           from below and from the left so that the width is a
            %           multiple of 4 and the height is a multiple of 2. It
            %           is claimed that the image must fulfill these
            %           requirements for it to be encoded using the FFDShow
            %           codec.
            % PadColor - Gray scale value between 0 and 255 which specifies
            %            the color to be used for padding.
            
            [aFFDshow, aPadColor] = GetArgs(...
                {'FFDshow', 'PadColor'}, {false, zeros(3,1)}, true, varargin);
            
            % Background color before the screen capture.
            bgc = get(this.mainFigure, 'Color');
            % Set the background color.
            set(this.mainFigure, 'Color', ones(1,3)*aPadColor/255);
            
            oIm = RecordAxes(this.ax);
            
            if aFFDshow
                oIm = PadForFFDshow(oIm, aPadColor);
            end
            
            % Restore the old background color.
            set(this.mainFigure, 'Color', bgc)
        end
        
        function oNumImages = GetNumImages(this)
            % Returns the number of images in the displayed image sequence.
            
            oNumImages = this.GetImData().sequenceLength;
        end
        
        function [oXmin, oXmax, oYmin, oYmax] = PopAxisLimits(this, aAxes)
            % Removes and returns the previous axis limits of an axes.
            %
            % A stack of prior axis limits can be created using
            % PushAxisLimits. This function pops the last entry in the
            % stack.
            %
            % Inputs:
            % aAxes - Axes object to retrieve the previous axis limits for.
            %
            % Outputs:
            % oXmin - The previous smallest x-value.
            % oXmax - The previous largest x-value.
            % oYmin - The previous smallest y-value.
            % oYmax - The previous largest y-value.
            %
            % See also:
            % PushAxisLimits, GetMaxAxisLimits
            
            % Get the index of the axes object.
            index = find(this.zoomAxes == aAxes);
            
            if ~isempty(index) && ~isempty(this.zoomLimits{index})
                % Get the latest limits for the axes.
                limits = this.zoomLimits{index}(end);
                oXmin = limits.xmin;
                oXmax = limits.xmax;
                oYmin = limits.ymin;
                oYmax = limits.ymax;
                
                % Remove the latest limits from the stack of limits.
                this.zoomLimits{index} =...
                    this.zoomLimits{index}(1:end-1);
            else
                % Return the maximum axis limits if there are no zoomed-in
                % axis limits to return.
                [oXmin, oXmax, oYmin, oYmax] = GetMaxAxisLimits(this, aAxes);
            end
        end
        
        function PushAxisLimits(this, aAxes)
            % Stores axis limits for an axes.
            %
            % This function stores the current axis limits so that the user
            % can go back to these axis limits later by right-clicking. The
            % storage works as in a stack, where entries are pushed using
            % this function and popped using PopAxisLimits. The axis limits
            % for one axis are stored in  an array of structs which have
            % the fields xmin, xmax, ymin, and ymax. These arrays of
            % structs are stored in the cell array this.axisLimits which
            % has one cell for each axis that the user has zoomed in. When
            % the user zooms in a new axes, a new cell is created, and the
            % axes object is appended to this.zoomAxes.
            %
            % Inputs:
            % aAxes - Axes object to store axis limits for.
            %
            % See also:
            % PopAxisLimits, GetMaxAxisLimits
            
            % Get the index of the axes object.
            index = find(this.zoomAxes == aAxes);
            
            % Put the current limits of the axes in a struct.
            limits = axis(aAxes);
            s = struct(...
                'xmin', limits(1),...
                'xmax', limits(2),...
                'ymin', limits(3),...
                'ymax', limits(4));
            
            if ~isempty(index)
                % Append the struct with limits to previously stored
                % structs.
                this.zoomLimits{index} =...
                    [this.zoomLimits{index} s];
            else
                % Create elements for the axes in zoomAxes and
                % zoomLimits and store the first struct.
                this.zoomAxes = [this.zoomAxes aAxes];
                this.zoomLimits = [this.zoomLimits {s}];
            end
        end
        
        function RecordSequence_Callback(this, ~, ~)
            % Opens GUI which records png-images for the current sequence.
            %
            % See also:
            % RecordAllSequences_Callback, RecordGUI
            
            RecordGUI(this, 'RecordAll', false)
        end
        
        function RecordAllSequences_Callback(this, ~, ~)
            % Opens GUI which records png-images for all sequences.
            %
            % See also:
            % RecordSequence_Callback, RecordGUI
            
            RecordGUI(this, 'RecordAll', true)
        end
        
        function SetAxisLimits(~, aAxes, aLimits)
            % Changes the axis limits of an axes and axes coupled to it.
            %
            % This function often needs to be redefined in subclasses.
            %
            % Inputs:
            % aAxes - Axes object for which the limits need to be changed.
            % aLimits - A 4 element vector with the new limits of the axes
            %           in the order [x-min x-max y-min y-max]. The x- and
            %           y-coordinates refer to the coordinate system of the
            %           axes and not to the image dimensions.
            
            axis(aAxes, aLimits)
        end
        
        function WindowButtonDownFcn(this, aObj, aEvent)
            % Executed when users click to zoom.
            %
            % If the left mouse button is pressed down, a zoom box can be
            % drawn to zoom in. When the user drags the mouse cursor,
            % WindowButtonMotionFcn will draw a zoom box in red, and when
            % the user lets go of the mouse button, WindowButtonUpFcn will
            % perform the zooming. Pressing the right mouse button will
            % will go back to the axis limits before the last zoom
            % operation.
            %
            % Inputs:
            % aObj - this.mainFigure
            %
            % See also:
            % WindowButtonMotionFcn, WindowButtonUpFcn
            
            clickedAxes = gca;
            
            % Get the current cursor coordinates.
            xy = get(clickedAxes, 'CurrentPoint');
            x = xy(1,1);
            y = xy(1,2);
            
            if ~InsideAxes(clickedAxes, x, y)
                % Don't do anything if the user clicked outside the axes.
                return
            end
            
            switch get(aObj,'SelectionType')
                case 'normal'
                    if this.panning
                        this.panCoordinates = [x y];
                        setptr(this.mainFigure, 'closedhand')
                    else
                        % Zoom in by dragging a zoom-box.
                        this.zoomCorner = [x y];
                    end
                    this.WindowButtonMotionFcn(aObj, aEvent)
                case 'alt'
                    % Go back to the previous zoom.
                    limits = axis(clickedAxes);
                    [xl, xu, yl, yu] = this.GetMaxAxisLimits(clickedAxes);
                    [xmin, xmax, ymin, ymax] = this.PopAxisLimits(clickedAxes);
                    % Keep popping axis limits until the old limits fit
                    % inside the new limits or the axes are fully zoomed
                    % out.
                    while max(limits(1),xl) < xmin ||...
                            min(limits(2),xu) > xmax ||...
                            max(limits(3),yl) < ymin ||...
                            min(limits(4),yu) > ymax
                        [xmin, xmax, ymin, ymax] = this.PopAxisLimits(clickedAxes);
                    end
                    this.SetAxisLimits(clickedAxes, [xmin xmax ymin ymax])
            end
        end
        
        function WindowButtonMotionFcn(this, ~, ~, varargin)
            % Draws outline of the zoom box or performs panning.
            %
            % During zooming, this function draws a red rectangle (zoom
            % box) which shows the region that will be zoomed in if the
            % user releases the mouse button. During panning, this function
            % will change the axes limits.
            %
            % Property/Value inputs:
            % PixelAxes - If this is true, the zoom box is rounded off to
            %             whole pixels. The default value is true.
            
            aPixelAxes = GetArgs({'PixelAxes'}, {true}, true, varargin);
            
            % Remove a previously drawn zoom box if one exists.
            if ~isempty(this.lines)
                for i = 1:length(this.lines)
                    if ishandle(this.lines(i))
                        delete(this.lines(i))
                    end
                end
                this.lines = [];
            end
            
            if isempty(this.zoomCorner) && isempty(this.panCoordinates)
                % Don't do anything if the user has not pressed down the
                % left mouse button to zoom or pan.
                return
            end
            
            clickedAxes = gca;
            
            % Get the current cursor coordinates.
            xy = get(clickedAxes, 'CurrentPoint');
            x = xy(1,1);
            y = xy(1,2);
            if isnan(x) || isnan(y)
                return
            end
            
            if ~isempty(this.panCoordinates)
                % Pan in a zoomed in image.
                
                % The number of pixels to pan.
                dx = x - this.panCoordinates(1);
                dy = y - this.panCoordinates(2);
                
                xlimits = xlim(clickedAxes);
                ylimits = ylim(clickedAxes);
                [xmin, xmax, ymin, ymax] = this.GetMaxAxisLimits(clickedAxes);
                
                % Stop at the image borders if the user tries to pan
                % outside the image.
                dx = min(dx,xlimits(1)-xmin);
                dx = max(dx,xlimits(2)-xmax);
                dy = min(dy,ylimits(1)-ymin);
                dy = max(dy,ylimits(2)-ymax);
                
                % Pan a whole number of pixels.
                if aPixelAxes
                    dx = round(dx);
                    dy = round(dy);
                end
                
                this.SetAxisLimits(clickedAxes, [xlimits-dx ylimits-dy])
            else
                % Draw a zoom box.
                
                % Get x- and y-coordinates of the corners of the zoom box.
                x1 = min(this.zoomCorner(1), x);
                x2 = max(this.zoomCorner(1), x);
                y1 = min(this.zoomCorner(2), y);
                y2 = max(this.zoomCorner(2), y);
                
                % Remove parts of the zoom box which are outside the image.
                [xmin, xmax, ymin, ymax] = this.GetMaxAxisLimits(clickedAxes);
                x1 = max(x1, xmin);
                x2 = min(x2, xmax);
                y1 = max(y1, ymin);
                y2 = min(y2, ymax);
                
                % Adjust the zoom box to display whole pixels.
                if aPixelAxes
                    x1 = round(x1-0.5)+0.5;
                    x2 = round(x2-0.5)+0.5;
                    y1 = round(y1-0.5)+0.5;
                    y2 = round(y2-0.5)+0.5;
                end
                
                % Draw the zoom box.
                if x2 > x1 && y2 > y1
                    rect = plot(clickedAxes, [x1 x1 x2 x2 x1], [y1 y2 y2 y1 y1], 'r');
                    this.lines = [this.lines rect];
                end
            end
        end
        
        function oChanged = WindowButtonUpFcn(this, aObj, aEvent, varargin)
            % Executes when a mouse button is released.
            %
            % During zooming, this function will zoom in when the user has
            % dragged a zoom box and releases the mouse button. This will
            % change the axis limits so that the contents of the zoom box
            % fill the entire axes. During panning, the function will stop
            % the panning operation and tell the calling function that the
            % axis limits have changed.
            %
            % Inputs:
            % aObj - this.mainFigure
            %
            % Property/Value inputs:
            % PixelAxes - If this is true, the zoom box is rounded off to
            %             whole pixels. The default value is true.
            %
            % Outputs:
            % oChanged - True if the axis limits have changed. This output
            %            can be used to perform the correct updates in
            %            sub-classes.
            %
            % See also:
            % WindowButtonDownFcn, WindowButtonMotionFcn
            
            aPixelAxes = GetArgs({'PixelAxes'}, {true}, true, varargin);
            
            clickedAxes = gca;
            
            oChanged = false;
            
            if ~isempty(this.panCoordinates)
                % Stop the panning operation.
                this.panCoordinates = [];
                % Assume that the limits have changed during panning unless
                % the image is fully zoomed out.
                [xmin, xmax, ymin, ymax] = this.GetMaxAxisLimits(clickedAxes);
                limits = axis(clickedAxes);
                % Ignore z-limits of the clicked axes.
                oChanged = any(limits(1:4) ~= [xmin xmax ymin ymax]);
                setptr(this.mainFigure, 'hand')
                return
            end
            
            % Don't do anything if the user has not dragged a zoom box.
            if isempty(this.zoomCorner)
                return
            end
            
            % Get the current cursor coordinates.
            xy = get(clickedAxes, 'CurrentPoint');
            x = xy(1,1);
            y = xy(1,2);
            
            % Get x- and y-coordinates of the corners of the zoom box.
            x1 = min(this.zoomCorner(1), x);
            x2 = max(this.zoomCorner(1), x);
            y1 = min(this.zoomCorner(2), y);
            y2 = max(this.zoomCorner(2), y);
            
            % Remove parts of the zoom box which are outside the image.
            [xmin, xmax, ymin, ymax] = this.GetMaxAxisLimits(clickedAxes);
            x1 = max(x1, xmin);
            x2 = min(x2, xmax);
            y1 = max(y1, ymin);
            y2 = min(y2, ymax);
            
            % Adjust the zoom box to display whole pixels if zooming is
            % done on an axes with an image in it.
            if aPixelAxes
                x1 = round(x1-0.5)+0.5;
                x2 = round(x2-0.5)+0.5;
                y1 = round(y1-0.5)+0.5;
                y2 = round(y2-0.5)+0.5;
            end
            
            % Adjust the axis limits if the zoom box has a non-zero area.
            if x2 > x1 && y2 > y1
                this.PushAxisLimits(clickedAxes);
                this.SetAxisLimits(clickedAxes, [x1 x2 y1 y2])
                oChanged = true;
            end
            
            this.zoomCorner = [];
            % Remove the outline of the zoom box.
            this.WindowButtonMotionFcn(aObj, aEvent)
        end
    end
end