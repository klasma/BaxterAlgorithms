classdef CellPHD_IMM < handle
    % Evolves 2 parallel GM-PHDs which can transition into each other.
    %
    % The object models targets which switch between 2 different motion
    % models. To model the switch between motion models in the propagation
    % step, the GM-PHD of one motion model is converted into the other
    % motion model, the weights are multiplied by the transition
    % probabilities, and then the converted Gaussian components are
    % propagated using the new motion model. In the update normalization,
    % the weights associated with one detection are normalized across the
    % different motion models, so that the weights of all Gaussian
    % components associated with the detection sum to 1. This method of
    % tracking targets with switching motion models is described in [1],
    % where it is applied to the data of the ISBI 2012 Particle Tracking
    % Challenge. The GM-PHDs of the different motion models are
    % represented using CellPHD objects. This class implements many of the
    % same functions as CellPHD, but it is not a sub-class of CellPHD.
    %
    % References:
    % [1] Magnusson, K. E. G. & Jaldén, J. Tracking of non-Brownian
    %     particles using the Viterbi algorithm Proc. 2015 IEEE Int. Symp.
    %     Biomed. Imaging (ISBI), 2015, 380-384
    %
    % See also:
    % CellPHD, ComputeGMPHD_IMM, MigLogLikeList_PHD_ISBI_IMM,
    % Parameters_GMPHD
    
    properties
        cellPHD1    % CellPHD using motion model 1.
        cellPHD2    % CellPHD using motion model 2.
        params1     % Tracking parameters for cellPHD1.
        params2     % Tracking parameters for cellPHD2.
        transMat    % Matrix with transition probabilities between the different models.
    end
    
    properties (Dependent = true)
        J;  % The total number of Gaussian components.
    end
    
    methods
        function this = CellPHD_IMM(aParams1, aParams2, aTransMat, aPHD1, aPHD2)
            % Constructs a CellPHD_IMM from two existing CellPHDs.
            %
            % The constructor can also be called without CellPHDs as input.
            % In that case, the object will only contain model definitions.
            %
            % Inputs:
            % aParams1 - Tracking parameters for the first GM-PHD.
            % aParams2 - Tracking parameters for the second GM-PHD.
            % aTransMat - Matrix with transition probabilities.
            % aPHD1 - The first GM-PHD (optional together with aPHD2).
            % aPHD2 - The second GM-PHD (optional together with aPHD1).
            
            this.params1 = aParams1;
            this.params2 = aParams2;
            this.transMat = aTransMat;
            if nargin > 3
                this.cellPHD1 = aPHD1;
                this.cellPHD2 = aPHD2;
            end
        end
        
        function J = get.J(this)
            % Returns the total number of Gaussian components.
            J = this.cellPHD1.J + this.cellPHD2.J;
        end
        
        function oPHD = GetPHD(this, aIndex)
            % Returns the GM-PHD with the specified index.
            %
            % Inputs:
            % aIndex - Index of the GM-PHD to be returned (1 or 2).
            %
            % Outputs:
            % oPHD - The requested PHD (not a copy of it).
            
            switch aIndex
                case 1
                    oPHD = this.cellPHD1;
                case 2
                    oPHD = this.cellPHD2;
                otherwise
                    error('There is no phd with index %d\n', aIndex)
            end
        end
        
        function oParams = GetParams(this, aIndex)
            % Returns the tracking parameters for the specified GM-PHD.
            %
            % Inputs:
            % aIndex - Index of the GM-PHD to return parameters for (1 or
            %          2).
            %
            % Outputs:
            % oParams - Tracking parameters for the GM-PHD.
            
            switch aIndex
                case 1
                    oParams = this.params1;
                case 2
                    oParams = this.params2;
                otherwise
                    error('There is no parameter set with index %d\n', aIndex)
            end
        end
        
        function oPHD = Copy(this)
            % Returns a deep copy of the CellPHD_IMM object.
            
            phd1 = this.cellPHD1.Copy();
            phd2 = this.cellPHD2.Copy();
            oPHD = CellPHD_IMM(this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function oPHD = Propagate(this)
            % Perform the Kalman filter prediction considering transitions.
            %
            % Outputs:
            % oPHD - CellPHD_IMM object where the Gaussian components have
            %        been propagated according to the respective motion
            %        models. Before the propagation, all Gaussian
            %        components are split in one component which stays in
            %        the original motion model and one component which
            %        switches to the other motion model.
            
            % Cells that stay in the original motion model.
            phd11 =  this.cellPHD1 .* this.transMat(1,1);
            phd22 = this.cellPHD2 .* this.transMat(2,2);
            
            % Convert cells that switch to the other motion model.
            phd12 = this.cellPHD1.Convert(this.params2) .* this.transMat(1,2);
            phd21 = this.cellPHD2.Convert(this.params1) .* this.transMat(2,1);
            
            % Combine cells that stay in the same motion model with cells
            % that switch from the other motion model.
            phd1 = phd11 + phd21;
            phd2 = phd22 + phd12;
            
            % Propagate all cells.
            phd1 = phd1.Propagate(this.params1);
            phd2 = phd2.Propagate(this.params2);
            
            oPHD = CellPHD_IMM(this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function RemoveUndetected(this)
            % Removes components which have never been detected.
            %
            % This function removes unobserved components, which represent
            % the intensity of targets that can appear for the first time.
            % The change is made directly to the CellPHD_IMM object, and
            % therefore there is no output.
            
            this.cellPHD1.RemoveUndetected();
            this.cellPHD2.RemoveUndetected();
        end
        
        function oPHD = Update(this, aBlobs)
            % Performs the Kalman filter update.
            %
            % The two GM-PHDs are updated separately, but without
            % normalizing the weights. The weights for all components that
            % correspond to the same measurement will be normalized so that
            % they sum to 1 together with the clutter.
            %
            % Inputs:
            % aBlobs - Array of Blob objects which represent measurements.
            %
            % Outputs:
            % oPHD - CellPHD_IMM object where the measurement update has
            %        been applied to the Gaussian components.
            
            % Perform separate measurement updates on the two GM-PHDs,
            % without normalizing the weights.
            phd1 = this.cellPHD1.Update(aBlobs, this.params1,...
                'Normalize', false);
            phd2 = this.cellPHD2.Update(aBlobs, this.params2,...
                'Normalize', false);
            
            % The clutter is assumed to be the same for both motion models.
            kappa = this.params1.kappa;
            
            for i = 1:length(aBlobs)
                % Find components in both GM-PHDs which correspond to
                % measurement (blob) i.
                index1 = phd1.z == i;
                index2 = phd2.z == i;
                
                w1 = phd1.w(index1);
                w2 = phd2.w(index2);
                
                total = sum(w1) + sum(w2) + kappa + realmin;
                
                phd1.w(index1) = w1 / total;
                phd2.w(index2) = w2 / total;
            end
            
            oPHD = CellPHD_IMM(...
                this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function oPHD = Prune(this)
            % Reduce the number of components in the Gaussian mixtures.
            %
            % The pruning is done separately in the two mixtures.
            %
            % Outputs:
            % oPHD - CellPHD_IMM object representing the pruned GM-PHD.
            
            phd1 = this.cellPHD1.Prune(this.params1);
            phd2 = this.cellPHD2.Prune(this.params2);
            oPHD = CellPHD_IMM(this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function oPHD = Gamma_start(this)
            % GM-PHD of objects present in the first image.
            %
            % oPHD - CellPHD_IMM object.
            
            phd1 = this.params1.gamma_start;
            phd2 = this.params2.gamma_start;
            oPHD = CellPHD_IMM(this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function oPHD = Gamma(this)
            % GM-PHD of appearing objects.
            %
            % Objects are assumed to appear with this intensity in each
            % frame, except the fist frame.
            %
            % oPHD - CellPHD_IMM object.
            
            phd1 = this.params1.gamma;
            phd2 = this.params2.gamma;
            oPHD = CellPHD_IMM(this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function Plot(this, aAx, aNum)
            % Plots the xy-coordinates of the means as green circles.
            %
            % Inputs:
            % aAx - Axes object where the coordinates will be plotted.
            % aNum - The maximum number of coordinates to plot in each of
            %        the two GM-PHDs. If there are more components in a
            %        GM-PHD, the function will plot the aNum components
            %        with the largest weights.
            
            this.cellPHD1.Plot(aAx, aNum)
            this.cellPHD2.Plot(aAx, aNum)
        end
        
        function PlotConfidence(this, aAx, aIndices1, aIndices2, aColors1, aColors2)
            % Plots confidence ellipsoids for all Gaussian components.
            %
            % The confidence ellipsoids contain 95 % of the probability
            % distributions of the Gaussian components.
            %
            % Inputs:
            % aAx - Axes to plot in.
            % aIndices1 - Array with indices of components in cellPHD1 to
            %             plot.
            % aColors1 - Colors for the components in cellPHD1. The input
            %            can be an RGB-triplet or a letter representing a
            %            single color, or a cell array of colors for the
            %            individual ellipses.
            % aIndices2 - Array with indices of components in cellPHD2 to
            %             plot.
            % aColors2 - Colors for the components in cellPHD2. The input
            %            can be an RGB-triplet or a letter representing a
            %            single color, or a cell array of colors for the
            %            individual ellipses.
            
            this.cellPHD1.PlotConfidence(aAx, aIndices1, aColors1)
            this.cellPHD2.PlotConfidence(aAx, aIndices2, aColors2)
        end
        
        function PlotContour(this, aAx, aX, aY, aColor1, aColor2)
            % Draw a contour plot of the GM-PHD.
            %
            % Inputs:
            % aAx - Axes to plot in.
            % aX - Array of x-values in the plotting grid.
            % aY - Array of y-values in the plotting grid.
            % aColor1 - RGB-triplet or character representing the color
            %           that the contours of cellPHD1 will be drawn in.
            % aColor2 - RGB-triplet or character representing the color
            %           that the contours of cellPHD2 will be drawn in.
            
            this.cellPHD1.PlotContour(this.params1, aAx, aX, aY, aColor1)
            this.cellPHD2.PlotContour(this.params2, aAx, aX, aY, aColor2)
        end
        
        function oPHD = plus(this, aPHD)
            % Operator which adds two CellPHD_IMM objects.
            %
            % Inputs:
            % aPHD - CellPHD_IMM object that will be added to the current
            %        object.
            %
            % Outputs:
            % oPHD - CellPHD_IMM object representing the sum of the
            %        GM-PHDs.
            
            phd1 = this.cellPHD1 + aPHD.cellPHD1;
            phd2 = this.cellPHD2 + aPHD.cellPHD2;
            oPHD = CellPHD_IMM(this.params1, this.params2, this.transMat, phd1, phd2);
        end
        
        function oPHD = times(this, aK)
            % Operator which multiplies a CellPHD_IMM object with a scalar.
            %
            % The multiplication is performed by multiplying the weights of
            % all Gaussian components by the scalar.
            %
            % Inputs:
            % aK - The scalar.
            %
            % Outputs:
            % oPHD - CellPHD_IMM representing the product between the
            %        original CellPHD_IMM and the scalar. The original
            %        CellPHD_IMM is not altered.
            
            oPHD = this.Copy();
            oPHD.cellPHD1.w = oPHD.cellPHD1.w*aK;
            oPHD.cellPHD1.w = oPHD.cellPHD1.w*aK;
        end
    end
end