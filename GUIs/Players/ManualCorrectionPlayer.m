classdef ManualCorrectionPlayer < ZControlPlayer
    % GUI for manual correction of tracks and outlines of cells.
    %
    % The GUI shows an image sequence and plots tracking results on top of
    % the images. For 3D data, different projections and slices can be
    % shown, just as in ZControlPlayer. The lineage tree corresponding to
    % the tracks can be shown to the left of the plotted tracks or in a
    % separate window. There are many different visualization options, and
    % the user can make edits to the tracks and the outlines of the cells
    % using a number of editing tools.
    %
    % In the default plotting style, small filled circles denote cells in
    % the previous frame and large filled circles denote cells in the
    % current frame. Unfilled circles denote cell positions in frames
    % further back in time, that can not be manipulated. Cell centroids
    % that have been manipulated by the user are shown as squares instead
    % of circles. Stars denote segmented centroids that are believed to be
    % false positives. These tracks will not be shown in the lineage tree.
    %
    % There are toggle buttons for the different operations that can be
    % performed. The buttons have keyboard shortcuts which can be seen in
    % the tooltips of the buttons. When the number of cells in a blob is
    % changed, the blob is split into smaller segments automatically, using
    % k-means clustering. This splitting is automatic and can not be
    % controlled by the user, but the user can edit the blobs by either
    % adding or removing pixels.
    %
    % It is faster to use the keyboard shortcuts when doing corrections,
    % but the buttons show the user what operation is currently performed
    % and what operations are available. It can be convenient to step
    % forwards and backwards in time using the backward and forward arrow
    % keys. You can also click in the lineage tree to move to any frame in
    % the sequence.
    %
    % The 'CloseRequestFcn' property of the main figure has been defined so
    % that the it can become impossible to close the figure using the
    % close-button, if something goes wrong in the function. If that
    % happens, you can use the command "delete(gcf)" to close the figure.
    %
    %
    %
    % Menu options:
    %
    % Export - Exports images or videos of the tracked cells.
    % Export->Image - Exports a tiled image with screen captures from the
    %                 different axes in the figure.
    % Export->Video - Lets the user record the frames that are played in
    %                 the GUI, export them to tiled png-images and turn
    %                 them into an avi-video.
    % Export->Videos for all sequences - Records tiled png-images for all
    %                                    time points in all images and
    %                                    turns them into an avi-video.
    % Export->Record iterations - Records intermediate tracking results
    %                             into a sequence of png-images.
    %
    % Channels - Selects which channels to display in multi-channel images.
    %
    % Style - Selects a plotting style for the tracks.
    %
    % Coloring - Selects a coloring scheme for the cells.
    %
    % Tree - Selects where the lineage tree should be displayed and what
    %        unit should be used on the time-axis.
    %
    %
    %
    % Controls:
    %
    % Load Tracks - Popup menu where the user can load automatically
    %               generated and manually corrected tracking results.
    %
    % Display Toggles - Options for how tracks and outlines are visualized.
    % Show/Hide Trajectories - Toggles plotting of trajectories.
    % Trajectory Trail Length - The number of time point plotted in each
    %                           trajectory. If 3 is selected, the current
    %                           time point and the 2 preceding time points
    %                           are plotted.
    % Show/Hide Outlines - Toggles plotting of outlines.
    % Outline Trail Length - The number of time points to plot outlines
    %                        for. The default value is 1, which shows only
    %                        the current outline, but the value can be
    %                        increased to show earlier outlines as well.
    % Show/Hide False Positives - Toggles plotting of false positives.
    %                             False positives are tracks of blobs which
    %                             are not considered to be cells, but which
    %                             were detected by the segmentation
    %                             algorithm.
    % False Positive RGB Color - Color in which false positive tracks will
    %                            be plotted. The color is defined as a 3
    %                            element vector with values between 0 and
    %                            1. The 3 elements define how much red,
    %                            green and  blue the color has.
    % Show/Hide Mitosis and Death events - Toggles plotting of events where
    %                                      cells divide, die, appear and
    %                                      disappear.
    % Show/Hide Current Frame Line - Toggles plotting of the horizontal
    %                                line showing the current frame in the
    %                                lineage tree.
    %
    % Coloring Tools - Tools used to color the tracks manually.
    % Change Color of Cell - Changes the color of a single cell when the
    %                        user clicks on the cell.
    % RGB Value for Cell Color - RGB triplet defining the color used by the
    %                            single cell coloring tool.
    % Change Color of All Cells - Changes the color of all cells when the
    %                             button is pressed.
    % RGB Value for Cell Color - RGB triplet defining the color used to
    %                            color all cells.
    %
    % Correction tools - Tools to correct tracks and outlines of cells.
    % Track Tool - Allows the user to change the links between cell nodes.
    %              A link in a trajectory is created by first clicking on
    %              a small filled circle representing a cell node in the
    %              previous frame and then clicking on a large filled
    %              circle representing a cell node in the current frame.
    % Leave Tool - Specifies that a cell dies or that it leaves the field
    %              of view. Clicking a cell toggles between the two fates.
    % Add - Adds a new cell node. If the node is added inside the outline
    %       of a cell or a cluster of cells, the outline will be split to
    %       give the new cell an outline. If the node is added in the
    %       background, it will not get an outline. The new cell is only
    %       present in the current frame.
    % Continuous Add - This tool lets the user add a chain of new cell
    %                  nodes. When the user clicks, a new node is created
    %                  and connected to the previous node if there is one.
    %                  Then the player goes to the following frame so that
    %                  the next node in the chain can be added.
    % Split - Allows the user to copy an entire cell trajectory. This will
    %         create a new cell that appears in the same blob as the copied
    %         cell in all frames where the cell is present. The blobs of
    %         the original cell will now be split between the two cells.
    % Track Split - Allows the user to click on a cell node in the previous
    %               image and then connect it to a copy of the end of a
    %               track in the current image. The cell in the current
    %               frame is copied from the current frame to the end of
    %               the track and then the segmentation is updated as when
    %               the Split tool is used.
    % Add Child - Allows the user to specify the parent-child relationship
    %             between cells. The user first clicks the small filled
    %             circle of the parent cell and then clicks the large
    %             filled circles of the two child cells. To avoid leaving a
    %             parent cell with a single child cell, the first child
    %             cell is appended to the parent cell using a migration
    %             link. When the second child is added, the migration link
    %             will be replaced by a parent-child link.
    % Move Mitosis - The mitosis can either be moved forward in time by
    %                clicking on one of the child cells or backward in
    %                time by clicking on the parent cell. If the clicked
    %                cell is both a parent cell and a child cell, the
    %                mitotic event closest in time will be moved. If the
    %                parent cell is clicked, the two child cells will both
    %                follow the old track of the parent cell between the
    %                time points of the new and the old mitosis. If a child
    %                cell is clicked, the parent cell will follow the old
    %                track of the clicked cell between the time points of
    %                the new and the old mitosis, and the track of the
    %                other child cell will be turned into a false positive
    %                track between the these time points.
    % Delete - Right-clicking on a cell will turn the whole cell into a
    %          false positive cell. This will also break the connection to
    %          the parent of the cell, and turn all children of the cell
    %          into false positive cells. Left-clicking on a cell will
    %          instead kill the cell in the current frame and keep all
    %          prior time points. This will also turn all children into
    %          false positive cells. Right-clicking or left-clicking false
    %          positives will turn the entire tracks or all subsequent
    %          frames into real cells.
    % Edit segments - Turns editing of blob segments on, so that the blobs
    %                 can be edited with a brush as in a drawing program.
    %                 The bush is displayed in red on the image. The user
    %                 can add pixels to blobs by putting the brush over a
    %                 blob, pressing down the left mouse button and drawing
    %                 the extension of the  blob. The user can also
    %                 subtract pixels by holding down the right mouse
    %                 button. The edits take effect when the mouse button
    %                 is released again. The edits are not made to the
    %                 blobs associated with the cells, but to the
    %                 underlying segmented regions of the image. What the
    %                 cell blobs will look like in the end is determined by
    %                 the k-means algorithm used to break cell clusters. To
    %                 override how cell clusters are broken, the user can
    %                 separate the cell regions by lines of background
    %                 pixels. The user can alter the size of the brush by
    %                 using the scroll wheel on the mouse or by pressing +
    %                 and -.
    % Move - Allows the user to move a single detection associated with a
    %        cell. The user can move it to another blob or place it in the
    %        background where there are no blobs, but then it will not get
    %        an outline. Moving a cell inside the same blob has no effect.
    % Remove FP - This tool removes false positive detections which don't
    %             have segments associated with them. Such detections can
    %             appear when a cell object is deleted in a super-blob with
    %             multiple cells. When a  false positive cell has some
    %             blobs with segments and some blobs without segments, the
    %             cell can be broken into multiple fragments when the time
    %             points without segments are removed.
    % Jump - Moves to the next frame where any track starts or ends.
    % Save - Opens a dialog box where the user can save the edited version
    %        of the cell information to a new tracking version. It is a
    %        good practice to save to a new version and not overwrite a
    %        computer generated version, because otherwise it can be hard
    %        to distinguish corrected versions from uncorrected versions.
    %
    % Visualization - Tools that can be used to visualize specific tracks.
    %                 These tools do not alter the tracks in any way.
    % Highlighting Mode - The cell that the user clicks on is colored
    %                     orange and all other cells are colored blue so
    %                     that a single track can be visualized more
    %                     easily. The cell can be clicked both in the
    %                     images and in the lineage tree.
    % Zoom - This tool lets the user zoom in all of the axes of the GUI.
    %        The tool was added mainly because the built in zoom function
    %        can be extremely slow when large datasets are processed. The
    %        user zooms in by dragging a box around the part of the image
    %        that should be enlarged. The user zooms out again by
    %        right-clicking in the axes. If multiple 3D-views are shown,
    %        they are coupled so that the axis limits of all axes are
    %        changed simultaneously.
    %
    % Hidden options:
    %
    % ALT+M - Toggles plotting of microwells.
    % ALT+B - Toggles between displaying the original image and displaying
    %         a background subtracted image.
    % 0-9   - Changes trajectory length to specified number
    % I     - Changes trajectory length to infinity
    %
    % See also:
    % BaxterAlgorithms, ProcessDirectory, SegmentationPlayer,
    % SetFluorescencePlayer, ZControlPlayer, ZPlayer, SequencePlayer
    %
    % TODO: Make it possible to load compact tracking data.
    %
    % Features suggested by Andrew Chan:
    % - Options menu where keyboard shortcuts can be customized
    % - Opening tracking versions and saving is done from a 'File' menu
    % option since most users look for opening and saving files in a 'File'
    % menu, plus it will save space in the tool and toggle palette.
    
    properties
        % Figures, axes and menus.
        
        treeFigure      % Separate figure for the lineage tree.
        saveFigure      % Separate figure with dialog for saving.
        treeAxes        % Axes object where the lineage tree is plotted.
        stylesMenu      % Menu for selecting plotting styles.
        coloringMenu    % Menu for selecting cell coloring.
        drawMenu
        treeMenu        % Menu for selecting lineage tree display options.
        
        % Tracking versions.
        
        versions    % Available tracking versions for the current sequence.
        loadedVer   % Currently loaded tracking version.
        prefVer     % The tracking version selected by the user.
        edited      % True if there are unsaved edits.
        
        % Cells.
        
        fromCell    % Cell in the previous image that the user can connect to cells in the current image.
        update      % Cell array with binary arrays indicating which blobs need to be updated.
        cellColors  % Array of cell colors that are saved when using the select/highlight cells tool.
        
        % Ground truth.
        
        gtCells     % Array of Cell objects with the ground truth cells currently loaded.
        gtSeqPath   % The path of the image sequence that the ground truth cells belong to.
        
        % Graphics.
        
        brush           % Brush object used to make segmentation edits.
        prevBrush       % Brush object from the previous update during segmentation editing.
        currentLine     % Line object marking the current frame in the lineage tree.
        
        % Visualization options.
        
        tLength         % The number of frames from which to plot trajectories.
        oLength         % The number of frames from which to plot cell outlines.
        style           % String with the selected plotting style.
        styleAlts       % Available plotting styles.
        coloring        % String with the selected cell coloring alternative.
        coloringAlts    % Different ways to color the cells.
        tree            % String with the selected lineage tree option.
        treeAlts        % Different ways to plot the lineage tree.
        showMicrowell   % Hidden binary option (toggled by ALT+M) for plotting of microwells.
        showBgSub       % Hidden binary option (toggled by ALT+B) for display of background subtracted images.
        
        % Variables connected to segmentation editing.
        
        drawBlob        % The (super-)blob currently drawn on.
        drawMask        % Binary image with the pixels of the segment that is being edited.
        drawValue       % The value to draw on the mask, where 1 = draw and 0 = erase.
        drawDown        % True if the mouse button is held down during editing of segments.
        drawBreak       % Selected option for creation of FP/TP when drawing.
        drawBreakAlts   % Available options for creation of FP/TP when drawing.
        drawMerge       % Selected option for merging of segments when drawing.
        drawMergeAlts   % Available options for merging of segments when drawing.
        drawHole        % Selected option for holes in segments when drawing.
        drawHoleAlts    % Available options for holes in segments when drawing.
        drawBrush       % Selected brush shape for drawing.
        drawBrushAlts   % Available brush shapes for drawing.
        
        % Display tools.
        
        verPopupMenu        % Popup menu for loading of tracking results.
        trajectoryToggle    % Toggle button specifying whether trajectories should be shown.
        trajectoryTextBox   % Text box where tLength is set.
        outlineToggle       % Toggle button specifying whether trajectories should be shown.
        outlineTextBox      % Text box where oLength is set.
        fpToggle            % Toggle button specifying whether false positives should be shown.
        fpColorTextBox      % Text box where the color of false positives is specified as an RGB triplet.
        cellEventsToggle    % Toggle button specifying whether events such as mitosis and apoptosis should be shown.
        currentLineToggle   % Toggle button specifying if the current frame should be marked by a line in the lineage tree.
        
        % Buttons for coloring tools.
        
        colorButton         % Lets the user color single cells by clicking on them.
        colorTextBox        % Text box with an RGB triplet specifying the color for coloring of single cells.
        colorAllButton      % Colors all cells in one color.
        colorAllTextBox     % Text box with an RGB triplet specifying the color for coloring of all cells.
        
        % Toggle buttons for tools.
        
        connectButton           % Modifies links in tracks.
        disappearButton         % Toggles the fate of cells between apoptosis and migration out of the image.
        addButton               % Adds a new cell in a single image by clicking.
        continuousAddButton     % Adds a cell track without outlines by clicking once in each image.
        splitButton             % Duplicates a track.
        trackSplitButton        % Duplicates the end of a track and links it to the selected track.
        childButton             % Specifies child cells for a parent cell.
        childSplitButton        % Splits a child cell when specifying children with the childButton.
        moveMitosisButton       % Changes the time point when a mitotic event occurs.
        deleteButton            % Deletes an entire track (right-click) or the beginning of a track (left-click).
        editSegmentsButton      % Selects the tool for editing of cell outlines.
        moveButton              % Moves a cell in a single image.
        removeFpButton          % Removes false positives without segments.
        jumpButton              % Skips to the next time point where any track starts or ends.
        saveButton              % Saves the corrected tracking results.
        continuousDrawButton    % Adds a cell track with outlines by drawing in each image.
        
        % Visualization tool toggle buttons.
        selectButton    % Shows a selected track in orange and the other tracks in blue.
        zoomButton      % Selects the zoom tool (not the MATLAB built in tool).
        
        % Category buttons which show or hide groups of tools.
        
        displayToolsButton          % Shows/hides display tools.
        coloringToolsButton         % Shows/hides coloring tools.
        correctionToolsButton       % Shows/hides correction tools.
        visualizationToolsButton    % Shows/hides visualization tools.
        
        % Arrays of objects with information about groups of buttons.
        
        pushButtons         % Information about all pushbuttons.
        toolButtons         % Information about all tool buttons which are not push buttons.
        toggleButtons       % Information about all toggle buttons which are not tool buttons.
        
        % For calculating positions of uicontrols.
        
        controlPositions    % Struct with relative control positions given in the format [left margin, top margin, width, height].
        controlOrder        % Cell array defining the order in which controls will be added to the panel.
        
        currentCursor       % String indicating the cursor state
    end
    
    properties (Dependent = true)
        % These properties are dependent, because they would make the
        % callbacks of the player object very slow in MATLAB 2015b if they
        % were normal properties. It seems like MATLAB 2015b has to go
        % through all of the properties to find the callbacks. The time
        % required to execute the callbacks depends on the number of cells
        % and blobs stored in the properties. The time spent is not
        % recorded by the profiler. I found a workaround to this issue by
        % storing the data in persistent variables of the functions
        % BlobStorage and CellStorage. The data is accessed by the get- and
        % set- functions associated with these properties.
        
        cells       % Array of Cell objects in the current image sequence.
        blobSeq     % Cell array with all segmented Blob objects (super-blobs).
    end
    
    methods
        function this = ManualCorrectionPlayer(aSeqPaths)
            % Creates a new manual correction figure.
            %
            % Inputs:
            % aSeqPath - Cell array with the full paths of image sequences
            %            that will be available for correction. The first
            %            sequence in the array will be displayed when the
            %            figure is first created.
            
            this = this@ZControlPlayer(aSeqPaths,...
                'Draw', false,...
                'ControlWidth', 0.1);
            
            this.SetCursor('arrow')
            this.currentCursor = 'arrow';
            
            % Initialize variables.
            this.edited = false;
            this.prefVer = '***SELECT_A_TRACKING***';
            this.fromCell = [];
            
            % Default display options.
            this.style = 'Default';
            this.tree = 'Frames';
            this.coloring = 'Rainbow';
            this.showMicrowell = false;
            this.showBgSub = false;
            this.tLength = 3;
            this.oLength = 1;
            
            % Variables connected to segmentation editing.
            this.drawBlob = [];
            this.drawMask = zeros(...
                this.GetImData().imageHeight, this.GetImData().imageWidth);
            this.drawValue = 1;
            this.drawDown = false;
            this.drawBreak = 'Create FP (CTRL+F)';
            this.drawMerge = 'Re-break (CRTL+R)';
            this.drawHole = 'Fill Holes (CRTL+I)';
            this.drawBrush = 'Disk (CTRL+D)';
            
            % Create the brush for segmentation editing.
            if this.GetImData().GetDim() == 2
                this.brush = Brush(5, 0, 0,...
                    this.GetImData().imageHeight, this.GetImData().imageWidth);
            else
                switch this.drawBrush
                    case 'Disk (CTRL+D)'
                        this.brush = Brush3D(5, 0, 0, 0, 'xy', 'disk',...
                            this.GetImData().imageHeight,...
                            this.GetImData().imageWidth,...
                            this.GetImData().numZ,...
                            this.GetImData().voxelHeight);
                    case 'Ball (CTRL+B)'
                        this.brush = Brush3D(5, 0, 0, 0, 'xy', 'ball',...
                            this.GetImData().imageHeight,...
                            this.GetImData().imageWidth,...
                            this.GetImData().numZ,...
                            this.GetImData().voxelHeight);
                end
            end
            this.prevBrush = [];
            
            % Add a dialog about saving changes to the callbacks of
            % existing control objects that would otherwise discard the
            % changes. The existing callbacks can not be gotten and set in
            % the same expression, because that results in an infinite
            % recursion.
            seqPopupMenu_callback = get(this.seqPopupMenu, 'Callback');
            previousButton_callback = get(this.previousButton, 'Callback');
            nextButton_callback = get(this.nextButton, 'Callback');
            set(this.seqPopupMenu,...
                'Callback', {@this.PromptSaveCallback, seqPopupMenu_callback})
            set(this.previousButton,...
                'Callback', {@this.PromptSaveCallback, previousButton_callback})
            set(this.nextButton,...
                'Callback', {@this.PromptSaveCallback, nextButton_callback})
            
            % Make modifications to the figure created by SequencePlayer.
            % Callbacks are added, and the renderer is set to zbuffer, as
            % the default renderer distorts the gray scale of the images
            % for sequences with a lot of cells.
            set(this.mainFigure,...
                'Renderer',                 'zbuffer',...
                'WindowButtonDownFcn',      @this.WindowButtonDownFcn,...
                'WindowButtonUpFcn',        @this.WindowButtonUpFcn,...
                'WindowButtonMotionFcn',    @this.WindowButtonMotionFcn,...
                'WindowScrollWheelFcn',     @this.WindowScrollWheelFcn,...
                'CloseRequestFcn',          @this.CloseRequestFcn,...
                'DeleteFcn',                @this.DeleteFcn,...
                'ResizeFcn',                @this.ResizeButtons)
            
            this.treeAxes = axes(...
                'Parent', this.mainFigure,...
                'Position', [0.05 0.07 0.174 0.925],...
                'Visible', 'off');
            
            this.treeFigure = [];
            
            this.CreateMenus()
            
            % The order in which controls will be added to the panel.
            % Objects in the same cell will be added on the same line.
            this.controlOrder = this.ControlOrder();
            
            % Relative control positions given in the format
            % [left margin, top margin, width, height].
            
            
            this.controlPositions = this.ControlPositions();
            
            this.CreateControls()
            
            this.UpdateVerPopupMenu()
            
            % This only initializes cells and blobSeq to be empty.
            this.LoadCells()
            
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
            set(this.trajectoryTextBox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.fpColorTextBox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.colorTextBox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.colorAllTextBox,...
                'KeyPressFcn', @(aObj, aEvent) disp([]),...
                'KeyReleaseFcn', @(aObj, aEvent) disp([]))
            set(this.outlineTextBox,...
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
            
            % Give all components of the figure appropriate sizes and draw
            % everything.
            this.PositionTools()
            % By default, hide some tools.
            this.Callback_CategoryToggle(this.coloringToolsButton)
            this.Callback_CategoryToggle(this.visualizationToolsButton)
            this.ReSizeControls()
            this.ReSizeAxes()
            this.ResizeButtons()
            this.Draw()
            this.DrawTree()
            this.WindowButtonMotionFcn([], [])
        end
        
        function oBlobSeq = get.blobSeq(this)
            oBlobSeq = BlobStorage(this.mainFigure);
        end
        
        function set.blobSeq(this, aBlobSeq)
            BlobStorage(this.mainFigure, aBlobSeq)
        end
        
        function oCells = get.cells(this)
            oCells = CellStorage(this.mainFigure);
        end
        
        function set.cells(this, aCells)
            CellStorage(this.mainFigure, aCells)
        end
        
        function AddUpdate(this, aCell, varargin)
            % Specifies that the outlines of a cell need to be updated.
            %
            % The segmentations need to be updated when the number of cells
            % in a region change or when the a region has been edited
            % manually. The outlines are not updated until the cells need
            % to be plotted or saved. The function takes one Cell object as
            % input, but all other Cell objects which are in the same
            % super-blobs will also be updated. When the outlines are
            % updated, clusters of cells are separated using k-means
            % clustering.
            %
            % Inputs:
            % aCell - Cell for which the segmentation needs to be updated.
            %
            % Property/Value inputs:
            % Frames - The frames in which the segmentation of the Cell
            %          needs to be updated. The default is to update the
            %          segmentation in all frames in which the Cell is
            %          present.
            %
            % See also:
            % UpdateAllSegmenting
            
            aFrames = GetArgs(...
                {'Frames'},...
                {aCell.firstFrame:aCell.lastFrame},...
                true, varargin);
            
            for i = 1:length(aFrames)
                t = aFrames(i);
                this.update{t}(aCell.blob(t-aCell.firstFrame+1).super.index) = true;
            end
        end
        
        function Callback_CategoryToggle(this, aObj, ~)
            % Callback which shows/hides categories of buttons/tools.
            %
            % The function sets the sizes of tools that should be hidden
            % very close to 0, and the sizes of tools that should be shown
            % to their normal values. Then PositionToolbar is called to
            % re-draw the controls.
            %
            % Inputs:
            % aObj - The toggle button which triggered the callback.
            % aEvent - Unused.
            %
            % See also:
            % PositionToolbar
            
            % Remove focus from the control.
            set(aObj, 'Enable', 'off')
            drawnow()
            set(aObj, 'Enable', 'on')
            
            % Choose which tools to resize based on which toggle button was
            % pressed.
            switch aObj
                case this.correctionToolsButton
                    tools = {
                        'connectButton'
                        'disappearButton'
                        'addButton'
                        'continuousAddButton'
                        'splitButton'
                        'trackSplitButton'
                        'childButton'
                        'childSplitButton'
                        'moveMitosisButton'
                        'deleteButton'
                        'editSegmentsButton'
                        'moveButton'
                        'removeFpButton'
                        'jumpButton'
                        'saveButton'
                        'continuousDrawButton'};
                case this.coloringToolsButton
                    tools = {...
                        'colorButton'
                        'colorTextBox'
                        'colorAllButton'
                        'colorAllTextBox'};
                case this.displayToolsButton
                    tools = {...
                        'trajectoryToggle'
                        'trajectoryTextBox'
                        'outlineToggle'
                        'outlineTextBox'
                        'fpToggle'
                        'fpColorTextBox'
                        'cellEventsToggle'
                        'currentLineToggle'};
                case this.visualizationToolsButton
                    tools = {'selectButton' 'zoomButton'};
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
        
        function Callback_ColorAllButton(this, ~, ~)
            % Colors all cells in the same color.
            %
            % The function colors all cells in the color specified in the
            % text box next to the button, but first asks users if they are
            % sure that they want to color all cells in the specified
            % color.
            
            % Remove focus from the control.
            set(this.colorAllButton, 'Enable', 'off')
            drawnow()
            set(this.colorAllButton, 'Enable', 'on')
            
            % Ask users if they really want to color all cells.
            answer = questdlg(...
                'Are you sure you want to change the color of all cells?',...
                'Color All Cells',...
                'Yes', 'Cancel', 'Yes');
            if isempty(answer)
                % The user closed the dialog.
                answer = 'Cancel';
            end
            
            if strcmp(answer, 'Yes')
                color = str2num(get(this.colorAllTextBox, 'String')); %#ok<ST2NM>
                areCells = AreCells(this.cells);
                for i = 1:length(areCells)
                    areCells(i).color = color;
                    areCells(i).coloring = 'manual';
                end
                
                % Ensures that the colors are not reverted if the user
                % deselects the selection tool.
                for i = 1:length(this.cellColors)
                    this.cellColors{i} = color;
                end
                
                this.edited = true;
                
                this.Draw()
                this.DrawTree()
            end
        end
        
        function Callback_ColorAllTextBox(this, aObj, ~)
            % Sets the color for the tool that colors all cells.
            %
            % The input text in the text box has to be a 3 element vector
            % with values between 0 and 1, otherwise the color is set to
            % '0 1 0'.
            %
            % Inputs:
            % aObj - Text box.
            % aEvent - Unused.
            %
            % See also:
            % Callback_ColorTextBox
            
            num = str2num(get(aObj, 'String')); %#ok<ST2NM>
            if length(num) == 3 && all(num >= 0) && all(num <= 1)
                this.Draw()
            else
                set(aObj, 'String', '0 1 0')
            end
        end
        
        function Callback_ColorTextBox(this, aObj, ~)
            % Sets the color for the single cell coloring tool.
            %
            % The input text in the text box has to be a 3 element vector
            % with values between 0 and 1, otherwise the color is set to
            % '1 0 0'.
            %
            % Inputs:
            % aObj - Text box.
            % aEvent - Unused.
            %
            % See also:
            % Callback_ColorAllTextBox
            
            num = str2num(get(aObj, 'String')); %#ok<ST2NM>
            if length(num) == 3 && all(num >= 0) && all(num <= 1)
                this.Draw()
            else
                set(aObj, 'String', '1 0 0')
            end
        end
        
        function Callback_FPColorTextBox(this, aObj, ~)
            % Sets the color that false positive cells are drawn in.
            %
            % The input text in the text box has to be a 3 element vector
            % with values between 0 and 1, otherwise the color is set to
            % '1 1 1'.
            %
            % Inputs:
            % aObj - Text box.
            % aEvent - Unused.
            
            num = str2num(get(aObj, 'String')); %#ok<ST2NM>
            if length(num) ~= 3 || any(num < 0) || any(num > 1)
                set(aObj, 'String', '1 1 1')
            end
            this.Draw()
        end
        
        function Callback_JumpButton(this, ~, ~)
            % Jumps to the next frame where any cell track starts or ends.
            
            % Remove focus from the control.
            set(this.jumpButton, 'Enable', 'off')
            drawnow()
            set(this.jumpButton, 'Enable', 'on')
            
            areCells = AreCells(this.cells);
            firstFrames = [areCells.firstFrame];
            lastFrames = [areCells.lastFrame];
            candidates = sort([firstFrames lastFrames+1]);
            jumpIndex = find(candidates > this.frame &...
                candidates <= this.GetNumImages(), 1, 'first');
            
            if ~isempty(jumpIndex)
                this.frame = candidates(jumpIndex);
            end
            this.Draw()
        end
        
        function Callback_OutlineTextBox(this, aObj, ~)
            % Selects how many outlines should be drawn for each cell.
            %
            % This function checks that the user has specified a valid
            % number of outlines in outlineTextBox. If the specified value
            % is not a non-negative integer (or inf), the content of the
            % text box is changed back to the previous value.
            %
            % Inputs:
            % aObj - Text box.
            % aEvent - Unused.
            %
            % See also:
            % Callback_TrajectoryTextBox
            
            s = get(aObj, 'String');
            num = str2double(s);
            if num >= 0 && num == round(num)
                this.oLength = round(num);
                this.Draw()
            else
                set(aObj, 'String', num2str(this.oLength))
            end
        end
        
        function Callback_RemoveFpButton(this, ~, ~)
            % Removes false positive point cells from the cell vector.
            %
            % The function removes false positive detections, which don't
            % have segments associated with them. Such detections can
            % appear when a cell object is deleted in a super-blob with
            % multiple cells. When a  false positive cell has some blobs
            % with segments and some blobs without segments, the cell can
            % be broken into multiple fragments when the time points
            % without segments are removed.
            
            % Remove focus from the control.
            set(this.removeFpButton, 'Enable', 'off')
            drawnow()
            set(this.removeFpButton, 'Enable', 'on')
            
            this.SetCursor('watch')
            drawnow()
            
            % Update the segmentation first, so that segments are
            % transferred to real cells whenever possible.
            this.UpdateAllSegmenting(this.GetNumImages())
            
            areCells = AreCells(this.cells);
            notCells = NotCells(this.cells);
            
            % Break the false positive cells into fragments with segments
            % and fragments without segments.
            [pointCells, segmentCells] = PointSegmentCells(notCells,...
                'EndWithDeath', true);
            
            % Remove super-blobs for which the removed point-blobs are the
            % only sub-blobs.
            removeIndices = cell(size(this.blobSeq));
            for i = 1:length(pointCells)
                c = pointCells(i);
                for t = c.firstFrame:c.lastFrame
                    sb = c.blob(t-c.firstFrame+1).super;
                    if any(isnan(sb.boundingBox))
                        removeIndices{t} = [removeIndices{t} sb.index];
                    end
                end
            end
            for t = 1:length(this.blobSeq)
                if ~isempty(removeIndices{t})
                    this.blobSeq{t}(removeIndices{t}) = [];
                    this.update{t} = false(size(this.blobSeq{t}));
                end
            end
            IndexBlobs(this.blobSeq)
            
            this.cells = [areCells segmentCells];
            
            this.Draw()
            this.SetCursor(this.currentCursor)
        end
        
        function Callback_SaveButton(this, ~, ~, varargin)
            % Opens a dialog for saving of the edited cells.
            %
            % The dialog asks the user for a name for the new tracking
            % version. The names of all preexisting tracking versions
            % appear in a list-box, and the user can click on the names to
            % copy them to the text box for the name of the new version.
            % 'CellData' should not be prepended to the name. It can take
            % some time to save the cells, because the segmentation needs
            % to be updated in all frames of the sequence. Saving the Cell
            % objects also takes some time. The function has nested
            % callbacks for the uicontrols in the dialog.
            %
            % Property/Value inputs:
            % AfterFunction - Function handle of a function which should be
            %                 executed after the saving has been performed.
            %                 This is used when the user is prompted to
            %                 save changes before some other operation
            %                 (AfterFunction) is performed.
            
            % Remove focus from the control.
            set(this.saveButton, 'Enable', 'off')
            drawnow()
            set(this.saveButton, 'Enable', 'on')
            
            aAfterFunction = GetArgs({'AfterFunction'}, {@()disp([])}, true, varargin);
            
            % If a save dialog is already open, that dialog is closed.
            if ~isempty(this.saveFigure)
                DeleteSaveFigure()
            end
            
            % Figure for the save dialog.
            this.saveFigure = figure(...
                'Name', 'Save tracking',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'Units', 'pixels',...
                'Position', [200 200 400 500],...
                'Resize', 'off',...
                'CloseRequestFcn', @DeleteSaveFigure);
            
            % Settings objects used to create uicontrols in the dialog.
            info.Existing_versions = Setting(...
                'name', 'Existing versions',...
                'type', 'list',...
                'default', {},...
                'alternatives_basic', GetVersions(this.GetSeqPath()),...
                'tooltip', 'Click on an existing version to select that name.',...
                'callbackfunction', @ExistingVersionCallback);
            info.Version_to_save = Setting(...
                'name', 'Version to save',...
                'type', 'char',...
                'default', '',...
                'tooltip', 'Name of the tracking version which will be saved.');
            
            % Create a SettingsPanel with uicontrols.
            sPanel = SettingsPanel(info,...
                'Parent', this.saveFigure,...
                'Position', [0 0.35 1 0.65],...
                'Split', 0.25,...
                'MinList', 10);
            
            % Create a text box where the user can write notes.
            uicontrol(...
                'Parent', this.saveFigure,...
                'HorizontalAlignment', 'left',...
                'Style', 'text',...
                'Units', 'normalized',...
                'Position', [0 0.3 1 0.05],...
                'String', 'Notes',...
                'Tooltip', 'Notes saved in the log-files of the tracking results.');
            noteTextbox = uicontrol(...
                'Parent', this.saveFigure,...
                'BackgroundColor', 'white',...
                'HorizontalAlignment', 'left',...
                'Style', 'edit',...
                'Min', 0,...
                'Max', 2,...  % Multiple lines.
                'Units', 'normalized',...
                'Position', [0 0.1 1 0.2],...
                'String', '',...
                'Tooltip', 'Notes saved in the log-files of the tracking results.');
            
            uicontrol(...
                'Parent', this.saveFigure,...
                'Style', 'pushbutton',...
                'Units', 'normalized',...
                'Position', [0 0 1 0.1],...
                'String', 'Save',...
                'Tooltip', 'Save the corrected tracks.',...
                'Callback', @SaveFigureCallback);
            
            function ExistingVersionCallback(~, ~)
                % Copies a version name from the list box to the text box.
                %
                % The suffix '_corr' is added to the selected version name
                % to show that the results have been corrected, and to
                % avoid overwriting the existing results. The function will
                % also enter user notes from the selected version in the
                % textbox for user notes.
                
                selectedVer = sPanel.GetValue('Existing_versions');
                if ~isempty(selectedVer)
                    sPanel.SetValue('Version_to_save',...
                        [selectedVer{1} '_corr'])
                    
                    % Enter user notes in the note textbox.
                    logFile = this.GetImData().GetLogPath(...
                        'Version', selectedVer{1});
                    if exist(logFile, 'file')
                        note = ReadLogNote(logFile);
                        note = FileStrToEditStr(note);
                    else
                        note = '';
                    end
                    set(noteTextbox, 'String', note)
                end
            end
            
            function SaveFigureCallback(~, ~)
                % Saves the edited cells when the user presses 'Save'.
                
                saveVer = sPanel.GetValue('Version_to_save');
                
                % Check that the entered version label is valid.
                if isempty(saveVer) || ~isvarname(['a' saveVer])
                    errordlg(['The tracking version label must not be '...
                        'empty and must only contain English letters, '...
                        'numbers, and underscores.'],...
                        'Invalid version to save')
                    return
                end
                
                this.SetCursor('watch')
                drawnow()
                
                this.UpdateAllSegmenting(this.GetNumImages())
                
                ComputeRegionPropsCells(this.cells, this.GetImData())
                
                SaveCells(this.cells, this.GetSeqPath(), saveVer)
                
                % Write user specified notes to the log file.
                notes = get(noteTextbox, 'String');
                notes = EditStrToFileStr(notes);
                logPath = this.GetImData().GetLogPath('Version', saveVer);
                WriteLog(logPath, 'ManualCorrectionPlayer', notes)
                
                if strcmp(this.loadedVer, '***NOT_TRACKED***') ||...
                        strcmp(this.loadedVer, '***SELECT_A_TRACKING***')
                    % Switch to the version that was just saved if no
                    % tracked version was displayed. Don't do this if some
                    % other tracked version was displayed, as the user
                    % might be working on correction of a particular
                    % version in all image sequences.
                    this.loadedVer = saveVer;
                    this.prefVer = saveVer;
                end
                
                % Add the saved version to the list of available versions.
                this.UpdateVerPopupMenu();
                
                fprintf('Done saving cells\n')
                DeleteSaveFigure()
                this.edited = false;
                
                this.SetCursor(this.currentCursor)
                
                feval(aAfterFunction)
            end
            
            function DeleteSaveFigure(~, ~)
                % Deletes the save dialog and clears "saveFigure".
                
                delete(this.saveFigure)
                this.saveFigure = [];
            end
        end
        
        function Callback_ToggleButton(this, aObj, aEvent)
            % Toggles the state of a toggle button which is not a tool.
            %
            % The function is normally called as a callback of the toggle
            % button, but it can also be called when when a keyboard
            % shortcut is used. The button image is set to either a
            % "pressed" color image icon or an "unpressed" gray image icon
            % based on its toggle state.
            %
            % Inputs:
            % aObj - Toggle button.
            % aEvent - [] if the function is executed as a callback. If the
            %          function is called from the key press callback (or
            %          some other function), the input should be 'key', to
            %          indicate that the state of the button needs to be
            %          toggled.
            %
            % See also:
            % Callback_ToolButton
            
            % Remove focus from the control.
            set(aObj, 'Enable', 'off')
            drawnow()
            set(aObj, 'Enable', 'on')
            
            % Toggles the button 'Value' if called from a key-press. This
            % way a mouse click and a key-press will have the same effect.
            if isequal(aEvent, 'key')
                set(aObj, 'Value', ~get(aObj, 'Value'))
            end
            
            if get(aObj, 'Value')
                this.toggleButtons([this.toggleButtons.uicontrol] == aObj).Select();
                
                % Make the tool button visible if it was activated using a
                % keyboard shortcut.
                if ~get(this.displayToolsButton, 'Value')
                    set(this.displayToolsButton, 'Value', true)
                    this.Callback_CategoryToggle(this.displayToolsButton)
                end
            else
                this.toggleButtons([this.toggleButtons.uicontrol] == aObj).Unselect();
            end
            this.Draw();
        end
        
        function Callback_ToolButton(this, aObj, aEvent)
            % Turns on the correction tool that the user clicked on.
            %
            % The function selects the tool that the user clicked on and
            % un-selects all other tools. The button image is set to either
            % a "pressed" color image icon or an "unpressed" gray image
            % icon based on its toggle state.
            %
            % Most of the tools do not perform any operations until
            % the user clicks on cells. The selection-tool in an exception,
            % as it colors all the cells blue when it is selected and gives
            % the cells their original colors back when the it is
            % un-selected. When the selection-tool is selected or
            % un-selected, the function will therefore call SelectButtonOn
            % or SelectButtonOff respectively. In other cases, this
            % function will only change the states of buttons and possibly
            % also the values of "fromCell" and "zoomCorner".
            %
            % Inputs:
            % aObj - Toggle button of the clicked tool.
            % aEvent - [] if the function is executed as a callback. If the
            %          function is called from the key press callback (or
            %          some other function), the input should be 'key', to
            %          indicate that the state of the button needs to be
            %          toggled.
            %
            % See also:
            % Callback_ToggleButton
            
            % Remove focus from the control.
            set(aObj, 'Enable', 'off')
            drawnow()
            set(aObj, 'Enable', 'on')
            
            % Toggles the button 'Value' if called from a key-press. This
            % way a mouse click and a key-press will have the same effect.
            if isequal(aEvent, 'key')
                set(aObj, 'Value', ~get(aObj, 'Value'))
            end
            
            % If the button was turned on from an off state, then un-select
            % all other buttons and change the icon of the button so that
            % it looks pressed.
            if get(aObj, 'Value')
                % Cells in the previous image that were selected using the
                % previous tool are un-selected when another tool is
                % clicked.
                
                % Remove partial links if the previous and the new tool
                % don't match.
                if ~isempty(this.fromCell)
                    if (aObj == this.childButton || aObj == this.childSplitButton) &&...
                            (any(cellfun(@any, this.update)) &&...
                            find(cellfun(@any, this.update), 1, 'first') <= this.frame)
                        % The user must not select a mitosis tool when the
                        % segmentation is not updated in the current frame,
                        % because then the parent cell could change between
                        % the additions of the first and the second child.
                        % This would have been possible with the continuous
                        % add tool.
                        this.fromCell = [];
                    elseif get(this.childButton, 'Value') &&...
                            aObj ~= this.childButton &&...  % childSplitButton was the previous tool.
                            aObj ~= this.childSplitButton &&...
                            this.fromCell.lastFrame > this.frame-1  % The user has added the first child.
                        % If users have added a first child, they have to
                        % continue adding a second child to keep the
                        % partial link.
                        this.fromCell = [];
                    elseif get(this.childSplitButton, 'Value') &&...
                            aObj ~= this.childSplitButton &&...  % childSplitButton was the previous tool.
                            aObj ~= this.childButton &&...
                            this.fromCell.lastFrame > this.frame-1  % The user has added the first child.
                        % If users have added a first child, they have to
                        % continue adding a second child to keep the
                        % partial link.
                        this.fromCell = [];
                    elseif aObj ~= this.connectButton &&...
                            aObj ~= this.trackSplitButton &&...
                            aObj ~= this.continuousAddButton &&...
                            aObj ~= this.childButton &&...
                            aObj ~= this.childSplitButton &&...
                            aObj ~= this.continuousDrawButton
                        % If the users have not started adding children,
                        % they are allowed to switch between any connection
                        % tools.
                        this.fromCell = [];
                    end
                end
                
                if aObj ~= this.selectButton && get(this.selectButton, 'Value')
                    % Turn the selection tool off.
                    this.SelectButtonOff();
                end
                if aObj ~= this.zoomButton && get(this.zoomButton, 'Value')
                    % Turn the zoom tool off.
                    this.zoomCorner = [];
                end
                
                for i = 1:length(this.toolButtons)
                    if aObj == this.toolButtons(i).uicontrol
                        this.toolButtons(i).Select();
                    else
                        this.toolButtons(i).Unselect();
                    end
                end
                
                if get(this.selectButton, 'Value')
                    % Turn the selection tool on.
                    this.SetCursor('crosshair')
                    this.currentCursor = 'crosshair';
                    this.SelectButtonOn();
                    if ~get(this.visualizationToolsButton, 'Value')
                        set(this.visualizationToolsButton, 'Value', true)
                        this.Callback_CategoryToggle(this.visualizationToolsButton)
                    end
                elseif get(this.zoomButton, 'Value')
                    this.SetCursor('glass')
                    this.currentCursor = 'glass';
                    if ~get(this.visualizationToolsButton, 'Value')
                        set(this.visualizationToolsButton, 'Value', true)
                        this.Callback_CategoryToggle(this.visualizationToolsButton)
                    end
                elseif get(this.colorButton, 'Value')
                    this.SetCursor('crosshair')
                    this.currentCursor = 'crosshair';
                    if ~get(this.coloringToolsButton, 'Value')
                        set(this.coloringToolsButton, 'Value', true)
                        this.Callback_CategoryToggle(this.coloringToolsButton)
                    end
                else
                    this.SetCursor('arrow')
                    this.currentCursor = 'arrow';
                    if ~get(this.correctionToolsButton, 'Value')
                        set(this.correctionToolsButton, 'Value', true)
                        this.Callback_CategoryToggle(this.correctionToolsButton)
                    end
                end
                
                if aObj == this.deleteButton
                    InfoDialog('InfoDeleteButton', 'Delete button',...
                        ['Right click to delete/undelete an entire '...
                        'track and left click to delete/undelete only '...
                        'the present and future time points of the track.'])
                elseif aObj == this.editSegmentsButton
                    InfoDialog('InfoEditSegmentsButton',...
                        'Segmentation editing',...
                        ['Click on the cell that you want to edit and '...
                        'hold down the mouse button while you make the '...
                        'edits. The edits take effect when you release '...
                        'the mouse button. Add pixels with the left '...
                        'mouse button and erase with the right. You '...
                        'can change the size of the brush using the '...
                        'scroll wheel of the mouse, or by pressing the '...
                        '+ and - keys. The Drawing menu has options '...
                        'for segmentation editing.'])
                end
            else
                % The button value is set to 1, so that tool buttons cannot
                % be turned off by pressing them while they are on.
                set(aObj, 'Value', 1)
            end
        end
        
        function Callback_TrajectoryTextBox(this, aObj, ~)
            % Select how many points should be drawn in each trajectory.
            %
            % This function checks that the user has specified a valid
            % number of points in trajectoryTextBox. If the specified value
            % is not a non-negative integer (or inf), the content of the
            % text box is changed back to the previous value.
            %
            % Inputs:
            % aObj - Text box.
            %
            % See also:
            % Callback_OutlineTextBox
            
            num = str2double(get(aObj, 'String'));
            if num >= 0 && num == round(num)
                this.tLength = round(num);
                this.Draw()
            else
                set(aObj, 'String', num2str(this.tLength))
            end
        end
        
        function Callback_VerPopupMenu(this, ~, ~)
            % Loads the tracking version selected in the popup menu.
            
            % Remove focus from the popupmenu so that pressing the uparrow
            % key does not trigger a call to this function later.
            set(this.verPopupMenu, 'Enable', 'off')
            drawnow()
            set(this.verPopupMenu, 'Enable', 'on')
            
            % Ask if the user wants to save, if there is something to save.
            if this.edited
                this.PromptSaveCallback([], [], @this.Callback_VerPopupMenu)
                return
            end
            
            this.SetCursor('watch')
            drawnow()
            
            this.prefVer = this.versions{get(this.verPopupMenu, 'Value')};
            
            % Update the version alternatives in case the previous
            % alternative was '***SELECT_A_TRACKING***'.
            this.UpdateVerPopupMenu()
            
            this.LoadCells()
            this.edited = false;
            
            this.Draw()
            this.DrawTree()
            
            this.SetCursor(this.currentCursor)
        end
        
        function oOrder = ControlOrder(~)
            % Defines the order of tools and other controls.
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
                {'trajectoryToggle' 'trajectoryTextBox'}
                {'outlineToggle' 'outlineTextBox'}
                {'fpToggle', 'fpColorTextBox'}
                {'cellEventsToggle' 'currentLineToggle'}
                {'coloringToolsButton'}
                {'colorButton', 'colorTextBox'}
                {'colorAllButton', 'colorAllTextBox'}
                {'correctionToolsButton'}
                {'connectButton' 'moveButton'}
                {'addButton' 'continuousAddButton'}
                {'splitButton' 'trackSplitButton'}
                {'childButton' 'childSplitButton'}
                {'disappearButton' 'moveMitosisButton'}
                {'deleteButton' 'removeFpButton'}
                {'editSegmentsButton' 'continuousDrawButton'}
                {'jumpButton' 'saveButton'}
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
            % normalized units of the control panel.
            %
            % See also:
            % ControlOrder
            
            oPositions = struct(...
                'verPopupMenu',             [0.1, 0.01, 0.8 0.03],...
                'displayToolsButton',       [0.05, 0.008, 0.9, 0.03],...
                'trajectoryToggle',         [0.2, 0.008, 0.25, 0.045],...
                'trajectoryTextBox',        [0.1, 0.008, 0.25, 0.045],...
                'outlineToggle',            [0.2, 0.008, 0.25, 0.045],...
                'outlineTextBox',           [0.1, 0.008, 0.25, 0.045],...
                'fpToggle',                 [0.2, 0.008, 0.25, 0.045],...
                'fpColorTextBox',           [0.1, 0.008, 0.25, 0.045],...
                'cellEventsToggle',         [0.2, 0.008, 0.25, 0.045],...
                'currentLineToggle',        [0.1, 0.008, 0.25, 0.045],...
                'coloringToolsButton',      [0.05, 0.008, 0.9, 0.03],...
                'colorButton',              [0.2, 0.008, 0.25, 0.045],...
                'colorTextBox',             [0.1, 0.008, 0.25, 0.045],...
                'colorAllButton',           [0.2, 0.008, 0.25, 0.045],...
                'colorAllTextBox',          [0.1, 0.008, 0.25, 0.045],...
                'correctionToolsButton',    [0.05, 0.008, 0.9, 0.03],...
                'connectButton',            [0.2, 0.008, 0.25, 0.045],...
                'moveButton',               [0.1, 0.008, 0.25, 0.045],...
                'disappearButton',          [0.2, 0.008, 0.25, 0.045],...
                'addButton',                [0.2, 0.008, 0.25, 0.045],...
                'continuousAddButton',      [0.1, 0.008, 0.25, 0.045],...
                'splitButton',              [0.2, 0.008, 0.25, 0.045],...
                'trackSplitButton',         [0.1, 0.008, 0.25, 0.045],...
                'childButton',              [0.2, 0.008, 0.25, 0.045],...
                'childSplitButton',         [0.1, 0.008, 0.25, 0.045],...
                'moveMitosisButton',        [0.1, 0.008, 0.25, 0.045],...
                'deleteButton',             [0.2, 0.008, 0.25, 0.045],...
                'removeFpButton',           [0.1, 0.008, 0.25, 0.045],...
                'editSegmentsButton',       [0.2, 0.008, 0.25, 0.045],...
                'continuousDrawButton',     [0.1, 0.008, 0.25, 0.045],...
                'jumpButton',               [0.2, 0.008, 0.25, 0.045],...
                'saveButton',               [0.1, 0.008, 0.25, 0.045],...
                'visualizationToolsButton', [0.05, 0.008, 0.9, 0.03],...
                'selectButton',             [0.2, 0.008, 0.25, 0.045],...
                'zoomButton',               [0.1, 0.008, 0.25, 0.045]);
        end
        
        function CloseRequestFcn(this, ~, ~)
            % Executed when the user tries to close the main figure.
            %
            % The function opens a dialog box asking if changes should
            % be saved, when there are unsaved edits. The function also
            % closes all other figures associated with the
            % ManualCorrectionPlayer.
            
            if this.edited
                this.PromptSaveCallback([], [], @(aObj, aEvent)this.DeleteFigures())
            else
                this.DeleteFigures()
            end
        end
        
        function ColorCells(this)
            % Colors the cells using the selected coloring option.
            
            this.cells = ColorCells(this.cells, 'Coloring', this.coloring);
        end
        
        function CreateControls(this)
            % Generates and groups control objects.
            
            this.verPopupMenu = uicontrol(...
                'Style', 'popupmenu',...
                'TooltipString', 'Load Tracks.',...
                'String', {'***SELECT_A_TRACKING***'},...  % The String property will be replaced by UpdateVerPopupMenu.
                'Value', 1,...
                'BackgroundColor', 'w',...
                'HorizontalAlignment', 'left',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_VerPopupMenu);
            this.displayToolsButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Display Toggles',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_CategoryToggle);
            this.trajectoryToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Trajectories (X)',...
                'Value', 1,...
                'HorizontalAlignment', 'left',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.trajectoryTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'Trajectory Trail Length (Keynums)',...
                'BackgroundColor', [.95 .95 .95]',...
                'HorizontalAlignment', 'center',...
                'String', num2str(this.tLength),...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_TrajectoryTextBox);
            this.outlineToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Outlines (Z)',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.outlineTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'Outline Trail Length',...
                'String', num2str(this.oLength),...
                'BackgroundColor', [.95 .95 .95],...
                'HorizontalAlignment', 'center',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_OutlineTextBox);
            this.fpToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide False Positives (F)',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.fpColorTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'False Positive RGB Color, e.g. 1 0 0',...
                'String', '1 1 1',...
                'BackgroundColor', [.95 .95 .95],...
                'HorizontalAlignment', 'center',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_FPColorTextBox);
            this.cellEventsToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Mitosis and Death Events (CTRL+E)',...
                'Value', true,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.currentLineToggle = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Current Frame Line (CTRL+L)',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToggleButton);
            this.coloringToolsButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Coloring Tools',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_CategoryToggle);
            this.colorButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Change Color of Cell (CTRL+C)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.colorTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'RGB Value for Cell Color, e.g. 1 0 0',...
                'String', '1 0 0',...
                'BackgroundColor', [.95 .95 .95],...
                'HorizontalAlignment', 'center',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ColorTextBox);
            this.colorAllButton = uicontrol(...
                'Style', 'pushbutton',...
                'TooltipString', 'Change Color of All Cells',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ColorAllButton);
            this.colorAllTextBox = uicontrol(...
                'Style', 'edit',...
                'TooltipString', 'RGB Value for Cell Colors, e.g. 1 0 0',...
                'String', '0 1 0',...
                'BackgroundColor', [.95 .95 .95],...
                'HorizontalAlignment', 'center',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ColorAllTextBox);
            this.correctionToolsButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Correction Tools',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_CategoryToggle);
            this.connectButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Track Tool (T)',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.disappearButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Mark cell that leaves the field of view (L)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.addButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Add Point (A)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.continuousAddButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Continuously Add Points (N)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.splitButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Split (S)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.trackSplitButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Track Split (G)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.childButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Set Children (C)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.childSplitButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Set Split Children (Y)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.moveMitosisButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Move Mitosis (Q)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.deleteButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Delete (D)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.editSegmentsButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Edit/Draw Segments (E)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.removeFpButton = uicontrol(...
                'Style', 'pushbutton',...
                'TooltipString', 'Remove False Points (R)',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_RemoveFpButton);
            this.moveButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Single Frame Track Tool (W)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.jumpButton = uicontrol(...
                'Style', 'pushbutton',...
                'TooltipString', 'Jump to Next Cell Event (J)',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_JumpButton);
            this.saveButton = uicontrol(...
                'Style', 'pushbutton',...
                'ToolTipString', 'Save Tracking Version (CTRL+S)',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_SaveButton);
            this.continuousDrawButton = uicontrol(...
                'Style', 'togglebutton',...
                'ToolTipString', 'Continuously draw outlines (CTRL+G)',...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.visualizationToolsButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Show/Hide Visualization Tools',...
                'Value', 1,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_CategoryToggle);
            this.selectButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Enable Cell Highlighting Mode (H)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            this.zoomButton = uicontrol(...
                'Style', 'togglebutton',...
                'TooltipString', 'Enable Zooming Mode (V)',...
                'Value', 0,...
                'Parent', this.controlPanel,...
                'Callback', @this.Callback_ToolButton);
            
            % Create ToggleButton objects to keep track of all toggle
            % buttons that are associated with correction and coloring
            % tools. The states of these buttons are dependent, so that
            % only one tool can be selected at a time.
            this.toolButtons = [...
                ToggleButton(this.connectButton,        'connectButton.png',        'connectButtonPressed.png',         [])
                ToggleButton(this.deleteButton,         'deleteButton.png',         'deleteButtonPressed.png',          [])
                ToggleButton(this.editSegmentsButton,   'editSegmentsButton.png',   'editSegmentsButtonPressed.png',    [])
                ToggleButton(this.childButton,          'addChildrenButton.png',    'addChildrenButtonPressed.png',     [])
                ToggleButton(this.childSplitButton,     'childSplitButton.png',     'childSplitButtonPressed.png',      [])
                ToggleButton(this.addButton,            'addButton.png',            'addButtonPressed.png',             [])
                ToggleButton(this.disappearButton,      'disappearButton.png',      'disappearButtonPressed.png',       [])
                ToggleButton(this.splitButton,          'splitButton.png',          'splitButtonPressed.png',           [])
                ToggleButton(this.moveMitosisButton,    'moveMitosisButton.png',    'moveMitosisButtonPressed.png',     [])
                ToggleButton(this.continuousAddButton,  'continuousAddButton.png',  'continuousAddButtonPressed.png',   [])
                ToggleButton(this.trackSplitButton,     'trackSplitButton.png',     'trackSplitButtonPressed.png',      [])
                ToggleButton(this.moveButton,           'moveButton.png',           'moveButtonPressed.png',            [])
                ToggleButton(this.colorButton,          'colorButton.png',          'colorButtonPressed.png',           this.colorTextBox)
                ToggleButton(this.selectButton,         'selectButton.png',         'selectButtonPressed.png',          [])
                ToggleButton(this.zoomButton,           'zoomButton.png',           'zoomButtonPressed.png',            [])
                ToggleButton(this.continuousDrawButton, 'ctcButton.png',            'ctcButtonPressed.png',             [])];
            
            % Create ToggleButton objects to keep track of all toggle
            % buttons. The states of these buttons are independent, so that
            % multiple buttons can be selected at once.
            this.toggleButtons = [...
                ToggleButton(this.trajectoryToggle,         'trajectoryButton.png',     'trajectoryButtonPressed.png',  this.trajectoryTextBox)
                ToggleButton(this.outlineToggle,            'outlineButton.png',        'outlineButtonPressed.png',     this.outlineTextBox)
                ToggleButton(this.fpToggle,                 'FPButton.png',             'FPButtonPressed.png',          this.fpColorTextBox)
                ToggleButton(this.currentLineToggle,        'currentLine.png',          'currentLinePressed.png',       [])
                ToggleButton(this.cellEventsToggle,         'cellEventsButton.png',     'cellEventsButtonPressed.png',  [])
                ToggleButton(this.displayToolsButton,       'displayTogglesOff.png',    'displayTogglesOn.png',         [])
                ToggleButton(this.coloringToolsButton,      'coloringToolsOff.png',     'coloringToolsOn.png',          [])
                ToggleButton(this.correctionToolsButton,    'correctionToolsOff.png',   'correctionToolsOn.png',        [])
                ToggleButton(this.visualizationToolsButton, 'visualizationOff.png',     'visualizationOn.png',          [])];
            
            % Create PushButton objects to keep track of tools which
            % perform an action whenever the button is pressed. The buttons
            % cannot be selected or deselected and only have one image
            % associated with them.
            this.pushButtons = [...
                PushButton(this.colorAllButton, 'colorAllButton.png')
                PushButton(this.removeFpButton, 'removeFP.png')
                PushButton(this.jumpButton, 'jump.png')
                PushButton(this.saveButton, 'save.png')];
        end
        
        function CreateMenus(this)
            % Creates the dropdown menus at the top of the figure.
            
            % User menu options.
            this.styleAlts = {'ISBI'; 'Default'; 'Save'};
            this.coloringAlts = {'Rainbow'; 'Random Hues'; 'Random Colors'};
            this.treeAlts = {
                'Frames'
                'Hours'
                'Frames (Separate Window)'
                'Hours (Separate Window)'
                'None'};
            this.drawBreakAlts = {'Create TP (CTRL+T)'; 'Create FP (CTRL+F)'};
            this.drawMergeAlts = {
                'Re-break (CRTL+R)'
                'Combine (CRTL+M)'
                'Overwrite (CTRL+O)'};
            this.drawHoleAlts = {'Allow Holes (CTRL+A)'; 'Fill Holes (CRTL+I)'};
            this.drawBrushAlts = {'Disk (CTRL+D)'; 'Ball (CTRL+B)'};
            
            % Create menus for style, coloring, and lineage tree options.
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
            this.treeMenu = uimenu(this.mainFigure, 'Label', 'Tree');
            for i = 1:length(this.treeAlts)
                m = uimenu(this.treeMenu,...
                    'Label', this.treeAlts{i},...
                    'Callback', @this.MenuCallback_TreeChange);
                if strcmp(this.treeAlts{i}, this.tree)
                    set(m, 'Checked', 'on')
                end
                if strcmp(this.treeAlts{i}, 'None')
                    set(m, 'Separator', 'on')
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
            if this.GetImData().GetDim() == 2
                % Hide the brush shape option for 2D data.
                set(drawBrushMenu, 'visible', 'off')
            end
        end
        
        function CreateTreeFigure(this)
            % Creates a separate figure for the lineage tree.
            %
            % The function also removes the tree axes from the main figure
            % and creates a new tree axes in the separate figure. If there
            % is already a separate figure for the lineage tree, the
            % function does not do anything.
            
            if isempty(this.treeFigure)
                this.treeFigure = figure(...
                    'NumberTitle', 'off',...
                    'Name', 'Lineage tree',...
                    'Units', 'normalized',...
                    'Position', [0.01 0.3 0.4 0.6],...
                    'Renderer', 'zbuffer',...
                    'WindowButtonDownFcn', @this.WindowButtonDownFcn,...
                    'WindowButtonUpFcn', @this.WindowButtonUpFcn,...
                    'WindowButtonMotionFcn', @this.WindowButtonMotionFcn,...
                    'CloseRequestFcn', @this.TreeCloseRequestFcn);
                setptr(this.treeFigure, this.currentCursor)
                delete(this.treeAxes);
                this.treeAxes = axes('Parent', this.treeFigure);
            end
        end
        
        function DeleteFcn(this, ~, ~)
            % Cleans up persistent variables associated with the figure.
            %
            % The values for the properties cells and blobSeq are stored in
            % persistent variables in the functions BlobStorage and
            % CellStorage. These persistent variables need to be cleaned up
            % when the player is closed, to free the memory.
            
            this.cells = [];
            this.blobSeq = [];
        end
        
        function DeleteFigures(this)
            % Closes the tree figure and the save dialog if they exist.
            
            if ~isempty(this.saveFigure)
                % Delete figure with save dialog if there is one.
                delete(this.saveFigure)
            end
            if ~isempty(this.treeFigure)
                % Delete figure with lineage tree if there is one.
                delete(this.treeFigure)
            end
            delete(this.mainFigure)
        end
        
        function Draw(this, varargin)
            % Draws images and tracks and outlines on top of them.
            %
            % The function will update the outlines of all cells up to the
            % displayed frame and then draw the tracks and the outlines of
            % the cells on top of the image. If 3D data is displayed, the
            % tracks and the outlines will be displayed on top of all 3D
            % views that are shown. The actual drawing is done by Draw3D,
            % which in turn calls DrawXY, DrawXZ and DrawYZ. The lineage
            % tree is drawn by DrawTree, which needs to be called
            % separately. The line in the lineage tree showing the current
            % time point is however drawn from this function. Dynamic
            % graphics objects that are connected to editing of tracks and
            % editing of segments, are drawn by
            % WindowButtonMotionFcn_Tracks and
            % WindowButtonMotionFcn_Segments respectively.
            %
            % Property/Value inputs:
            % EditedCells - A vector of cells which need to be re-drawn. If
            %               this input is specified, only the specified
            %               cells and cells which are modified by
            %               segmentation updates will be re-drawn. Other
            %               cells and the images will not be re-drawn. This
            %               normally speeds up the drawing significantly
            %               when there are a lot of cells.
            %
            % See also:
            % Draw3D, DrawXY, DrawXZ, DrawYZ, DrawTree,
            % WindowButtonMotionFcn_Tracks, WindowButtonMotionFcn_Segments
            
            if ~this.play
                this.SetCursor('watch')
            end
            
            % Remove partial links if the linking cannot be finalized in
            % the current frame.
            if ~isempty(this.fromCell)
                if get(this.moveButton, 'Value')
                    if this.fromCell.firstFrame > this.frame ||...
                            this.fromCell.lastFrame < this.frame
                        % The cell to be moved is not present
                        this.fromCell = [];
                    end
                elseif get(this.connectButton, 'Value') ||...
                        get(this.continuousAddButton, 'Value') ||...
                        get(this.trackSplitButton, 'Value') ||...
                        get(this.continuousDrawButton, 'Value')
                    if this.fromCell.lastFrame ~= this.frame - 1
                        % The frame has been changed.
                        this.fromCell = [];
                    end
                elseif get(this.childButton, 'Value') ||...
                        get(this.childSplitButton, 'Value')
                    if this.fromCell.firstFrame > this.frame - 1 ||...
                            this.fromCell.lastFrame < this.frame - 1
                        % The parent is not present in the previous image.
                        this.fromCell = [];
                    end
                else
                    % The selected tool should not have a partial link.
                    error('The variable fromCell should have been [].')
                end
            end
            
            aEditedCells = GetArgs({'EditedCells'}, {0}, true, varargin);
            
            if ~get(this.continuousAddButton, 'Value') ||...
                    isempty(this.fromCell)
                % The segmentation update could change assignments so that
                % fromCell is extended past the current frame.
                if isequaln(aEditedCells, 0)
                    this.UpdateAllSegmenting(this.frame)
                else
                    segEditedCells = this.UpdateAllSegmenting(this.frame);
                    aEditedCells = UniqueCells([aEditedCells segEditedCells]);
                    % Cells that were marked as edited previously may
                    % have been removed by the bipartite matching in
                    % UpdateAllSegmenting.
                    aEditedCells = intersect(this.cells, aEditedCells);
                end
            end
            
            if ~strcmp(this.tree, 'None')
                this.DrawCurrentLine()
            end
            this.Draw3D('EditedCells', aEditedCells)
            
            if ~this.play
                this.SetCursor(this.currentCursor)
            end
        end
        
        function Draw3D(this, varargin)
            % Displays planes and projections of 3D (or 2D) image data.
            %
            % The function calls 3 different function which generate the
            % xy-, xz- and xz-plots in the 3 different axes. Depending on
            % the display option selected, all axes may not be updated
            % and displayed. This function assumes that the Draw function
            % has already been called for the current frame and that the
            % outlines of all cells in the current frame are up to date.
            % The function is normally called from the Draw function or
            % when the 3D view has been changed for 3D data.
            %
            % Property/Value inputs:
            % EditedCells - A vector of cells which need to be re-drawn. If
            %               this input is specified, only the specified
            %               cells will be re-drawn. Other cells and the
            %               images will not be re-drawn. This normally
            %               speeds up the drawing significantly when there
            %               are a lot of cells. This function will remove
            %               the old graphics objects associated with the
            %               specified cells, and the functions DrawXY,
            %               DrawXZ and DrawYZ will create the new graphics
            %               objects.
            %
            % See also:
            % Draw, DrawXY, DrawXZ, DrawYZ
            
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
                
                % Remove edited cells which fall outside the zoomed in
                % volume. Such cells can occur when tracks are split or
                % truncated so that a part of a track which is outside the
                % zoomed in volume becomes its own track.
                if this.IsZoomed() && this.GetImData().GetDim() == 3
                    [x1, x2, y1, y2, z1, z2] = this.GetZoom();
                    % Select cells that touch the zoomed in volume.
                    plotParams.plotCells =...
                        CropCells(plotParams.plotCells,...
                        this.frame-this.tLength+1, this.frame,...
                        x1, x2, y1, y2, z1, z2);
                end
                
                updateGraphics = true;
            end
            
            % Remove old pointers to graphics objects associated with the
            % cells to be plotted. If the existing plots are updated, the
            % objects have been deleted above and otherwise they will be
            % deleted when the axes are cleared in DrawXY, DrawXZ and
            % DrawYZ.
            for i = 1:length(plotParams.plotCells)
                plotParams.plotCells(i).graphics = [];
            end
            
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
        
        function DrawCurrentLine(this)
            % Updates the time line in the lineage tree.
            %
            % The time line is a horizontal line in the lineage tree,
            % showing the current time point.
            
            % Delete the old time line if one exists.
            if ishandle(this.currentLine)
                delete(this.currentLine)
            end
            
            imData = this.GetImData();
            
            % Plot the new time line.
            if get(this.currentLineToggle, 'Value')
                % The line is plotted from the left border of the axes to
                % the right border. The borders are given by the y-limits
                % of the axes as the y-axis points down and the x-axis
                % points to the right.
                ylims = get(this.treeAxes, 'ylim');
                switch this.tree
                    case {'Frames', 'Frames (Separate Window)'}
                        this.currentLine = plot(this.treeAxes,...
                            this.frame*ones(1,2), ylims, 'k', 'LineWidth', 2);
                        xlim(this.treeAxes, imData.GetTLim('frames',...
                            'Margins', [0.01 0.01]))
                    case {'Hours', 'Hours (Separate Window)'}
                        this.currentLine = plot(this.treeAxes,...
                            imData.FrameToT(this.frame*ones(1,2)), ylims,...
                            'k', 'LineWidth', 2);
                        xlim(this.treeAxes, imData.GetTLim('hours',...
                            'Margins', [0.01 0.01]))
                end
                view(this.treeAxes, 90, 90)
            end
        end
        
        function DrawTree(this)
            % Draws the lineage tree.
            %
            % This function also sorts the cells, as the function used to
            % plot the lineage tree requires the input to be sorted. No
            % sorting is done if the coloring is set to 'Rainbow', as the
            % coloring function sorts the cells in that case. The function
            % used to draw the lineage tree is also used to produce plots
            % for analysis and therefore the title needs to be removed.
            % This function also updates the horizontal line showing the
            % current time point in the lineage tree.
            %
            % See also:
            % Draw, DrawCurrentLine
            
            imData = this.GetImData();
            
            if ~strcmp(this.tree, 'None') && ~strcmp(this.coloring, 'Rainbow')
                this.cells = SortCells(this.cells);
            end
            
            switch this.tree
                case {'Frames' 'Frames (Separate Window)'}
                    % Plot a tree where the time scale is in frames.
                    Plot_LineageTree(this.cells, this.treeAxes,...
                        'XUnit', 'frames',...
                        'Vertical', true)
                    xlim(this.treeAxes, imData.GetTLim('frames',...
                        'Margins', [0.01 0.01]))
                    title(this.treeAxes, '')
                case {'Hours' 'Hours (Separate Window)'}
                    % Plot a tree where the time scale is in hours.
                    Plot_LineageTree(this.cells, this.treeAxes,...
                        'XUnit', 'hours',...
                        'Vertical', true)
                    xlim(this.treeAxes, imData.GetTLim('hours',...
                        'Margins', [0.01 0.01]))
                    title(this.treeAxes, '')
                case 'None'
                    cla(this.treeAxes)
            end
            
            this.DrawCurrentLine()
        end
        
        function DrawXY(this, aParams, varargin)
            % Draws 2D data and xy-views of 3D data in the xy-axes.
            %
            % This function displays an xy-view of the data and plots
            % tracks and outlines on top of it. For 2D data, the image
            % itself or a background subtracted image is displayed and for
            % 3D data a maximum intensity projection or a z-slice is
            % displayed. If a maximum intensity projection is displayed,
            % all tracks are shown together with the outlines of all cells
            % seen from above. When a z-slice is displayed, all tracks are
            % displayed, but only crossections of the outlines are shown.
            % If the style 'Iterations' is selected, the function will
            % visualize intermediate tracking results. The function can
            % also draw outlines of circular microwells.
            %
            % Inputs
            % aParams - All parameters used for plotting of the tracks and
            %           the outlines of the cells. The cells to be plotted
            %           are in a field named 'plotCells'.
            %
            % Property/Value inputs:
            % Update - This input is set to true when the existing plot
            %          should be updated. In this case, the tracks of the
            %          cells that need to be updated will be plotted, but
            %          the image and the preexisting tracks will not be
            %          removed. The old graphics objects associated with
            %          the edited cells are removed in Draw3D.
            %
            % See also:
            % Draw, Draw3D, DrawXZ, DrawYZ, PlotTrajectories, PlotOutlines
            
            aUpdate = GetArgs({'Update'}, {false}, true, varargin);
            
            if ~aUpdate
                if this.showBgSub &&...
                        ~strcmp(this.GetImData().Get('SegBgSubAlgorithm'), 'none')
                    % Plot on top of a background subtracted image.
                    im = BgSubDisplay(this.GetImData(), this.frame);
                    cla(this.ax)  % Avoids accumulation.
                    imshow(im, 'Parent', this.ax)
                    colormap(this.ax, gray(256))
                    hold(this.ax, 'on')
                else
                    % Plot on top of a the original image.
                    this.DrawXY@ZControlPlayer(aParams)
                end
            end
            
            if this.GetImData().GetDim() == 2 || aParams.zProj
                plotCells = aParams.plotCells;
            else
                % Select only the cells touching the plane to be plotted.
                [x1, x2, y1, y2] = this.GetZoom();
                plotCells = CropCells(aParams.plotCells,...
                    this.frame-this.tLength+1, this.frame,...
                    x1, x2, y1, y2, this.z, this.z);
            end
            
            % Plot trajectories.
            if get(this.trajectoryToggle, 'Value')
                PlotTrajectories(...
                    this.ax,...
                    plotCells,...
                    this.frame,...
                    this.tLength,...
                    'Options', aParams.trajOpts,...
                    'TrackGraphics', true)
            end
            
            % Plot outlines.
            if get(this.outlineToggle, 'Value')
                PlotOutlines(...
                    this.ax,...
                    plotCells,...
                    this.frame,...
                    this.oLength,...
                    'Options', aParams.outlineOpts,...
                    'MaxProj', this.volumeSettingsPanel.GetValue('z_proj'),...
                    'Slice', this.volumeSettingsPanel.GetValue('z'),...
                    'TrackGraphics', true)
            end
            
            % Visualizes mitotic event, apoptotic events and events where
            % the cells enter or leave the field of view.
            if get(this.cellEventsToggle, 'Value')
                PlotMitosis(...
                    this.ax,...
                    plotCells,...
                    this.frame,...
                    this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'TrackGraphics', true)
                
                PlotApoptosis(this.ax, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'TrackGraphics', true)
                PlotAppearance(this.ax, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'TrackGraphics', true)
                PlotDisappearance(this.ax, plotCells, this.frame, this.tLength,...
                    'TrackGraphics', true)
            end
            
            % Plot the microwell circle.
            if this.showMicrowell
                [circX, circY, circR] = GetWellCircle(this.GetImData());
                if ~any(isnan([circX circY circR] ))
                    rectangle(...
                        'Parent', this.ax,...
                        'Position', [circX-circR circY-circR 2*circR 2*circR],...
                        'Curvature', [1 1],...
                        'LineWidth', 3,...
                        'LineStyle', '--')
                end
            end
            drawnow()
        end
        
        function DrawXZ(this, aParams, varargin)
            % Draws xz-views of 3D data in the xz-axes.
            %
            % This function displays a maximum intensity projection in the
            % xz-plane or a y-slice of a z-stack and plots tracks and
            % outlines on top of it. If a maximum intensity projection is
            % displayed, all tracks are shown together with the outlines of
            % all cells seen from the side. When a y-slice is displayed,
            % all tracks are displayed, but only crossections of the
            % outlines are shown. The styles 'Scores', 'Iterations' and
            % 'Indices' are replaced by the 'Default' style.
            %
            % Inputs
            % aParams - All parameters used for plotting of the tracks and
            %           the outlines of the cells. The cells to be plotted
            %           are in a field named 'plotCells'.
            %
            % Property/Value inputs:
            % Update - This input is set to true when the existing plot
            %          should be updated. In this case, the tracks of the
            %          cells that need to be updated will be plotted, but
            %          the image and the preexisting tracks will not be
            %          removed. The old graphics objects associated with
            %          the edited cells are removed in Draw3D.
            %
            % See also:
            % Draw, Draw3D, DrawXY, DrawYZ, PlotTrajectories, PlotOutlines
            %
            % TODO: Consider the styles 'Scores', 'Iterations' and
            %       'Indices'.
            
            aUpdate = GetArgs({'Update'}, {false}, true, varargin);
            
            if ~aUpdate
                this.DrawXZ@ZControlPlayer(aParams);
            end
            
            if aParams.yProj
                plotCells = aParams.plotCells;
            else
                % Select only the cells touchnig the plane to be plotted.
                [x1, x2, ~, ~, z1, z2] = this.GetZoom();
                plotCells = CropCells(aParams.plotCells,...
                    this.frame-this.tLength+1, this.frame,...
                    x1, x2, this.y, this.y, z1, z2);
            end
            
            % Plot trajectories.
            if get(this.trajectoryToggle, 'Value')
                PlotTrajectories(...
                    this.axXZ,...
                    plotCells,...
                    this.frame,...
                    this.tLength,...
                    'Options', aParams.trajOpts,...
                    'Plane', 'xz',...
                    'TrackGraphics', true)
            end
            
            % Plot outlines.
            if get(this.outlineToggle, 'Value')
                PlotOutlines(...
                    this.axXZ,...
                    plotCells,...
                    this.frame,...
                    this.oLength,...
                    'Options', aParams.outlineOpts,...
                    'Plane', 'xz',...
                    'MaxProj', this.volumeSettingsPanel.GetValue('y_proj'),...
                    'Slice', this.volumeSettingsPanel.GetValue('y'),...
                    'TrackGraphics', true)
            end
            
            % Visualize mitotic event, apoptotic events and events where
            % the cells enter or leave the field of view.
            if get(this.cellEventsToggle, 'Value')
                PlotMitosis(this.axXZ, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'Plane', 'xz',...
                    'TrackGraphics', true)
                PlotApoptosis(this.axXZ, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'Plane', 'xz',...
                    'TrackGraphics', true)
                PlotAppearance(this.axXZ, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'Plane', 'xz',...
                    'TrackGraphics', true)
                PlotDisappearance(this.axXZ, plotCells, this.frame, this.tLength,...
                    'Plane', 'xz',...
                    'TrackGraphics', true)
            end
            drawnow()
        end
        
        function DrawYZ(this, aParams, varargin)
            % Draws yz-views of 3D data in the yz-axes.
            %
            % This function displays a maximum intensity projection in the
            % yz-plane or an x-slice of a z-stack and plots  tracks and
            % outlines on top of it. If a maximum intensity projection is
            % displayed, all tracks are shown together with the outlines of
            % all cells seen from the side. When an x-slice is displayed,
            % all tracks are displayed, but only crossections of the
            % outlines are shown. The styles 'Scores', 'Iterations' and
            % 'Indices' are replaced by the 'Default' style.
            %
            % Inputs
            % aParams - All parameters used for plotting of the tracks and
            %           the outlines of the cells. The cells to be plotted
            %           are in a field named 'plotCells'.
            %
            % Property/Value inputs:
            % Update - This input is set to true when the existing plot
            %          should be updated. In this case, the tracks of the
            %          cells that need to be updated will be plotted, but
            %          the image and the preexisting tracks will not be
            %          removed. The old graphics objects associated with
            %          the edited cells are removed in Draw3D.
            %
            % See also:
            % Draw, Draw3D, DrawXY, DrawXZ, PlotTrajectories, PlotOutlines
            %
            % TODO: Consider the styles 'Scores', 'Iterations' and
            %       'Indices'.
            
            aUpdate = GetArgs({'Update'}, {false}, true, varargin);
            
            if ~aUpdate
                this.DrawYZ@ZControlPlayer(aParams);
            end
            
            if aParams.xProj
                plotCells = aParams.plotCells;
            else
                % Select only the cells touching the plane to be plotted.
                [~, ~, y1, y2, z1, z2] = this.GetZoom();
                plotCells = CropCells(aParams.plotCells,...
                    this.frame-this.tLength+1, this.frame,...
                    this.x, this.x, y1, y2, z1, z2);
            end
            
            % Plot trajectories.
            if get(this.trajectoryToggle, 'Value')
                PlotTrajectories(...
                    this.axYZ,...
                    plotCells,...
                    this.frame,...
                    this.tLength,...
                    'Options', aParams.trajOpts,...
                    'Plane', 'yz',...
                    'TrackGraphics', true)
            end
            
            % Plot outlines.
            if get(this.outlineToggle, 'Value')
                PlotOutlines(this.axYZ, plotCells, this.frame, this.oLength,...
                    'Options', aParams.outlineOpts,...
                    'Plane', 'yz',...
                    'MaxProj', this.volumeSettingsPanel.GetValue('x_proj'),...
                    'Slice', this.volumeSettingsPanel.GetValue('x'),...
                    'TrackGraphics', true)
            end
            
            % Visualize mitotic event, apoptotic events and events where
            % the cells enter or leave the field of view.
            if get(this.cellEventsToggle, 'Value')
                PlotMitosis(this.axYZ, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'Plane', 'yz',...
                    'TrackGraphics', true)
                PlotApoptosis(this.axYZ, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'Plane', 'yz',...
                    'TrackGraphics', true)
                PlotAppearance(this.axYZ, plotCells, this.frame, this.tLength,...
                    'LineWidth', aParams.markerLineWidth,...
                    'Plane', 'yz',...
                    'TrackGraphics', true)
                PlotDisappearance(this.axYZ, plotCells, this.frame, this.tLength,...
                    'Plane', 'yz',...
                    'TrackGraphics', true)
            end
            drawnow()
        end
        
        function EditTracks_AddCell(this, aCreatedCell)
            % Adds a new cell to the set of tracks.
            %
            % The cell will only be present in the current frame.
            %
            % Inputs:
            % aCreatedCell - Cell created from the most recent click.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            this.cells = [this.cells aCreatedCell];
            this.fromCell = [];
            this.AddUpdate(aCreatedCell, 'Frames', this.frame);
            if any(isnan(aCreatedCell.blob(this.frame-aCreatedCell.firstFrame+1).boundingBox))
                this.blobSeq{this.frame} = [this.blobSeq{this.frame}...
                    aCreatedCell.blob(this.frame-aCreatedCell.firstFrame+1).super];
                this.update{this.frame} = [this.update{this.frame} false];
            end
        end
        
        function oEditedCells = EditTracks_AddChild(this, aClosestCell, aClickedFrame)
            % Links two tracks with a mititoc event.
            %
            % The function either picks a parent cell to connect children
            % to or connects children to an already picked parent cell.
            % When the first child cell is added, fromCell is not changed,
            % so that a second child can be added. When the second child
            % has been added, fromCell is emptied, as there is no need to
            % add more cells. To avoid leaving a parent cell with a single
            % child cell, the first child cell is appended to the parent
            % cell using a migration link. When the second child is added,
            % the migration link will be replaced by a parent-child link.
            %
            % Inputs:
            % aClosestCell - Child cell that the user clicked on.
            % aClickedFrame - The frame of the detection that the user
            %                 clicked on.
            %
            % Outputs:
            % oEditedCells - Cells which were affected by the edit, without
            %                requiring an update in the segmentation. These
            %                cells need to be updated by Draw, but may not
            %                be scheduled for re-drawing by
            %                UpdateAllSegmenting.
            %
            % See also:
            % WindowButtonDownFcn_Tracks, EditTracks_Connect
            
            oEditedCells = [];
            if ~isempty(this.fromCell)
                % Add a child to a parent cell that has already been
                % picked.
                
                % Get the child cell.
                if get(this.childSplitButton, 'Value')
                    connectCell = aClosestCell.Clone();
                    if connectCell.firstFrame == this.frame
                        this.cells = [this.cells connectCell];
                    end
                else
                    connectCell = aClosestCell;
                    if connectCell.firstFrame == this.frame
                        if ~isempty(connectCell.parent)
                            oEditedCells = [oEditedCells connectCell.parent];
                            this.cells = connectCell.CutBranch(this.cells);
                        end
                    end
                end
                
                if connectCell.firstFrame < this.frame
                    if ~get(this.childSplitButton, 'Value')
                        % The cell about to be split is in the tree.
                        oEditedCells = [oEditedCells connectCell];
                    end
                    connectCell = connectCell.Split(this.frame);
                end
                
                % Add segmentation updates.
                if get(this.childSplitButton, 'Value') ||...
                        (connectCell.isCell ~= this.fromCell.isCell)
                    this.AddUpdate(connectCell)
                end
                
                if this.fromCell.lastFrame == this.frame-1
                    % The first child is added using a migration link, to
                    % make sure that there are never parent cells with one
                    % child cell.
                    this.fromCell.AddCell(connectCell)
                    this.cells(this.cells == connectCell) = [];
                    oEditedCells = [oEditedCells this.fromCell];
                else
                    % When the second child cell is added, the child
                    % that was previously added using a migration link is
                    % disconnected and both children are added to the
                    % parent cells using mitosis links.
                    child = this.fromCell.Split(this.frame);
                    this.cells = [this.cells child];
                    if ~any(this.cells == connectCell)
                        this.cells = [this.cells connectCell];
                    end
                    this.fromCell.AddChild(child);
                    this.fromCell.AddChild(connectCell);
                    oEditedCells = [oEditedCells this.fromCell child connectCell];
                end
                
                % Stop adding children if two children have been added.
                if this.fromCell.lastFrame == this.frame-1 &&...
                        length(this.fromCell.children) == 2
                    this.fromCell = [];
                end
            else
                if aClickedFrame < this.frame  % Only pick up cells from the previous frame.
                    % Pick a parent cell.
                    if aClosestCell.lastFrame >= this.frame &&...
                            aClosestCell.firstFrame < this.frame
                        newCell = aClosestCell.Split(this.frame);
                        this.cells = [this.cells newCell];
                        oEditedCells = [oEditedCells aClosestCell newCell];
                    elseif ~isempty(aClosestCell.children)
                        oEditedCells = [oEditedCells aClosestCell aClosestCell.children];
                        aClosestCell.RemoveChildren();
                    end
                    this.fromCell = aClosestCell;
                else
                    this.fromCell = [];
                end
            end
        end
        
        %         function EditTracks_AddMitosis(this, aClosestCell)
        %             % Edits tracks by introducing a mitotic event into a track.
        %             %
        %             % All future frames of the track are duplicated to produce the
        %             % second child cell.
        %             %
        %             % Inputs:
        %             % aClosestCell - Cell that the user clicked on.
        %             %
        %             % See also:
        %             % WindowButtonDownFcn_Tracks
        %
        %             parent = aClosestCell;
        %             child1 = parent.Split(this.frame);
        %             child2 = child1.Clone();
        %             parent.AddChild(child1);
        %             parent.AddChild(child2);
        %             this.cells = [this.cells child1 child2];
        %             this.AddUpdate(child2);
        %         end
        
        function oEditedCells = EditTracks_Connect(this,...
                aClosestCell, aCreatedCell, aClickedFrame)
            % Connects cell nodes with migration links.
            %
            % The function selects a track from the previous frame that
            % will be linked to a track in the current frame, or adds such
            % a link to a track in the current frame. Which operation is
            % performed depends on whether or not a track from the previous
            % frame has already been selected. When a track in the previous
            % frame is selected, that track is broken in the previous
            % frame, creating two parts. The first part can be linked to a
            % track in the current frame. This function perform edits done
            % using the Track tool, the Continuous Add tool and the Track
            % Split tool. When a link is created using the Track tool, the
            % track in the current frame is broken in two, and the second
            % part is linked to the selected track. When the link is
            % created using the Continuous Add tool, the selected track is
            % connected to a new cell node which was created where the user
            % clicked, and then the next frame is displayed so that more
            % cell nodes can be created. When the link is created using the
            % Track Split tool, the selected cell is connected to a copy
            % (from the current frame to the end of the track) of the cell
            % that the user clicked on.
            %
            % Inputs:
            % aClosestCell - Cell that the user clicked on.
            % aCreatedCell - Cell created for the Continuous Add tool.
            % aClickedFrame - The frame of the detection that the user
            %                 clicked on.
            %
            % Outputs:
            % oEditedCells - Cells which were affected by the edit, without
            %                requiring an update in the segmentation. These
            %                cells need to be updated by Draw, but may not
            %                be scheduled for re-drawing by
            %                UpdateAllSegmenting.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            oEditedCells = [];
            if ~isempty(this.fromCell)  % Connect previously selected cell.
                this.fromCell.RemoveChildren();
                
                % Determine what track to link to the selected track.
                if get(this.continuousAddButton, 'Value')
                    connectCell = aCreatedCell;
                elseif get(this.trackSplitButton, 'Value')
                    connectCell = aClosestCell.Clone();
                else
                    connectCell = aClosestCell;
                end
                
                % Link the tracks.
                if connectCell.firstFrame == this.frame
                    if ~isempty(connectCell.parent)
                        if get(this.trackSplitButton, 'Value')
                            oEditedCells = [oEditedCells aClosestCell.parent];
                        else
                            oEditedCells = [oEditedCells connectCell.parent];
                        end
                        this.cells = connectCell.CutBranch(this.cells);
                    end
                    this.cells(this.cells == connectCell) = [];
                else
                    if get(this.trackSplitButton, 'Value')
                        oEditedCells = [oEditedCells aClosestCell];
                    else
                        oEditedCells = [oEditedCells connectCell];
                    end
                    connectCell = connectCell.Split(this.frame);
                end
                
                % Add the new blob if a point blob has been created using
                % the Continuous Add tool.
                if get(this.continuousAddButton, 'Value') &&...
                        any(isnan(connectCell.blob(this.frame-connectCell.firstFrame+1).boundingBox))
                    this.blobSeq{this.frame} = [this.blobSeq{this.frame}...
                        connectCell.blob(this.frame-connectCell.firstFrame+1).super];
                    this.update{this.frame} = [this.update{this.frame} false];
                end
                
                % Add segmentation updates.
                if get(this.trackSplitButton, 'Value') ||...
                        get(this.continuousAddButton, 'Value') ||...
                        (connectCell.isCell ~= this.fromCell.isCell)
                    this.AddUpdate(connectCell)
                end
                
                oEditedCells = [oEditedCells this.fromCell];
                this.fromCell.AddCell(connectCell);
                
                this.fromCell.SetNote(1, this.frame)  % Indicate edit.
                
                if get(this.continuousAddButton, 'Value')
                    % Go to the next frame, so that the user can add a
                    % chain of detections without manually switching frame.
                    if this.frame < this.GetNumImages()
                        this.frame = this.frame + 1;
                        % Gives complete drawing of the following frame.
                        oEditedCells = 0;
                    else
                        this.fromCell = [];
                    end
                else
                    this.fromCell = [];
                end
            else
                if get(this.continuousAddButton, 'Value')
                    this.cells = [this.cells aCreatedCell];
                    this.fromCell = aCreatedCell;
                    if any(isnan(aCreatedCell.blob(this.frame-aCreatedCell.firstFrame+1).boundingBox))
                        this.blobSeq{this.frame} = [this.blobSeq{this.frame}...
                            aCreatedCell.blob(this.frame-aCreatedCell.firstFrame+1).super];
                        this.update{this.frame} = [this.update{this.frame} false];
                    end
                    this.AddUpdate(aCreatedCell, 'Frames', this.frame);
                    oEditedCells = [oEditedCells this.fromCell];
                    
                    % Go to the next frame, so that the user can add a
                    % chain of detections without manually switching frame.
                    if this.frame < this.GetNumImages()
                        this.frame = this.frame + 1;
                        % Gives complete drawing of the following frame.
                        oEditedCells = 0;
                    else
                        this.fromCell = [];
                    end
                elseif aClickedFrame < this.frame  % Only pick up cells from the previous frame.
                    % Select a track in the previous frame to be linked.
                    % Break the track if the user clicked in the middle of
                    % the track.
                    if aClosestCell.lastFrame >= this.frame
                        newCell = aClosestCell.Split(this.frame);
                        this.cells = [this.cells newCell];
                        oEditedCells = [oEditedCells aClosestCell newCell];
                    elseif ~isempty(aClosestCell.children)
                        oEditedCells = [oEditedCells aClosestCell aClosestCell.children];
                        aClosestCell.RemoveChildren();
                    end
                    this.fromCell = aClosestCell;
                else
                    this.fromCell = [];
                end
            end
        end
        
        function oEditedCells = EditTracks_DeleteCell(this,...
                aClosestCell, aWholeCell, aClickedFrame)
            % Deletes a cell track or a part of a cell track.
            %
            % The deleted cell and all of its progeny are turned into false
            % positive tracks that can be converted back to real cells by
            % applying EditTracks_DeleteCell to them a second time. If the
            % user right-clicks, the whole cell is deleted and if the user
            % left-clicks, only the current frame and all subsequent frames
            % are deleted.
            %
            % Inputs:
            % aClosestCell - The cell to be removed.
            % aWholeCell - True if the whole cell should be removed.
            % aClickedFrame - The frame from which a partial deletion
            %                 should start.
            %
            % Outputs:
            % oEditedCells - Cells which were affected by the edit, without
            %                requiring an update in the segmentation. These
            %                cells need to be updated by Draw, but may not
            %                be scheduled for re-drawing by
            %                UpdateAllSegmenting.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            % The segmentations of the progeny of the edited cell should be
            % updated.
            progeny =  aClosestCell.GetProgeny();
            for pIndex = 1:length(progeny)
                this.AddUpdate(progeny(pIndex))
            end
            
            oEditedCells = [];
            if aWholeCell || aClosestCell.firstFrame == aClickedFrame
                % Delete the whole cell.
                if aClosestCell.isCell  % Delete.
                    if ~isempty(aClosestCell.parent)
                        oEditedCells = [oEditedCells aClosestCell.parent];
                    end
                    this.cells = aClosestCell.DeleteBranch(this.cells);
                else  % Un-delete.
                    this.cells = aClosestCell.UndeleteBranch(this.cells);
                end
                this.AddUpdate(aClosestCell);
            else  % Delete the current and the subsequent frames.
                clickedCell = aClosestCell.Split(aClickedFrame);
                this.cells = [this.cells clickedCell];
                oEditedCells = [oEditedCells aClosestCell];
                if clickedCell.isCell  % Delete.
                    this.cells = clickedCell.DeleteBranch(this.cells);
                else  % UnDelete.
                    this.cells = clickedCell.UndeleteBranch(this.cells);
                end
                this.AddUpdate(clickedCell);
            end
        end
        
        function oEditedCells = EditTracks_Disappear(this, aClosestCell)
            % Specifies if a cell leaves the field of view or dies.
            %
            % EditTracks_Disappear toggles the fate of the clicked cell
            % between apoptosis and leaving the field of view, if the cell
            % does not undergo mitosis or survive to the end of the image
            % sequence.
            %
            % Inputs:
            % aClosestCell - Cell to be re-labeled.
            %
            % aClosestCell - Cell that the user clicked on.
            %
            % Outputs:
            % oEditedCells - Cells which were affected by the edit, without
            %                requiring an update in the segmentation. These
            %                cells need to be updated by Draw, but may not
            %                be scheduled for re-drawing by
            %                UpdateAllSegmenting.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            if aClosestCell.lastFrame < this.GetNumImages() &&...
                    isempty(aClosestCell.children)
                % Cells are not allowed to disappear or die in the last
                % image.
                aClosestCell.disappeared = ~aClosestCell.disappeared;
                oEditedCells = aClosestCell;
            else
                oEditedCells = [];
            end
        end
        
        function EditTracks_MoveCell(this, aCreatedCell, aClosestCell)
            % Moves a cell.
            %
            % EditTracks_MoveCell edits tracks by moving a cell to a
            % different segment or into the background, creating a point
            % blob. The function either puts down a cell that was
            % previously picked up or picks up a new cell.
            %
            % first - Cell with all frames before the current frame.
            % middle - Cell with the current frame.
            % final - Cell with all frames after the current frame.
            %
            % Inputs:
            % aCreatedCell - New cell created from the most recent click.
            % aClosestCell - The cell closest to the click.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            if ~isempty(this.fromCell)  % Put down a cell.
                this.AddUpdate(this.fromCell, 'Frames', this.frame)
                
                if this.fromCell.firstFrame < this.frame
                    first = this.fromCell;
                    middle = this.fromCell.Split(this.frame);
                    this.cells = [this.cells middle];
                else
                    first = [];
                    middle = this.fromCell;
                end
                
                if middle.lastFrame > this.frame
                    final = Split(middle, this.frame + 1);
                else
                    final = [];
                end
                
                if ~isempty(final)
                    aCreatedCell.AddCell(final);
                end
                
                if ~isempty(first)
                    first.AddCell(aCreatedCell);
                else
                    % Link a child cell that is moved in the first frame.
                    par = middle.parent;
                    if ~isempty(par)
                        par.children(par.children == middle) = aCreatedCell;
                        aCreatedCell.parent = par;
                        middle.parent = [];
                    end
                    
                    this.cells = [this.cells aCreatedCell];
                end
                
                if ~isempty(first)
                    newMiddle = first;
                else
                    newMiddle = aCreatedCell;
                    newMiddle.isCell = middle.isCell;
                end
                middle.isCell = false;
                
                if newMiddle.GetCx(this.frame) == middle.GetCx(this.frame) &&...
                        newMiddle.GetCy(this.frame) == middle.GetCy(this.frame)
                    this.cells(this.cells == middle) = [];
                end
                
                % If the cell is moved to a location where there is no
                % blob, the newly created point blob has to be added to the
                % set of blobs.
                if any(isnan(aCreatedCell.blob(this.frame-aCreatedCell.firstFrame+1).boundingBox))
                    this.blobSeq{this.frame} = [this.blobSeq{this.frame}...
                        aCreatedCell.blob(this.frame-aCreatedCell.firstFrame+1).super];
                    this.update{this.frame} = [this.update{this.frame} false];
                end
                
                this.fromCell = [];
                this.AddUpdate(aCreatedCell)
            else
                this.fromCell = aClosestCell;
            end
        end
        
        function oEditedCells = EditTracks_MoveMitosis(this, aClosestCell)
            % Moves a mitotic event to the current frame.
            %
            % The mitosis can either be moved forward in time by clicking
            % on one of the child cells or backward in time by clicking
            % on the parent cell. If the clicked cell is both a parent cell
            % and a child cell, the mitotic event closest in time will be
            % moved. If the parent cell is clicked, the two child cells
            % will both follow the track of the parent cell between the
            % time points of the new and the old mitosis. If a child cell
            % is clicked, the parent cell will follow the track of the
            % clicked cell between the time points of the new and the old
            % mitosis, and the track of the other child cell will be turned
            % into a false positive track between the these time points.
            %
            % Inputs:
            % aClosestCell - Cell that the user clicked on.
            %
            % Outputs:
            % oEditedCells - Cells which were affected by the edit, without
            %                requiring an update in the segmentation. These
            %                cells need to be updated by Draw, but may not
            %                be scheduled for re-drawing by
            %                UpdateAllSegmenting.
            %
            % See also:
            % WindowButtonDownFcn_Tracks
            
            if nargout > 0
                oEditedCells = [];
            end
            
            if aClosestCell.firstFrame == this.frame
                % We can not split a cell in its first frame.
                return
            end
            
            if this.frame - aClosestCell.firstFrame < aClosestCell.lastFrame + 1 - this.frame &&...  % Closer to the beginning of this cell than the beginning of the child cell.
                    ~isempty(aClosestCell.parent) &&...  % Must be a child cell.
                    aClosestCell.parent.OtherChild(aClosestCell).lastFrame >= this.frame  % The other child cell must exist.
                % A child cell was clicked.
                
                cell1 = aClosestCell;
                cell2 = cell1.parent.OtherChild(cell1);
                parent = cell1.parent;
                child1 = cell1.Split(this.frame);
                child2 = cell2.Split(this.frame);
                parent.RemoveChildren();
                % Prior frames of the clicked child cell go to the parent
                % cell.
                parent.AddCell(cell1);
                parent.AddChild(child1);
                parent.AddChild(child2);
                % Prior frames of the other child cell disappear.
                cell2.isCell = false;
                this.cells(this.cells == cell1) = [];
                this.cells = [this.cells child1 child2];
                this.AddUpdate(cell1)
                this.AddUpdate(cell2)
            else
                % The parent cell was clicked.
                
                parent = aClosestCell;
                child1 = parent.Split(this.frame);
                % Duplicate the continuation of the parent cell to produce
                % a second child cell.
                child2 = child1.Clone();
                this.cells = [this.cells child1 child2];
                this.AddUpdate(child1)
                % Join the preexisting child tracks with the new ones.
                if ~isempty(child1.children)
                    child11 = child1.children(1);
                    child12 = child1.children(2);
                    child1.RemoveChildren();
                    child1.AddCell(child11);
                    child2.AddCell(child12);
                    this.cells(this.cells == child11) = [];
                    this.cells(this.cells == child12) = [];
                end
                parent.AddChild(child1);
                parent.AddChild(child2);
            end
            oEditedCells = [parent parent.children];
        end
        
        function EditTracks_SplitCell(this, aClosestCell)
            % Creates a copy of a preexisting cell using the Split tool.
            %
            % The copy will be added to all of the detections where the
            % specified cell is present. Parts of cells can be copied and
            % connected to a track in the previous image using the Track
            % Split tool, but the corresponding operations are performed by
            % EditTracks_Connect.
            %
            % Inputs:
            % aClosestCell - Cell to be copied.
            %
            % See also:
            % WindowButtonDownFcn_Tracks, EditTracks_Connect
            
            clonedCell = aClosestCell.Clone();
            ClearCellNotes(clonedCell, 'Value', 1);
            this.cells = [this.cells clonedCell];
            this.AddUpdate(clonedCell);
        end
        
        function oAx = GetCurrAx(this)
            % Find axes that the user holds the cursor over.
            %
            % The function only considers the xy-, xz-, and yz-axes, and
            % not the tree-axes. If the cursor is not inside any of the
            % axes, [] is returned.
            %
            % Outputs:
            % oAx - Axes object or [].
            
            plotAxes = [this.ax this.axXZ this.axYZ];
            oAx = [];  % Axes that the user holds the cursor over.
            for i = 1:length(plotAxes)
                % Get the current cursor coordinates.
                xy = get(plotAxes(i), 'CurrentPoint');
                x2 = xy(1,1);
                y2 = xy(1,2);
                if InsideAxes(plotAxes(i), x2, y2)
                    oAx = plotAxes(i);
                    break
                end
            end
        end
        
        function oIm = GetFrame(this, varargin)
            % Performs screen capture on the tracks and the lineage tree.
            %
            % The contents of the different axes are captured separately
            % and then merged together. In the merge, the different images
            % are separated by bands of 10 black or white pixels. The
            % background of the figure is temporarily made white or black
            % during the screen so that pixels captured outside the axes
            % get right color. The background color of the figure is
            % restored when the screen capture is finished. The function
            % can handle all possible 3D views and lineage tree options,
            % but the lineage tree will not be included in the screen
            % capture if it is shown in a separate window. If the tree axes
            % is higher than the axes with tracks, there will be white
            % pixels under the panels with tracks in the captured image.
            % Panels with 3D views are normally saved with black pixels
            % between the images, but if a lineage tree is shown in the
            % main figure or in a separate figure, the pixels between the
            % images will be white.
            %
            % Property/Value inputs:
            % FFDshow - If this is set to true, the image will be padded
            %           with black or white pixels from above and from the
            %           left so that the width is a multiple of 4 and the
            %           height is a multiple of 2. It is claimed that the
            %           image must fulfill these requirements for it to be
            %           encoded using the FFDShow codec.
            
            aFFDshow = GetArgs({'FFDshow'}, {false}, true, varargin);
            
            if strcmpi(this.tree, 'None')
                % Use a white background if there is no lineage tree. One
                % can get a white background without the lineage tree by
                % putting the lineage tree in a separate figure.
                padColor = 0;
            else
                % Use a black background if there is no lineage tree.
                padColor = 255;
            end
            
            % Capture 3D projectsion of the data.
            trackImage = this.GetFrame@ZControlPlayer(...
                'PadColor', padColor,...
                'FFDshow', false);
            
            if any(strcmp({'Frames', 'Hours'},this.tree))
                % Background color before the screen capture.
                bgc = get(this.mainFigure, 'Color');
                % Set the background color to the padding color.
                set(this.mainFigure, 'Color', ones(1,3)*padColor/255);
                
                % Some pixels outside the axes need to be captured.
                treeImage = RecordAxes(this.treeAxes, 'Offsets', [-60 -3 60 3]);
                
                % Pad at the bottom so that trackImage and treeImage get
                % the same height.
                if size(treeImage,1) > size(trackImage,1)
                    trackImage = padarray(trackImage,...
                        [size(treeImage,1)-size(trackImage,1) 0 0], padColor, 'post');
                elseif size(treeImage,1) < size(trackImage,1)
                    treeImage = padarray(treeImage,...
                        [size(trackImage,1)-size(treeImage,1) 0 0], padColor, 'post');
                end
                
                % Separate the tree and the tracks by 10 pixels.
                treeImage = padarray(treeImage, [0 10 0], padColor, 'post');
                
                % Concatenate the two images.
                oIm = [treeImage trackImage];
                
                % Restore the old background color.
                set(this.mainFigure, 'Color', bgc)
            else
                oIm = trackImage;
            end
            
            if aFFDshow
                oIm = PadForFFDshow(oIm, padColor);
            end
        end
        
        function oGT = GetGTCells(this)
            % Returns ground truth cells for the current image sequence.
            %
            % The ground truth version has to be called 'GT'. The ground
            % truth cells are only loaded when plotting is done using the
            % 'ISBI-errors' style.
            
            if ~strcmp(this.gtSeqPath, this.GetSeqPath())
                this.gtCells = LoadCells(this.GetSeqPath(), 'GT');
                this.gtSeqPath = this.GetSeqPath();
            end
            oGT = this.gtCells;
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
            
            if aAxes == this.treeAxes
                areCells = AreCells(this.cells);
                switch this.tree
                    case {'Frames', 'Frames (Separate Window)'}
                        xlims = this.GetImData().GetTLim('frames',...
                            'Margins', [0.01 0.01]);
                    case {'Hours', 'Hours (Separate Window)'}
                        xlims = this.GetImData().GetTLim('hours',...
                            'Margins', [0.01 0.01]);
                end
                oXmin = xlims(1);
                oXmax = xlims(2);
                oYmin = 0;
                oYmax = max([areCells.Y2])+1;
            else
                [oXmin, oXmax, oYmin, oYmax] =...
                    this.GetMaxAxisLimits@ZControlPlayer(aAxes);
            end
        end
        
        
        function [oName] = GetName(~)
            % Returns the name of the player.
            %
            % The name will be displayed in the title of the main window
            % together with the path of the current image.
            
            oName = 'Track correction';
        end
        
        function [oX, oY, oZ, oXY] = GetXYZ(this, aAx)
            % Returns the coordinates that the cursor points at.
            %
            % This function gets coordinates from the 3D-slices of the
            % z-stack. The coordinate not displayed in the axes is taken
            % from the slice selection text box. This is done even if a
            % maximum intensity projection is shown in the axes.
            %
            % Inputs:
            % aAx - Axes object to compute the coordinates in. This input
            %       must be this.ax, this.axXZ, or this.axYZ. The cursor
            %       does not have to be inside the axes.
            %
            % Outputs:
            % oX - X-coordinate in voxels.
            % oY - Y-coordinate in voxels.
            % oZ - Z-coordinate in voxels. This is 0 for 2D data.
            % oXY - The 'CurrentPoint' array of the axes. This array
            %       contains the x- and y-coordinates in the axes object,
            %       and not the coordinates in the z-stack.
            
            oXY = get(aAx, 'CurrentPoint');
            switch aAx
                case this.ax
                    oX = oXY(1,1);
                    oY = oXY(1,2);
                    if this.GetImData().GetDim() == 2
                        oZ = 0;
                    else
                        oZ = this.z;
                    end
                case this.axXZ
                    oX = oXY(1,1);
                    oY = this.y;
                    oZ = oXY(1,2);
                case this.axYZ
                    oX = this.x;
                    oY = oXY(1,2);
                    oZ = oXY(1,1);
                otherwise
                    error('Invalid axes given as input to GetXYZ.')
            end
        end
        
        function KeyPressFcn(this, aObj, aEvent)
            % Defines keyboard shortcuts for the ManualCorrectionPlayer.
            %
            % This function is be the key-press callback of the main
            % figure and of all uicontrols in it, except the text boxes.
            % There are hidden options to show a background subtracted
            % image (ALT+B) and to display microwell outlines (ALT+M).
            % These options are only defined as keyboard shortcuts and can
            % not be accessed from the GUI. Mouse buttons can be linked to
            % functions in the GUI if the mouse buttons are linked to keys
            % on the keyboard using third party software.
            %
            % Inputs:
            % aObj - The object that had focus when the button was
            %           pressed.
            % aEvent - Event structure with information about the key
            %          press.
            
            % Ignore modifier keypresses
            if (any(strcmp(aEvent.Key, ['control', 'alt', 'shift'])))
                return
            end
            
            if length(aEvent.Modifier) == 1 && ...
                    strcmp(aEvent.Modifier{1}, 'control')
                % Shortcuts where the CTRL-key is held down.
                switch aEvent.Key
                    case 'g'
                        % Select the tool for continuous drawing.
                        this.Callback_ToolButton(this.continuousDrawButton, 'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'e'
                        % Show/Hide cell events.
                        this.Callback_ToggleButton(this.cellEventsToggle, 'key')
                    case 'l'
                        % Show/Hide the time line in the lineage tree.
                        this.Callback_ToggleButton(this.currentLineToggle, 'key')
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
            elseif length(aEvent.Modifier) == 1 && ...
                    strcmp(aEvent.Modifier{1}, 'alt')
                % (Hidden) shortcuts where the ATL-key is held down.
                switch aEvent.Key
                    case 'b'
                        % Display a background subtracted image.
                        this.showBgSub = ~this.showBgSub;
                        this.Draw();
                    case 'm'
                        % Show the microwell boundary as a hatched line.
                        this.showMicrowell = ~this.showMicrowell;
                        this.Draw();
                end
            elseif isempty(aEvent.Modifier)
                % Shortcuts where a single key is pressed.
                switch aEvent.Key
                    case 'a'
                        % Select the add tool.
                        this.Callback_ToolButton(this.addButton,  'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'c'
                        % Select the set child tool.
                        this.Callback_ToolButton(this.childButton,  'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'y'
                        % Select the child splitting tool.
                        this.Callback_ToolButton(this.childSplitButton, 'key')
                    case 'd'
                        % Select the delete tool.
                        this.Callback_ToolButton(this.deleteButton, 'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'e'
                        % Select the tool to edit segments.
                        this.Callback_ToolButton(this.editSegmentsButton, 'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'f'
                        % Remove false positives without segments.
                        this.Callback_ToggleButton(this.fpToggle, 'key')
                    case 'g'
                        % Select the Track Split tool.
                        this.Callback_ToolButton(this.trackSplitButton,  'key')
                    case 'h'
                        % Select the selection tool.
                        this.Callback_ToolButton(this.selectButton, 'key')
                    case 'i'
                        % Set the trajectory length to infinity.
                        this.tLength = inf;
                        set(this.trajectoryTextBox, 'String', num2str(this.tLength))
                        this.Draw();
                    case 'j'
                        % Go to the next image where a track starts or
                        % ends.
                        this.Callback_JumpButton(this.jumpButton, [])
                    case 'l'
                        % Select the tool for cells that leave the image.
                        this.Callback_ToolButton(this.disappearButton,  'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'n'
                        % Select the continuous add tool.
                        this.Callback_ToolButton(this.continuousAddButton,  'key')
                    case 'leftarrow'
                        % Go to the previous image.
                        if(this.play)
                            this.Stop()
                        end
                        this.frame = max(1, this.frame - this.step);
                        this.Draw();
                    case 'q'
                        % Select the tool that moves mitotic events.
                        this.Callback_ToolButton(this.moveMitosisButton,  'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'r'
                        % Removes false positives without segments.
                        this.Callback_RemoveFpButton(this.removeFpButton, []);
                    case 'rightarrow'
                        % Go to the next image.
                        if(this.play)
                            this.Stop()
                        end
                        this.frame = min(this.GetNumImages(), this.frame + this.step);
                        this.Draw();
                    case 'home'
                        % Switch to the first frame.
                        this.frame = 1;
                        this.Draw();
                    case 'end'
                        % Switch to the last frame.
                        this.frame = this.GetNumImages();
                        this.Draw();
                    case 't'
                        % Select the Track tool.
                        this.Callback_ToolButton(this.connectButton,  'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 's'
                        % Select the Split tool.
                        this.Callback_ToolButton(this.splitButton,  'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'space'
                        % Turn panning on.
                        if ~this.panning && ~this.drawDown
                            % KeyPressFcn is called repeatedly when the
                            % space bar is held down, and the cursor should
                            % only change on the first call. Panning is
                            % disabled when segments are edited.
                            this.panning = true;
                            this.SetCursor('hand')
                        end
                    case 'm'
                        % Toggle panning.
                        if ~this.panning
                            % Panning is disabled when segments are edited.
                            if ~this.drawDown
                                this.panning = true;
                                this.SetCursor('hand')
                            end
                        else
                            this.panning = false;
                            this.SetCursor(this.currentCursor)
                        end
                    case 'uparrow'
                        % Start/Stop playing the image sequence.
                        this.PlayButton_Callback(this.playButton, [])
                    case 'w'
                        % Select the move tool.
                        this.Callback_ToolButton(this.moveButton, 'key')
                        this.WindowButtonMotionFcn(this.mainFigure, aEvent)
                    case 'x'
                        % Toggle plotting of trajectories.
                        this.Callback_ToggleButton(this.trajectoryToggle, 'key')
                    case 'v'
                        % Turn on the zoom tool.
                        this.Callback_ToolButton(this.zoomButton, 'key')
                        this.SetCursor('glass')
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
                        
                        if isstrprop(aEvent.Character, 'digit')
                            % Set the trajectory length to a number.
                            this.tLength = str2double(aEvent.Character);
                            set(this.trajectoryTextBox, 'String', aEvent.Character)
                            this.Draw();
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
            % cannot be started. This function overwrites a function with
            % the same name in SequencePlayer, and sets the cursor to the
            % current cursor instead of an arrow.
            
            if strcmp(aEvent.Key, 'space')
                this.panning = false;
                this.SetCursor(this.currentCursor)
            end
        end
        
        function LoadCells(this)
            % Loads cells from a tracking result.
            %
            % If the user has selected a tracking version (result label),
            % the cells in that tracking version will be loaded. Otherwise,
            % the this.cells will be set to an empty array. When the user
            % selects a tracking version, the cells are loaded and the name
            % of the version is stored in this.prefVer. If the user opens a
            % different image sequence which does not have that version, no
            % cells will be loaded, but the value of this.prefVer is not
            % changed. This makes it possible to open the previously
            % selected tracking version the next time an image sequence
            % which has that version is opened.
            %
            % All variables are updated based on the loaded cells. The
            % function tries to set the coloring scheme to the scheme that
            % was used to color the cells before they were saved. If the
            % coloring scheme of the cells does not match any of the
            % available schemes, the cells are colored using the scheme
            % selected in the Coloring menu.
            
            if any(strcmp(this.versions, this.prefVer))
                ver = this.prefVer;
            else
                % Selects '***NOT_TRACKED***' or '***SELECT_A_TRACKING***'.
                ver = this.versions{1};
            end
            
            this.fromCell = [];
            
            % Load the cells.
            if ~strcmp(ver, '***NOT_TRACKED***') &&...
                    ~strcmp(ver, '***SELECT_A_TRACKING***')
                this.cells = LoadCells(this.GetSeqPath(), ver);
            else
                % No cells should be loaded.
                this.cells = [];
            end
            
            this.blobSeq = Cells2Blobs(this.cells, this.GetImData());
            IndexBlobs(this.blobSeq)
            
            this.update = cell(size(this.blobSeq));
            for t = 1:length(this.blobSeq)
                this.update{t} = false(size(this.blobSeq{t}));
            end
            this.loadedVer = ver;
            
            % Try to set the coloring scheme to what was used when the
            % cells were saved.
            if ~isempty(this.cells)
                scheme = {this.cells.coloring};
                scheme = unique(scheme);
                scheme = setdiff(scheme, 'manual');
                if length(scheme) == 1 && any(strcmp(this.coloringAlts, scheme{1}))
                    this.coloring = scheme{1};
                    
                    % Check the selected coloring menu and uncheck the
                    % others.
                    menu = GetMenu(this.coloringMenu, this.coloring);
                    submenus = get(get(menu, 'Parent'), 'Children');
                    for i = 1:length(submenus)
                        set(submenus(i), 'Checked', 'off')
                    end
                    set(menu, 'Checked', 'on')
                else
                    this.ColorCells()
                end
            end
            
            if get(this.selectButton, 'Value')
                this.SelectButtonOn()
            end
        end
        
        function MenuCallback_ColoringChange(this, aObj, ~)
            % Callback for the coloring menu.
            %
            % The callback changes the cell coloring when the user selects
            % a coloring.
            
            this.coloring = get(aObj, 'Label');
            
            % Makes it possible for ColorCells to update all colors.
            for i = 1:length(this.cells)
                this.cells(i).coloring = 'Default';
            end
            
            % Check the selected coloring menu and uncheck the others.
            submenus = get(get(aObj, 'Parent'), 'Children');
            for i = 1:length(submenus)
                set(submenus(i), 'Checked', 'off')
            end
            set(aObj, 'Checked', 'on')
            
            % Color the cells.
            this.ColorCells()
            
            % Ensures that the colors are not reverted if the user
            % deselects the selection tool.
            areCells = AreCells(this.cells);
            for i = 1:length(areCells)
                this.cellColors{i} = areCells(i).color;
            end
            
            this.Draw()
            this.DrawTree()
        end
        
        function MenuCallback_DrawChange(this, aObj, ~)
            % Callback for the menus with drawing options.
            %
            % The function checks the selected option and unchecks the
            % other options on the same menu. Then it updates class
            % properties based on the selection.
            
            parentMenu = get(aObj, 'Parent');
            
            % Uncheck all options.
            subMenus = get(parentMenu, 'Children');
            for i = 1:length(subMenus)
                set(subMenus(i), 'Checked', 'off')
            end
            % Check the selected option.
            set(aObj, 'Checked', 'on')
            
            % Update class properties based on the selection.
            switch get(parentMenu, 'Label')
                case 'Create'
                    this.drawBreak = get(aObj, 'Label');
                case 'Merging'
                    this.drawMerge = get(aObj, 'Label');
                case 'Holes'
                    this.drawHole = get(aObj, 'Label');
                case 'Brush'
                    if this.GetImData().GetDim() == 3
                        this.drawBrush = get(aObj, 'Label');
                        switch this.drawBrush
                            case 'Disk (CTRL+D)'
                                this.brush.SetShape('disk')
                            case 'Ball (CTRL+B)'
                                this.brush.SetShape('ball')
                        end
                    end
            end
            
        end
        
        function MenuCallback_StyleChange(this, aObj, ~)
            % Callback for the style menu.
            %
            % The callback changes the plotting style when the user selects
            % a style.
            
            this.style = get(aObj, 'Label');
            
            % Check the selected style menu and uncheck the others.
            submenus = get(get(aObj, 'Parent'), 'Children');
            for i = 1:length(submenus)
                set(submenus(i), 'Checked', 'off')
            end
            set(aObj, 'Checked', 'on')
            
            this.Draw()
            this.DrawTree()
        end
        
        function MenuCallback_TreeChange(this, aObj, ~)
            % Callback for the tree menu.
            %
            % The callback changes where the lineage tree is plotted an the
            % unit on the time axis. The entire lineage tree will be
            % re-drawn.
            
            this.tree = get(aObj, 'Label');
            
            % Check the selected coloring menu and uncheck the others.
            submenus = get(get(aObj, 'Parent'), 'Children');
            for i = 1:length(submenus)
                set(submenus(i), 'Checked', 'off')
            end
            set(aObj, 'Checked', 'on')
            
            switch this.tree
                case {'Frames' 'Hours'}
                    % Plot the lineage tree in an axes to the left of the
                    % axes with images.
                    if ~isempty(this.treeFigure) ||...
                            strcmp(get(this.treeAxes, 'Visible'), 'off')
                        this.RemoveTreeFigure()  % Must come before resizing (creates new treeAxes).
                        this.ReSizeAxes('KeepAxisLimits', true)
                    end
                case {'Frames (Separate Window)' 'Hours (Separate Window)'}
                    % Plot the lineage tree in a separate figure.
                    if isempty(this.treeFigure)
                        this.CreateTreeFigure();  % Must come before resizing (creates new treeAxes).
                        this.ReSizeAxes('KeepAxisLimits', true)
                    end
                case 'None'
                    % Do not plot a lineage tree at all.
                    if strcmp(get(this.treeAxes, 'Visible'), 'on')
                        this.ReSizeAxes('KeepAxisLimits', true)
                        this.RemoveTreeFigure()
                    end
            end
            
            this.DrawTree()
        end
        
        function oParams = PlotParameters(this)
            % Generates a struct with parameters for plotting.
            %
            % The function is inherited from ZPlayer and in addition to the
            % fields defined in ZPlayer, the parameter structure has the
            % fields:
            %
            % plotCells - Array of Cell objects to be plotted.
            % trajOpts - Plotting options for PlotTrajectories.
            % outlineOpts - Plotting options for PlotOutlines.
            % markerLineWidth - Line width used to draw markers for events
            %                   such as mitosis and apoptosis.
            %
            % See also:
            % ZPlayer, Draw, PlotTrajectories, PlotOutlines
            
            oParams = this.PlotParameters@ZControlPlayer();
            
            if get(this.fpToggle, 'Value')
                % Plot all cells including false positives.
                oParams.plotCells = this.cells;
            else
                % Don't plot false positives.
                oParams.plotCells = AreCells(this.cells);
            end
            
            % Get options for plotting of trajectories and outlines.
            trajOpts = struct('fMarkerEdgeColor',...
                {repmat({str2num(get(this.fpColorTextBox, 'String'))}, 1, 3)}); %#ok<ST2NM>
            outlineOpts = struct('fpColor',...
                str2num(get(this.fpColorTextBox, 'String'))); %#ok<ST2NM>
            
            if this.IsZoomed() && this.GetImData().GetDim() == 3
                [x1, x2, y1, y2, z1, z2] = this.GetZoom();
                
                % Select cells that touch the zoomed in volume.
                oParams.plotCells =...
                    CropCells(oParams.plotCells,...
                    this.frame-this.tLength+1, this.frame,...
                    x1, x2, y1, y2, z1, z2);
                
                % Define the borders of the zoomed in volume so that
                % PlotOutlines can crop away parts of the blobs which are
                % outside the volume.
                outlineOpts.x1 = x1;
                outlineOpts.x2 = x2;
                outlineOpts.y1 = y1;
                outlineOpts.y2 = y2;
                outlineOpts.z1 = z1;
                outlineOpts.z2 = z2;
            end
            
            switch this.style
                case 'Save'
                    % This style is nice for exported videos. All lines are
                    % thicker and all cell nodes are filled and have the
                    % same size.
                    oParams.markerLineWidth = 2;
                    outlineOpts.LineWidth =  1.5;
                    trajOpts.dMarkerSize =  [3 3 3];
                    trajOpts.dMarkerFaceColor =  {[], [], []};
                    trajOpts.cMarker = {'o', 'o', 'o'};
                    trajOpts.cMarkerSize =  [3 3 3];
                    trajOpts.cMarkerFaceColor = {[], [], []};
                    trajOpts.fMarkerSize = [3 3 3];
                case 'ISBI'
                    % This style is nice for visualization of particle
                    % tracks or small cells. The cell nodes in the current
                    % image is marked by a circle and the cell nodes in
                    % previous images are not marked at all. This prevents
                    % small objects from being covered by the tracks.
                    oParams.markerLineWidth = 1;
                    trajOpts.dMarkerSize = [eps eps 10];
                    trajOpts.cMarkerSize = [eps eps 10];
                    trajOpts.fMarkerSize = [eps eps 10];
                    trajOpts.dMarkerFaceColor = {'none', 'none', 'none'};
                    trajOpts.cMarkerFaceColor = {'none', 'none', 'none'};
                    trajOpts.fMarkerFaceColor = {'none', 'none', 'none'};
                otherwise
                    % The default plotting options are used for all other
                    % styles. In these styles, the cell nodes in the
                    % current image are bigger than other cell nodes and
                    % the cell nodes in the current image and the previous
                    % image are filled, so that it is easy to see which
                    % nodes can be connected during manual correction.
                    oParams.markerLineWidth = 1;
            end
            oParams.trajOpts = trajOpts;
            oParams.outlineOpts = outlineOpts;
        end
        
        function PositionTools(this)
            % (Re)positions all of the controls on the control panel.
            
            % Go from relative control positions to absolute positions on
            % the control panel. The positions are in normalized units. The
            % positions are computed from the top of the panel to the
            % bottom.
            top = 1;  % y-coordinate of the upper edge of the next control.
            for i = 1:length(this.controlOrder)
                dTop = 0;
                left = 0;  % x-coordinate of the left edge of the next control.
                for j = 1:length(this.controlOrder{i})
                    field = this.controlOrder{i}{j};
                    pos = this.controlPositions.(field);
                    positions.(field) = [left + pos(1), top - pos(2) - pos(4), pos(3), pos(4)];
                    left = left + pos(1) + pos(3);
                    dTop = max(dTop, pos(2) + pos(4));
                end
                top = top - dTop;
            end
            
            % Change the positions of the controls.
            for i = 1:length(this.controlOrder)
                for j = 1:length(this.controlOrder{i})
                    command = sprintf(...
                        'set(this.%s, ''Units'', ''normalized'', ''Position'', [%s])',...
                        this.controlOrder{i}{j},...
                        num2str(positions.(this.controlOrder{i}{j})));
                    
                    eval(command)
                end
            end
        end
        
        function PromptSaveCallback(this, aObj, aEvent, aFun)
            % Opens a dialog where unsaved changes can be saved.
            %
            % PromptSaveCallback is a wrapper callback which asks the user
            % if unsaved edits should be saved before the callback of a
            % uicontrol is executed. If the user answers "yes", the edits
            % are saved and then the callback of the uicontrol is executed.
            % If the user answers "no", the callback is executed without
            % saving the edits and if the user answers "cancel", no further
            % actions are taken. If there are no unsaved changes,
            % PromptSaveCallback will execute the callback of the uicontrol
            % without asking. To use this function, the callback property
            % of the uicontrol should be defined as
            % {this.PromptSaveCallback, aFun}, where aFun is the callback
            % normally associated with the uicontrol.
            %
            % Inputs:
            % aObj - uicontrol that gave rise to the callback.
            % aEvent - Event object associated with the callback.
            % aFun - Callback of the uicontrol.
            
            if this.edited
                answer = questdlg(...
                    'Do you want to save the changes made?',...
                    'Save changes', 'Yes', 'No', 'Cancel', 'Yes');
                if isempty(answer)
                    answer = 'Cancel';
                end
                
                switch answer
                    case 'Yes'
                        this.Callback_SaveButton(this.saveButton, [],...
                            'AfterFunction', aFun)
                    case 'No'
                        this.edited = false;  % This allows the edits to be rejected.
                        if iscell(aFun)
                            feval(aFun{1}, aObj, aEvent, aFun{2:end})
                        else
                            feval(aFun, aObj, aEvent)
                        end
                    case 'Cancel'
                        % Don't execute the callback.
                end
            else
                % There were no unsaved edits. Just execute the callback.
                if iscell(aFun)
                    feval(aFun{1}, aObj, aEvent, aFun{2:end})
                else
                    feval(aFun, aObj, aEvent)
                end
            end
        end
        
        function RecordIterations_Callback(this, ~, ~)
            % Records an image sequence with intermediate tracking results.
            %
            % This callback will generate an image sequence visualizing
            % intermediate tracking results generated using the option
            % "Automated->Generate intermediate trackings" in the main GUI.
            % The images of the sequence will visualize the iterations of
            % the Viterbi tracking. For each iteration, the track created
            % in that iteration is colored red and all other tracks are
            % colored blue. To record an image sequence like this, the user
            % should select a tracking version for which there are
            % intermediate results. The names of the intermediate tracking
            % versions start with the name of the selected tracking version
            % and end with '_iter' followed by a number. The images are
            % saved as individual png-files.
            
            % Open a dialog to select a folder for the image sequence.
            savePath = UiGetMultipleDirs(...
                'Path', this.GetImData().GetAnalysisPath(),...
                'MultiSelect', false);
            
            % Find the names of intermediate tracking versions.
            start_ver = this.loadedVer;
            iter_vers = regexp(this.versions, [start_ver '_iter\d*'], 'match', 'once');
            iter_vers(cellfun(@isempty, iter_vers)) = [];
            
            for i = 1:length(iter_vers)
                fprintf('Recording iteration %d / %d.\n', i, length(iter_vers))
                
                % Load intermediate tracking version number i.
                this.prefVer = iter_vers{i};
                this.LoadCells()
                
                if ~exist(savePath, 'dir')
                    mkdir(savePath)
                end
                
                this.Draw();
                this.DrawTree()
                
                % Save the image using screen capture.
                im = this.GetFrame('FFDshow', true);
                imName = sprintf('iter%05d.png', i);
                imwrite(im, fullfile(savePath, imName))
            end
            fprintf('Done recording iterations.\n')
        end
        
        function RemoveTreeFigure(this)
            % Removes the separate lineage tree figure.
            %
            % The function also creates an invisible axes for the lineage
            % tree in the main figure. If there is no lineage tree figure,
            % the function does not do anything.
            
            if ~isempty(this.treeFigure)
                delete(this.treeFigure)
                this.treeFigure = [];
                this.treeAxes = axes('Parent', this.mainFigure,...
                    'Position', [0.05 0.07 0.175 0.925],...
                    'Visible', 'off');
            end
        end
        
        function ReSizeAxes(this, varargin)
            % Resizes all image axes and the lineage tree axes.
            %
            % The axes are given appropriate sizes depending on where the
            % lineage tree is placed, which 3D view is selected and how
            % much the user has zoomed in.
            %
            % Property/Value inputs:
            % KeepAxisLimits - If this parameter is set to true, the
            %                  dimensions of the displayed region of the
            %                  image or z-stack  will be determined from
            %                  the axis limits. By default, it is assumed
            %                  that the entire image or z-stack is shown.
            %                  In that case, the dimensions of the image or
            %                  z-stack are determined from the ImageData
            %                  object. The parameter needs to be set to
            %                  true to arrange the axes properly when
            %                  zooming is used together with the 'all'
            %                  3D-layout.
            %
            % See also:
            % ReSizeAxesMargin
            
            % The fraction of the figure width taken up by uicontrols.
            if this.GetImData().numZ > 1
                w = this.volumePanelWidth + this.controlWidth;
            else
                w = this.controlWidth;
            end
            
            % The selected 3D-layout.
            if this.GetImData().numZ > 1
                layout = this.volumeSettingsPanel.GetValue('display');
            else
                layout = 'xy';
            end
            
            switch this.tree
                case {'Frames', 'Hours'}
                    % The lineage tree is to left of the axes with images.
                    this.ReSizeAxesMargin(layout, [0.225 w], varargin{:})
                    set(this.treeAxes, 'Visible', 'on')
                case {'Frames (Separate Window)', 'Hours (Separate Window)'}
                    % The lineage tree is in a separate figure.
                    this.ReSizeAxesMargin(layout, [0 w], varargin{:})
                    set(this.treeAxes, 'Visible', 'on')
                case 'None'
                    % The lineage tree is not shown.
                    this.ReSizeAxesMargin(layout, [0 w], varargin{:})
                    set(this.treeAxes, 'Visible', 'off')
            end
        end
        
        function ResizeButtons(this, ~, ~)
            % Adjusts the sizes of all button icons.
            %
            % The sizes of button icons are normally constant and do not
            % change when the buttons are resized. This function adjusts
            % the sizes of the button icons so that they fill the buttons.
            
            for i = 1:length(this.toolButtons)
                this.toolButtons(i).Draw()
            end
            
            for i = 1:length(this.toggleButtons)
                this.toggleButtons(i).Draw()
            end
            
            for i = 1:length(this.pushButtons)
                this.pushButtons(i).Draw()
            end
        end
        
        function SelectButtonOff(this, ~, ~)
            % Undoes the coloring done by the selection tool.
            %
            % When the selection tool is deselected, the cells are colored
            % in the colors they had before the selection tool was used.
            %
            % See also:
            % SelectButtonOn
            
            areCells = AreCells(this.cells);
            for i = 1:length(areCells)
                areCells(i).color = this.cellColors{i};
            end
            this.toolButtons([this.toolButtons.uicontrol] ==...
                this.selectButton).Unselect();
            this.Draw();
            this.DrawTree();
        end
        
        function SelectButtonOn(this, ~, ~)
            % Colors all cells blue when the selection tool is selected.
            %
            % When the user selects a cell, that cell is colored orange by
            % WindowButtonDownFcn_Color. When the selection tool is
            % deselected, the cells get their original colors back.
            %
            % See also:
            % SelectButtonOff, WindowButtonDownFcn_Color
            
            % Color the cells.
            areCells = AreCells(this.cells);
            for i = 1:length(areCells)
                this.cellColors{i} = areCells(i).color;
                areCells(i).color = [0 0 1];
            end
            
            this.Draw();
            this.DrawTree();
        end
        
        function SwitchSequence(this, aIndex)
            % Executed when the player switches to a new image sequence.
            %
            % The function overrides the same function in ZControlPlayer.
            %
            % Inputs:
            % aIndex - Index of the new image sequence.
            
            % Remove the cells temporarily and let the SwitchSequence
            % function in ZPlayer draw new images without cells. The
            % functions DrawXY, DrawXZ, and DrawYZ have been overloaded and
            % therefore ZPlayer would draw the cells if they were not
            % removed.
            this.cells = [];
            
            % Remove the old lineage tree before the new have been drawn.
            cla(this.treeAxes)
            
            this.SwitchSequence@ZControlPlayer(aIndex);
            % Allows the axis limits to change for a new sequence.
            this.UpdateVerPopupMenu()
            this.LoadCells();
            this.edited = false;
            this.fromCell = [];
            
            % Change the image parameters stored in the segmentation brush.
            if this.GetImData().GetDim() == 2
                this.brush = Brush(...
                    this.brush.GetR(),...
                    this.brush.GetX(),...
                    this.brush.GetY(),...
                    this.GetImData().imageHeight,...
                    this.GetImData().imageWidth);
                set(GetMenu(this.drawMenu, 'Brush'), 'visible', 'off')
            else
                if isa(this.brush, 'Brush3D')
                    this.brush = Brush3D(...
                        this.brush.GetR(),...
                        this.brush.GetX(),...
                        this.brush.GetY(),...
                        this.brush.GetZ(),...
                        this.brush.GetView(),...
                        this.brush.GetShape(),...
                        this.GetImData().imageHeight,...
                        this.GetImData().imageWidth,...
                        this.GetImData().numZ,...
                        this.GetImData().voxelHeight);
                else
                    switch this.drawBrush
                        case 'Disk (CTRL+D)'
                            shape = 'disk';
                        case 'Ball (CTRL+B)'
                            shape = 'ball';
                    end
                    this.brush = Brush3D(...
                        this.brush.GetR(),...
                        this.brush.GetX(),...
                        this.brush.GetY(),...
                        0,...
                        'xy',...
                        shape,...
                        this.GetImData().imageHeight,...
                        this.GetImData().imageWidth,...
                        this.GetImData().numZ,...
                        this.GetImData().voxelHeight);
                end
                set(GetMenu(this.drawMenu, 'Brush'), 'visible', 'on')
            end
            
            
            this.ReSizeAxes()
            this.ReSizeControls()
            
            this.Draw()
            this.DrawTree()
        end
        
        function SetCursor(this, aCursor)
            % Sets the cursor in the main figure and the tree figure.
            %
            % The cursor is only set in the lineage tree figure if it
            % exists.
            %
            % Inputs:
            % aCursor - String specifying a cursor type (e.g. 'glass' for a
            %           magnifying glass).
            
            setptr(this.mainFigure, aCursor)
            if ishandle(this.treeFigure)
                setptr(this.treeFigure, aCursor)
            end
        end
        
        function TreeCloseRequestFcn(this, ~, ~)
            % Called when the lineage tree figure is closed.
            %
            % To set the tree option to 'None' and check the 'None' menu
            % option, this function calls the callback of the 'None' menu.
            % This will also close the tree figure.
            %
            % See also:
            % MenuCallback_TreeChange
            
            % Find the None menu.
            submenus = get(this.treeMenu, 'children');
            noneMenu = submenus(strcmp(get(submenus, 'Label'), 'None'));
            
            % Execute the callback of the 'None' menu.
            this.MenuCallback_TreeChange(noneMenu, []);
        end
        
        function oEditedCells = UpdateAllSegmenting(this, aT)
            % Updates the segmentation up to frame aT.
            %
            % The function will update the segmentation of super-blobs
            % which need to be updated according to this.update. The
            % function also changes the links in the affected tracks to
            % minimize the scoring function given the new segmentations.
            % The segmentation update is done by breaking clusters of cells
            % using k-means clustering. The function also colors the cells
            % and keeps track of which cells need to be re-drawn by Draw.
            %
            % Inputs:
            % aT - The last frame to update the segmentation in.
            %
            % Outputs:
            % oEditedCells - Array of cells which have been altered by the
            %                segmentation update. These cells need to be
            %                re-drawn. This output is optional and is not
            %                computed if the number of output arguments is
            %                0.
            %
            % See also:
            % AddUpdate, Draw
            
            if nargout > 0
                oEditedCells = [];
            end
            
            if isempty(this.cells)
                return
            end
            
            % The first frame where the segmentation needs to be updated.
            firstT = find(cellfun(@any, this.update), 1, 'first');
            
            if isempty(firstT) || firstT > aT
                % There is nothing to update.
                return
            end
            
            isCell = [this.cells.isCell];
            areCells = this.cells(isCell);
            notCells = this.cells(~isCell);
            
            if ~isempty(this.fromCell) && this.frame > 1
                % The ends of the cells can get mixed up by the bipartite
                % matching so we need to keep track of where and how
                % fromCell ends. If a cell is moved in the first image,
                % this.frame will be 1, and no matching should be done.
                fromFate = this.fromCell.fate;
                fromIndex = this.fromCell.GetBlob(this.frame-1).super.index;
            end
            
            % Update the segmentation and change the links to minimize the
            % scoring function given the new segments.
            if nargout > 0
                [areCells, oEditedCells] = BipartiteMatch_correction(...
                    areCells,...
                    this.blobSeq,...
                    this.update,...
                    aT,...
                    this.GetImData());
            else
                areCells = BipartiteMatch_correction(...
                    areCells,...
                    this.blobSeq,...
                    this.update,...
                    aT,...
                    this.GetImData());
            end
            
            if ~isempty(this.fromCell) && this.frame > 1 &&...
                    this.update{aT-1}(fromIndex) &&...
                    (this.fromCell.lastFrame ~= this.frame-1 ||...
                    ~any([areCells notCells] == this.fromCell))
                % Find the cell which ends in the right place and the right
                % way as fromCell did before the bipartite matching.
                for i = 1:length(this.cells)
                    c = this.cells(i);
                    if c.lastFrame == this.frame-1 &&...
                            c.blob((this.frame-1)-c.firstFrame+1).super.index == fromIndex &&...
                            strcmp(c.fate, fromFate)
                        this.fromCell = c;
                        break
                    end
                end
            end
            
            % Remove the outlines of the false positive cells that are
            % inside blobs with real cells.
            activeNotCells = AliveCells(notCells, [firstT aT]);
            activeAreCells = AliveCells(areCells, [firstT aT]);
            for i = 1:length(activeNotCells)
                nc = activeNotCells(i);
                ncEdit = false;
                for t = max(nc.firstFrame,firstT) : min(nc.lastFrame,aT)
                    index = nc.blob(t-nc.firstFrame+1).super.index;
                    if this.update{t}(index)
                        ncEdit = true;
                        if ~any(isnan(nc.blob(t-nc.firstFrame+1).boundingBox))
                            remove = false;
                            for j = 1:length(activeAreCells)
                                % Check if the false positive cell has the
                                % same super-blobs as one of the true
                                % cells and remove its outline if it does.
                                ac = activeAreCells(j);
                                if ac.firstFrame <= t && ac.lastFrame >= t
                                    if ac.blob(t-ac.firstFrame+1).super.index == index
                                        remove = true;
                                        break
                                    end
                                end
                            end
                            if remove
                                b = nc.blob(t-nc.firstFrame+1);
                                b.image = [];
                                b.boundingBox = nan(size(b.boundingBox));
                            end
                        end
                    end
                end
                if nargout > 0 && ncEdit
                    oEditedCells = [oEditedCells nc]; %#ok<AGROW>
                end
            end
            
            this.cells = [areCells notCells];
            this.ColorCells()
            
            for t = firstT:aT
                this.update{t} = false(size(this.blobSeq{t}));
            end
        end
        
        function UpdateVerPopupMenu(this)
            % Updates the alternatives in the version popup menu.
            %
            % The alternatives of the version popup menu are changed so
            % that it has all of the version of the current image sequence.
            % The version names are given without the 'CellData' prefix. If
            % the preferred tracking version (this.prefVer) is set to
            % '***SELECT_A_TRACKING***' or if the preferred tracking
            % version is not available, the option
            % '***SELECT_A_TRACKING***' is added to the popup menu and
            % selected. If there are no tracking versions, the alternative
            % '***NOT_TRACKED***' is added and selected.
            
            this.versions = GetVersions(this.GetSeqPath());
            if isempty(this.versions)
                % The image sequence has not been tracked, but the versions
                % variable must not be empty. Therefore a dummy field is
                % created. '*' is not allowed in folder names, so therefore
                % there can never be a tracking version named
                % '***NOT_TRACKED***'.
                this.versions = {'***NOT_TRACKED***'};
                selIndex = 1;
            elseif strcmp(this.prefVer, '***SELECT_A_TRACKING***')
                % When ManualCorrectionPlayer is started, no tracking
                % version selected, so that time is not spent loading a
                % tracking versions that the user is not interested in.
                this.versions = [{'***SELECT_A_TRACKING***'} this.versions];
                selIndex = 1;
            elseif ~any(strcmp(this.versions, this.prefVer))
                % The preferred version is not available.
                this.versions = [{'***SELECT_A_TRACKING***'} this.versions];
                selIndex = 1;
            else
                % The preferred version is available.
                selIndex = find(strcmp(this.versions, this.prefVer));
            end
            
            set(this.verPopupMenu,...
                'String', this.versions,...
                'Value', selIndex)
        end
        
        function WindowButtonDownFcn(this, aObj, aEvent)
            % Executes when the user clicks somewhere in the figure.
            %
            % If the user clicks in the xy-axes,
            % WindowButtonDownFcn_Tracks or
            % WindowButtonDownFcn_Segments is called to make edits
            % to tracks or segments respectively. If the selection tool or
            % the tool to color single cells is selected,
            % WindowButtonDownFcn_Color is called to color a cell.
            % If the user clicks on the lineage tree, the corresponding
            % frame is displayed. If the user clicks in the xz-axes or the
            % yz-axes, 3D-slices are selected in the 3D viewer.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - []
            %
            % See also:
            % WindowButtonDownFcn_Tracks, WindowButtonDownFcn_Segments,
            % WindowButtonDownFcn_Color, WindowButtonDownFcn_Tree
            
            clickedAx = gca;
            
            if get(this.zoomButton, 'Value') || this.panning
                this.WindowButtonDownFcn@ZControlPlayer(aObj, [])
                return
            end
            
            if clickedAx == this.treeAxes
                % Switch frame.
                this.WindowButtonDownFcn_Tree(aObj, aEvent)
            else
                if get(this.connectButton, 'Value') ||...
                        get(this.addButton, 'Value') ||...
                        get(this.continuousAddButton, 'Value') ||...
                        get(this.moveButton, 'Value') ||...
                        get(this.moveMitosisButton, 'Value') ||...
                        get(this.deleteButton, 'Value') ||...
                        get(this.disappearButton, 'Value') ||...
                        get(this.childButton, 'Value') ||...
                        get(this.childSplitButton, 'Value') ||...
                        get(this.trackSplitButton, 'Value') ||...
                        get(this.splitButton, 'Value')
                    % Edit tracks.
                    this.WindowButtonDownFcn_Tracks(aObj, aEvent)
                elseif get(this.editSegmentsButton, 'Value') ||...
                        get(this.continuousDrawButton, 'Value')
                    % Edit segments.
                    this.WindowButtonDownFcn_Segments(aObj, aEvent)
                elseif get(this.colorButton, 'Value') || get(this.selectButton, 'Value')
                    % Change the color of a cell.
                    this.WindowButtonDownFcn_Color(aObj, aEvent)
                end
            end
        end
        
        function WindowButtonDownFcn_Color(this, ~, ~)
            % Colors clicked cells temporarily or permanently.
            %
            % If the cell selection tool is selected, the clicked cell is
            % colored orange and the other cells are colored blue. When the
            % cell selection tool is un-selected the cells get their
            % original colors back. If the single cell coloring tool is
            % selected, the clicked cell is colored permanently in the
            % color specified in the text box next to the button of the
            % tool. Only the cells which change color are re-drawn by the
            % Draw function.
            %
            % See also:
            % WindowButtonDownFcn, SelectButtonOn, SelectButtonOff, Draw
            
            % Get the coordinate of the click.
            clickedAx = gca;
            xy = get(clickedAx, 'CurrentPoint');
            x = xy(1,1);
            y = xy(1,2);
            
            if ~InsideAxes(clickedAx, x, y)
                % Don't do anything if the user clicked outside the axes.
                return
            end
            
            % Find the cell which is closest to the click in this frame.
            alive = AliveCells(AreCells(this.cells), this.frame);
            if isempty(alive)
                % Don't do anything if there are no cells in this frame.
                return
            end
            closestCell = [];
            minDist = inf;
            for cellNum = 1:length(alive)
                switch clickedAx
                    case this.ax
                        dist = norm([x y] -...
                            [alive(cellNum).GetCx(this.frame)...
                            alive(cellNum).GetCy(this.frame)]);
                    case this.axXZ
                        dist = norm([x y] -...
                            [alive(cellNum).GetCx(this.frame)...
                            alive(cellNum).GetCz(this.frame)]);
                    case this.axYZ
                        dist = norm([x y] -...
                            [alive(cellNum).GetCz(this.frame)...
                            alive(cellNum).GetCy(this.frame)]);
                end
                if dist < minDist
                    closestCell = alive(cellNum);
                    minDist = dist;
                end
            end
            
            if get(this.selectButton, 'Value')
                % Color cells temporarily using the selection tool.
                areCells = AreCells(this.cells);
                editedIndices = false(size(areCells));  % Cells which change color.
                for i = 1:length(areCells)
                    if any(areCells(i).color ~= [0 0 1])
                        % Color other cells blue if they are not already
                        % blue.
                        areCells(i).color = [0 0 1];
                        editedIndices(i) = true;
                    end
                end
                % Color the clicked cell orange.
                closestCell.color = [1 0.5 0];
                editedIndices(areCells == closestCell) = true;
                updateCells = areCells(editedIndices);
            else
                % Color cells permanently using the single cell coloring
                % tool.
                closestCell.color = str2num(get(this.colorTextBox, 'String')); %#ok<ST2NM>
                closestCell.coloring = 'manual';
                updateCells = closestCell;
                this.edited = true;
            end
            
            this.Draw('EditedCells', updateCells)
            this.DrawTree()
        end
        
        function WindowButtonDownFcn_Segments(this, aObj, ~)
            % Executed when the user clicks to start editing an outline.
            %
            % This function is called when the user presses down a mouse
            % button to edit the outline of a cell. The Blob which overlaps
            % with the editing brush in most pixels is selected for
            % editing. Left-clicking adds pixels to the selected blob and
            % right-clicking erases pixels from it. The user can hold down
            % the mouse button and drag to create or remove a region larger
            % than the editing brush. The actual editing is done in
            % WindowButtonMotionFcn_Segments. Editing is done to
            % super-blobs which may contain multiple cells. If the
            % continuous drawing tool is used, no Blob is selected for
            % editing. Instead, a new blob is created in the same way as
            % when the user starts drawing in the background.
            %
            % Inputs:
            % aObj - this.mainFigure
            %
            % See also:
            % WindowButtonDownFcn, WindowButtonMotionFcn,
            % WindowButtonMotionFcn_Segments, WindowButtonUpFcn_Segments
            
            clickedAx = gca;
            % Get the coordinate of the click.
            xy = get(clickedAx, 'CurrentPoint');
            if ~InsideAxes(clickedAx, xy(1,1), xy(1,2))
                % Don't do anything if the user clicked outside the axes.
                return
            end
            if this.GetImData().GetDim() == 3
                switch this.brush.GetView()
                    case 'xy'
                        if this.volumeSettingsPanel.GetValue('z_proj')
                            errordlg('Uncheck z proj. to draw.', 'Error drawing')
                            return
                        end
                    case 'xz'
                        if this.volumeSettingsPanel.GetValue('y_proj')
                            errordlg('Uncheck y proj. to draw.', 'Error drawing')
                            return
                        end
                    case 'yz'
                        if this.volumeSettingsPanel.GetValue('x_proj')
                            errordlg('Uncheck x proj. to draw.', 'Error drawing')
                            return
                        end
                end
            end
            
            this.drawDown = true;
            this.drawBlob = [];
            
            if get(this.editSegmentsButton, 'Value')
                % Find the blob which overlaps with the brush in most pixels.
                maxOverlap = 0;
                for bIndex = 1:length(this.blobSeq{this.frame})
                    b = this.blobSeq{this.frame}(bIndex);
                    if ~any(isnan(b.boundingBox))
                        overlap = Overlap(b, this.brush);
                    else
                        % Point blobs are said to overlap with the brush in one
                        % pixel if they are inside the brush.
                        if this.GetImData().GetDim() == 2
                            overlap = this.brush.IsInside(b.centroid(1), b.centroid(2));
                        else
                            overlap = this.brush.IsInside(...
                                b.centroid(1), b.centroid(2), b.centroid(3));
                        end
                    end
                    if overlap > maxOverlap
                        this.drawBlob = b;
                        maxOverlap = overlap;
                    end
                end
                
                if this.GetImData().GetDim() == 3 && maxOverlap == 0
                    % Look for overlaps in neighboring slices.
                    for shift = [-1 1]
                        shiftedBrush = this.brush.Clone();
                        shiftedBrush.Shift(shift)
                        for bIndex = 1:length(this.blobSeq{this.frame})
                            b = this.blobSeq{this.frame}(bIndex);
                            if ~any(isnan(b.boundingBox))
                                overlap = Overlap(b, shiftedBrush);
                            else
                                % Point blobs are said to overlap with the
                                % brush in one pixel if they are inside the
                                % brush.
                                overlap = shiftedBrush.IsInside(...
                                    b.centroid(1), b.centroid(2), b.centroid(3));
                            end
                            if overlap > maxOverlap
                                this.drawBlob = b;
                                maxOverlap = overlap;
                            end
                        end
                    end
                end
            end
            
            % Create a binary mask that will take all of the drawings.
            this.drawMask = zeros(...
                this.GetImData().imageHeight,...
                this.GetImData().imageWidth,...
                this.GetImData().numZ);
            if ~isempty(this.drawBlob)
                bb = this.drawBlob.boundingBox;
                if ~any(isnan(bb))
                    % Insert the preexisting blob into the drawing mask.
                    if length(bb) == 4
                        this.drawMask(...
                            bb(2)+0.5:bb(2)+bb(4)-0.5,...
                            bb(1)+0.5:bb(1)+bb(3)-0.5) =...
                            this.drawBlob.image;
                    else % length(bb) == 6
                        this.drawMask(...
                            bb(2)+0.5:bb(2)+bb(5)-0.5,...
                            bb(1)+0.5:bb(1)+bb(4)-0.5,...
                            bb(3)+0.5:bb(3)+bb(6)-0.5) =...
                            this.drawBlob.image;
                    end
                end
            end
            
            % Right-clicking erases from the existing blob.
            this.drawValue = ~strcmp(get(aObj,'SelectionType'),'alt');
            
            % The motion function does all the drawing.
            this.WindowButtonMotionFcn(aObj, [])
        end
        
        function WindowButtonDownFcn_Tracks(this, aObj, ~)
            % Executes when the user clicks to edit the tracks of cells.
            %
            % The actual editing of the cell tracks is done in functions
            % starting with 'EditTracks_'. This function prepares for the
            % track edits by determining which cell and super-blob the user
            % clicked on, creating a new cell where the use clicked, and
            % calling the appropriate track edit function. If some kind of
            % linking tool is used, this function will be called once when
            % the user clicks on the track node of a cell in the previous
            % image and once when the user clicks on a track node in the
            % current image. The linking tool will then connect the two
            % nodes with a link representing migration or mitosis. Tools
            % that operate on a single track require that the user clicks
            % on a cell node in the current image. All clicks need to be
            % within 10 pixels of the cell nodes for edits to take place.
            % To save time, only the tracks of cells affected by the edits
            % will be re-drawn by the Draw function. The lineage tree on
            % the other hand will be re-drawn completely, so it makes sense
            % to hide the lineage tree when an image sequence with a lot of
            % cells is corrected.
            %
            % Inputs:
            % aObj - this.mainFigure
            %
            % See also:
            % WindowButtonDownFcn, WindowButtonDownFcn_Segments
            
            % Get the coordinate of the click.
            clickedAx = gca;
            xy = get(clickedAx, 'CurrentPoint');
            if ~InsideAxes(clickedAx, xy(1,1), xy(1,2))
                % Don't do anything if the user clicked outside the axes.
                return
            end
            % Don't allow adding of cells in maximum intensity projections.
            if this.GetImData().GetDim() == 3
                if (get(this.addButton, 'Value') ||...
                        (get(this.continuousAddButton, 'Value') &&...
                        ~isempty(this.fromCell))) ||...
                        (get(this.moveButton, 'Value') &&...
                        ~isempty(this.fromCell)) &&...
                        this.GetImData().GetDim() == 3
                    switch clickedAx
                        case this.ax
                            if this.volumeSettingsPanel.GetValue('z_proj')
                                errordlg('Uncheck z proj. to make edit.',...
                                    'Error making edit')
                                return
                            end
                        case this.axXZ
                            if this.volumeSettingsPanel.GetValue('y_proj')
                                errordlg('Uncheck y proj. to make edit.',...
                                    'Error making edit')
                                return
                            end
                        case this.axYZ
                            if this.volumeSettingsPanel.GetValue('x_proj')
                                errordlg('Uncheck x proj. to make edit.',...
                                    'Error making edit')
                                return
                            end
                    end
                end
            end
            
            [x, y, z] = this.GetXYZ(clickedAx);
            
            % If we don't have a cell to build on, we look for cells in the
            % previous frame. Otherwise we look for cells to connect to the
            % cell we already have.
            if isempty(this.fromCell) &&...
                    (get(this.connectButton, 'Value') ||...
                    get(this.childButton, 'Value') ||...
                    get(this.childSplitButton, 'Value') ||...
                    get(this.trackSplitButton, 'Value'))
                clickFrame = max(1, this.frame-1);
            else
                clickFrame = this.frame;
            end
            
            % Find the cell in the correct frame, closest to the click.
            alive = AliveCells(this.cells, clickFrame);
            [x1, x2, y1, y2, z1, z2] = this.GetZoom();
            isSliced = false;
            switch clickedAx
                case this.ax
                    if ~this.volumeSettingsPanel.GetValue('z_proj')
                        z1 = this.z;
                        z2 = this.z;
                        isSliced = true;
                    end
                case this.axXZ
                    if ~this.volumeSettingsPanel.GetValue('y_proj')
                        y1 = this.y;
                        y2 = this.y;
                        isSliced = true;
                    end
                case this.axYZ
                    if ~this.volumeSettingsPanel.GetValue('x_proj')
                        x1 = this.x;
                        x2 = this.x;
                        isSliced = true;
                    end
            end
            if this.IsZoomed() || isSliced
                alive = CropCells(alive,...
                    this.frame-this.tLength+1, this.frame,...
                    x1, x2, y1, y2, z1, z2);
            end
            
            closestCell = [];
            minDist = inf;
            for cellNum = 1:length(alive)
                switch clickedAx
                    case this.ax
                        dist = norm([x y] -...
                            [alive(cellNum).GetCx(clickFrame)...
                            alive(cellNum).GetCy(clickFrame)]);
                    case this.axXZ
                        dist = norm([x z] -...
                            [alive(cellNum).GetCx(clickFrame)...
                            alive(cellNum).GetCz(clickFrame)]);
                    case this.axYZ
                        dist = norm([z y] -...
                            [alive(cellNum).GetCz(clickFrame)...
                            alive(cellNum).GetCy(clickFrame)]);
                end
                
                if dist < minDist
                    closestCell = alive(cellNum);
                    minDist = dist;
                end
            end
            
            % Find the segment that the user clicked in. Create a new empty
            % blob if the user did not click in a blob.
            blobs = this.blobSeq{this.frame};
            closestBlob = [];
            if this.GetImData().GetDim() == 2
                for cbIndex = 1:length(blobs)
                    if blobs(cbIndex).IsInside(x,y)
                        closestBlob = blobs(cbIndex);
                        break
                    end
                end
            else
                for cbIndex = 1:length(blobs)
                    if blobs(cbIndex).IsInside(x,y,z)
                        closestBlob = blobs(cbIndex);
                        break
                    end
                end
            end
            if isempty(closestBlob)
                if this.GetImData().GetDim() == 2
                    closestBlob = Blob(struct(...
                        'BoundingBox', nan(1,4),...
                        'Image', nan,...
                        'Centroid', [x y]),...
                        't', this.frame,...
                        'index', length(this.blobSeq{this.frame})+1);
                else
                    closestBlob = Blob(struct(...
                        'BoundingBox', nan(1,6),...
                        'Image', nan,...
                        'Centroid', [x y z]),...
                        't', this.frame,...
                        'index', length(this.blobSeq{this.frame})+1);
                end
            end
            
            % New cell created by a user click. Not always used.
            createdCell = Cell(...
                'imageData', this.GetImData(),...
                'firstFrame', this.frame,...
                'lifeTime', 1,...
                'blob', closestBlob.CreateSub(),...
                'cx', closestBlob.centroid(1),...
                'cy', closestBlob.centroid(2),...
                'notes', 1);
            if this.GetImData().GetDim() == 3
                createdCell.cz = closestBlob.centroid(3);
            end
            
            % Do not pick up cells far from the clicked point.
            if minDist > 10 &&...
                    ~get(this.addButton, 'Value') &&...
                    ~get(this.continuousAddButton, 'Value') &&...
                    ~(get(this.moveButton, 'Value') && ~isempty(this.fromCell))
                this.fromCell = [];
                return
            end
            
            rightButton = ~strcmp(get(aObj,'SelectionType'), 'normal');  % True if right-click.
            
            % Call the the appropriate function to edit the cell tracks.
            editedCells = [];
            if get(this.connectButton, 'Value') ||...
                    get(this.continuousAddButton, 'Value') ||...
                    get(this.trackSplitButton, 'Value')
                editedCells = this.EditTracks_Connect(closestCell, createdCell, clickFrame);
            elseif get(this.addButton, 'Value')
                this.EditTracks_AddCell(createdCell)
            elseif get(this.moveButton, 'Value')
                this.EditTracks_MoveCell(createdCell, closestCell)
            elseif get(this.moveMitosisButton, 'Value')
                editedCells = this.EditTracks_MoveMitosis(closestCell);
            elseif get(this.deleteButton, 'Value')
                editedCells = this.EditTracks_DeleteCell(closestCell, rightButton, clickFrame);
            elseif get(this.disappearButton, 'Value')
                editedCells = this.EditTracks_Disappear(closestCell);
            elseif get(this.childButton, 'Value') || get(this.childSplitButton, 'Value')
                editedCells = this.EditTracks_AddChild(closestCell, clickFrame);
            elseif get(this.splitButton, 'Value')
                this.EditTracks_SplitCell(closestCell)
            end
            
            % Update the segmentation based on the new tracks (only up to
            % the current frame).
            this.ColorCells()
            
            % Update the figure.
            this.Draw('EditedCells', editedCells)
            this.DrawTree()
            this.WindowButtonMotionFcn(aObj, [])
            
            this.edited = true;
        end
        
        function WindowButtonDownFcn_Tree(this, ~, ~)
            % Executes when the user clicks in the lineage tree.
            %
            % When the user clicks in the lineage tree, this function goes
            % to the frame corresponding to the time point where the user
            % clicked. If the selection tool is selected, the function
            % colors the cell closest to the click (on the horizontal axis)
            % orange and all other cells blue. The cells are colored both
            % in the lineage tree and in the images with tracks. The
            % function will make Draw re-draw the tracks of all cells, even
            % if their colors are not changed.
            %
            % See also:
            % WindowButtonDownFcn, WindowButtonDownFcn_Tracks,
            % WindowButtonDownFcn_Segments
            
            % Get the coordinate where the user clicked.
            xy = get(this.treeAxes, 'CurrentPoint');
            x = xy(1,1);
            y = xy(1,2);
            
            if ~InsideAxes(this.treeAxes, x, y)
                % Don't do anything if the user clicked outside the axes.
                return
            end
            
            % Convert the x-coordinate to a frame index.
            switch this.tree
                case {'Frames', 'Frames (Separate Window)'}
                    newFrame = round(x);
                case {'Hours', 'Hours (Separate Window)'}
                    newFrame = round((x - this.GetImData().Get('startT')) /...
                        this.GetImData().dT * 3600);
                otherwise
                    return
            end
            
            % Switch to the desired frame.
            newFrame = max(newFrame, get(this.slider, 'Min'));
            newFrame = min(newFrame, get(this.slider, 'Max'));
            this.frame = newFrame;
            
            % Change the colors of cells if the select tool is selected.
            if get(this.selectButton, 'Value')
                areCells = AliveCells(this.cells, this.frame);
                
                % Find the cell closest to the click on the horizontal
                % axis of the linage tree.
                minDist = inf;
                for cellNum = 1:length(areCells)
                    Y2Val = abs(areCells(cellNum).Y2 - y);
                    if Y2Val < minDist
                        closestCell = areCells(cellNum);
                        minDist = Y2Val;
                    end
                end
                
                areCells = AreCells(this.cells);
                for i = 1:length(areCells)
                    % Color all cells blue.
                    areCells(i).color = [0 0 1];
                end
                % Color the clicked cell orange.
                closestCell.color = [1 0.5 0];
            end
            
            % Update the tracks and the lineage tree.
            this.Draw()
            this.DrawTree()
        end
        
        function WindowButtonMotionFcn(this, aObj, aEvent)
            % Executes when the mouse cursor is moved.
            %
            % The function forwards the call to different functions
            % depending on which tool is used. There are separate
            % functions for editing of tracks, editing of segments and
            % zooming.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - []
            %
            % See also:
            % WindowButtonMotionFcn_Segments, WindowButtonMotionFcn_Tracks
            
            if get(this.zoomButton, 'Value') || this.panning
                clickedAx = gca;
                if clickedAx == this.treeAxes
                    this.WindowButtonMotionFcn@ZControlPlayer(aObj, [],...
                        'PixelAxes', false)
                else
                    this.WindowButtonMotionFcn@ZControlPlayer(aObj, [])
                end
            elseif get(this.editSegmentsButton, 'Value') ||...
                    get(this.continuousDrawButton, 'Value')
                this.WindowButtonMotionFcn_Segments(aObj, aEvent)
            else
                this.WindowButtonMotionFcn_Tracks(aObj, aEvent)
            end
        end
        
        function WindowButtonMotionFcn_Segments(this, ~, ~)
            % Executes when the cursor is moved during editing of segments.
            %
            % This will alter the region which is being edited, draw the
            % region which is being edited and draw the editing brush. The
            % segmentation editing tool is explained in
            % WindowButtonDownFcn_Segments.
            %
            % See also:
            % WindowButtonMotionFcn, WindowButtonDownFcn_Segments,
            % WindowButtonUpFcn_Segments
            
            h = this.GetImData().imageHeight;
            w = this.GetImData().imageWidth;
            d = this.GetImData().numZ;
            
            % Delete the old brush and the old outline of the region.
            if ~isempty(this.lines)
                for i = 1:length(this.lines)
                    if ishandle(this.lines(i))
                        delete(this.lines(i))
                    end
                end
                this.lines = [];
            end
            
            % Get the current cursor coordinates.
            if this.GetImData().GetDim() == 2
                currAx = this.ax;
                [x, y, ~, xy] = this.GetXYZ(currAx);
                x = round(x);
                y = round(y);
            else
                if this.drawDown
                    switch this.brush.GetView()
                        case 'xy'
                            currAx = this.ax;
                        case 'xz'
                            currAx = this.axXZ;
                        case 'yz'
                            currAx = this.axYZ;
                    end
                else
                    currAx = this.GetCurrAx();
                    if isempty(currAx)
                        return
                    end
                    switch currAx
                        case this.ax
                            this.brush.SetView('xy')
                        case this.axXZ
                            this.brush.SetView('xz')
                        case this.axYZ
                            this.brush.SetView('yz')
                    end
                end
                [x, y, z, xy] = this.GetXYZ(currAx);
                x = round(x);
                y = round(y);
                z = round(z);
            end
            
            % Edit the brush blob.
            if this.GetImData().GetDim() == 2
                this.brush.SetXY(x,y);
            else
                this.brush.SetXYZ(x,y,z)
            end
            
            % Edit the current region.
            if this.drawDown
                % The current region is not changed if the cursor is
                % outside the image. The region must however always to be
                % redrawn.
                
                % Change the current region.
                if InsideAxes(currAx, xy(1,1), xy(1,2))
                    if ~isempty(this.prevBrush)
                        if this.GetImData().GetDim() == 2
                            combinedBrush = CombineBlobs(this.prevBrush, this.brush,...
                                'FillCracks', false);
                        else
                            combinedBrush = CombineBlobs3D(this.prevBrush, this.brush,...
                                'FillCracks', false);
                        end
                        ConvexAllBlobs(combinedBrush, this.GetImData())
                    else
                        combinedBrush = this.brush;
                    end
                    this.prevBrush = this.brush.Clone();
                    
                    if this.GetImData().GetDim() == 2
                        [px, py] = combinedBrush.GetPixelCoordinates();
                        ind = sub2ind([h w], py, px);
                    else
                        [px, py, pz] = combinedBrush.GetPixelCoordinates();
                        ind = sub2ind([h w d], py, px, pz);
                    end
                    this.drawMask(ind) = this.drawValue; % Draw on the current region.
                end
                
                % Draw the current region.
                if this.GetImData().GetDim() == 2
                    mask = this.drawMask;
                else
                    switch this.brush.GetView()
                        case 'xy'
                            mask = this.drawMask(:,:,this.z);
                        case 'xz'
                            mask = permute(this.drawMask(this.y, :, :), [3 2 1]);
                        case 'yz'
                            mask = squeeze(this.drawMask(:, this.x, :));
                    end
                end
                if strcmp(this.drawHole, 'Allow Holes (CTRL+A)')
                    maskBoundaries = GetBoundaries(mask, 'AllowHoles', true);
                else
                    maskBoundaries = GetBoundaries(mask);
                end
                for i = 1:length(maskBoundaries)
                    p1 = plot(currAx, maskBoundaries{i}(:,2), maskBoundaries{i}(:,1), 'g');
                    this.lines = [this.lines p1];
                end
            end
            
            % Draw the brush.
            if InsideAxes(currAx, xy(1,1), xy(1,2))
                if this.GetImData().GetDim() == 2
                    brushBoundary = GetBoundaries(this.brush);
                else
                    [bx, by, bz] = this.brush.GetPixelCoordinates();
                    switch this.brush.GetView()
                        case 'xy'
                            brushMask = zeros(h,w);
                            brushMask(sub2ind([h w], by, bx)) = 1;
                        case 'xz'
                            brushMask = zeros(d,w);
                            brushMask(sub2ind([d w], bz, bx)) = 1;
                        case 'yz'
                            brushMask = zeros(h,d);
                            brushMask(sub2ind([h d], by, bz)) = 1;
                    end
                    brushBoundary = GetBoundaries(brushMask);
                end
                
                if isempty(brushBoundary)
                    return
                end
                
                edgex = brushBoundary{1}(:,2);
                edgey = brushBoundary{1}(:,1);
                
                % Don't plot anything if all lines are outside the image.
                if all(edgex < 0.5) || all(edgex > w+0.5) ||...
                        all(edgey < 0.5) || all(edgey > h+0.5)
                    return
                end
                
                if ~isempty(edgex)
                    p3 = plot(currAx, edgex, edgey, 'r');  % Plot brush.
                    this.lines = [this.lines p3];
                end
                
                if ~isempty(this.fromCell)
                    if this.fromCell.firstFrame < this.frame
                        switch currAx
                            case this.ax
                                x1 = this.fromCell.GetCx(this.frame-1);
                                y1 = this.fromCell.GetCy(this.frame-1);
                            case this.axXZ
                                x1 = this.fromCell.GetCx(this.frame-1);
                                y1 = this.fromCell.GetCz(this.frame-1);
                            case this.axYZ
                                x1 = this.fromCell.GetCz(this.frame-1);
                                y1 = this.fromCell.GetCy(this.frame-1);
                        end
                    else
                        % this.fromCell should appear before the current frame,
                        % but if this is not the case for some reason, this
                        % if/else-statement prevents an error from occurring.
                        x1 = [];
                        y1 = [];
                    end
                    
                    % Select the color to draw with.
                    if this.fromCell.isCell
                        color = this.fromCell.color;
                    else
                        % False positives are always black but can be displayed
                        % in a different color in the GUI.
                        color = str2num(get(this.fpColorTextBox, 'String')); %#ok<ST2NM>
                    end
                    
                    newLine = plot(currAx, [x1 x], [y1 y], 'Color', color);
                    this.lines = [this.lines newLine];
                end
            end
        end
        
        function WindowButtonMotionFcn_Tracks(this, ~, ~)
            % Executes when the cursor is moved during editing of tracks.
            %
            % When the user is connecting a cell node in the previous frame
            % to a cell node in the current frame, this function will draw
            % a line between the node in the previous frame and the cursor
            % to indicate that a link is about to be made. When the Add
            % tool or the Continuous Add tool are used, this function will
            % display a blue dot under the cursor, indicating that a new
            % cell node is about to be created.
            %
            % See also:
            % WindowButtonMotionFcn, WindowButtonMotionFcn_Segments
            
            % Delete lines and dots that were drawn the last time the
            % function was called.
            if ~isempty(this.lines)
                for i = 1:length(this.lines)
                    if ishandle(this.lines(i))
                        delete(this.lines)
                    end
                end
                this.lines = [];
            end
            
            currAx = this.GetCurrAx();
            if isempty(currAx)
                % Don't plot anything if the cursor is outside the axes.
                return
            end
            
            xy = get(currAx, 'CurrentPoint');
            x2 = xy(1,1);
            y2 = xy(1,2);
            
            if ~isempty(this.fromCell)
                if this.fromCell.firstFrame < this.frame
                    switch currAx
                        case this.ax
                            x1 = this.fromCell.GetCx(this.frame-1);
                            y1 = this.fromCell.GetCy(this.frame-1);
                        case this.axXZ
                            x1 = this.fromCell.GetCx(this.frame-1);
                            y1 = this.fromCell.GetCz(this.frame-1);
                        case this.axYZ
                            x1 = this.fromCell.GetCz(this.frame-1);
                            y1 = this.fromCell.GetCy(this.frame-1);
                    end
                else
                    % this.fromCell should appear before the current frame,
                    % but if this is not the case for some reason, this
                    % if/else-statement prevents an error from occurring.
                    x1 = [];
                    y1 = [];
                end
                
                % Select the color to draw with.
                if this.fromCell.isCell
                    color = this.fromCell.color;
                else
                    % False positives are always black but can be displayed
                    % in a different color in the GUI.
                    color = str2num(get(this.fpColorTextBox, 'String')); %#ok<ST2NM>
                end
                
                newLine = plot(currAx, [x1 x2], [y1 y2], 'Color', color);
                this.lines = [this.lines newLine];
            else
                color = 'b';
            end
            
            % Draw a filled circle under the cursor when the user is
            % creating new cell centroids.
            if get(this.addButton, 'Value') ||...
                    get(this.continuousAddButton, 'Value') ||...
                    (get(this.moveButton, 'Value') && ~isempty(this.fromCell))
                newLine = plot(currAx, x2, y2, 'o',...
                    'MarkerEdgeColor', color,...
                    'MarkerFaceColor', color,...
                    'MarkerSize', 5);
                this.lines = [this.lines newLine];
            end
        end
        
        function WindowButtonUpFcn(this, aObj, aEvent)
            % Executes when a mouse button is released.
            %
            % The function forwards the call to different functions
            % depending on which tool is used. There are separate
            % functions for editing of segments and zooming.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - []
            %
            % See also:
            % WindowButtonUpFcn_Segments
            
            clickedAx = gca;
            
            if this.panning
                if clickedAx == this.treeAxes
                    changed = this.WindowButtonUpFcn@SequencePlayer(aObj, [],...
                        'PixelAxes', false);
                else
                    changed = this.WindowButtonUpFcn@SequencePlayer(aObj, []);
                end
                
                if changed && this.GetImData().GetDim() == 3
                    this.Draw3D()
                end
            elseif get(this.zoomButton, 'Value')
                if clickedAx == this.treeAxes
                    this.WindowButtonUpFcn@ZControlPlayer(aObj, [],...
                        'PixelAxes', false)
                else
                    this.WindowButtonUpFcn@ZControlPlayer(aObj, [])
                end
            elseif (get(this.editSegmentsButton, 'Value')  ||...
                    get(this.continuousDrawButton, 'Value')) &&...
                    clickedAx ~= this.treeAxes
                this.WindowButtonUpFcn_Segments(aObj, aEvent)
            end
        end
        
        function WindowButtonUpFcn_Segments(this, aObj, ~)
            % Runs when a mouse button is released while editing segments.
            %
            % This will perform edits to all the blobs and cells that are
            % be affected by the most recent editing. To save time, only
            % the edited cells will be re-drawn by the Draw function.
            %
            % Inputs:
            % aObj - this.mainFigure
            %
            % See also:
            % WindowButtonDownFcn_Segments, WindowButtonMotionFcn_Segments
            
            if ~this.drawDown
                % If the user clicked outside the axes, drawDown will not
                % be true, and nothing needs to be done.
                return
            end
            
            this.drawDown = false;
            this.prevBrush = [];
            aliveCells = AliveCells(this.cells, this.frame);
            editedCells = [];
            
            % Fill holes in the drawing mask.
            if strcmp(this.drawHole, 'Fill Holes (CRTL+I)')
                if this.GetImData().GetDim() == 2
                    this.drawMask = imfill(this.drawMask, 'holes');
                else
                    conn = zeros(3,3,3);
                    switch this.brush.GetView()
                        case 'xy'
                            conn(1:3, 2, 2) = 1;
                            conn(2, 1:3, 2) = 1;
                        case 'xz'
                            conn(2, 1:3, 2) = 1;
                            conn(2, 2, 1:3) = 1;
                        case 'yz'
                            conn(1:3, 2, 2) = 1;
                            conn(2, 2, 1:3) = 1;
                    end
                    this.drawMask = imfill(this.drawMask, conn, 'holes');
                end
            end
            
            % Create new Blob objects.
            if this.drawValue
                % Create a single blob.
                newBlobs = Blob(this.drawMask, 't', this.frame);
            else
                % Create one blob for each connected component.
                rawProps = regionprops(...
                    logical(this.drawMask),...
                    'BoundingBox',...
                    'Image',...
                    'Centroid');
                if ~isempty(rawProps)
                    newBlobs(length(rawProps)) = Blob();
                    for rpIndex = 1:length(rawProps)
                        props = rawProps(rpIndex);
                        newBlobs(rpIndex) = Blob(props, 't', this.frame);
                    end
                else
                    newBlobs = [];
                end
            end
            
            % Find cells in drawBlob.
            % Find blobs which were drawn on, except drawBlob.
            changedBlobs = [];
            if this.drawValue
                for bIndex = 1:length(this.blobSeq{this.frame})
                    b = this.blobSeq{this.frame}(bIndex);
                    if ~any(isnan(b.boundingBox))
                        overlap = Overlap(newBlobs, b);
                    else
                        % Point blobs are said to overlap with the brush in
                        % one pixel if they are inside the brush.
                        if this.GetImData().GetDim() == 2
                            overlap = newBlobs.IsInside(...
                                b.centroid(1), b.centroid(2));
                        else
                            overlap = newBlobs.IsInside(...
                                b.centroid(1), b.centroid(2), b.centroid(3));
                        end
                    end
                    if overlap > 0
                        changedBlobs = [changedBlobs b]; %#ok<AGROW>
                    end
                end
            else
                changedBlobs = this.drawBlob;
            end
            
            % Find cells in changedBlobs
            changedCells = [];
            for i = 1:length(aliveCells)
                c = aliveCells(i);
                b = c.GetBlob(this.frame).super;
                if any(changedBlobs == b)
                    changedCells = [changedCells c]; %#ok<AGROW>
                end
            end
            
            if this.drawValue && ~isempty(changedBlobs)
                if ~strcmp(this.drawMerge, 'Overwrite (CTRL+O)')
                    refill = false;
                    for i = 1:length(changedBlobs)
                        if ~any(isnan(changedBlobs(i).boundingBox)) &&...
                                (isempty(this.drawBlob) ||...
                                changedBlobs(i) ~= this.drawBlob)
                            if this.GetImData().GetDim() == 2
                                CombineBlobs(newBlobs, changedBlobs(i));
                            else
                                CombineBlobs3D(newBlobs, changedBlobs(i));
                            end
                            refill = true;
                        end
                    end
                    if refill && strcmp(this.drawHole, 'Fill Holes (CRTL+I)')
                        newBlobs.image = imfill(newBlobs.image,'holes');
                    end
                end
                
                switch this.drawMerge
                    case 'Re-break (CRTL+R)'
                        cellAreas = zeros(size(changedCells));
                        for i = 1:length(changedCells)
                            cellAreas(i) = sum(changedCells(i).GetBlob(this.frame).image(:));
                        end
                        if any([changedCells.isCell])
                            for i = 1:length(changedCells)
                                if changedCells(i).isCell
                                    changedCells(i).SetBlob(newBlobs.CreateSub(), this.frame)
                                else
                                    RemoveOutlines(changedCells(i), this.frame);
                                end
                            end
                        else
                            [~, keepIndex] = max(cellAreas);
                            changedCells(keepIndex).SetBlob(newBlobs.CreateSub(), this.frame)
                            discardCells = changedCells;
                            discardCells(keepIndex) = [];
                            RemoveOutlines(discardCells, this.frame);
                        end
                        % The breaking is handled by the segmentation
                        % update.
                    case 'Combine (CRTL+M)'
                        cellAreas = zeros(size(changedCells));
                        for i = 1:length(changedCells)
                            cellAreas(i) = sum(changedCells(i).GetBlob(this.frame).image(:));
                        end
                        if any([changedCells.isCell])
                            cellAreas(~[changedCells.isCell]) = -inf;
                        end
                        [~, keepIndex] = max(cellAreas);
                        changedCells(keepIndex).SetBlob(newBlobs.CreateSub(), this.frame)
                        discardCells = changedCells;
                        discardCells(keepIndex) = [];
                        RemoveOutlines(discardCells, this.frame);
                        for i = 1:length(discardCells)
                            discardCells(i).isCell = false;
                            % The super blob needs to be set in case the
                            % cell is undeleted later.
                            discardCells(i).GetBlob(this.frame).super = newBlobs;
                        end
                    case 'Overwrite (CTRL+O)'
                        if this.GetImData().GetDim() == 2
                            [x,y] = newBlobs.GetPixelCoordinates();
                            ind = sub2ind(this.GetImData().GetSize(), y, x);
                        else
                            [x,y,z] = newBlobs.GetPixelCoordinates();
                            ind = sub2ind(this.GetImData().GetSize(), y, x, z);
                        end
                        for i = 1:length(changedBlobs)
                            if ~any(isnan(changedBlobs(i).boundingBox)) &&...
                                    (isempty(this.drawBlob) || changedBlobs(i) ~= this.drawBlob)
                                RemoveBlobPixels(changedBlobs(i), ind, this.GetImData())
                            end
                        end
                        for i = 1:length(changedCells)
                            if ~isempty(this.drawBlob) &&...
                                    changedCells(i).GetBlob(this.frame).super == this.drawBlob
                                changedCells(i).SetBlob(newBlobs.CreateSub(), this.frame)
                            elseif ~changedCells(i).isCell
                                b = changedCells(i).GetBlob(this.frame).super.CreateSub();
                                changedCells(i).SetBlob(b, this.frame)
                            end
                        end
                        if isempty(this.drawBlob)
                            % The user drew a new region in the background.
                            if ~get(this.continuousDrawButton, 'Value')
                                newCell = Cell(...
                                    'imageData', this.GetImData(),...
                                    'firstFrame', this.frame,...
                                    'lifeTime', 1,...
                                    'isCell', strcmp(this.drawBreak, 'Create TP (CTRL+T)'),...
                                    'blob', newBlobs.CreateSub(),...
                                    'cx', newBlobs.centroid(1),...
                                    'cy', newBlobs.centroid(2),...
                                    'notes', 1);
                                if this.GetImData().GetDim() == 3
                                    newCell.cz = newBlobs(bIndex).centroid(3);
                                end
                                this.cells = [this.cells newCell];
                                changedCells = [changedCells newCell];
                            end
                        end
                end
            elseif ~isempty(newBlobs)
                usedBlobs = false(size(newBlobs));
                for i = 1:length(changedCells)
                    dist2s = zeros(length(newBlobs),1);
                    for j = 1:length(newBlobs)
                        dist2s(j) = sum((changedCells(i).GetBlob(this.frame).centroid...
                            - newBlobs(j).centroid).^2);
                    end
                    [~, minIndex] = min(dist2s);
                    changedCells(i).SetBlob(newBlobs(minIndex).CreateSub(), this.frame);
                    usedBlobs(minIndex) = true;
                end
                
                if ~isempty(changedCells) && any([changedCells.positive])
                    pos = true;
                else
                    pos = false;
                end
                for bIndex = 1:length(newBlobs)
                    if ~usedBlobs(bIndex)
                        if ~get(this.continuousDrawButton, 'Value')
                            newCell = Cell(...
                                'imageData', this.GetImData(),...
                                'firstFrame', this.frame,...
                                'lifeTime', 1,...
                                'isCell', strcmp(this.drawBreak, 'Create TP (CTRL+T)'),...
                                'blob', newBlobs(bIndex).CreateSub(),...
                                'cx', newBlobs(bIndex).centroid(1),...
                                'cy', newBlobs(bIndex).centroid(2),...
                                'positive', pos,...
                                'notes', 0);
                            if this.GetImData().GetDim() == 3
                                newCell.cz = newBlobs(bIndex).centroid(3);
                            end
                            this.cells = [this.cells newCell];
                            changedCells = [changedCells newCell]; %#ok<AGROW>
                        end
                    end
                end
            elseif ~isempty(this.drawBlob)
                for cIndex = 1:length(aliveCells)
                    c = aliveCells(cIndex);
                    b = c.GetBlob(this.frame).super;
                    if b == this.drawBlob
                        RemoveOutlines(c, this.frame);
                        if this.GetNumImages() == 1
                            % Turn erased objects into false positives if
                            % the image sequence consists of a single
                            % image.
                            c.isCell = false;
                        end
                        editedCells = [editedCells c]; %#ok<AGROW>
                    end
                end
            else
                % The user just erased on the background.
                return
            end
            
            if get(this.continuousDrawButton, 'Value')
                if isempty(this.fromCell)
                    if ~isempty(changedCells) && any([changedCells.positive])
                        pos = true;
                    else
                        pos = false;
                    end
                    newCell = Cell(...
                        'imageData', this.GetImData(),...
                        'firstFrame', this.frame,...
                        'lifeTime', 1,...
                        'isCell', strcmp(this.drawBreak, 'Create TP (CTRL+T)'),...
                        'blob', newBlobs.CreateSub(),...
                        'cx', newBlobs.centroid(1),...
                        'cy', newBlobs.centroid(2),...
                        'positive', pos,...
                        'notes', 0);
                    if this.GetImData().GetDim() == 3
                        newCell.cz = newBlobs.centroid(3);
                    end
                    this.cells = [this.cells newCell];
                    changedCells = [changedCells newCell];
                    this.fromCell = newCell;
                else
                    this.fromCell.AddFrame(newBlobs.CreateSub());
                    changedCells = [changedCells this.fromCell];
                end
            end
            
            % Recompute this.blobSeq as updating is error prone.
            this.blobSeq{this.frame} = [];
            aliveCells = AliveCells(this.cells, this.frame);
            for i = 1:length(aliveCells)
                sb = aliveCells(i).GetBlob(this.frame).super;
                if ~any(this.blobSeq{this.frame} == sb)
                    this.blobSeq{this.frame} = [this.blobSeq{this.frame} sb];
                    sb.index = length(this.blobSeq{this.frame});
                end
            end
            this.update{this.frame} = false(size(this.blobSeq{this.frame}));
            
            % Update blobs which have at least one real cell.
            for i = 1:length(changedCells)
                this.AddUpdate(changedCells(i), 'Frames', this.frame)
            end
            
            if get(this.continuousDrawButton, 'Value')
                % Go to the next frame, so that the user can draw a chain
                % of outlines without manually switching frame.
                if this.frame < this.GetNumImages()
                    this.frame = this.frame + 1;
                else
                    this.fromCell = [];
                end
                this.Draw()
            else
                % Update the figure.
                this.Draw('EditedCells', editedCells)
            end
            this.DrawTree()
            this.WindowButtonMotionFcn(aObj, [])
            this.edited = true;
        end
        
        function WindowScrollWheelFcn(this, aObj, aEvent)
            % Executes when the mouse scroll wheel is turned.
            %
            % This function will change the radius of the brush for editing
            % of segments if the segmentation editing tool is selected.
            % If you scroll towards you, you make the brush bigger and if
            % you scroll away from you, you make it smaller. You can also
            % make it bigger by pressing + and smaller by pressing -. The
            % radius of the brush cannot be made smaller than 0.5 pixels
            % and cannot be made larger than the largest image dimension
            % divided by 2.
            %
            % Inputs:
            % aObj - this.mainFigure
            % aEvent - Struct with information about how much the user
            %          scrolled.
            %
            % See also:
            % KeyPressFcn
            
            % Don't do anything unless the user is editing segments.
            if ~get(this.editSegmentsButton, 'Value')  &&...
                    ~get(this.continuousDrawButton, 'Value')
                return
            end
            
            r = this.brush.GetR();  % Radius of brush.
            
            % The factor by which the brush radius is changed. The brush
            % radius will change by 10 % or 0.5 pixels depending on what is
            % largest.
            scroll = max(0.10,0.5/r);
            
            if aEvent.VerticalScrollCount > 0
                r = min(r*(1+scroll),...
                    max(this.GetImData().imageHeight,this.GetImData().imageWidth)/2);
            elseif aEvent.VerticalScrollCount < 0
                r = max(r*(1-scroll), 1/2);
            end
            this.brush.SetR(r);
            % Draw the new brush.
            this.WindowButtonMotionFcn_Segments(aObj, [])
        end
    end
end

function varargout = BlobStorage(aFigure, aBlobSeq)
% Stores or returns data for the 'blobSeq' property.
%
% This function stores the 'blobSeq' property of different
% ManualCorrectionPlayer objects in a persistent variable. This is a
% workaround to avoid callback delays in MATLAB 2015b, which occurred when
% there were lots of blobs in the 'blobSeq' property. The 'blobSeq' values
% are stored with the figure object of the player as a key.
%
% Inputs:
% aFigure - The main figure of the player, which will be used as a key.
% aBlobSeq - The 'blobSeq' property of the player. The variable is a cell
%            array where each cell contains the Blob objects that were
%            segmented in the corresponding frame. If this input is given,
%            the function will store a new value. Otherwise the 'blobSeq'
%            value associated with aFigure is returned as an output.
%
% Outputs:
% varargout - If aFigure is given as the only input, the 'blobSeq' value
%             associated with aFigure is returned as an output.
%
% See also:
% CellStorage

persistent figures  % Array of figure objects that are used as keys.
persistent blobSeqs  % Cell array of 'blobSeq' values, associated with the figures.

if nargin == 2
    % Store a new 'blobSeq' value.
    index = find(figures == aFigure);
    if isempty(index)
        figures = [figures aFigure];
        blobSeqs = [blobSeqs {aBlobSeq}];
    else
        blobSeqs{index} = aBlobSeq;
    end
    varargout = {};
else
    % Return a 'blobSeq' value.
    varargout = blobSeqs(figures == aFigure);
end
end

function varargout = CellStorage(aFigure, aCells)
% Stores or returns data for the 'cells' property.
%
% This function stores the 'cells' property of different
% ManualCorrectionPlayer objects in a persistent variable. This is a
% workaround to avoid callback delays in MATLAB 2015b, which occurred when
% there were lots of cells in the 'cells' property. The 'cells' values are
% stored with the figure object of the player as a key.
%
% Inputs:
% aFigure - The main figure of the player, which will be used as a key.
% aBlobSeq - The 'cells' property of the player. The variable is an array
%            of Cell objects. If this input is given, the function will
%            store a new value. Otherwise the 'cells' value associated with
%            aFigure is returned as an output.
%
% Outputs:
% varargout - If aFigure is given as the only input, the 'cells' value
%             associated with aFigure is returned as an output.
%
% See also:
% BlobStorage

persistent figures  % Array of figure objects that are used as keys.
persistent cells  % Cell array of 'cells' values, associated with the figures.

if nargin == 2
    % Store a new 'cells' value.
    index = find(figures == aFigure);
    if isempty(index)
        figures = [figures aFigure];
        cells = [cells {aCells}];
    else
        cells{index} = aCells;
    end
    varargout = {};
else
    % Return a 'cells' value.
    varargout = cells(figures == aFigure);
end
end