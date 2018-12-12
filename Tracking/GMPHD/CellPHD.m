classdef CellPHD < handle
    % Class representing a GM-PHD for tracking of cells and particles.
    %
    % This class is used to represent Gaussian Mixture Probability
    % Hypothesis Densities (GM-PHDs), which can be used in GM-PHD filters
    % to track cells and particles. In a PHD filter, a target intensity
    % (hypothesis density) is tracked over time. The filter does not keep
    % track of the individual targets. Instead, the integral of the
    % intensity over an area is the expected number of targets in that
    % area. Further, the number of targets is assumed to follow a Poisson
    % distribution. In a GM-PHD filter, the intensity is represented using
    % a Gaussian mixture. The Gaussian components are propagated and
    % updated according to the Kalman filter equation, and the Gaussian
    % mixture is pruned in each step to make the filter computationally
    % tractable. The Gaussian components of the GM-PHD can then be linked
    % into tracks using Viterbi track linking. The GM-PHD filter is
    % described in [1]. The math behind the propagation and update function
    % in this class are described in [1]. In [2], this class was used to
    % track simulated particles in the datasets of the ISBI 2012 Particle
    % Tracking Challenge.
    %
    % This class can be used to represent objects that follow either a
    % Brownian motion model or a constant velocity motion model, in 2D or
    % 3D.
    %
    % References:
    % [1] Vo, B.-N. & Ma, W.-K. The Gaussian mixture probability hypothesis
    %     density filter IEEE Trans. Signal Process., IEEE, 2006, 54,
    %     4091-4104
    %
    % [2] Magnusson, K. E. G. & Jaldén, J. Tracking of non-Brownian
    %     particles using the Viterbi algorithm Proc. 2015 IEEE Int. Symp.
    %     Biomed. Imaging (ISBI), 2015, 380-384
    %
    % See also:
    % CellPHD_IMM, ComputeGMPHD, MigLogLikeList_PHD_ISBI_tracks,
    % Parameters_GMPHD
    
    properties
        w  % Array of weights for the Gaussian components.
        m  % Matrix where the columns are means of the Gaussians.
        P  % 3D array where each 3D-slice is the covariance matrix of a Gaussian.
        z  % Array or measurement indices that the Gaussians correspond to.
        d  % Binary array saying which Gaussians have gone through measurement updates.
    end
    
    properties (Dependent = true)
        J;  % Number of components.
        n;  % The number of elements in the state of each target.
    end
    
    methods
        function this = CellPHD(aW, aM, aP, aZ, aD)
            % Constructor which defines a Gaussian mixture to start from.
            %
            % The function can also be called without arguments, to create
            % a dummy-object that can be used for pre-allocation of arrays.
            %
            % Inputs:
            % aW - Weights
            % aM - Means
            % aP - Covariance matrices
            % aZ - Measurement indices
            % aD - Optional binary array marking updated Gaussians. If the
            %      input is left out, all Gaussians are assumed not to have
            %      been updated by a measurement.
            
            if nargin == 0
                % Empty object used for pre-allocation of arrays.
                return
            end
            
            this.w = aW;
            this.m = aM;
            this.P = aP;
            this.z = aZ;
            if nargin > 4
                this.d = aD;
            else
                this.d = false(size(this.w));
            end
        end
        
        function J = get.J(this)
            % Returns the number of components in the Gaussian mixture.
            J = length(this.w);
        end
        
        function n = get.n(this)
            % Returns the length of the state vectors.
            n = size(this.m,1);
        end
        
        function oPHD = Copy(this)
            % Returns a deep copy of a CellPHD.
            oPHD = CellPHD(this.w, this.m, this.P, this.z, this.d);
        end
        
        function oPHD = Propagate(this, aParams)
            % Performs the Kalman filter prediction.
            %
            % Inputs:
            % aParams - Parameters for GM-PHD tracking.
            %
            % Outputs:
            % oPHD - CellPHD object where the Gaussian components have been
            %        propagated according to the motion model in aParams.
            
            F = aParams.F;
            Q = aParams.Q;
            pS = aParams.pS;
            
            % Decrease the weights to account for tracks that disappear.
            w_new = pS * this.w;
            
            % Propagated components have not been updated by measurements.
            z_new = nan(size(this.z));
            
            % Propagate the means.
            m_new = F * this.m;
            
            % Propagate the covariances.
            P_new = zeros(size(this.P));
            for j = 1:this.J
                P_new(:,:,j) = Q + F * this.P(:,:,j) * F';
                % Ensure exact symmetry.
                P_new(:,:,j) = (P_new(:,:,j) + P_new(:,:,j)')/2;
            end
            
            oPHD = CellPHD(w_new, m_new, P_new, z_new, this.d);
        end
        
        function RemoveUndetected(this)
            % Removes components which have never been detected.
            %
            % This function removes unobserved components, which represent
            % the intensity of targets that can appear for the first time.
            % The change is made directly to the CellPHD object, and
            % therefore there is no output.
            
            this.w = this.w(this.d);
            this.z = this.z(this.d);
            this.m = this.m(:,this.d);
            this.P = this.P(:,:,this.d);
            this.d = this.d(this.d);
        end
        
        function oPHD = Update(this, aBlobs, aParams, varargin)
            % Perform the Kalman filter measurement update.
            %
            % The measurement updates are performed by treating the blob
            % centroids as measurements of target locations. The
            % measurement updates take clutter and missed detections into
            % account.
            %
            % Inputs:
            % aBlobs - Array of Blob objects which represent measurements.
            % aParams - Parameters for GM-PHD tracking.
            %
            % Property/Value inputs:
            % Normalize - This parameter specifies if the weights of the
            %             Gaussian components should be normalized, so that
            %             they sum to 1 together with the weight of
            %             clutter. The default is true. This parameter
            %             should only be set to false when the function is
            %             called from derived classes which perform the
            %             normalization differently.
            %
            % Outputs:
            % oPHD - CellPHD object where the measurement update has been
            %        applied to the Gaussian components.
            
            % Parse property/value inputs.
            aNormalize = GetArgs({'Normalize'}, {true}, true, varargin);
            
            H = aParams.H;
            R = aParams.R;
            pD = aParams.pD;
            kappa = aParams.kappa;
            % Dimensionality of the observations.
            n_obs = size(aParams.H,1);
            
            % Expected measurement means.
            eta = H * this.m;
            % Expected measurement covariances.
            S = nan(n_obs, n_obs, this.J);
            
            % Compute covariances after measurement updates.
            P_kk = nan(this.n, this.n, this.J);
            for j = 1:this.J
                S(:,:,j) = R + H * this.P(:,:,j) * H';
                % Ensure exact symmetry.
                S(:,:,j) = (S(:,:,j) + S(:,:,j)') / 2;
                P_kk(:,:,j) = ( eye(this.n) - this.P(:,:,j)...
                    * H' * (S(:,:,j)\H) ) * this.P(:,:,j);
                % Ensure exact symmetry.
                P_kk(:,:,j) = (P_kk(:,:,j) + P_kk(:,:,j)')/2;
            end
            
            % Contribution from undetected targets.
            w_new = (1-pD) * this.w;
            z_new = nan(size(this.z));
            m_new = this.m;
            P_new = this.P;
            d_new = this.d;
            
            for l = 1:length(aBlobs)
                centroid = aBlobs(l).centroid(1:n_obs);
                dist2 = sum((this.m(1:n_obs,:) -...
                    repmat(centroid',1,this.J)).^2);
                
                % Only consider targets which are within 75 pixels of
                % the blob centroid. TODO: Make this threshold adaptable.
                candidates = find(dist2 <= 75^2 | ~this.d);
                J_new = length(candidates);
                
                % Create one new Gaussian component for each target which
                % is close enough to the measurement.
                w_add = nan(1, J_new);
                m_add = nan(this.n, J_new);
                P_add = nan(this.n, this.n, J_new);
                z_add = l * ones(1, J_new);
                for j = 1:J_new
                    i = candidates(j);
                    % Multiply the weight by the detection probability and
                    % the expected measurement likelihood taken over the
                    % propagated target distribution.
                    w_add(j) = pD * this.w(i) *...
                        GaussPDF(centroid', eta(:,i), S(:,:,i));
                    % Update the mean.
                    m_add(:,j) = this.m(:,i) +...
                        this.P(:,:,i) * H' * (S(:,:,i) \...
                        (centroid' - eta(:,i)));
                    % The covariance is independent of the measurement.
                    P_add(:,:,j) = P_kk(:,:,i);
                end
                
                % The weights of all targets are normalized so that they
                % sum to 1, together with the weight of clutter.
                if aNormalize
                    w_add = w_add / (kappa + sum(w_add) + eps(sum(w_add)));
                end
                
                w_new = [w_new w_add]; %#ok<AGROW>
                z_new = [z_new z_add]; %#ok<AGROW>
                m_new = [m_new m_add]; %#ok<AGROW>
                P_new = cat(3, P_new, P_add);
                d_new = [d_new true(size(w_add))]; %#ok<AGROW>
            end
            
            oPHD = CellPHD(w_new, m_new, P_new, z_new, d_new);
        end
        
        function oPHD = Prune(this, aParams)
            % Prunes the Gaussian mixture representing the PHD.
            %
            % The pruning is done by first removing small components and
            % then calling a pruning function which uses merging of
            % components to prune the mixture. Unobserved components, which
            % represent the intensity of targets that can appear for the
            % first time, are pruned separately as they must not be merged
            % with ordinary targets.
            %
            % Inputs:
            % aParams - Parameters for GM-PHD tracking.
            %
            % Outputs:
            % oPHD - CellPHD object representing the pruned GM-PHD.
            
            % Prune based on the component weights here so that merging
            % methods without pruning do not take too long.
            big_index = find(this.w > aParams.w_thresh);
            w_big = this.w(big_index);
            z_big = this.z(big_index);
            m_big = this.m(:,big_index);
            P_big = this.P(:,:,big_index);
            d_big = this.d(big_index);
            
            % Un-observed targets.
            w_seed = w_big(~d_big);
            z_seed = z_big(~d_big);
            m_seed = m_big(:,~d_big);
            P_seed = P_big(:,:,~d_big);
            
            % Prune un-observed target mixture.
            [w_seed, m_seed, P_seed, z_seed] =...
                GMMmergeKLdiv(w_seed, m_seed, P_seed, z_seed,...
                aParams.Jmax, aParams.w_thresh, aParams.kldiv_thresh);
            
            % Observed targets.
            w_true = w_big(d_big);
            z_true = z_big(d_big);
            m_true = m_big(:,d_big);
            P_true = P_big(:,:,d_big);
            
            % Prune observed target mixture.
            [w_true, m_true, P_true, z_true] =...
                GMMmergeKLdiv(w_true, m_true, P_true, z_true,...
                aParams.Jmax, aParams.w_thresh, aParams.kldiv_thresh);
            
            % Combine the observed and the un-observed targets again.
            w_new = [w_seed w_true];
            z_new = [z_seed z_true];
            m_new = [m_seed m_true];
            if isempty(P_seed)
                % To allow concatenation.
                P_seed = zeros(this.n,this.n,0);
            end
            if isempty(P_true)
                % To allow concatenation.
                P_true = zeros(this.n,this.n,0);
            end
            P_new = cat(3, P_seed, P_true);
            d_new = [false(size(w_seed)) true(size(w_true))];
            
            oPHD = CellPHD(w_new, m_new, P_new, z_new, d_new);
        end
        
        function Plot(this, aAx, aNum)
            % Plots the xy-coordinates of the means as green circles.
            %
            % Inputs:
            % aAx - Axes object where the coordinates will be plotted.
            % aNum - The maximum number of coordinates to plot. If there
            %        are more components in the Gaussian mixture, the
            %        function will plot the aNum components with the
            %        largest weights.
            
            [~, index] = sort(this.w, 'descend');
            for i = 1:min(aNum,length(index))
                plot(aAx, this.m(1,index(i)), this.m(2,index(i)), 'o',...
                    'Color', [0 0.75 0],...
                    'LineWidth', 2)
                hold on
            end
        end
        
        function PlotConfidence(this, aAx, aIndices, aColors)
            % Plots confidence ellipsoids for the mixture components.
            %
            % The confidence ellipsoids contain 95 % of the probability
            % distributions of the Gaussian components. There is also code
            % to draw velocity vectors, but that has been commented out.
            %
            % Inputs:
            % aAx - Axes to plot in.
            % aIndices - Array with indices of Gaussian components to plot.
            % aColors - RGB-triplet or letter representing a color, or a
            %           cell array of colors for the individual ellipses.
            
            % Confidence level for confidence ellipsoid.
            conf = 0.95;
            
            if ~iscell(aColors)
                % A single color is used for all components.
                aColors = repmat({aColors}, size(aIndices));
            end
            
            for i = 1:length(aIndices)
                index = aIndices(i);
                
                % Compute ellipse.
                [V, D] = eig(inv(this.P(1:2,1:2,index)));
                % Lengths of ellipse axes.
                alpha = sqrt(chi2inv(conf,2) ./ diag(D));
                % Create coordinates for a circle and scale the points
                % based on the coordinates in the coordinate system of the
                % ellipse axes.
                theta = 0:pi/50:2*pi;
                x = cos(theta);  % x-coordinates in circle.
                y = sin(theta);  % y-coordinates in circle.
                circle = [x; y];
                % Transform to ellipse coordinates, scale the circle and
                % transform back to normal coordinates.
                xy_ellipse = repmat(this.m(1:2,index),1,length(theta)) +...
                    V * diag(alpha) * V' * circle;
                
                % Plot ellipse.
                plot(aAx, xy_ellipse(1,:), xy_ellipse(2,:),...
                    'Color', aColors{i},...
                    'LineWidth', 2)
                
                % % Draw velocity vector.
                % if size(this.m,1) == 4
                %     s = this.m(:,index);
                %     plot(aAx, [s(1) s(1)-s(3)], [s(2) s(2)-s(4)],...
                %         'Color', aColors{i},...
                %         'LineWidth', 2)
                % end
            end
        end
        
        function PlotContour(this, aParams, aAx, aX, aY, aColor)
            % Draw a contour plot of the GM-PHD.
            %
            % Inputs:
            % aParams - Parameters for GM-PHD tracking.
            % aAx - Axes to plot in.
            % aX - Array of x-values in the plotting grid.
            % aY - Array of y-values in the plotting grid.
            % aColor - RGB-triplet or character representing the color that
            %          the contours will be drawn in.
            
            % Parameters.
            H = aParams.H;
            
            % Grid.
            [X, Y] = meshgrid(aX, aY);
            x = X(:);
            y = Y(:);
            
            % Height of the PHD.
            v = zeros(size(x));
            
            % Add one Gaussian component at a time to the PHD.
            for i = 1:length(this.w)
                eta = H * this.m(:,i);
                S = H * this.P(:,:,i) * H';
                % Ensure exact symmetry.
                S = (S + S') / 2;
                v = v + this.w(i) * mvnpdf([x y], eta', S);
            end
            
            V = reshape(v,size(X));
            contour(aAx, X, Y, V, 10.^(-6:0), 'Color', aColor)
        end
        
        function oPHD = Convert(this, aParams)
            % Switches between Brownian and constant velocity motion.
            %
            % This function will change the means and the covariances of
            % the Gaussian components, so that they can be used in a
            % different motion model. Components with constant velocity
            % motion can be converted to components with Brownian motion by
            % removing the velocity states. Brownian components can be
            % converted to constant velocity motion components, by
            % appending velocities and velocity covariances that are
            % normally given to newly appearing targets.
            %
            % Inputs:
            % aParams - New parameters for GM-PHD tracking.
            %
            % Outputs:
            % oPHD - CellPHD object where the states and the covariances
            %        have been converted to the new motion model.
            
            % Unaltered properties.
            n_old = this.n;
            w_new = this.w;
            z_new = this.z;
            d_new = this.d;
            
            % Convert the means and the covariances.
            n_new = size(aParams.F,1);
            if n_new < n_old
                % Convert from Brownian to constant velocity motion by
                % removing the velocity states.
                m_new = this.m(1:n_new,:);
                P_new = this.P(1:n_new,1:n_new,:);
            else
                % Convert from Brownian to constant velocity motion by
                % appending velocities and velocity covariances of
                % appearing objects.
                gamma = aParams.gamma_start;
                m_new = [this.m(1:n_old,:)
                    repmat(gamma.m(n_old+1:n_new), 1, this.J)];
                % Indexing the whole P-array with colons prevents a
                % warning, which will become an error in a future release,
                % from occurring when the P is empty.
                P_new = [this.P(1:n_old,1:n_old,:)...
                    repmat(gamma.P(1:n_old,n_old+1:n_new), [1 1 this.J])
                    repmat(gamma.P(n_old+1:n_new,1:n_new), [1 1 this.J])];
            end
            
            oPHD = CellPHD(w_new, m_new, P_new, z_new, d_new);
        end
        
        function oPHD = plus(this, aPHD)
            % Operator which adds two CellPHD objects.
            %
            % The addition is performed by concatenating the Gaussian
            % components of the two GM-PHDs.
            %
            % Inputs:
            % aPHD - CellPHD object that will be added to the current
            %        object.
            %
            % Outputs:
            % oPHD - CellPHD object representing the sum of the GM-PHDs.
            
            w_new = [this.w aPHD.w];
            z_new = [this.z aPHD.z];
            m_new = [this.m aPHD.m];
            P_new = cat(3,this.P, aPHD.P);
            d_new = [this.d aPHD.d];
            oPHD = CellPHD(w_new, m_new, P_new, z_new, d_new);
        end
        
        function oPHD = times(this, aK)
            % Operator which multiplies a CellPHD object with a scalar.
            %
            % The multiplication is performed by multiplying the weights of
            % the Gaussian components by the scalar.
            %
            % Inputs:
            % aK - The scalar.
            %
            % Outputs:
            % oPHD - CellPHD representing the product between the original
            %        CellPHD and the scalar. The original CellPHD is not
            %        altered.
            
            oPHD = this.Copy();
            oPHD.w = oPHD.w*aK;
        end
    end
end