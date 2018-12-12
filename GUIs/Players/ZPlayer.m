classdef ZPlayer < SequencePlayer
    % Player which can display different planes in 3D z-stacks.
    %
    % The player has an additional panel on the right, where the user can
    % select planes in the z-stack to display. The panel is shown only when
    % there are multiple z-planes. Otherwise the GUI looks like the normal
    % player for 2D sequences. The player can show all planes which are
    % orthogonal to a coordinate axis. The user can choose between
    % displaying xy-, xz- or yz-planes, There is also an additional option
    % where one plane of each type are shown together. In this option one
    % can choose to plot two lines in each plot, showing the locations of
    % the other two planes. There are also check boxes for displaying
    % maximum intensity projections along each coordinate axis. x-, y- and
    % z-values for the planes can be selected using sliders, using text
    % boxes, or by clicking in one of the plots. xy-planes are shown in the
    % axes object this.ax.
    
    properties
        volumePanel = [];           % uipanel with all 3D controls.
        volumeSettingsPanel = [];   % SettingsPanel object with all 3D controls except the sliders.
        x = 1;                      % The displayed x-value in yz-planes.
        y = 1;                      % The displayed y-value in xz-planes.
        z = 1;                      % The displayed z-value in xy-planes.
        xSlider = [];               % Slider for selection of x-values.
        ySlider = [];               % Slider for selection of y-values.
        zSlider = [];               % Slider for selection of z-values.
        xLabel = [];                % Label for x-slider.
        yLabel = [];                % Label for y-slider.
        zLabel = [];                % Label for z-slider.
        volumePanelWidth = 0.1;     % Fraction of the figure width used by volumePanel.
        axXZ = [];                  % Axes objects where xz-planes are shown.
        axYZ = [];                  % Axes objects where yz-planes are shown.
    end
    
    methods
        function this = ZPlayer(aSeqPaths, varargin)
            % Constructs the player object and a figure associated with it.
            %
            % Inputs:
            % aSeqPath - Cell array with all image sequences that can be
            %            played.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        a the end of the constructor. This allows derived
            %        classes to postpone the call to Draw to the end of the
            %        derived class constructor. Default is true.
            
            % Get additional inputs.
            aDraw = GetArgs({'Draw'}, {true}, true, varargin);
            
            this = this@SequencePlayer(aSeqPaths, 'Draw', false);
            
            set(this.mainFigure,...
                'WindowButtonDownFcn',  @this.WindowButtonDownFcn)
            
            this.volumePanel = uipanel(...
                'BackgroundColor', [0.8 0.8 0.8],...
                'Units', 'normalized',...
                'Position', [1.0025-this.volumePanelWidth, 0,...
                this.volumePanelWidth-0.0025, 1]);
            
            % Input data for SettingsPanel, used to create ui-objects.
            info.display = Setting(...
                'name', 'display',...
                'default', 'xy',...
                'type', 'choice',...
                'alternatives_basic', {'xy'; 'yz'; 'xz'; 'all'},...
                'tooltip', ['Show projections or slices in all dimensions. '...
                'Otherwise only the selected projection is shown.'],...
                'callbackfunction', @this.Display_Callback);
            info.lines = Setting(...
                'name', 'lines',...
                'default', true,...
                'type', 'check',...
                'tooltip', 'Show lines representing slices in other dimensions.',...
                'callbackfunction', @this.Update3D);
            info.line_color = Setting(...
                'name', 'line color',...
                'default', [1 0 0],...
                'type', 'numeric',...
                'checkfunction', @(x) length(str2num(x)) == 3 &&...
                all(str2num(x) >= 0) && all(str2num(x) <= 1),...
                'tooltip', 'RGB color of the lines.',...
                'callbackfunction', @this.Update3D); %#ok<ST2NM>
            info.x_proj = Setting(...
                'name', 'x proj.',...
                'default', true,...
                'type', 'check',...
                'tooltip', 'Show maximum intensity projection in x-dimension.',...
                'callbackfunction', @this.Update3D);
            info.y_proj = Setting(...
                'name', 'y proj.',...
                'default', true,...
                'type', 'check',...
                'tooltip', 'Show maximum intensity projection in y-dimension.',...
                'callbackfunction', @this.Update3D);
            info.z_proj = Setting(...
                'name', 'z proj.',...
                'default', true,...
                'type', 'check',...
                'tooltip', 'Show maximum intensity projection in z-dimension.',...
                'callbackfunction', @this.Update3D);
            info.x = Setting(...
                'name', 'x',...
                'default', 1,...
                'type', 'numeric',...
                'tooltip', 'Selected x-plane.',...
                'checkfunction', @(x) ~isnan(str2double(x)),...
                'callbackfunction', @this.X_Callback);
            info.y = Setting(...
                'name', 'y',...
                'default', 1,...
                'type', 'numeric',...
                'tooltip', 'Selected y-plane.',...
                'checkfunction', @(x) ~isnan(str2double(x)),...
                'callbackfunction', @this.Y_Callback);
            info.z = Setting(...
                'name', 'z',...
                'default', 1,...
                'type', 'numeric',...
                'tooltip', 'Selected z-plane.',...
                'checkfunction', @(x) ~isnan(str2double(x)),...
                'callbackfunction', @this.Z_Callback);
            
            % The fraction of volumePanel height taken used by the
            % SettingsPanel. The rest will be used for by sliders.
            panelHeight = 0.3;
            
            this.volumeSettingsPanel = SettingsPanel(info,...
                'Parent', this.volumePanel,....
                'Position', [0 1-panelHeight 1 panelHeight],...
                'Split', 0.6,...
                'RemoveFocus', true);
            
            % Disable 3D options which have no effect in the xy-view.
            this.volumeSettingsPanel.Enable('lines', 'off')
            this.volumeSettingsPanel.Enable('line_color', 'off')
            this.volumeSettingsPanel.Enable('x_proj', 'off')
            this.volumeSettingsPanel.Enable('y_proj', 'off')
            this.volumeSettingsPanel.Enable('x', 'off')
            this.volumeSettingsPanel.Enable('y', 'off')
            this.volumeSettingsPanel.Enable('z', 'off')
            
            % Labels for the sliders.
            this.xLabel = uicontrol('Style', 'text',...
                'Parent', this.volumePanel,...
                'BackgroundColor', [0.8 0.8 0.8],...
                'String', 'x',...
                'Enable', 'off',...
                'Units', 'normalized',...
                'Position', [1/12 1-panelHeight-0.05 1/6 0.025]);
            this.yLabel = uicontrol('Style', 'text',...
                'Parent', this.volumePanel,...
                'BackgroundColor', [0.8 0.8 0.8],...
                'String', 'y',...
                'Enable', 'off',...
                'Units', 'normalized',...
                'Position', [5/12 1-panelHeight-0.05 1/6 0.025]);
            this.zLabel = uicontrol('Style', 'text',...
                'Parent', this.volumePanel,...
                'BackgroundColor', [0.8 0.8 0.8],...
                'String', 'z',...
                'Enable', 'off',...
                'Units', 'normalized',...
                'Position', [9/12 1-panelHeight-0.05 1/6 0.025]);
            
            % Sliders.
            this.xSlider = uicontrol('Style', 'slider',...
                'Parent', this.volumePanel,...
                'Min', 1,...
                'Max', this.GetImData().imageWidth,...
                'Value', 1,...
                'SliderStep', [1/this.GetImData().imageWidth 10/this.GetImData().imageWidth],...
                'Enable', 'off',...
                'Units', 'normalized',...
                'Interruptible', 'off',...
                'BusyAction', 'cancel',...
                'Position', [1/12 0.05 1/6 1-panelHeight-0.1],...
                'Tooltip', 'Slide to the desired x-slice',...
                'Callback', @this.XSlider_Callback);
            this.ySlider = uicontrol('Style', 'slider',...
                'Parent', this.volumePanel,...
                'Min', 1,...
                'Max', this.GetImData().imageHeight,...
                'Value', 1,...
                'SliderStep', [1/this.GetImData().imageHeight 10/this.GetImData().imageHeight],...
                'Enable', 'off',...
                'Units', 'normalized',...
                'Interruptible', 'off',...
                'BusyAction', 'cancel',...
                'Position', [5/12 0.05 1/6 1-panelHeight-0.1],...
                'Tooltip', 'Slide to the desired y-slice',...
                'Callback', @this.YSlider_Callback);
            this.zSlider = uicontrol('Style', 'slider',...
                'Parent', this.volumePanel,...
                'Min', 1,...
                'Max', this.GetImData().numZ+eps,...
                'Value', 1,...
                'SliderStep', [1/this.GetImData().numZ 10/this.GetImData().numZ],...
                'Enable', 'off',...
                'Units', 'normalized',...
                'Interruptible', 'off',...
                'BusyAction', 'cancel',...
                'Position', [9/12 0.05 1/6 1-panelHeight-0.1],...
                'Tooltip', 'Slide to the desired z-slice',...
                'Callback', @this.ZSlider_Callback);
            
            this.axYZ = axes();
            this.axXZ = axes();
            
            % Set the axis limits and do hold on so that one can rely on
            % having correct axis limits even when nothing has been plotted
            % in the axes. If this is removed, the XZ and YZ projections
            % can be incorrect if the XY projection is zoomed before the
            % other projections are shown.
            set(this.ax, 'xlim', [0 this.GetImData().imageWidth]+0.5)
            set(this.ax, 'ylim', [0 this.GetImData().imageHeight]+0.5)
            hold(this.ax, 'on')
            set(this.axXZ, 'xlim', [0 this.GetImData().imageWidth]+0.5)
            set(this.axXZ, 'ylim', [0 this.GetImData().numZ]+0.5)
            hold(this.axXZ, 'on')
            set(this.axYZ, 'xlim', [0 this.GetImData().numZ]+0.5)
            set(this.axYZ, 'ylim', [0 this.GetImData().imageHeight]+0.5)
            hold(this.axYZ, 'on')
            
            % Make the keyboard callbacks work after an uicontrol object
            % has been selected.
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
            
            if aDraw
                this.ReSizeAxes()
                this.ReSizeControls()
                this.Draw();
                
                % This ensures that zoom settings are not reset when a new
                % z-slice is displayed.
                axis(this.ax, 'manual')
            end
        end
        
        function ChannelMenu_Callback(this, aObj, ~)
            % Called when the user selects microscope channels.
            %
            % The function ensures that at least one microscope channel is
            % selected and redraws the image when the user clicks one of
            % the channel selection menus.
            %
            % This function overwrites a function with the same name in
            % SequencePlayer. This function calls Draw3D instead of Draw.
            %
            % Inputs:
            % aObj - Menu object which was clicked.
            
            if strcmp(get(aObj, 'Checked'), 'off')
                set(aObj, 'Checked', 'on')
            elseif sum(strcmp(get(this.channelMenus, 'Checked'), 'on')) > 1
                set(aObj, 'Checked', 'off')
            end
            this.Draw3D()
        end
        
        function Draw3D(this)
            % Displays planes and projections of 3D (or 2D) image data.
            %
            % The function calls 3 different function which generate the
            % xy-, xz- and xz-plots in the 3 different axes. Depending on
            % the display option selected, all axes may not be updated
            % and displayed. The Plot3D function is supposed to be used
            % when only the 3D display has been altered. If the plotted
            % data has been altered, the function Draw should be called
            % instead. This makes it possible to pre-compute results and
            % then display many different planes and projections without
            % recomputing the results.
            
            % Make slider move.
            set(this.slider, 'Value', this.frame)
            
            % Display current frame number.
            set(this.frameTextbox, 'String', num2str(this.frame))
            set(this.frameLabel, 'String', ['/' num2str(this.GetNumImages())])
            
            plotParams = this.PlotParameters();
            
            % The xy-plotting function is used for 2D data.
            if this.GetImData().numZ == 1 ||...
                    any(strcmp({'xy', 'all'}, plotParams.display))
                this.DrawXY(plotParams)
            end
            
            if this.GetImData().numZ > 1 &&...
                    any(strcmp({'xz', 'all'}, plotParams.display))
                this.DrawXZ(plotParams)
            end
            
            if this.GetImData().numZ > 1 &&...
                    any(strcmp({'yz', 'all'}, plotParams.display))
                this.DrawYZ(plotParams)
            end
        end
        
        function Draw(this)
            % Displays the image data.
            %
            % In this class, the function does exactly the same thing as
            % Draw3D, but in derived classes, this function should be
            % called when the plotted data has been altered. If only the 3D
            % display options have been altered, the function Draw3D should
            % be called instead, as that function is meant not to recompute
            % the plotted data.
            
            this.Draw3D()
        end
        
        function oParams = PlotParameters(this)
            % Generates a struct with parameters for plotting.
            %
            % The plotting functions for xy-, xz- and yz-plots have many
            % parameters in common and therefore it makes sense to compute
            % the settings only once in this function. The settings struct
            % has the following fields.
            %
            % lines - Set to 1 if lines showing the locations of other
            %         planes should be plotted, 0 otherwise.
            % lineColor - The color of lines showing the locations of other
            %             planes, in the form of an RGB triplet with values
            %             between 0 and 1.
            % xProj - If this is 1, a maximum intensity projection is done
            %         in x.
            % yProj - If this is 1, a maximum intensity projection is done
            %         in y.
            % zProj - If this is 1, a maximum intensity projection is done
            %         in z.
            % chs - Indices of the selected channels.
            % display - 'yz', 'xz', 'xy' or 'all', specifying what planes
            %           or projections should be displayed.
            
            oParams = struct(...
                'lines', this.volumeSettingsPanel.GetValue('lines'),...
                'lineColor', this.volumeSettingsPanel.GetValue('line_color'),...
                'xProj', this.volumeSettingsPanel.GetValue('x_proj'),...
                'yProj', this.volumeSettingsPanel.GetValue('y_proj'),...
                'zProj', this.volumeSettingsPanel.GetValue('z_proj'),...
                'chs', find(strcmp(get(this.channelMenus, 'Checked'), 'on')),...
                'display', this.volumeSettingsPanel.GetValue('display'));
        end
        
        function DrawXY(this, aParams, varargin)
            % Drawing function showing xy-planes or xy-projections.
            %
            % This function is also used to display 2D data. Unlike the
            % other plotting functions, this function can handle multiple
            % channels.
            %
            % Inputs:
            % aParams - struct with parameters used for plotting.
            
            aImage = GetArgs({'Image'}, {[]}, true, varargin);
            
            imData = this.GetImData();
            
            [~, ~, ~, ~, z1, z2] = this.GetZoom();
            
            if ~isempty(aImage)
                if imData.numZ == 1
                    im = aImage;
                else
                    im = aImage(:, :, z1:z2);
                    if aParams.zProj
                        % Maximum intensity projection.
                        im = max(im, [], 3);
                    else
                        % z-plane.
                        im = im(:, :, this.z);
                    end
                end
                
                if isa(im, 'logical')
                    % Logical values are not recognized in 'cLim'.
                    im = double(im);
                end
            else
                if imData.numZ == 1 || aParams.zProj
                    % Maximum intensity projection or 2D image.
                    im = imData.GetShownImage(this.frame,...
                        'Channels', aParams.chs,...
                        'ZPlane', z1:z2);
                else
                    % z-plane.
                    im = imData.GetShownImage(this.frame,...
                        'ZPlane', this.z,...
                        'Channels', aParams.chs);
                end
            end
            
            cla(this.ax) % Avoid accumulation.
            if isa(im, 'uint8') || ndims(im) == 3
                % Slightly faster than imshow, but does not work for all
                % images.
                image(im, 'Parent', this.ax)
                colormap(this.ax, gray(256))
            else
                imshow(im, 'Parent', this.ax)
            end
            % Get the true relationship between width and height of pixels.
            set(this.ax,...
                'DataAspectRatio',...
                [imData.voxelHeight() imData.voxelHeight() 1])
            if ~isempty(aImage)
                imMin = min(im(:));
                imMax = max(im(:));
                if imMin < imMax
                    set(this.ax, 'cLim', [imMin imMax])
                end
            end
            hold(this.ax, 'on')
            
            % Plot lines displaying the locations of other planes if other
            % planes (not projections) are shown.
            if imData.numZ > 1 && aParams.lines && strcmp(aParams.display, 'all')
                if ~aParams.xProj
                    plot(this.ax, [this.x this.x], [0.5 imData.imageHeight+0.5],...
                        'Color', aParams.lineColor)
                end
                if ~aParams.yProj
                    plot(this.ax, [0.5 imData.imageWidth+0.5], [this.y this.y],...
                        'Color', aParams.lineColor)
                end
            end
            
            % Y is 0 at the top of the image. The function 'imshow' does
            % this already, but 'image' does not.
            set(this.ax, 'yDir', 'reverse')
        end
        
        function DrawXZ(this, aParams, varargin)
            % Drawing function showing xz-planes or xz-projections. The
            % first z-slice appears at the top of the image.
            %
            % Inputs:
            % aParams - struct with parameters used for plotting.
            
            aImage = GetArgs({'Image'}, {[]}, true, varargin);
            
            imData = this.GetImData();
            
            if ~isempty(aImage)
                stack = aImage;
            else
                stack = imData.GetShownZStack(this.frame,...
                    'Channels', aParams.chs);
            end
            
            if aParams.yProj
                [~, ~, y1, y2] = this.GetZoom();
                im = squeeze(max(stack(y1:y2,:,:,:), [], 1));
            else
                im = squeeze(stack(this.y,:,:,:));
            end
            im = permute(im, [2, 1 3:ndims(im)]);
            
            if isa(im, 'logical')
                % Logical values are not recognized in 'cLim'.
                im = double(im);
            end
            
            cla(this.axXZ) % Avoid accumulation.
            if isa(im, 'uint8') || ndims(im) == 3
                % Slightly faster than imshow, but does not work for all
                % images.
                image(im, 'Parent', this.axXZ)
                colormap(this.axXZ, gray(256))
            else
                imshow(im, 'Parent', this.axXZ)
            end
            
            % Get the true relationship between width and height of pixels.
            set(this.axXZ,...
                'DataAspectRatio',...
                [imData.voxelHeight() 1 imData.voxelHeight()])
            if ~isempty(aImage)
                imMin = min(im(:));
                imMax = max(im(:));
                if imMin < imMax
                    set(this.axXZ, 'cLim', [imMin imMax])
                end
            end
            hold(this.axXZ, 'on')
            
            % Plot lines displaying the locations of other planes if other
            % planes (not projections) are shown.
            if aParams.lines && strcmp(aParams.display, 'all')
                if ~aParams.xProj
                    plot(this.axXZ, [this.x this.x], [0.5 imData.numZ+0.5],...
                        'Color', aParams.lineColor)
                end
                if ~aParams.zProj
                    plot(this.axXZ, [0.5 imData.imageWidth+0.5], [this.z this.z],...
                        'Color', aParams.lineColor)
                end
            end
            
            % Y is 0 at the top of the image. The function 'imshow' does
            % this already, but 'image' does not.
            set(this.axXZ, 'yDir', 'reverse')
        end
        
        function DrawYZ(this, aParams, varargin)
            % Drawing function showing yz-planes or yz-projections. The
            % first z-slice appears at the left side of the image.
            %
            % Inputs:
            % aParams - struct with parameters used for plotting.
            
            
            aImage = GetArgs({'Image'}, {[]}, true, varargin);
            
            imData = this.GetImData();
            
            if ~isempty(aImage)
                stack = aImage;
            else
                stack = imData.GetShownZStack(this.frame,...
                    'Channels', aParams.chs);
            end
            
            if aParams.xProj
                [x1, x2] = this.GetZoom();
                im = squeeze(max(stack(:,x1:x2,:,:), [], 2));
            else
                im = squeeze(stack(:,this.x,:,:));
            end
            
            if isa(im, 'logical')
                % Logical values are not recognized in 'cLim'.
                im = double(im);
            end
            
            cla(this.axYZ) % Avoid accumulation.
            if isa(im, 'uint8') || ndims(im) == 3
                % Slightly faster than imshow, but does not work for all
                % images.
                image(im, 'Parent', this.axYZ)
                colormap(this.axYZ, gray(256))
            else
                imshow(im, 'Parent', this.axYZ)
            end
            
            % Get the true relationship between width and height of pixels.
            set(this.axYZ,...
                'DataAspectRatio',...
                [1 imData.voxelHeight() imData.voxelHeight()])
            if ~isempty(aImage)
                imMin = min(im(:));
                imMax = max(im(:));
                if imMin < imMax
                    set(this.axYZ, 'cLim', [imMin imMax])
                end
            end
            hold(this.axYZ, 'on')
            
            % Plot lines displaying the locations of other planes if other
            % planes (not projections) are shown.
            if aParams.lines && strcmp(aParams.display, 'all')
                if ~aParams.yProj
                    plot(this.axYZ, [0.5 imData.numZ+0.5], [this.y this.y],...
                        'Color', aParams.lineColor)
                end
                if ~aParams.zProj
                    plot(this.axYZ, [this.z this.z], [0.5 imData.imageHeight+0.5],...
                        'Color', aParams.lineColor)
                end
            end
            
            % Y is 0 at the top of the image. The function 'imshow' does
            % this already, but 'image' does not.
            set(this.axYZ, 'yDir', 'reverse')
        end
        
        function oIm = GetFrame(this, varargin)
            % Performs screen capture on the tracks and the lineage tree.
            %
            % The contents of the different axes are captured separately
            % and then merged together. In the merge, the different images
            % are separated by bands of 10 black pixels by default. It is
            % however possible to change the background color to any gray
            % scale value by specifying the input PadColor. The background
            % of the figure is temporarily changed to the desired image
            % background color during the screen capture, in case the
            % coordinates of the axes boundaries are slightly off. The
            % background color of the figure is restored after the screen
            % capture.
            %
            % Property/Value inputs:
            % FFDshow - If this is set to true, the image will be padded
            %           from below and from the left so that the width is a
            %           multiple of 4 and the height is a multiple of 2. It
            %           is claimed that the image must fulfill these
            %           requirements for it to be encoded using the FFDShow
            %           codec.
            % PadColor - Gray scale value between 0 and 255 which specifies
            %            the color used for padding.
            
            [aFFDshow, aPadColor] = GetArgs(...
                {'FFDshow', 'PadColor'}, {false, 0}, true, varargin);
            
            % Background color before the screen capture.
            bgc = get(this.mainFigure, 'Color');
            % Set the background color to white.
            set(this.mainFigure, 'Color', ones(1,3)*aPadColor/255);
            
            % Find out which axes to record.
            if this.GetImData().GetDim == 2
                % Ignore the display setting for 2D data, because there is
                % only the xy-axes to record.
                display = 'xy';
            else
                display = this.volumeSettingsPanel.GetValue('display');
            end
            
            % Capture the different views.
            switch display
                case 'xy'
                    oIm = RecordAxes(this.ax);
                case 'xz'
                    oIm = RecordAxes(this.axXZ);
                case 'yz'
                    oIm = RecordAxes(this.axYZ);
                case 'all'
                    xyImage = RecordAxes(this.ax);
                    xzImage = RecordAxes(this.axXZ);
                    yzImage = RecordAxes(this.axYZ);
                    
                    % Pad at the bottom so that xyImage and yzImage get the
                    % same height.
                    if size(xyImage,1) > size(yzImage,1)
                        yzImage = padarray(yzImage,...
                            [size(xyImage,1)-size(yzImage,1) 0 0],...
                            aPadColor,...
                            'post');
                    elseif size(xyImage,1) < size(yzImage,1)
                        xyImage = padarray(xyImage,...
                            [size(yzImage,1)-size(xyImage,1) 0 0],...
                            aPadColor,...
                            'post');
                    end
                    
                    % Pad on the right side so that xyImage and xzImage get
                    % the same width.
                    if size(xyImage,2) > size(xzImage,2)
                        xzImage = padarray(xzImage,...
                            [0 size(xyImage,2)-size(xzImage,2) 0],...
                            aPadColor,...
                            'post');
                    elseif size(xyImage,2) < size(xzImage,2)
                        xyImage = padarray(xyImage,...
                            [0 size(xzImage,2)-size(xyImage,2) 0],...
                            aPadColor,...
                            'post');
                    end
                    
                    % Separate the 3D views with bands of 10 white pixels.
                    xyImage = padarray(xyImage, [10 10 0], aPadColor, 'post');
                    xzImage = padarray(xzImage, [0 10 0], aPadColor, 'post');
                    yzImage = padarray(yzImage, [10 0 0], aPadColor, 'post');
                    
                    % Merge the 3D views into a single image.
                    oIm = [xyImage yzImage
                        xzImage aPadColor*ones(size(xzImage,1), size(yzImage,2), 3)];
            end
            
            if aFFDshow
                oIm = PadForFFDshow(oIm, aPadColor);
            end
            
            % Restore the old background color.
            set(this.mainFigure, 'Color', bgc)
        end
        
        function [oXmin, oXmax, oYmin, oYmax] = GetMaxAxisLimits(this, aAxes)
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
            
            switch aAxes
                case this.ax
                    oXmin = 0.5;
                    oXmax = this.GetImData().imageWidth + 0.5;
                    oYmin = 0.5;
                    oYmax = this.GetImData().imageHeight + 0.5;
                case this.axXZ
                    oXmin = 0.5;
                    oXmax = this.GetImData().imageWidth + 0.5;
                    oYmin = 0.5;
                    oYmax = this.GetImData().numZ + 0.5;
                case this.axYZ
                    oXmin = 0.5;
                    oXmax = this.GetImData().numZ + 0.5;
                    oYmin = 0.5;
                    oYmax = this.GetImData().imageHeight + 0.5;
            end
        end
        
        function [oX1, oX2, oY1, oY2, oZ1, oZ2] = GetZoom(this)
            % Gets the current zoom limits.
            %
            % Outputs:
            % oX1 - Smallest x-value shown (horizontal dimension).
            % oX2 - Largest x-value shown (horizontal dimension).
            % oY1 - Smallest y-value shown (vertical dimension).
            % oY2 - Largest y-value shown (vertical dimension).
            % oZ1 - Smallest z-value (depth dimension in 3D data).
            % oZ2 - Smallest z-value (depth dimension in 3D data).
            
            xlimits = get(this.ax, 'xlim');
            oX1 = xlimits(1) + 0.5;
            oX2 = xlimits(2) - 0.5;
            
            ylimits = get(this.ax, 'ylim');
            oY1 = ylimits(1) + 0.5;
            oY2 = ylimits(2) - 0.5;
            
            zlimits = get(this.axXZ, 'ylim');
            oZ1 = zlimits(1) + 0.5;
            oZ2 = zlimits(2) - 0.5;
        end
        
        function oZoomed = IsZoomed(this)
            % Returns true if the user has zoomed in from the normal view.
            
            [x1, x2, y1, y2, z1, z2] = this.GetZoom();
            
            if x1 > 1 || x2 < this.GetImData().imageWidth ||...
                    y1 > 1 || y2 < this.GetImData().imageHeight ||...
                    z1 > 1 || z2 < this.GetImData().numZ
                oZoomed = true;
            else
                oZoomed = false;
            end
        end
        
        function X_Callback(this, ~, ~)
            % Function called when x is changed in the text box.
            
            val = this.volumeSettingsPanel.GetValue('x');
            val = round(val);
            val = max(val, 1);
            val = min(val, this.GetImData.imageWidth);
            this.volumeSettingsPanel.SetValue('x', val)
            if val ~= this.x
                this.x = val;
                set(this.xSlider, 'Value', this.x)
                this.Draw3D();
            end
        end
        
        function Y_Callback(this, ~, ~)
            % Function called when y is changed in the text box.
            
            val = this.volumeSettingsPanel.GetValue('y');
            val = round(val);
            val = max(val, 1);
            val = min(val, this.GetImData.imageHeight);
            this.volumeSettingsPanel.SetValue('y', val)
            if val ~= this.y
                this.y = val;
                set(this.ySlider, 'Value', this.y)
                this.Draw3D();
            end
        end
        
        function Z_Callback(this, ~, ~)
            % Function called when z is changed in the text box.
            
            val = this.volumeSettingsPanel.GetValue('z');
            val = round(val);
            val = max(val, 1);
            val = min(val, this.GetImData.numZ);
            this.volumeSettingsPanel.SetValue('z', val)
            if val ~= this.z
                this.z = val;
                set(this.zSlider, 'Value', this.z)
                this.Draw3D();
            end
        end
        
        function XSlider_Callback(this, ~, ~)
            % Function called when x is changed using the slider.
            
            % Remove focus from the slider so that it is not affected by
            % key-presses.
            set(this.xSlider, 'Enable', 'off')
            drawnow()
            set(this.xSlider, 'Enable', 'on')
            
            this.x = round(get(this.xSlider, 'Value'));
            set(this.xSlider, 'Value', this.x)
            this.volumeSettingsPanel.SetValue('x', this.x)
            this.Draw3D();
        end
        
        function YSlider_Callback(this, ~, ~)
            % Function called when y is changed using the slider.
            
            % Remove focus from the slider so that it is not affected by
            % key-presses.
            set(this.ySlider, 'Enable', 'off')
            drawnow()
            set(this.ySlider, 'Enable', 'on')
            
            this.y = round(get(this.ySlider, 'Value'));
            set(this.ySlider, 'Value', this.y)
            this.volumeSettingsPanel.SetValue('y', this.y)
            this.Draw3D();
        end
        
        function ZSlider_Callback(this, ~, ~)
            % Function called when z is changed using the slider.
            
            % Remove focus from the slider so that it is not affected by
            % key-presses.
            set(this.zSlider, 'Enable', 'off')
            drawnow()
            set(this.zSlider, 'Enable', 'on')
            
            this.z = round(get(this.zSlider, 'Value'));
            set(this.zSlider, 'Value', this.z)
            this.volumeSettingsPanel.SetValue('z', this.z)
            this.Draw3D();
        end
        
        function SwitchSequence(this, aIndex, varargin)
            % Switches to a specified image sequence.
            %
            % Redefines the same function in SequencePlayer, which switches
            % to displaying a new image sequence. The function changes
            % everything in the figure, so that the the new image sequence
            % can be played. In addition to the function of SequencePlayer,
            % the new function changes the sizes of the axes to match the
            % dimensions of the sample, and changes the limits of all
            % controls used to specify x-, y- and z-values. If a selected
            % coordinate is larger than the maximum value in then new
            % sequence, the coordinate is set to the maximum value in the
            % new sequence. If the new sequence is a 2D image, the panel
            % with 3D controls is not displayed.
            %
            % Inputs:
            % aIndex - The index of the new image sequence.
            %
            % Property/Value inputs:
            % Draw - If this is set to false, the Draw method is not called
            %        a the end of the function. This allows derived classes
            %        to postpone the call to Draw to the end of a redefined
            %        SwitchSequence in the derived class. The default is
            %        true.
            
            % Get additional inputs.
            aDraw = GetArgs({'Draw'}, {true, 0.1}, true, varargin);
            
            this.SwitchSequence@SequencePlayer(aIndex, 'Draw', false)
            
            imData = this.GetImData();
            
            if imData.numZ > 1
                % Change the 3D controls if it is a 3D sequence.
                
                % Change coordinates.
                this.x = min(this.volumeSettingsPanel.GetValue('x'), imData.imageWidth);
                this.y = min(this.volumeSettingsPanel.GetValue('y'), imData.imageHeight);
                this.z = min(this.volumeSettingsPanel.GetValue('z'), imData.numZ);
                
                % Change text boxes.
                this.volumeSettingsPanel.SetValue('x', this.x);
                this.volumeSettingsPanel.SetValue('y', this.y);
                this.volumeSettingsPanel.SetValue('z', this.z);
                
                % Change sliders.
                set(this.xSlider,...
                    'Max', imData.imageWidth,...
                    'Value', this.x,...
                    'SliderStep', [1/imData.imageWidth 10/imData.imageWidth])
                set(this.ySlider,...
                    'Max', imData.imageHeight,...
                    'Value', this.y,...
                    'SliderStep', [1/imData.imageHeight 10/imData.imageHeight])
                set(this.zSlider,...
                    'Max', imData.numZ,...
                    'Value', this.z,...
                    'SliderStep', [1/imData.numZ 10/imData.numZ])
            end
            
            if aDraw
                % Necessary to allow the image size to change between
                % sequences.
                xlim(this.ax, [0 imData.imageWidth]+0.5)
                ylim(this.ax, [0 imData.imageHeight]+0.5)
                xlim(this.axXZ, [0 imData.imageWidth]+0.5)
                ylim(this.axXZ, [0 imData.numZ]+0.5)
                xlim(this.axYZ, [0 imData.numZ]+0.5)
                ylim(this.axYZ, [0 imData.imageHeight]+0.5)
                
                this.ReSizeAxes()
                this.ReSizeControls()  % This hides the 3D controls for 2D data.
                this.Draw();
            end
        end
        
        function ReSizeControls(this)
            % Changes the sizes of all controls for 2D or 3D data display.
            %
            % If the data is in 2D, the function hides the panel with 3D
            % controls, and stretches all of the controls under the image
            % to use the full with of the figure. If the data is in 3D, the
            % function adds the panel with 3D controls and sets the sizes
            % and locations of the controls under the image accordingly.
            % The function does not change the sizes of the axes objects.
            % That is done in ReSizeAxes. The actual resizing of controls
            % is done in ReSizeControlsMargin.
            
            if this.GetImData().numZ > 1  % 3D data.
                set(this.volumePanel, 'Visible', 'on')
                this.ReSizeControlsMargin(this.volumePanelWidth)
            else  % 2D data.
                set(this.volumePanel, 'Visible', 'off')
                this.ReSizeControlsMargin(0)
            end
        end
        
        function ReSizeControlsMargin(this, aMarginWidth)
            % Resizes controls under the image to create a right margin.
            %
            % This function should only be called from ReSizeControls.
            %
            % Inputs:
            % aMarginWidth - The width of the right margin in normalized
            %                figure units.
            
            set(this.seqPopupMenu, 'Position', [0.025, 0.005, 0.25*(1-aMarginWidth), 0.035])
            set(this.slider, 'Position', [0.025 0.045 0.95-aMarginWidth 0.015])
            set(this.playbackPanel, 'Position', [0.775-aMarginWidth, 0.005, 0.2, 0.035])
            set(this.playButton, 'Position', [0.45-aMarginWidth/2, 0.005, 0.1, 0.035])
            set(this.previousButton, 'Position', [0.35-aMarginWidth/2, 0.005, 0.1, 0.035])
            set(this.nextButton, 'Position', [0.55-aMarginWidth/2, 0.005, 0.1, 0.035])
        end
        
        function ReSizeAxes(this, varargin)
            % Changes the sizes of the axes objects to match the sample.
            %
            % Property/Value inputs:
            % KeepAxisLimits - If this parameter is set to true, the
            %                  dimensions of the displayed region of the
            %                  sample will be determined from the axis
            %                  limits. By default, it is assumed that the
            %                  entire sample is shown. In that case, the
            %                  dimensions of the sample are determined
            %                  from the ImageData object. The parameter
            %                  needs to be set to true to arrange the axes
            %                  properly when zooming is used together with
            %                  the 'all' layout.
            %
            % This function updates the dimensions of the axes based on the
            % selections in the 3D control panel, by calling
            % ReSizeAxesMargin.
            
            layout = this.volumeSettingsPanel.GetValue('display');
            if this.GetImData().numZ > 1
                this.ReSizeAxesMargin(layout, [0 this.volumePanelWidth], varargin{:})
            else
                this.ReSizeAxesMargin('xy', [0 0], varargin{:})
            end
        end
        
        function ReSizeAxesMargin(this, aLayout, aMarginWidth, varargin)
            % Changes the sizes of the axes objects.
            %
            % The sizes of the axes are set so that the all projections of
            % the z-stack can be displayed in the correct aspect ratio. If
            % all 3 projections are displayed simultaneously, the sizes of
            % the axes are set so that the xy-axes is in the top left
            % corner and the xz- and yz-axes are below and to the right of
            % the xy-projection respectively. The xz- and yz-axes are
            % placed and sized so that they get the same x- and y-axis as
            % the xy-projection respectively. This is ensured by giving the
            % xy-axes and the xz-axes heights which are proportional to the
            % y-length and the z-length of the sample respectively.
            % Similarly the xy- and the yz-axes are given widths which are
            % proportional to the x-length and the z-length of the sample
            % respectively. Axes which should not be displayed are hidden,
            % and their positions are changed to [0 0 eps eps], so that
            % they do not interfere with zooming in the displayed axes. All
            % sizes and locations of graphics components are given in the
            % normalized coordinates of the figure. This function should
            % only be called from ReSizeAxes.
            %
            % Inputs:
            % aLayout - One out of 4 different layouts, showing the sample
            %           seen in different planes. The options are 'xy',
            %           'xz', 'yz', and 'all', where all shows 3 axes with
            %           the sample seen from all directions 3 directions.
            % aMarginWidth - Specifies how wide the margins to the right
            %                and to the left of the axes should be. These
            %                margins can be used for the 3D control panel,
            %                other control objects or plots. The first
            %                element specifies the left margin and the
            %                second element specifies the right margin. The
            %                margins are given in normalized figure units.
            %
            % Property/Value inputs:
            % KeepAxisLimits - If this parameter is set to true, the
            %                  dimensions of the displayed region of the
            %                  sample will be determined from the axis
            %                  limits. By default, it is assumed that the
            %                  entire sample is shown. In that case, the
            %                  dimensions of the sample are determined
            %                  from the ImageData object. The parameter
            %                  needs to be set to true to arrange the axes
            %                  properly when zooming is used together with
            %                  the 'all' layout.
            
            aKeepAxisLimits = GetArgs({'KeepAxisLimits'}, {false}, true, varargin);
            
            switch aLayout
                % 3D data. Set the axes sizes based on which
                % projections should be displayed. Unused axes are
                % hidden by changing the 'Visible' property.
                case 'all'
                    delta_h = 0.02;  % Distance between xy- and xz-axes.
                    delta_w = 0.01;  % Distance between xy- and yz-axes.
                    W = 1 - sum(aMarginWidth);  % Height of area available to all axes.
                    H = 0.925;  % Width of area available to all axes.
                    
                    % Dimensions of the displayed region of the sample in
                    % voxel widths.
                    if aKeepAxisLimits
                        w = diff(get(this.ax, 'xlim'));
                        h = diff(get(this.ax, 'ylim'));
                        d = diff(get(this.axXZ, 'ylim')) * this.GetImData().voxelHeight;
                    else
                        w = this.GetImData().imageWidth;
                        h = this.GetImData().imageHeight;
                        d = this.GetImData().numZ * this.GetImData().voxelHeight;
                    end
                    
                    h1 = (H-delta_h) / (1+d/h);  % Height of xy-axes (and yz-axes).
                    h2 = (H-delta_h) / (1+h/d);  % Height of xz-axes.
                    w1 = (W-delta_w) / (1+d/w);  % Width of xy-axes (and xz-axes).
                    w2 = (W-delta_w) / (1+w/d);  % Width of yz-axes.
                    
                    set(this.axYZ,....
                        'Visible', 'on',...
                        'Position', [aMarginWidth(1)+w1+delta_w 0.07+h2+delta_h w2 h1])
                    set(this.axXZ,...
                        'Visible', 'on',...
                        'Position', [aMarginWidth(1) 0.07 w1 h2])
                    set(this.ax,...
                        'Visible', 'on',...
                        'Position', [aMarginWidth(1) 0.07+h2+delta_h w1 h1])
                case 'yz'
                    set(this.axYZ,...
                        'Visible', 'on',...
                        'Position', [aMarginWidth(1) 0.07 1-sum(aMarginWidth) 0.925])
                    cla(this.axXZ)
                    set(this.axXZ, 'Visible', 'off', 'Position', [0 0 eps eps]);
                    cla(this.ax)
                    set(this.ax, 'Visible', 'off', 'Position', [0 0 eps eps])
                case 'xz'
                    cla(this.axYZ)
                    set(this.axYZ, 'Visible', 'off', 'Position', [0 0 eps eps]);
                    set(this.axXZ,...
                        'Visible', 'on',...
                        'Position', [aMarginWidth(1) 0.07 1-sum(aMarginWidth) 0.925])
                    cla(this.ax)
                    set(this.ax, 'Visible', 'off', 'Position', [0 0 eps eps])
                case 'xy'
                    cla(this.axYZ)
                    set(this.axYZ, 'Visible', 'off', 'Position', [0 0 eps eps]);
                    cla(this.axXZ)
                    set(this.axXZ, 'Visible', 'off', 'Position', [0 0 eps eps]);
                    set(this.ax,...
                        'Visible', 'on',...
                        'Position', [aMarginWidth(1) 0.07 1-sum(aMarginWidth) 0.925])
            end
            axis(this.ax, 'off')
            axis(this.axXZ, 'off')
            axis(this.axYZ, 'off')
        end
        
        function Display_Callback(this, ~, ~)
            % Called when the set of projections to be shown is changed.
            
            this.Update3D()
            this.ReSizeAxes('KeepAxisLimits', true)
        end
        
        function PushAxisLimits(this, aAxes)
            % Stores axis limits for axes.
            %
            % This function stores the current axis limits so that the user
            % can go back to these axis limits later by right-clicking.
            % This function overrides the function with the same name in
            % SequencePlayer. The difference compared to the function in
            % SequencePlayer is that the axis limits of all 3D views are
            % stored when the user clicks in one of them.
            %
            % Inputs:
            % aAxes - Axes object that the user clicked in.
            %
            % See also:
            % PopAxisLimits, GetMaxAxisLimits
            
            this.PushAxisLimits@SequencePlayer(aAxes)
            switch aAxes
                case this.ax
                    this.PushAxisLimits@SequencePlayer(this.axXZ)
                    this.PushAxisLimits@SequencePlayer(this.axYZ)
                case this.axXZ
                    this.PushAxisLimits@SequencePlayer(this.ax)
                    this.PushAxisLimits@SequencePlayer(this.axYZ)
                case this.axYZ
                    this.PushAxisLimits@SequencePlayer(this.axXZ)
                    this.PushAxisLimits@SequencePlayer(this.ax)
            end
        end
        
        function SetAxisLimits(this, aAxes, aLimits)
            % Changes the axis limits of an axes and axes coupled to it.
            %
            % The 3D view axes are coupled so that the same x-, y- and
            % z-intervals are shown in all axes when the limits of one of
            % them are changed using this function.
            %
            % Inputs:
            % aAxes - Axes object for which the limits need to be changed.
            % aLimits - A 4 element vector with the new limits of the axes
            %           in the order [x-min x-max y-min y-max]. The x- and
            %           y-coordinates refer to the coordinate system of the
            %           axes and not to the image dimensions.
            %
            % See also:
            % ReSizeAxes
            
            axis(aAxes, aLimits)
            switch aAxes
                case this.ax
                    set(this.axXZ, 'xlim', aLimits(1:2))
                    set(this.axYZ, 'ylim', aLimits(3:4))
                case this.axXZ
                    set(this.ax, 'xlim', aLimits(1:2))
                    set(this.axYZ, 'xlim', aLimits(3:4))
                case this.axYZ
                    set(this.axXZ, 'ylim', aLimits(1:2))
                    set(this.ax, 'ylim', aLimits(3:4))
            end
            
            this.ReSizeAxes('KeepAxisLimits', true)
        end
        
        function Update3D(this, ~, ~)
            % Callback which enables usable 3D visualization tools.
            %
            % This function enables all 3D visualization tools which affect
            % the current view, and disables the rest. Then the function
            % updates the displayed images.
            
            % Get the selected visualization options from the controls.
            display = this.volumeSettingsPanel.GetValue('display');
            lines = this.volumeSettingsPanel.GetValue('lines');
            xProj = this.volumeSettingsPanel.GetValue('x_proj');
            yProj = this.volumeSettingsPanel.GetValue('y_proj');
            zProj = this.volumeSettingsPanel.GetValue('z_proj');
            
            % Enable/disable tools that display lines for selected slices.
            if strcmp('all', display) && (~xProj || ~yProj || ~zProj)
                this.volumeSettingsPanel.Enable('lines', 'on')
                if lines
                    this.volumeSettingsPanel.Enable('line_color', 'on')
                else
                    this.volumeSettingsPanel.Enable('line_color', 'off')
                end
            else
                this.volumeSettingsPanel.Enable('lines', 'off')
                this.volumeSettingsPanel.Enable('line_color', 'off')
            end
            
            % Disables tools for slicing and projections which cannot be
            % used in the current 3D view.
            switch display
                case 'all'
                    this.volumeSettingsPanel.Enable('x_proj', 'on')
                    this.volumeSettingsPanel.Enable('y_proj', 'on')
                    this.volumeSettingsPanel.Enable('z_proj', 'on')
                    
                    if xProj
                        this.volumeSettingsPanel.Enable('x', 'off')
                        set(this.xLabel, 'Enable', 'off')
                        set(this.xSlider, 'Enable', 'off')
                    else
                        this.volumeSettingsPanel.Enable('x', 'on')
                        set(this.xLabel, 'Enable', 'on')
                        set(this.xSlider, 'Enable', 'on')
                    end
                    
                    if yProj
                        this.volumeSettingsPanel.Enable('y', 'off')
                        set(this.yLabel, 'Enable', 'off')
                        set(this.ySlider, 'Enable', 'off')
                    else
                        this.volumeSettingsPanel.Enable('y', 'on')
                        set(this.ySlider, 'Enable', 'on')
                        set(this.yLabel, 'Enable', 'on')
                    end
                    
                    if zProj
                        this.volumeSettingsPanel.Enable('z', 'off')
                        set(this.zLabel, 'Enable', 'off')
                        set(this.zSlider, 'Enable', 'off')
                    else
                        this.volumeSettingsPanel.Enable('z', 'on')
                        set(this.zLabel, 'Enable', 'on')
                        set(this.zSlider, 'Enable', 'on')
                    end
                case 'xy'
                    this.volumeSettingsPanel.Enable('x_proj', 'off')
                    this.volumeSettingsPanel.Enable('y_proj', 'off')
                    this.volumeSettingsPanel.Enable('z_proj', 'on')
                    
                    this.volumeSettingsPanel.Enable('x', 'off')
                    set(this.xLabel, 'Enable', 'off')
                    set(this.xSlider, 'Enable', 'off')
                    
                    this.volumeSettingsPanel.Enable('y', 'off')
                    set(this.yLabel, 'Enable', 'off')
                    set(this.ySlider, 'Enable', 'off')
                    
                    if zProj
                        this.volumeSettingsPanel.Enable('z', 'off')
                        set(this.zLabel, 'Enable', 'off')
                        set(this.zSlider, 'Enable', 'off')
                    else
                        this.volumeSettingsPanel.Enable('z', 'on')
                        set(this.zLabel, 'Enable', 'on')
                        set(this.zSlider, 'Enable', 'on')
                    end
                case 'xz'
                    this.volumeSettingsPanel.Enable('x_proj', 'off')
                    this.volumeSettingsPanel.Enable('y_proj', 'on')
                    this.volumeSettingsPanel.Enable('z_proj', 'off')
                    
                    this.volumeSettingsPanel.Enable('x', 'off')
                    set(this.xLabel, 'Enable', 'off')
                    set(this.xSlider, 'Enable', 'off')
                    
                    if yProj
                        this.volumeSettingsPanel.Enable('y', 'off')
                        set(this.yLabel, 'Enable', 'off')
                        set(this.ySlider, 'Enable', 'off')
                    else
                        this.volumeSettingsPanel.Enable('y', 'on')
                        set(this.ySlider, 'Enable', 'on')
                        set(this.yLabel, 'Enable', 'on')
                    end
                    
                    this.volumeSettingsPanel.Enable('z', 'off')
                    set(this.zLabel, 'Enable', 'off')
                    set(this.zSlider, 'Enable', 'off')
                case 'yz'
                    this.volumeSettingsPanel.Enable('x_proj', 'on')
                    this.volumeSettingsPanel.Enable('y_proj', 'off')
                    this.volumeSettingsPanel.Enable('z_proj', 'off')
                    
                    if xProj
                        this.volumeSettingsPanel.Enable('x', 'off')
                        set(this.xLabel, 'Enable', 'off')
                        set(this.xSlider, 'Enable', 'off')
                    else
                        this.volumeSettingsPanel.Enable('x', 'on')
                        set(this.xLabel, 'Enable', 'on')
                        set(this.xSlider, 'Enable', 'on')
                    end
                    
                    this.volumeSettingsPanel.Enable('y', 'off')
                    set(this.yLabel, 'Enable', 'off')
                    set(this.ySlider, 'Enable', 'off')
                    
                    this.volumeSettingsPanel.Enable('z', 'off')
                    set(this.zLabel, 'Enable', 'off')
                    set(this.zSlider, 'Enable', 'off')
            end
            
            % Updates the displayed images.
            this.Draw3D()
        end
        
        function WindowButtonDownFcn(this, aObj, ~)
            % Called when the user clicks inside one of the axes objects.
            %
            % The function does zooming and switches between displayed
            % planes in a 3D volume. If all 3 3D projections are shown, the
            % axes are coupled so that zooming in one axes changes the
            % limits of all 3 axes. If the shift key is held while the user
            % clicks, the planes shown in the other axes are altered to
            % display planes which go through the pixel which was clicked.
            % This makes it possible to click on a cell in one
            % coordinate-plane and see what it looks like in the other two
            % coordinate-planes. This does not work when projections are
            % displayed.
            
            if ~strcmp(get(aObj,'SelectionType'), 'extend')
                this.WindowButtonDownFcn@SequencePlayer(aObj, [])
                if strcmp(get(aObj,'SelectionType'), 'alt')
                    this.Draw3D()
                end
                return
            end
            
            if this.GetImData.GetDim() == 3 &&...
                    ~strcmp(this.volumeSettingsPanel.GetValue('display'), 'all')
                return
            end
            
            xProj = this.volumeSettingsPanel.GetValue('x_proj');
            yProj = this.volumeSettingsPanel.GetValue('y_proj');
            zProj = this.volumeSettingsPanel.GetValue('z_proj');
            
            switch gca
                case this.axYZ
                    coord = get(this.axYZ, 'CurrentPoint');
                    if ~InsideAxes(this.axYZ, coord(1,1), coord(1,2))
                        return
                    end
                    if ~yProj
                        this.y = round(coord(1,2));
                    end
                    if ~zProj
                        this.z = round(coord(1,1));
                    end
                case this.axXZ
                    coord = get(this.axXZ, 'CurrentPoint');
                    if ~InsideAxes(this.axXZ, coord(1,1), coord(1,2))
                        return
                    end
                    if ~xProj
                        this.x = round(coord(1,1));
                    end
                    if ~zProj
                        this.z = round(coord(1,2));
                    end
                case this.ax
                    coord = get(this.ax, 'CurrentPoint');
                    if ~InsideAxes(this.ax, coord(1,1), coord(1,2))
                        return
                    end
                    if ~xProj
                        this.x = round(coord(1,1));
                    end
                    if ~yProj
                        this.y = round(coord(1,2));
                    end
            end
            
            % Update text boxes.
            this.volumeSettingsPanel.SetValue('x', this.x);
            this.volumeSettingsPanel.SetValue('y', this.y);
            this.volumeSettingsPanel.SetValue('z', this.z);
            
            % Update sliders.
            set(this.xSlider, 'Value', this.x)
            set(this.ySlider, 'Value', this.y)
            set(this.zSlider, 'Value', this.z)
            
            this.Draw3D()
        end
        
        function WindowButtonUpFcn(this, aObj, aEvent, varargin)
            % Performs zooming when the user finishes drawing a zoom-box.
            %
            % In 3D data, it is not enough to change the axes limits when
            % zooming is performed, as 3D projections should be done only
            % on the displayed region. Therefore, WindowButtonUpFcn is
            % redefined.
            
            
            
            changed = this.WindowButtonUpFcn@SequencePlayer(aObj, aEvent, varargin{:});
            
            if this.GetImData.GetDim() == 3 &&...
                    strcmp(this.volumeSettingsPanel.GetValue('display'), 'all') &&...
                    changed
                this.Draw3D()
            end
        end
    end
end