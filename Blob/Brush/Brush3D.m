classdef Brush3D < Brush
    % Brush for 3D segmentation editing.
    %
    % The brush can be shaped as a disk or as a ball. The disk shaped brush
    % is a disk in two dimensions and a one voxel plane in the third
    % dimension. If the voxel height is different from the voxel width, the
    % z-dimension of the brush is re-scaled, so that the brush becomes a
    % circular disk  or a sphere when distances are converted from voxels
    % to micrometers.
    %
    % See also:
    % Brush, Blob, ManualCorrectionPlayer, ConvexEllipse
    
    properties (Access = protected)
        numZ            % The number of z-planes in the edited image sequence.
        shape           % The shape or the brush ('disk' or 'ball').
        voxelHeight     % The ratio between the height and the width of voxels.
        view            % The 3D view in which the brush is a disk ('xy', 'xz', or 'yz').
    end
    
    methods
        function this = Brush3D(aR, aX, aY, aZ, aView, aShape,...
                aImageHeight, aImageWidth, aNumZ, aVoxelHeight)
            % Creates a 3D brush.
            %
            % Inputs:
            % aR - Radius in pixels.
            % aX - x-coordinate of center in voxels.
            % aY - y-coordinate of center in voxels.
            % aZ - z-coordinate of center in voxels.
            % aView - 3D projection view in which editing is done.
            % aShape - The shape or the brush ('disk' or 'ball').
            % aImageHeight - Image height in voxels.
            % aImageWidth - Image width in voxels.
            % aNumZ - Number of z-planes.
            % aVoxelHeight - Ratio between the height and the width of
            %                voxels.
            
            this.imageHeight = aImageHeight;
            this.imageWidth = aImageWidth;
            this.numZ = aNumZ;
            this.voxelHeight = aVoxelHeight;
            
            this.Update(aR, aX, aY, aZ, aView, aShape)
        end
        
        function oBrush = Clone(this)
            % Creates a deep copy of the current Brush3D object.
            %
            % Outputs:
            % oBrush - Deep copy of the current object.
            
            oBrush = Brush3D(...
                this.GetR(),...
                this.GetX(),...
                this.GetY(),...
                this.GetZ(),...
                this.GetView(),...
                this.shape,...
                this.imageHeight,...
                this.imageWidth,...
                this.numZ,...
                this.voxelHeight);
        end
        
        function oShape = GetShape(this)
            % Returns the shape of the brush.
            %
            % Outputs:
            % oShape - The shape or the brush ('disk' or 'ball').
            
            oShape = this.shape;
        end
        
        function oView = GetView(this)
            % Returns the 3D projection in which editing is done.
            %
            % Outputs:
            % oView - 'xy', 'xz', or 'yz'.
            
            oView = this.view;
        end
        
        function oZ = GetZ(this)
            % Get z-coordinate of brush center.
            %
            % Outputs:
            % oZ - z-coordinate in voxels.
            
            oZ = this.centroid(3);
        end
        
        function RemovePixelsOutsideImage(this)
            % Removes brush pixels which are outside the microscope image.
            %
            % The brush will be cropped at the edges of the microscope
            % image, so that the user does not draw outside the image.
            
            % Crop along left image border.
            if this.boundingBox(1) < 0.5
                this.image = this.image(:, 0.5-this.boundingBox(1) : end, :);
                this.boundingBox(1) = 0.5;
                this.boundingBox(4) = size(this.image,2);
            end
            
            % Crop along right image border.
            if this.boundingBox(1) + this.boundingBox(4) - 0.5 > this.imageWidth
                this.boundingBox(4) = this.imageWidth + 0.5 - this.boundingBox(1);
                this.image = this.image(:, 1:this.boundingBox(4), :);
            end
            
            % Crop along top image border.
            if this.boundingBox(2) < 0.5
                this.image = this.image(0.5 - this.boundingBox(2):end, :, :);
                this.boundingBox(2) = 0.5;
                this.boundingBox(5) = size(this.image,1);
            end
            
            % Crop along bottom image border.
            if this.boundingBox(2) + this.boundingBox(5) - 0.5 > this.imageHeight
                this.boundingBox(5) = this.imageHeight + 0.5 - this.boundingBox(2);
                this.image = this.image(1:this.boundingBox(5), :, :);
            end
            
            % Crop along uppermost z-slice.
            if this.boundingBox(3) < 0.5
                this.image = this.image(:, :, 0.5 - this.boundingBox(3):end);
                this.boundingBox(3) = 0.5;
                this.boundingBox(6) = size(this.image,3);
            end
            
            % Crop along lowermost z-slice.
            if this.boundingBox(3) + this.boundingBox(6) - 0.5 > this.numZ
                this.boundingBox(6) = this.numZ + 0.5 - this.boundingBox(3);
                this.image = this.image(:, :, 1:this.boundingBox(6));
            end
        end
        
        function SetR(this, aR)
            % Sets the radius of the brush.
            %
            % Inputs:
            % aR - Radius in pixels.
            
            this.Update(...
                aR,...
                this.centroid(1),...
                this.centroid(2),...
                this.centroid(3),...
                this.view,...
                this.shape)
        end
        
        function SetShape(this, aShape)
            % Sets the shape of the brush.
            %
            % Inputs:
            % aShape - The shape or the brush ('disk' or 'ball').
            
            this.Update(...
                this.radius,...
                this.centroid(1),...
                this.centroid(2),...
                this.centroid(3),...
                this.view,...
                aShape)
        end
        
        function SetView(this, aView)
            % Selects the 3D projection in which editing is done.
            %
            % Inputs:
            % aView - 'xy', 'xz', or 'yz'.
            
            this.Update(...
                this.radius,...
                this.centroid(1),...
                this.centroid(2),...
                this.centroid(3),...
                aView,...
                this.shape)
        end
        
        function SetXYZ(this, aX, aY, aZ)
            % Specifies the center coordinate of the brush.
            %
            % The coordinates should be integers, as the brush shape is
            % fixed.
            %
            % Inputs:
            % aX - x-coordinate of center in voxels.
            % aY - y-coordinate of center in voxels.
            % aZ - z-coordinate of center in voxels.
            
            this.Update(this.radius, aX, aY, aZ, this.view, this.shape)
        end
        
        function Shift(this, aShift)
            % Shifts the brush a number of slices up or down.
            %
            % This function will move the brush up or down in the dimension
            % not shown in the current view. Voxels that end up outside the
            % image volume are removed.
            %
            % Inputs:
            % aShift - Integer specifying how many voxels the brush should
            %          be shifted. Positive values move the brush up and
            %          negative values move the brush down.
            
            switch this.view
                case 'xy'
                    this.boundingBox(3) = this.boundingBox(3) + aShift;
                case 'xz'
                    this.boundingBox(2) = this.boundingBox(2) + aShift;
                case 'yz'
                    this.boundingBox(1) = this.boundingBox(1) + aShift;
            end
            
            this.RemovePixelsOutsideImage()
        end
        
        function Update(this, aR, aX, aY, aZ, aView, aShape)
            % Sets the x- and y center coordinates.
            %
            % There is no rounding, so if you want the brush to maintain
            % exactly the same shape when it is moved, you need to round
            % the coordinates outside the class.
            %
            % Inputs:
            % aR - Radius in voxels.
            % aX - X-coordinate in voxels.
            % aY - Y-coordinate in voxels.
            % aZ - Z-coordinate in voxels.
            % aView - 3D projection ('xy', 'xz', or 'yz').
            % aShape - The shape or the brush ('disk' or 'ball').
            
            switch lower(aShape)
                case 'disk'
                    if aR ~= this.radius ||...
                            ~strcmpi(aShape, this.shape) ||...
                            ~strcmpi(aView, this.view)
                        % Only recompute the binary mask if necessary.
                        switch lower(aView)
                            case 'xy'
                                this.fullImage = ConvexDisk(aR);
                            case 'xz'
                                this.fullImage = permute(ConvexEllipse(...
                                    [aR aR/this.voxelHeight]), [3 1 2]);
                            case 'yz'
                                this.fullImage = permute(ConvexEllipse(...
                                    [aR aR/this.voxelHeight]), [1 3 2]);
                            otherwise
                                error('Unknown view %s.', lower(aView))
                        end
                    end
                case 'ball'
                    % Only recompute the binary mask if necessary.
                    if aR ~= this.radius || ~strcmpi(aShape, this.shape)
                        this.fullImage = ConvexEllipse([aR aR aR/this.voxelHeight]);
                    end
                otherwise
                    error('Unknown shape %s.', lower(aShape))
            end
            this.image = this.fullImage;
            
            this.centroid = [aX, aY, aZ];
            this.view = lower(aView);
            this.shape = lower(aShape);
            this.radius = aR;
            
            [h, w, d] = size(this.image);
            this.boundingBox = [aX-floor(w/2)-0.5, aY-floor(h/2)-0.5, aZ-floor(d/2)-0.5, w, h, d];
            
            this.RemovePixelsOutsideImage()
        end
    end
end