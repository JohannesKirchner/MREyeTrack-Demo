function MR = segment_2D(MR, Eye, P)
% Finds the optimal 2D projection according to normal gradient matching as
% a function of motion of the 3D eyeball

% Imaging Slice parameter
P.d = 0;
P.T = [MR.v_row, MR.v_col, MR.v_n];
P.pixel_mm = MR.pixel_mm;
P.imsz = size(MR.image{1}(:,:,1));
P.img_center = repmat(floor(P.imsz(1)/2)+1,3,1);

% As a starting point, assume no motion from 3D reference position
b0 = [0, 1, 0, 0, 0, 0];
lb = [b0(1:3) - 3, repmat(-45, 1, 3)];
ub = [b0(1:3) + 3, repmat( 45, 1, 3)];

% You can exclude torsional rotation from the analysis in the parameter
% settings
if ~P.segment_2D.include_torsion
    lb(5) = b0(5);
    ub(5) = b0(5);
end

% We use a generalized patternsearch algorithm to find the global minimum.
% This is kind of a brute-force approach for problems which don't have a
% well defined gradient, so common gradient-descent methods don't apply.
% Patternsearch is essientally just a systematic way to wander through
% parameter space until no further improvement can be made. Empirical
% results are very good, but computation time is high.
options = optimoptions('patternsearch', ...
                       'Display', 'off', ...
                       'MeshTolerance', 1e-2, ...
                       'UseCompletePoll', true, ...
                       'Scale', false, ...
                       'PollMethod', 'GPSPositiveBasis2N');
 
% create time vector                   
MR.image_range = 1:100;%size(MR.image{1},3);
MR.t = (MR.image_range-1)*MR.sampling_interval;

%% Eyeball segmentation
fprintf('\n\n###### 2D Eyeball Segmentation ######\n')
for iEye = 1:numel(MR.image)
    fprintf('Segmenting Eye %d/%d...\n', iEye, numel(MR.image))
    
    % Adjust Eye to pixel spacing
    Eye(iEye).x0_scl  = Eye(iEye).x0_scl / P.pixel_mm;
    Eye(iEye).x0_crn  = Eye(iEye).x0_crn / P.pixel_mm;
    Eye(iEye).x0_lns  = Eye(iEye).x0_lns / P.pixel_mm;
    Eye(iEye).rad_scl = Eye(iEye).rad_scl / P.pixel_mm;
    Eye(iEye).rad_crn = Eye(iEye).rad_crn / P.pixel_mm;
    Eye(iEye).rad_lns = Eye(iEye).rad_lns / P.pixel_mm;
    
    
    % Choose number of grid points roughly proportional to ellipse perimeter
    P.N_scl = round(4 * 2*pi*max(Eye(iEye).rad_scl));
    P.N_crn = round(4 * 2*pi*max(Eye(iEye).rad_crn));
    P.N_lns = round(4 * 2*pi*max(Eye(iEye).rad_lns));
    
    
    % Loop over images
    n_Sca = length(P.segment_2D.scaling_mm2deg);
    b   = nan(6, n_Sca, length(MR.image_range));
    GoF = nan(4, n_Sca, length(MR.image_range));
    MR.b{iEye}       = [];
    MR.GoF{iEye}     = [];
    MR.max_GoF{iEye} = [];
    MR.max_b{iEye}   = [];
    for iImg = 1:length(MR.image_range)
        if P.segment_2D.print_progress && rem(iImg-1,100) == 0
            fprintf('Segmenting Image %d/%d\n', iImg, length(MR.image_range))
        end
        
        % Calculate the image gradients. Careful, the output of imgradientxy
        % is ordered (col,row)! Throughout the algorithm, we always use the
        % (row,col) order.
        img = MR.image{iEye}(:,:,MR.image_range(iImg));
        [g_y, g_x] = imgradientxy(img, 'central');
        grad = [g_x(:), g_y(:)];
        
        % prepare b0 for each run
        if iImg ~= 1
            b0 = MR.max_b{iEye}(:,iImg-1) + 0.2*(rand(6,1)-0.5);
        end
        
        % Loop over each scaling. To use different scalings are helpful to find
        % the global minimum, because the patternsearch algorithm treats each 
        % parameter as dimensionless, i.e. doesn't differentiate between 
        % parameters expressed in degrees or mm. In order to find the global 
        % minimum, different degree to mm scalings can be used.
        for iSca = 1:n_Sca
            P.scaling = P.segment_2D.scaling_mm2deg(iSca);
            b0(4:6) = b0(4:6) / P.scaling;
            lb(4:6) = lb(4:6) / P.scaling;
            ub(4:6) = ub(4:6) / P.scaling;
            
            % Patternsearch algorithm
            iB = patternsearch(@(b) -normal_gradient_matching_2D(b, grad, Eye(iEye), P), ...
                b0, [], [], [], [], lb, ub, options);
            
            [m, m_scl, m_crn, m_lns] = normal_gradient_matching_2D(iB, grad, Eye(iEye), P);
            
            % Rescale before pursuing next run
            iB(4:6) = iB(4:6) * P.scaling;
            b0(4:6) = b0(4:6) * P.scaling;
            lb(4:6) = lb(4:6) * P.scaling;
            ub(4:6) = ub(4:6) * P.scaling;
            
            % Store Results for this scaling
            GoF(:,iSca,iImg) = [m, m_scl, m_crn, m_lns];
            b(:,iSca,iImg) = iB;
        end
        % store the results for this image
        MR.b{iEye}(:,:,iImg)   = b(:,:,iImg);
        MR.GoF{iEye}(:,:,iImg) = GoF(:,:,iImg);
        [~, idx_max_GoF] = max(squeeze(GoF(1,:,iImg)));
        MR.max_b{iEye}(:,iImg)   = b(:,idx_max_GoF,iImg);
        MR.max_GoF{iEye}(:,iImg) = GoF(:,idx_max_GoF,iImg);
        MR.x{iEye}(iImg) = MR.max_b{iEye}(1,iImg);
        MR.y{iEye}(iImg) = MR.max_b{iEye}(2,iImg);
        MR.z{iEye}(iImg) = MR.max_b{iEye}(3,iImg);
        MR.rot_x{iEye}(iImg) = MR.max_b{iEye}(4,iImg);
        MR.rot_y{iEye}(iImg) = MR.max_b{iEye}(5,iImg);
        MR.rot_z{iEye}(iImg) = MR.max_b{iEye}(6,iImg);
        MR.P{iEye} = P;
        
        % Update boundaries to restrict unreasonable out-of-plane motion
        if iImg == 1
            if strcmp(MR.plane, 'axial')
                lb(3) = MR.max_b{iEye}(3,iImg) - 1;
                ub(3) = MR.max_b{iEye}(3,iImg) + 1;
                lb(4) = MR.max_b{iEye}(4,iImg) - 5;
                ub(4) = MR.max_b{iEye}(4,iImg) + 5;
            elseif strcmp(MR.plane, 'sagittal')
                lb(1) = MR.max_b{iEye}(1,iImg) - 1;
                ub(1) = MR.max_b{iEye}(1,iImg) + 1;
                lb(6) = MR.max_b{iEye}(6,iImg) - 5;
                ub(6) = MR.max_b{iEye}(6,iImg) + 5;
            end
        end
    end
    
     
    % Adjust Eye back to mm
    Eye(iEye).x0_scl  = Eye(iEye).x0_scl * P.pixel_mm;
    Eye(iEye).x0_crn  = Eye(iEye).x0_crn * P.pixel_mm;
    Eye(iEye).x0_lns  = Eye(iEye).x0_lns * P.pixel_mm;
    Eye(iEye).rad_scl = Eye(iEye).rad_scl * P.pixel_mm;
    Eye(iEye).rad_crn = Eye(iEye).rad_crn * P.pixel_mm;
    Eye(iEye).rad_lns = Eye(iEye).rad_lns * P.pixel_mm;
    
    
    if P.segment_2D.plot_segmentation
        plot_2D_segmentation(MR, Eye, iEye)
        plot_parameter_dynamic(MR, iEye)
    end
end
end