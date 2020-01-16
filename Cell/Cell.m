classdef Cell < handle
    % Data structure representing a track.
    %
    % Cell objects hold information about cell tracks, and contain Blob
    % objects that hold information about the segmented cell regions in all
    % frames. The class inherits from handle, so if you pass a Cell object
    % to a function and edit it there, the edits will be made to your
    % object and not to a copy.
    %
    % When a cell divides, the cell splits into two new daughter cells.
    % After that the old cell no longer exists.
    %
    % The cells can be compressed using the method Compress. This removes
    % the Blob objects, so that the cells take less memory. Such objects
    % are faster to read from file.
    %
    % See also:
    % LoadCells, SaveCells, CopyCellVec, Blob
    
    properties
        
        index = nan;                        % Index of the cell in the array of cells that it has been or will be saved to.
        isCompressed = false;               % True for cells where the blobs have been removed to save computation time.
        imageData = [];                     % ImageData object with information about the image sequence.
        blob = [];                          % An array of Blob objects that have information about the cell regions.
        isCell = true;                      % Set to false if the object is a false positive.
        color = [0 0 0];                    % Color used to draw trajectories and other information about the cell.
        coloring = 'default';               % The coloring scheme used to color this particular cell.
        parent = [];                        % Parent of the cell.
        children = [];                      % Array that will store pointers to the two daughter cells created in mitosis.
        firstFrame = nan;                   % The index of the image where the cell first appears. Indexing starts at 1.
        lifeTime = 0;                       % The number of frames in which the cell appears.
        regionProps_compressed = struct();  % Pre-computed region properties of compressed cells.
        disappeared = false;                % True for cells that leave the field of view.
        
        cx = [];                            % x-coordinate of centroid.
        cy = [];                            % y-coordinate of centroid.
        cz = [];                            % z-coordinate of centroid.
        
        notes = [];                         % TO BE REMOVED
        iterations = [];                    % Array that specifies in what Viterbi-iterations the blobs were created. Can be empty.
        
        Y2 = [];                            % Y2 Value on the Lineage Tree
        
        graphics = [];                      % Array of handles to lines and other graphics objects drawn for this cell.
        
        positive = false;                   % True if the cell is positive for a fluorescent marker of interest.
    end % properties
    
    properties (Dependent = true)
        regionProps;                % Array with the region properties (such as area) in all images.
        seqPath;                    % Folder with the image sequence.
        condition;                  % Name of the experimental condition.
        lastFrame;                  % Index of the last image where the cell is present.
        sequenceLength;             % The number of images in the image sequence.
        generation;                 % Cells that are present in the first image are generation 1, their children are generation 2 and so on.
        maxSubFrame;                % The last frame of the cell or its progeny.
        cloneParent;                % The top parent of the lineage tree that the cell is a part of.
        avgSpeed;                   % Speed averaged over the whole cell trajectory.
        avgAxisRatio;               % Axis ratio averaged over the whole cell trajectory.
        avgSize;                    % Size averaged over the whole cell trajectory.
        divisionTime;               % Nan, or the time (in hours) from birth to division.
        timeToFirstDivision;        % Nan, or the time (in hours) from the first image to division (for cells present in first image).
        timeOfBirth;                % The time point when a cell is born.
        lifeSpan;                   % The life time of the cell in hours.
        deltaT;                     % Nan, or the time (in hours) between the division of the cell and the division of the cell's sister.
        timeToDeath;                % Nan, or the time (in hours) that it took for the cell to die.
        divided;                    % True if the cell divided.
        survived;                   % True if the cell survived to the end of the image sequence.
        died;                       % True if the cell died.
        fate;                       % Cell fate. ('divided', 'live', 'dead' or 'disappeared')
        fate_dead_others;           % 'dead' if the cell dies, and 'others' otherwise.
        startT;                     % The time (in hours, after plating the cells) when the imaging experiment started.
        stopT;                      % The time (in hours, after plating the cells) when the imaging experiment ended.
        dT;                         % Time between images in seconds.
    end
    
    methods
        
        function this = Cell(varargin)
            % Constructor generating a Cell object.
            %
            % Property/Value inputs:
            % Valid properties of the Cell class.
            
            for i = 1 : 2 : length(varargin)
                this.(varargin{i}) = varargin{i+1};
            end
            
            if ~any(strcmp(varargin, 'blob'))
                % Generate an empty 2D blob if no blob was specified.
                this.blob = Blob(struct(...
                    'BoundingBox', nan(1,4),...
                    'Image', nan,...
                    'Centroid', nan(1,2)));
            end
        end
        
        function oCell = Clone(this)
            % Returns a deep copy of a cell object.
            %
            % Normal assignment statements only copies the pointer to the
            % cell object.
            
            oCell = Cell(...
                'imageData', this.imageData,...
                'blob', Blob.Copy(this.blob),...
                'firstFrame', this.firstFrame,...
                'lifeTime', this.lifeTime,...
                'cx', this.cx,...
                'cy', this.cy,...
                'cz', this.cz,...
                'isCell', this.isCell,...
                'positive', this.positive,...
                'disappeared', this.disappeared,...
                'color', this.color,...
                'notes', this.notes,...
                'iterations', this.iterations,...
                'isCompressed', this.isCompressed,...
                'regionProps_compressed', this.regionProps_compressed);
        end
        
        function oFilename = get.seqPath(this)
            oFilename = this.imageData.seqPath;
        end
        
        function oExperiment = get.condition(this)
            oExperiment = this.imageData.condition;
        end
        
        function oFrame = get.lastFrame(this)
            oFrame = this.firstFrame + this.lifeTime - 1;
        end
        
        function oSequenceLength = get.sequenceLength(this)
            oSequenceLength = this.imageData.sequenceLength;
        end
        
        function oT = get.dT(this)
            oT = this.imageData.dT;
        end
        
        function oGen = get.generation(this)
            % Generation number of the cell.
            %
            % Cells which are present in the first image belong to
            % generation 1, and then the generation number increases by 1
            % for each cell division.
            
            cell = this;
            oGen = 1;
            while ~isempty(cell.parent)
                cell = cell.parent;
                oGen = oGen + 1;
            end
        end
        
        function oFrame = get.maxSubFrame(this)
            parents = this;
            oFrame = this.lastFrame;
            while true
                ch = [parents.children];
                if isempty(ch)
                    break
                end
                parents = ch;
                oFrame = max([oFrame [ch.lastFrame]]);
            end
        end
        
        function oCloneParent = get.cloneParent(this)
            % Pointer to the root of the cell's lineage tree.
            %
            % The root of the lineage tree is another cell object, but can
            % also be the cell itself, if it has no parent.
            
            oCloneParent = this;
            while ~isempty(oCloneParent.parent)
                oCloneParent = oCloneParent.parent;
            end
        end
        
        function oSpeed = get.avgSpeed(this)
            % The average migration speed of the cell.
            %
            % The migration speed in micrometers per hour, averaged over
            % all displacements made by the cell in the entire image
            % sequence.
            
            if ~isempty(this.cx)
                dx = diff(this.cx);
                dy = diff(this.cy);
                if isempty(this.cz)
                    dz = zeros(size(dx));
                else
                    dz = diff(this.cz) * this.imageData.voxelHeight;
                end
                dM = this.imageData.PixelToMicroM(sum(sqrt(dx.^2 + dy.^2 + dz.^2)));
                lifeTimeH = this.imageData.FramesToHours(length(this.cx) - 1);
                oSpeed = dM/lifeTimeH;
            else
                oSpeed = nan;
            end
        end
        
        function oRatio = get.avgAxisRatio(this)
            % The axis ratio of the cell, averaged over time.
            %
            % The axis ratio is the major axes length divided by the minor
            % axis length, resulting in 1 for a round cell and larger
            % values for stretched out cells.
            
            if isempty(this.regionProps)  ||...
                    ~isfield(this.regionProps, 'MajorAxisLength')
                oRatio = nan;
            else
                ratio = this.regionProps.MajorAxisLength ./...
                    this.regionProps.MinorAxisLength;
                oRatio = mean(ratio(~isnan(ratio)));
            end
        end
        
        function oSize = get.avgSize(this)
            if this.imageData.GetDim() == 2
                if isempty(this.regionProps) || ~isfield(this.regionProps, 'Area')
                    oSize = nan;
                else
                    areas = [this.regionProps.Area];
                    oSize = this.imageData.Pixel2ToMicroM2(mean(areas(~isnan(areas))));
                end
            else
                if isempty(this.regionProps) || ~isfield(this.regionProps, 'Volume')
                    oSize = nan;
                else
                    volumes = [this.regionProps.Volume];
                    oSize = this.imageData.VoxelToMicroM3(mean(volumes(~isnan(volumes))));
                end
            end
        end
        
        function oTime = get.divisionTime(this)
            if isempty(this.children) || isempty(this.parent)
                oTime = nan;
            else
                oTime = this.imageData.FramesToHours(this.lifeTime);
            end
        end
        
        function oTime = get.timeToFirstDivision(this)
            if this.firstFrame == 1 && isempty(this.parent) && ~isempty(this.children)
                oTime = this.imageData.FrameToT(this.lastFrame+1);
            else
                oTime = nan;
            end
        end
        
        function oTime = get.timeOfBirth(this)
            if ~isempty(this.parent)
                oTime = this.imageData.FrameToT(this.firstFrame);
            else
                oTime = nan;
            end
        end
        
        function oTime = get.lifeSpan(this)
            oTime = this.imageData.FramesToHours(this.lifeTime);
        end
        
        function oDeltaT = get.deltaT(this)
            if ~this.divided ||...
                    isempty(this.parent) ||...
                    isempty(this.parent.OtherChild(this)) ||...
                    ~this.parent.OtherChild(this).divided
                oDeltaT = nan;
            else
                frames = this.lifeTime - this.parent.OtherChild(this).lifeTime;
                oDeltaT = this.imageData.FramesToHours(frames);
            end
        end
        
        function oTime = get.timeToDeath(this)
            if this.died
                oTime = this.imageData.FramesToHours(this.lifeTime);
            else
                oTime = nan;
            end
        end
        
        function oDivided = get.divided(this)
            oDivided = ~isempty(this.children);
        end
        
        function oSurvived = get.survived(this)
            oSurvived = this.lastFrame == this.sequenceLength;
        end
        
        function oDied = get.died(this)
            oDied = isempty(this.children) &&...
                this.lastFrame < this.sequenceLength &&...
                ~this.disappeared;
        end
        
        function oFate = get.fate(this)
            if this.divided
                oFate = 'divided';
            elseif this.survived
                oFate = 'live';
            elseif this.died
                oFate = 'dead';
            elseif this.disappeared
                oFate = 'disappeared';
            else
                error('Unknown cell fate')
            end
        end
        
        function oFate = get.fate_dead_others(this)
            if this.divided || this.survived || this.disappeared
                oFate = 'others';
            elseif this.died
                oFate = 'dead';
            else
                error('Unknown cell fate')
            end
        end
        
        function oRegionProps = get.regionProps(this)
            % Properties of the cell regions.
            %
            % If the cell is not compressed, the function returns region
            % properties (such as area) associated with the blob objects of
            % the cell. If the cell is compressed, the function returns
            % pre-computed blob properties. The region properties are
            % determined by what properties have been computed for the
            % blobs. The region properties are returned in the form of a
            % struct array with the properties as fields.
            
            if this.isCompressed
                oRegionProps = this.regionProps_compressed;
            else
                regProps = [this.blob.regionProps];
                if isempty(regProps)
                    oRegionProps = struct();
                    return
                end
                fields = fieldnames(regProps);
                oRegionProps = struct();
                for fIndex = 1:length(fields)
                    oRegionProps.(fields{fIndex}) = [regProps.(fields{fIndex})];
                end
            end
        end
        
        function oT = get.startT(this)
            oT = this.imageData.Get('startT');
        end
        
        function oT = get.stopT(this)
            oT = this.imageData.FrameToT(this.sequenceLength);
        end
        
        function AddCell(this, aCell)
            % Append another cell after the last frame of the current cell.
            %
            % This connects two cell tracks by appending another cell after
            % the current cell. The first image of the appended cell must
            % be the image after the last image of the current cell. The
            % pointer of the current cell remains the same, but the cell
            % track becomes longer.
            
            this.blob = [this.blob aCell.blob];
            this.cx = [this.cx aCell.cx];
            this.cy = [this.cy aCell.cy];
            this.cz = [this.cz aCell.cz];
            this.notes = [this.notes aCell.notes];
            this.iterations = [this.iterations aCell.iterations];
            this.lifeTime = this.lifeTime + aCell.lifeTime;
            for i = 1:length(aCell.children)
                this.AddChild(aCell.children(i), 'GapsOk', true)
            end
            this.disappeared = aCell.disappeared;
            this.graphics = [this.graphics aCell.graphics];
        end
        
        function AddChild(this, aCell, varargin)
            % Add a daughter cells to the current cell.
            %
            % Inputs:
            % aCell - A cell which should be added as a daughter to the
            %         current cell. The daughter cell will not be added if
            %         the current cell already has two daughter cells.
            %
            % Paramter/Value inputs:
            % GapsOk - If this is set to true, the first frame of the
            %          daughter cell does not have to be the frame directly
            %          after the last frame of the current cell.
            
            % Get additional inputs.
            aGapsOk = GetArgs({'GapsOk'}, {false}, 1, varargin);
            
            if length(this.children) == 2
                warning('This cell already has 2 children. Not adding child')
            elseif aGapsOk && this.lastFrame + 1 > aCell.firstFrame
                warning(['The suggested child cell starts before the '...
                    'parent cell ends. Not adding child.'])
            elseif ~aGapsOk && this.lastFrame + 1 ~= aCell.firstFrame
                warning(['The first frame of the suggested child does '...
                    'not match the last frame of the parent. Not '...
                    'adding child.'])
            elseif ~any(this.children == aCell)
                this.children = [this.children aCell];
                this.disappeared = false;
                aCell.parent = this;
                if this.isCell
                    aCell.UnhideBranch()
                else
                    aCell.HideBranch()
                end
            end
        end
        
        function RemoveChildren(this)
            % Removes the children of the current cell.
            %
            % The daughter cells can still be used, but they will no longer
            % be daughter cells of the current cell.
            
            this.children(1).parent = [];
            this.children(2).parent = [];
            this.children = [];
        end
        
        function oCells = DeleteBranch(this, aCells)
            % Removes a cell and its progeny from a lineage tree.
            %
            % The cell division where the cell is created is removed, and
            % the parent cell continues in the track of the other daughter
            % cell. The isCell-property of the cell and its progeny is set
            % to false.
            
            oCells = this.CutBranch(aCells);
            this.HideBranch()
        end
        
        function oCells = UndeleteBranch(this, aCells)
            % Turns a branch in a false positive lineage tree into cells.
            %
            % The branch is first removed from the lineage tree in the same
            % way as in DeleteBranch, and then the isCell-property of the
            % cell and its progeny is set to true.
            
            oCells = this.CutBranch(aCells);
            this.UnhideBranch()
        end
        
        function oCellVec = CutBranch(this, aCellVec)
            % Disconnects a branch from a lineage tree.
            %
            % The branch is removed from the lineage tree in the same way
            % as in DeleteBrach. The disconnected branch becomes its own
            % lineage tree. The isCell-property of the cells are not
            % changed.
            
            oCellVec = aCellVec;
            p = this.parent;
            if ~isempty(p)
                otherChild = p.OtherChild(this);
                p.RemoveChildren();
                if ~isempty(otherChild)
                    if otherChild.firstFrame == p.lastFrame + 1
                        p.AddCell(otherChild)
                        oCellVec(oCellVec == otherChild) = [];
                    else
                        p.AddChild(otherChild, 'GapsOk', true)
                    end
                end
            end
        end
        
        function HideBranch(this)
            % Turns a cell and its progeny into false positive cells.
            
            this.isCell = false;
            for i = 1:length(this.children)
                this.children(i).HideBranch();
            end
        end
        
        function UnhideBranch(this)
            % Turns a false positive cell and its progeny into real cells.
            
            this.isCell = true;
            for i = 1:length(this.children)
                this.children(i).UnhideBranch();
            end
        end
        
        function oCell = OtherChild(this, aCell)
            % Returns the sister cell of one of the cell's daughter cells.
            %
            % Inputs:
            % aCell - The daughter cell that we want to find the sister
            %         cell to.
            
            oCell = this.children(this.children ~= aCell);
        end
        
        function oCells = GetProgeny(this)
            % Returns a vector with all cells that are progeny of a
            % specified cell. The progeny are found recursively and are
            % therefore not sorted by generation.
            %
            % Outputs:
            % oCells - Vector with cell objects that are progeny of the
            %          current cell.
            
            oCells = [];
            if ~isempty(this.children)
                for i = 1:length(this.children)
                    oCells = [oCells this.children(i)]; %#ok<AGROW>
                    oCells = [oCells this.children(i).GetProgeny()]; %#ok<AGROW>
                end
            end
        end
        
        function oCell = Split(this, aSplit)
            % Cuts a cell into two new cells.
            %
            % The time points after aSplit are removed from the current
            % cell and are then used to create a new cell, which is
            % returned. It is assumed that the current cell ends with
            % apoptosis after the end has been cut way.
            
            if aSplit < this.firstFrame
                error('A cell can not be split before its first frame.')
            elseif aSplit == this.firstFrame
                error('A cell can not be split in its first frame.')
            elseif aSplit > this.lastFrame
                error('A cell can not be split after its last frame.')
            end
            
            % Generate a new cell from the second half of the current cell.
            oCell = Cell(...
                'imageData', this.imageData,...
                'blob', this.blob(aSplit - this.firstFrame + 1 : end),...
                'color', this.color,...
                'firstFrame', aSplit,...
                'lifeTime', this.firstFrame + this.lifeTime - aSplit,...
                'cx', this.cx(aSplit - this.firstFrame + 1 : end),...
                'cy', this.cy(aSplit - this.firstFrame + 1 : end),...
                'cz', this.cz(aSplit - this.firstFrame + 1 : end),...
                'notes', this.notes(aSplit - this.firstFrame + 1 : end),...
                'iterations', this.iterations(aSplit - this.firstFrame + 1 : end),...
                'isCompressed', this.isCompressed,...
                'parent', [],...
                'isCell', this.isCell,...
                'disappeared', this.disappeared);
            
            % Transfer compressed region properties if the cell is
            % compressed.
            if this.isCompressed && ~isempty(this.regionProps_compressed)
                props = fieldnames(this.regionProps_compressed);
                newRegionProps_compressed = [];
                for pIndex = 1:length(props)
                    newRegionProps_compressed.(props{pIndex}) =...
                        this.regionProps_compressed.(props{pIndex})...
                        (aSplit - this.firstFrame + 1 : end);
                    this.regionProps_compressed.(props{pIndex})...
                        (aSplit - this.firstFrame + 1 : end) = [];
                end
                oCell.regionProps_compressed = newRegionProps_compressed;
            end
            
            % Transfer children to the new cell.
            for i = 1:length(this.children)
                oCell.AddChild(this.children(i), 'GapsOk', true)
            end
            
            % Cut away the end of the current cell.
            this.lifeTime = aSplit - this.firstFrame;
            this.children = [];
            this.disappeared = false;
            this.blob(aSplit - this.firstFrame + 1 : end) = [];
            this.cx(aSplit - this.firstFrame + 1 : end) = [];
            this.cy(aSplit - this.firstFrame + 1 : end) = [];
            this.cz(aSplit - this.firstFrame + 1 : end) = [];
            this.notes(aSplit - this.firstFrame + 1 : end) = [];
            this.iterations(aSplit - this.firstFrame + 1 : end) = [];
        end
        
        function ComputeRegionProps(this)
            % Computes region properties of the cell.
            %
            % The region properties are not returned, but are stored in the
            % Blob objects of the cell.
            
            for i = 1:length(this.blob)
                this.blob(i).Update(this.imageData);
            end
        end
        
        function SetBlob(this, aBlob, aFrame)
            % Switches one of the cell's blobs to a new blob.
            %
            % Inputs:
            % aBlob - The blob which should replace the blob in image
            %         aFrame.
            % aFrame - The index of the image in which the Blob object
            %          should be replaced.
            
            this.blob(aFrame - this.firstFrame + 1) = aBlob;
            centroid = aBlob.centroid;
            this.SetCx(centroid(1), aFrame);
            this.SetCy(centroid(2), aFrame);
            
            if length(centroid) == 3  % 3D data.
                this.SetCz(centroid(3), aFrame);
            else  % 2D data (z = 0).
                this.SetCz(0, aFrame);
            end
        end
        
        function SetNote(this, aNote, aFrame)
            % Sets the note of the cell in a specified frame.
            %
            % Inputs:
            % aNote - The new note value (usually an integer).
            % aFrame - The image for which the note value should be set.
            
            this.notes(aFrame - this.firstFrame + 1) = aNote;
        end
        
        function oProperty = GetProperty(this, aProperty, aFrame)
            % Returns properties of one of the blobs of the cell.
            %
            % Inputs:
            % aProperty - The name of the blob property. It can be either a
            %             property of the blob class or a field in the blob
            %             property regionProps.
            % aFrame - The frame index.
            %
            % See also:
            % GetProperties, GetFluorProperty
            
            if aFrame < this.firstFrame || aFrame > this.lastFrame
                error('The cell track is not present at the desired time point.')
            end
            
            % The blob object in frame aFrame.
            b = this.blob(aFrame - this.firstFrame + 1);
            
            if any(strcmp(properties(b), aProperty))
                % Properties of the blob.
                oProperty = this.blob(aFrame - this.firstFrame + 1).(aProperty);
            elseif isa(fieldnames(b.regionProps), 'struct') &&...
                    any(strcmp(fieldnames(b.regionProps), aProperty))
                % Fields in the Blob regionProps. We have to check that
                % regionProps is a struct, as the older versions of the
                % code made regionprops be [] if it was empty.
                oProperty = b.regionProps.(aProperty);
            else
                error('The desired property is not available')
            end
        end
        
        function oProperty = GetFluorProperty(this, aProperty)
            % Returns average fluorescence properties of the cell's blobs.
            %
            % The function causes an error if the given property is not a
            % fluorescence property. The property has to be defined in the
            % region properties of the cell.
            %
            % Inputs:
            % aProperty - The name of the fluorescence property. The names
            %             of fluorescence properties follow the format
            %             Fluor<Max|Avg|Tot><channel name>. Total
            %             fluorescence values are given in intensity times
            %             area in square microns for 2D datasets and in
            %             intensity times cubic microns for 3D datasets.
            %
            % See also:
            % GetProperty, GetProperties, Extract
            
            % Extract the properties which are not NaN.
            properties = [this.regionProps.(aProperty)];
            properties(isnan(properties)) = [];
            
            metric = regexp(aProperty, '(?<=Fluor)\w{3}', 'match', 'once');
            if ~isempty(metric)
                switch lower(metric)
                    case 'max'
                        oProperty = mean(properties);
                    case 'avg'
                        oProperty = mean(properties);
                    case 'tot'
                        oProperty = mean(properties);
                        if this.imageData.GetDim() == 2
                            % Convert the area from pixels to square microns.
                            oProperty = this.imageData.Pixel2ToMicroM2(oProperty);
                        else
                            % Convert the volume from voxels to cubic microns.
                            oProperty = this.imageData.VoxelToMicroM3(oProperty);
                        end
                end
            else
                error('The property %s is not a fluorescence property.',...
                    aProperty)
            end
        end
        
        function oBlob = GetBlob(this, aFrame)
            % Returns the cell's blob in image aFrame.
            
            oBlob = this.blob(aFrame - this.firstFrame + 1);
        end
        
        function oCx = GetCx(this, aFrame)
            % Returns the cell's x-coordinate in image aFrame.
            
            if isempty(this.cx)
                oCx = [];
                return
            end
            oCx = this.cx(aFrame - this.firstFrame + 1);
        end
        
        function oCy = GetCy(this, aFrame)
            % Returns the cell's y-coordinate in image aFrame.
            
            if isempty(this.cy)
                oCy = [];
                return
            end
            oCy = this.cy(aFrame - this.firstFrame + 1);
        end
        
        function oCz = GetCz(this, aFrame)
            % Returns the cell's z-coordinate in image aFrame.
            
            if isempty(this.cz)
                oCz = [];
                return
            end
            oCz = this.cz(aFrame - this.firstFrame + 1);
        end
        
        function oNote = GetNote(this, aFrame)
            % Returns the cell's note value in image aFrame.
            
            if isempty(this.notes)
                oNote = [];
                return
            end
            oNote = this.notes(aFrame - this.firstFrame + 1);
        end
        
        function SetCx(this, aCx, aFrame)
            % Sets the cell's x-coordinate to aCx in image aFrame.
            
            this.cx(aFrame - this.firstFrame + 1) = aCx;
        end
        
        function SetCy(this, aCy, aFrame)
            % Sets the cell's y-coordinate to aCy in image aFrame.
            
            this.cy(aFrame - this.firstFrame + 1) = aCy;
        end
        
        function SetCz(this, aCz, aFrame)
            % Sets the cell's z-coordinate to aCz in image aFrame.
            
            this.cz(aFrame - this.firstFrame + 1) = aCz;
        end
        
        function oHasSeg = HasSegment(this, aFrame)
            % Returns true if the cell has a pixel-blob in image aFrame.
            %
            % The function returns false if the cell is not present in
            % image aFrame, or if it has a point-blob in image aFrame.
            
            if this.firstFrame > aFrame || this.lastFrame < aFrame
                oHasSeg = false;
            else
                oHasSeg = ~any(isnan(this.GetProperty('boundingBox', aFrame)));
            end
        end
        
        function oExist = Exist(this, aFrame)
            oExist = this.firstFrame <= aFrame && this.lastFrame >= aFrame;
        end
        
        function Compress(this)
            % Compresses the blob by removing all of its blob objects.
            %
            % The blob objects tend to take up a lot of memory when the
            % cells are saved, so the loading of the cells can become
            % faster if the blobs are not saved. Region properties of the
            % blobs are stored in the variable regionProps_compressed, so
            % that they can be accessed even when the blobs have been
            % removed.
            
            this.regionProps_compressed = this.regionProps;
            this.isCompressed = true;
            this.blob = [];
        end
        
        function AddFrame(this, aBlob)
            % Append an additional blob object to the end of the cell.
            %
            % This extends the life time of the cell by one frame, and can
            % be used to construct cell tracks.
            
            this.blob = [this.blob aBlob];
            if length(aBlob.centroid) == 2
                this.cx = [this.cx aBlob.centroid(1)];
                this.cy = [this.cy aBlob.centroid(2)];
                this.cz = [this.cz 0];
            else % 3D
                this.cx = [this.cx aBlob.centroid(1)];
                this.cy = [this.cy aBlob.centroid(2)];
                this.cz = [this.cz aBlob.centroid(3)];
            end
            this.notes = [this.notes 0];
            this.lifeTime = this.lifeTime + 1;
            if length(this.notes) ~= this.lifeTime
                error('AddFrame: Wrong number of notes in this!')
            end
        end
        
    end % methods
end