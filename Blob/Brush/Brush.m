classdef Brush < Blob
    % Class used to represent the paint brush for segmentation editing.
    %
    % The brush is used in the manual correction interface. The class
    % inherits from Blob, so that the overlap with other blobs, and some
    % other features can be computed easily. The region is circular unless
    % it is cropped at the edges of the microscope image. All of the
    % important properties except the radius are public, as the fields are
    % public in the Blob class. The class does however implement set- and
    % get-methods so that  ManualCorrectionPlayer does not have to access
    % the properties directly.
    %
    % See also:
    % ManualCorrectionPlayer, Blob, ConvexDisk
    
    properties (Access = protected)
        imageHeight  % Height of the microscope image that the user draws on.
        imageWidth   % Width of the microscope image that the user draws on.
        radius = 0;  % Radius of the brush.
        fullImage    % Un-cropped image. Introduced to save computation time.
    end
    
    methods
        function this = Brush(aR, aX, aY, aImageHeight, aImageWidth)
            % Creates a brush with a specified center and radius.
            %
            % Inputs:
            % aR - Radius in pixels.
            % aX - x-coordinate of center in pixels.
            % aY - y-coordinate of center in pixels.
            % aImageHeight - Height of the microscope image.
            % aImageWidth - Width of the microscope image.
            
            if nargin == 0
                return
            end
            
            this.imageHeight = aImageHeight;
            this.imageWidth = aImageWidth;
            this.centroid = [aX, aY];
            this.radius = aR;
            
            % Set the bounding box.
            rf = floor(this.radius);
            this.boundingBox = [aX-rf-0.5, aY-rf-0.5, rf*2+1, rf*2+1];
            
            this.fullImage = ConvexDisk(aR);
            this.image = this.fullImage;
            
            this.RemovePixelsOutsideImage()
        end
        
        function oBrush = Clone(this)
            % Creates a deep copy of the current Brush object.
            %
            % Outputs:
            % oBrush - Deep copy of the current object.
            
            oBrush = Brush(this.GetR(), this.GetX(), this.GetY(),...
                this.imageHeight, this.imageWidth);
        end
        
        function SetR(this, aR)
            % Sets the radius of the brush.
            %
            % Inputs:
            % aR - Radius in pixels.
            
            this.radius = aR;
            
            this.fullImage = ConvexDisk(aR);
            this.image = this.fullImage;
            
            % Set the bounding box.
            rf = floor(this.radius);
            xc = this.centroid(1);
            yc = this.centroid(2);
            this.boundingBox = [xc-rf-0.5, yc-rf-0.5, rf*2+1, rf*2+1];
            
            this.RemovePixelsOutsideImage()
        end
        
        function SetXY(this, aX, aY)
            % Sets the x- and y center coordinates.
            %
            % There is no rounding, so if you want the brush to maintain
            % exactly the same shape when it is moved, you need to round
            % the coordinates outside the class.
            %
            % aX - x-coordinate in pixels.
            % aY - y-coordinate in pixels.
            
            this.centroid = [aX, aY];
            
            % Set the bouding box.
            rf = floor(this.radius);
            this.boundingBox = [aX-rf-0.5, aY-rf-0.5, rf*2+1, rf*2+1];
            % The image has to be reset, in case it was cropped at the
            % previous location.
            this.image = this.fullImage;
            this.RemovePixelsOutsideImage()
        end
        
        function oR = GetR(this)
            % Get brush radius.
            %
            % Outputs:
            % oR - radius in pixels.
            
            oR = this.radius;
        end
        
        function oIm = GetImage(this)
            % Get the binary mask representing the pixels of the brush.
            %
            % The image is a binary variable and it is cut tight around the
            % edges so that there are no rows or columns with only zeros.
            % The boundingBox property in the Blob class specifies where
            % this image should be placed in the the microscope image.
            
            oIm = this.image;
        end
        
        function oX = GetX(this)
            % Get x-coordinate of brush.
            %
            % Outputs:
            % oX - x-coordinate in pixels.
            
            oX = this.centroid(1);
        end
        
        function oY = GetY(this)
            % Get y-coordinate of brush.
            %
            % Outputs:
            % oX - y-coordinate in pixels.
            
            oY = this.centroid(2);
        end
        
        function RemovePixelsOutsideImage(this)
            % Removes brush pixels which are outside the microscope image.
            %
            % The brush will be cropped at the edges of the microscope
            % image, so that the user does not draw outside the image.
            
            % Crop along left image border.
            if this.boundingBox(1) < 0.5
                this.image = this.image(:, 0.5-this.boundingBox(1) : end);
                this.boundingBox(1) = 0.5;
                this.boundingBox(3) = size(this.image,2);
            end
            
            % Crop along right image border.
            if this.boundingBox(1) + this.boundingBox(3) > this.imageWidth + 0.5
                this.boundingBox(3) = this.imageWidth + 0.5 - this.boundingBox(1);
                this.image = this.image(:, 1:this.boundingBox(3));
            end
            
            % Crop along top image border.
            if this.boundingBox(2) < 0.5
                this.image = this.image(0.5 - this.boundingBox(2):end, :);
                this.boundingBox(2) = 0.5;
                this.boundingBox(4) = size(this.image,1);
            end
            
            % crop along bottom image border.
            if this.boundingBox(2) + this.boundingBox(4) > this.imageHeight + 0.5
                this.boundingBox(4) = this.imageHeight + 0.5 - this.boundingBox(2);
                this.image = this.image(1:this.boundingBox(4), :);
            end
        end
    end
end