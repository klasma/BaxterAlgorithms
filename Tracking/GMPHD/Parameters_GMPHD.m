classdef Parameters_GMPHD < handle
    % Parameters for GM-PHD tracking.
    %
    % This class contains parameters that are necessary for tracking using
    % Gaussian Mixture Probability Hypothesis Density (GM-PHD) filtering.
    % The class compiles tracking settings and constructs the corresponding
    % Kalman filter matrices and CellPHDs. The fields of the class define a
    % linear Gaussian motion model, probabilities of detection and target
    % termination, the densities of clutter and appearing targets, and
    % parameters for reduction of the Gaussian mixtures representing the
    % target densities in each time step. The class contains definitions of
    % motion models for the simulated particles (vesicles, microtubules,
    % receptors, and viruses) of the ISBI 2012 Particle Tracking Challenge,
    % and for the Drosophila melanogaster nuclei of the ISBI 2015 Cell
    % Tracking Challenge. A Brownian constant position model is used for
    % the vesicles, and constant velocity models are used for the
    % microtubles and the Drosophila nuclei. Switching models are used for
    % the receptors and the viruses. In the switching models, the particles
    % switch between constant position and constant velocity. The switching
    % models are implemented by creating one Parameters_GMPHD object for
    % the constant position model and one for the constant velocity model.
    % The class also has an experimental motion model with constant
    % acceleration, that can be used for the Drosophila nuclei. This class
    % can create parameters for tracking in both 2D and 3D.
    %
    % See also:
    % CellPHD, CelPHD_IMM, ComputeGMPHD, ComputeGMPHD_IMM,
    % MigLogLikeList_PHD_ISBI_tracks, MigLogLikeList_PHD_ISBI_IMM,
    % MigLogLikeList_PHD_DRO, GammaBorders, GMMmergeKLdiv
    
    properties
        kappa         % Intensity of clutter.
        pS            % Probability that a target still exists in the next frame.
        pD            % Probability of detection.
        gamma_start   % Intensity of preexisting objects in the first frame.
        gamma         % Birth intensity.
        F             % Prediction matrix.
        H             % Measurement matrix.
        Q             % Input covariance.
        R             % Noise covariance.
        w_thresh      % Lower bound on component weight.
        kldiv_thresh  % KL-divergence threshold for merging of components.
        Jmax          % Upper bound on the number of components.
    end
    
    methods
        function this = Parameters_GMPHD(aImData)
            % Constructs parameters for GM-PHD tracking.
            %
            % Inputs:
            % aImData - ImageData object associated with the image
            %           sequence. The tracking parameters are defined based
            %           on the settings in aImData. The names of the
            %           settings related to GM-PHD tracking start with
            %           'TrackGM'.
            
            % Image dimensions.
            w = aImData.imageWidth;
            h = aImData.imageHeight;
            d = aImData.numZ;
            n = aImData.GetDim();
            
            this.kappa = aImData.Get('TrackGMkappa');
            this.pS = aImData.Get('TrackGMpS');
            this.pD = aImData.Get('TrackGMpD');
            
            % Define variables for commonly used expressions. I is
            % isotropic in voxel units while J is isotropic in physical
            % length units.
            I = eye(n);
            O = zeros(n);
            o = zeros(n,1);
            if n == 2
                J = eye(2);
                center = [(w+1)/2; (h+1)/2];
                v = w*h;
            else
                J = diag([1 1 1/aImData.voxelHeight]);
                center = [(w+1)/2; (h+1)/2; (d+1)/2];
                v = w*h*d;
            end
            
            w_gamma_start = (aImData.Get('TrackGMn')/v) /...
                mvnpdf(center, center, 1E8*I);
            w_gamma = aImData.Get('TrackGMgamma') /...
                mvnpdf(center, center, 1E8*I);
            
            switch aImData.Get('TrackGMModel')
                case 'ConstantPosition'
                    % Constant position Brownian motion model for vesicles
                    % and receptors or viruses in the constant position
                    % state.
                    
                    % Kalman filter matrices.
                    this.F = I;
                    this.H = I;
                    this.Q = aImData.Get('TrackGMStdX')^2 * J^2;
                    % The measurement uncertainty is given in voxels and
                    % does not depend on the ratio between the voxel height
                    % and the voxel width.
                    this.R = aImData.Get('TrackGMr')^2 * I;
                    
                    % Objects in the first frame and appearing objects.
                    this.gamma_start =...
                        CellPHD(w_gamma_start, center, 1E8*I, nan);
                    this.gamma = CellPHD(w_gamma, center, 1E8*I, nan);
                    if aImData.Get('TrackMigInOut')
                        this.gamma = this.gamma +...
                            GammaBorders(aImData, this.Q);
                    end
                case 'ConstantVelocity'
                    % Constant velocity motion model for microtubules and
                    % receptors or viruses in the constant velocity state.
                    
                    % Kalman filter matrices.
                    this.F = [I I; O I];
                    this.H = [I O];
                    this.Q = aImData.Get('TrackGMq') *...
                        [1/3*J^2 1/2*J^2; 1/2*J^2 J^2];
                    % The measurement uncertainty is given in voxels and
                    % does not depend on the ratio between the voxel height
                    % and the voxel width.
                    this.R = aImData.Get('TrackGMr')^2*I;
                    
                    % Objects in the first frame and appearing objects.
                    varV = aImData.Get('TrackGMStdV')^2;
                    this.gamma_start = CellPHD(...
                        w_gamma_start,...
                        [center; o],...
                        [1E8*I O; O varV*J^2],...
                        nan);
                    this.gamma = CellPHD(...
                        w_gamma,...
                        [center; o],...
                        [1E8*I O; O varV*J^2],...
                        nan);
                    if aImData.Get('TrackMigInOut')
                        this.gamma = this.gamma +...
                            GammaBorders(aImData, this.Q);
                    end
                case 'ConstantVelocity_DRO'
                    % Constant velocity motion model for nuclei in
                    % Drosophila melanogaster embryos. The difference
                    % compared to 'ConstantVelocity' is that the
                    % observation uncertainty is isotropic in physical
                    % length units instead of voxels.
                    
                    % Kalman filter matrices.
                    this.F = [I I; O I];
                    this.H = [I O];
                    this.Q = aImData.Get('TrackGMq') *...
                        [1/3*J^2 1/2*J^2; 1/2*J^2 J^2];
                    % The measurement uncertainty is isotropic in the
                    % coordinate system of the sample and therefore depends
                    % on the ratio between the voxel height and the voxel
                    % width.
                    this.R = aImData.Get('TrackGMr')^2 * J^2;
                    
                    % Objects in the first frame and appearing objects.
                    varV = aImData.Get('TrackGMStdV')^2;
                    this.gamma_start = CellPHD(...
                        w_gamma_start,...
                        [center; o],...
                        [1E8*I O; O varV*J^2],...
                        nan);
                    this.gamma = CellPHD(...
                        w_gamma,...
                        [center; o],...
                        [1E8*I O; O varV*J^2],...
                        nan);
                    if aImData.Get('TrackMigInOut')
                        this.gamma = this.gamma +...
                            GammaBorders(aImData, this.Q);
                    end
                case 'ConstantAcceleration_DRO'
                    % Constant acceleration motion model for nuclei in
                    % Drosophila melanogaster embryos.
                    
                    % Kalman filter matrices.
                    this.F = [...
                        I I O
                        O I I
                        O O I];
                    this.H = [I O O];
                    this.Q = aImData.Get('TrackGMq') *...
                        [1/3*J 1/2*J J]' * [1/3*J 1/2*J J];
                    % The measurement uncertainty is isotropic in the
                    % coordinate system of the sample and therefore depends
                    % on the ratio between the voxel height and the voxel
                    % width.
                    this.R = aImData.Get('TrackGMr')^2 * J^2;
                    
                    % Objects in the first frame and appearing objects.
                    varV = aImData.Get('TrackGMStdV')^2;
                    varA = 1^2;  % Starting acceleration.
                    this.gamma_start = CellPHD(...
                        w_gamma_start,...
                        [center; o; o],...
                        [1E8*I O O; O varV*J^2 O; O O varA*J^2],...
                        nan);
                    this.gamma = CellPHD(...
                        w_gamma,...
                        [center; o; o],...
                        [1E8*I O O; O varV*J^2 O; O O varA*J^2],...
                        nan);
                    % TODO: Handle objects that enter the field of view.
                otherwise
                    error('Unknown motion model %s.',...
                        aImData.Get('TrackGMModel'))
            end
            
            % Parameters for reduction of Gaussian mixtures.
            this.w_thresh = aImData.Get('TrackGMw_thresh');
            this.kldiv_thresh = aImData.Get('TrackGMKLdiv_thresh');
            this.Jmax = aImData.Get('TrackGMJmax');
        end
    end
end