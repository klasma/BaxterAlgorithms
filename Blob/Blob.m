classdef Blob < handle
    % Class which stores information about a pixel region.
    %
    % The blob objects represent a pixel or voxel region in a single image.
    % The pixel region may correspond to a single cell, multiple cells, or
    % clutter. The region will normally consist of a single connected
    % component, but there is no constraint enforcing that. When cells are
    % tracked, the initially segmented regions are represented using Blob
    % objects. When clusters of cells are broken into multiple regions,
    % those regions are represented using other blobs which link to the
    % originally segmented region using the super-property. The blobs that
    % are used to represent individual cell regions will always link to a
    % super-blob, even if the super-blob only contains a single sub-blob.
    % Super-blobs are segmented regions and sub-blobs are regions of cell
    % objects. Blobs do not have to have pixel or voxel regions associated
    % with them. They can also be point blobs, defined entirely by their
    % centroid property. These blobs can be recognized by the fact that
    % their bounding boxes are vectors of NaNs.
    %
    % See also:
    % Cell, SegmentSequence
    
    properties
        % The frame index of the Blob.
        t = nan;
        
        % Index of the Blob. The blobs in one image should have unique
        % integer indices.
        index = nan;
        
        % Bounding box of the blob image in the format returned by
        % the function regionprops. 2D blobs have 4 elements and 3D blobs
        % have 6. The first half of the array gives the coordinates of the
        % lower left corner and the second half gives the widths in the
        % different dimensions. The first dimension is the x-dimension.
        boundingBox = [];
        
        % Binary image where pixels belonging to the blob are 1s. The image
        % is cropped so that there are 1s on all borders.
        image = [];
        
        % The centroid of the blob pixel region given in coordinates of the
        % full image.
        centroid = [];
        
        % Blob from the original segmentation, that the current blob
        % belongs to. Each blob in the original segmentation can contain
        % one or more blobs associated with different cells.
        super = [];
        
        % Pre-computed properties of the blob used for analysis.
        regionProps = struct();
        
        % Features of the blob that can be used for classification.
        features = [];
    end
    
    methods
        
        function this = Blob(varargin)
            % Creates a Blob from region properties or a binary mask.
            %
            % The first input argument can either be a struct with region
            % properties or a binary mask with the same size as the
            % original image. The constructor can also be called with no
            % arguments, to generate an object with no specified
            % properties. The constructor can also take values of class
            % parameters as Property/Value inputs in addition to the struct
            % or the binary mask.
            
            if ~isempty(varargin)
                if isstruct(varargin{1})
                    % Region properties as input.
                    aRegionProps = varargin{1};
                    this.boundingBox = aRegionProps.BoundingBox;
                    this.image = aRegionProps.Image;
                    this.centroid = aRegionProps.Centroid;
                else
                    % Binary mask as input.
                    mask = varargin{1};
                    % The region properties are computed here instead of by
                    % regionprops. This is faster and allows multiple
                    % connected components in the same blob.
                    if size(mask,3) == 1  % 2D data
                        [y,x] = find(mask);
                        if ~isempty(y)
                            xmin = min(x);
                            xmax = max(x);
                            ymin = min(y);
                            ymax = max(y);
                            this.boundingBox = [xmin-0.5 ymin-0.5...
                                xmax-xmin+1 ymax-ymin+1];
                            this.image = mask(ymin:ymax, xmin:xmax);
                            this.centroid = [mean(x) mean(y)];
                        else
                            this.boundingBox = nan(1,4);
                            this.image = [];
                            this.centroid = nan(1,2);
                        end
                    else
                        ind = find(mask);
                        [y,x,z] = ind2sub(size(mask), ind);
                        if ~isempty(y)
                            xmin = min(x);
                            xmax = max(x);
                            ymin = min(y);
                            ymax = max(y);
                            zmin = min(z);
                            zmax = max(z);
                            this.boundingBox = [xmin-0.5 ymin-0.5 zmin-0.5...
                                xmax-xmin+1 ymax-ymin+1 zmax-zmin+1];
                            this.image = mask(ymin:ymax, xmin:xmax, zmin:zmax);
                            this.centroid = [mean(x) mean(y) mean(z)];
                        else
                            this.boundingBox = nan(1,6);
                            this.image = [];
                            this.centroid = nan(1,3);
                        end
                    end
                end
            end
            
            if length(varargin) > 1
                % Assign property values from additional input arguments.
                for i = 2 : 2 : length(varargin)
                    this.(varargin{i}) = varargin{i+1};
                end
            end
        end
        
        function oBlob = Clone(this, varargin)
            % Creates a deep copy of a Blob object.
            %
            % The blob class inherits from handle, so normal assignment
            % only copies a handle to the blob object.
            %
            % Inputs:
            % Properties of the copied object can be specified as
            % Property/Value inputs arguments.
            
            oBlob = Blob();
            
            % Transfer the values of all class properties.
            props = properties('Blob');
            for i = 1:length(props)
                oBlob.(props{i}) = this.(props{i});
            end
            
            % Overwrite with properties specified by the caller.
            for i = 1 : 2 : length(varargin)
                oBlob.(varargin{i}) = varargin{i+1};
            end
        end
        
        function oBlob = CreateSub(this)
            % Creates a sub-blob for the current blob.
            %
            % The sub-blob is identical to the current blob, but it links
            % to the current blob using the super-property. Super-blobs are
            % segmented regions and sub-blobs are regions of cell objects.
            
            oBlob = this.Clone('super', this);
        end
        
        function oInside = IsInside(this, x, y, z)
            % Returns true if a specified coordinate is inside the Blob.
            %
            % Inputs:
            % x - x-coordinate (image width dimension)
            % y - y-coordinate (image height dimension)
            % z - z-coordinate (must be omitted for 2D blobs)
            %
            % Outputs:
            % oInside - True if the point is inside one of the blobs pixels
            %           or voxels.
            
            if nargin == 3  % 2D data
                ndim = 2;
                bb = this.boundingBox;
                if length(bb) == 6
                    error(['For 3D data, you need to give x, y and z '...
                        'as inputs to IsInside.'])
                end
                im = this.image;
                % First check if the point is inside the bounding box.
                if x >= bb(1) && x < bb(1)+bb(ndim+1) &&...
                        y >= bb(2) && y < bb(2)+bb(ndim+2)
                    % Then check if the pixel is 1.
                    if im(1 + floor(y-bb(2)), 1 + floor(x - bb(1)))
                        oInside = true;
                    else
                        oInside = false;
                    end
                else
                    oInside = false;
                end
            else % 3D
                ndim = 3;
                bb = this.boundingBox;
                if length(bb) == 4
                    error(['For 2D data, you need to give x and y as '...
                        'inputs to IsInside.'])
                end
                im = this.image;
                % First check if the point is inside the bounding box.
                if x >= bb(1) && x < bb(1)+bb(ndim+1) &&...
                        y >= bb(2) && y < bb(2)+bb(ndim+2) &&...
                        z >= bb(3) && z < bb(3)+bb(ndim+3)
                    % Then check if the pixel is 1.
                    if im(1 + floor(y-bb(2)), 1 + floor(x - bb(1)), 1 + floor(z - bb(3)))
                        oInside = true;
                    else
                        oInside = false;
                    end
                else
                    oInside = false;
                end
            end
        end
        
        function Update(this, aImData)
            % Computes region parameters for the blob region.
            %
            % The following parameters are computed:
            %
            % Area (2D) or Volume (3D)
            % Major axis length
            % Minor axis length
            %
            % This information is stored in the regionProps property of the
            % Blob object and is used by some analysis functions. No region
            % parameters are computed for point blobs.
            %
            % Inputs:
            % aImData - ImageData object for the image sequence that the
            %           Blob was extracted from.
            
            if any(isnan(this.boundingBox))
                % Point blob which has no region.
                this.regionProps = struct(...
                    'Area', nan,...
                    'MajorAxisLength', nan,...
                    'MinorAxisLength', nan);
            else
                if aImData.GetDim() == 3
                    this.regionProps.Volume = sum(this.image(:));
                    [this.regionProps.MajorAxisLength, this.regionProps.MinorAxisLength] =...
                        AxisLengths3(this.image, aImData);
                else
                    this.regionProps.Area = sum(this.image(:));
                    [this.regionProps.MajorAxisLength, this.regionProps.MinorAxisLength] =...
                        AxisLengths2(this.image);
                end
            end
        end
        
        function [y1, y2, x1, x2, z1, z2] = GetBoundaryCoordinates(this)
            % Returns the boundaries of the boundingbox.
            %
            % Returns the minimum and maximum voxel coordinate values found
            % in the blob for each image dimension. These values define the
            % limits of the smallest rectangular box that can contain the
            % blob. The function returns integer coordinates of the pixels
            % and works for both 2D and 3D blobs. For 2D blobs, z1 and z2
            % are both equal to 1.
            
            bb = this.boundingBox;
            
            if length(bb) == 4  % 2D data.
                x1 = bb(1) + 0.5;
                x2 = bb(1) + bb(3) - 0.5;
                y1 = bb(2) + 0.5;
                y2 = bb(2) + bb(4) - 0.5;
                z1 = 1;
                z2 = 1;
            else % 3D data.
                x1 = bb(1) + 0.5;
                x2 = bb(1) + bb(4) - 0.5;
                y1 = bb(2) + 0.5;
                y2 = bb(2) + bb(5) - 0.5;
                z1 = bb(3) + 0.5;
                z2 = bb(3) + bb(6) - 0.5;
            end
        end
        
        function oSubIm = GetSubImage(this, aIm)
            % Cuts out a sub-image corresponding to the blobs bounding box.
            %
            % Inputs:
            % aIm - Image from which the sub-image (bounding box region)
            %       should be extracted.
            %
            % oSubIm - The extracted sub-image (bounding box region).
            
            if length(this.boundingBox) == 4  % 2D
                [y1, y2, x1, x2] = GetBoundaryCoordinates(this);
                oSubIm = aIm(y1:y2, x1:x2);
            else  % 3D
                [y1, y2, x1, x2, z1, z2] = GetBoundaryCoordinates(this);
                oSubIm = aIm(y1:y2, x1:x2, z1:z2);
            end
        end
        
        function [x, y, z] = GetPixelCoordinates(this)
            % Returns x-, y-, and z-coordinates of all pixels in the blob.
            %
            % Outputs:
            % x - Column vector of x-coordinates.
            % y - Column vector of y-coordinates.
            % z - Column vector of z-coordinates. For 2D data, this is a
            %     vector of ones.
            
            bb = this.boundingBox;
            if length(this.centroid) == 2  % 2D
                [yi, xi] = find(this.image);
                x = xi + bb(1) - 0.5;
                y = yi + bb(2) - 0.5;
                z = ones(size(x));
            else  % 3D
                ind = find(this.image);
                [yi, xi, zi] = ind2sub(size(this.image), ind);
                x = xi + bb(1) - 0.5;
                y = yi + bb(2) - 0.5;
                z = zi + bb(3) - 0.5;
            end
        end
        
        function oPixels = GetPixels(this, aImage)
            % Returns image values for the pixels in the blob.
            %
            % Inputs:
            % aImage - Image to extract values from. The ordering of the
            %          values is the same as the order of the coordinates
            %          returned by GetPixelCoordinates.
            %
            % Outputs:
            % oPixels - Column vector of pixel values.
            
            [x, y, z] = GetPixelCoordinates(this);
            oPixels = aImage(sub2ind(size(aImage), y, x, z));
        end
        
        function oArea = GetArea(this)
            % Returns the area of the blob in pixels/voxels.
            oArea = sum(this.image(:));
        end
    end
    
    methods (Static = true)
        
        function oBlobs = Copy(aBlobs)
            % Copies an array of blobs or a cell array of such blob arrays.
            %
            % The blobs segmented from an image sequence are stored in a
            % cell array where each cell holds an array with the blobs from
            % one image. This function performs a deep copy of such a cell
            % array. The function can also be used to deep copy an array of
            % blobs.
            %
            % Inputs:
            % aBlobs - Array or cell array with blobs to be deep copied.
            %
            % Outputs:
            % oBlobs - Array or cell array with deep copied blobs.
            
            if iscell(aBlobs)
                % Cell array of blob arrays.
                oBlobs = cell(1,length(aBlobs));
                for i = 1:length(aBlobs)
                    tmp = Blob;
                    tmp(length(aBlobs{i})) = Blob; % Pre-allocate.
                    for j = 1:length(aBlobs{i})
                        tmp(j) = aBlobs{i}(j).Clone();
                    end
                    oBlobs{i} = tmp;
                end
            else
                % Blob array.
                if isempty(aBlobs)
                    oBlobs = aBlobs;
                    return
                end
                oBlobs(length(aBlobs)) = Blob;
                for i = 1:length(aBlobs)
                    oBlobs(i) = aBlobs(i).Clone();
                end
            end
        end
    end
end