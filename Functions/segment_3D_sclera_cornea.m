function Eye = segment_3D_sclera_cornea(MR, P)
% Finds the optimal eyeball model parameter for sclera and cornea according 
% to normal gradient matching and stores the results in the "Eye" structure.

% Transfer cornea center distance to pixel spacing
P.cornea_center_px = P.segment_3D.cornea_center_mm / MR.pixel_mm;

% Transformation matrix from imaging coordinates to MR scanner coordinates.
P.T = [MR.v_row, MR.v_col, MR.v_n];

% Initial estimation of eyeball parameters are based on typical anatomical 
% human eyeball values. Parameters that will be estimated here are (x0,
% radii sclera, rotation sclera, radii cornea, rotation sclera) each in
% x,y,z directions.
rad_lt_scl = 10.5 / MR.pixel_mm;
rad_tv_scl = 12 / MR.pixel_mm;
rad_lt_crn = (10.5 + 2 - P.segment_3D.cornea_center_mm)  / MR.pixel_mm;  
rad_tv_crn = 6  / MR.pixel_mm;
b0 = [0         , 1         , 0         , ...
      rad_tv_scl, rad_lt_scl, rad_tv_scl, ...
      0         , 0         , 0         , ...
      rad_tv_crn, rad_lt_crn, rad_tv_crn, ...
      0         , 0         , 0         ];

% lower & upper boundaries to exclude unrealistic values
max_pos = 4 / MR.pixel_mm ;
max_rot = 45;
max_rad = 3 / MR.pixel_mm;
max_b = [max_pos , max_pos, max_pos, ...
         max_rad , max_rad, max_rad, ...
         max_rot , max_rot, max_rot, ...
      	 max_rad , max_rad, max_rad, ...
         max_rot , max_rot, max_rot];
lb = b0 - max_b;
ub = b0 + max_b;

% We use a generalized patternsearch algorithm to find the global minimum.
% This is kind of a brute-force approach for problems which don't have a
% well defined gradient, so common gradient-descent methods don't apply.
% Patternsearch is essientally just a systematic way to wander through
% parameter space until no further improvement can be made. Empirical
% results are very good, but computation time is high.
options = optimoptions('patternsearch', ...
                       'Display', 'off', ...
                       'MeshTolerance', 1e-3, ...
                       'UseCompletePoll', true, ...
                       'Scale', false, ...
                       'PollMethod', 'GPSPositiveBasis2N', ...
                        'InitialMeshSize', 2);

    
%% Eyeball segmentation 
fprintf('\n\n###### 3D Eyeball Segmentation - Sclera & Cornea ######\n')
Eye = struct();
n_sca = length(P.segment_3D.scaling_mm2deg);
for iEye = 1:numel(MR.image)
    fprintf('Segmenting Eye %d/%d...\n', iEye, numel(MR.image))
    
    % Calculate the image gradients. Careful, the output of imgradientxyz
    % is ordered (col,row,3)! Throughout the algorithm, we always use the
    % (row,col,3) order.
    img = MR.image{iEye};
    [g_y, g_x, g_z] = imgradientxyz(img, 'central');
    grad = [g_x(:), g_y(:), g_z(:)];
    P.imsz = length(img);
    P.img_center = repmat(floor(P.imsz/2)+1, 3, 1);
    P.N_scl = round(P.segment_3D.grid_points_px * 4*pi*rad_tv_scl^2); 
    P.N_crn = round(P.segment_3D.grid_points_px * 4*pi*rad_tv_crn^2);
    b   = nan(n_sca, size(b0,2));
    GoF = nan(n_sca, 1);
    GoF_scl = nan(n_sca, 1);
    GoF_crn = nan(n_sca, 1);
    sca = nan(n_sca, 1);
    
    % Loop over each scaling. To use different scalings are helpful to find
    % the global minimum, because the patternsearch algorithm treats each 
    % parameter as dimensionless, i.e. doesn't differentiate between 
    % parameters expressed in degrees or mm. In order to find the global 
    % minimum, different degree to mm scalings can be used.
    for iSca = 1:n_sca
        fprintf('Scaling %d/%d ', iSca, n_sca)
        
        P.scaling = P.segment_3D.scaling_mm2deg(iSca);
        b0([7:9,13:15]) = b0([7:9,13:15]) / P.scaling;
        lb([7:9,13:15]) = lb([7:9,13:15]) / P.scaling;
        ub([7:9,13:15]) = ub([7:9,13:15]) / P.scaling;
        
        iB = patternsearch(@(b) -normal_gradient_matching_3D_sclera_cornea(b, grad, P), ...
                                b0, [], [], [], [], lb, ub, options);
        
        [m, m_scl, m_crn] = normal_gradient_matching_3D_sclera_cornea(iB, grad, P);
        
        iB([7:9,13:15]) = iB([7:9,13:15]) * P.scaling;
        b0([7:9,13:15]) = b0([7:9,13:15]) * P.scaling;
        lb([7:9,13:15]) = lb([7:9,13:15]) * P.scaling;
        ub([7:9,13:15]) = ub([7:9,13:15]) * P.scaling;
        
        GoF(iSca) = m;
        GoF_scl(iSca) = m_scl;
        GoF_crn(iSca) = m_crn;
        b(iSca,:) = iB;
        sca(iSca) = P.segment_3D.scaling_mm2deg(iSca);
        
        fprintf('completed\n')
    end
    % Take the best solution among the runs with different scalings
    [~, max_sca] = max(GoF);
    
    % Store results in the "Eye" struct
    max_b = b(max_sca,:);
    [~, ~, ~, ~, x0_crn] = eyeball_model_3D_sclera_cornea(max_b(1:3), max_b(4:6), max_b(7:9), max_b(10:12), max_b(13:15), P);
    Eye(iEye).x0_scl  = max_b(1:3) * MR.pixel_mm;
    Eye(iEye).rad_scl = max_b(4:6) * MR.pixel_mm;
    Eye(iEye).rot_scl = max_b(7:9);
    Eye(iEye).x0_crn  = x0_crn' * MR.pixel_mm;
    Eye(iEye).rad_crn = max_b(10:12) * MR.pixel_mm;
    Eye(iEye).rot_crn = max_b(13:15);
    Eye(iEye).fit_body_cornea.b        = b;
    Eye(iEye).fit_body_cornea.GoF      = GoF;
    Eye(iEye).fit_body_cornea.GoF_scl  = GoF_scl;
    Eye(iEye).fit_body_cornea.GoF_crn  = GoF_crn;
    Eye(iEye).fit_body_cornea.scaling  = sca;
    Eye(iEye).fit_body_cornea.best_sca = max_sca;
    P.pixel_mm = MR.pixel_mm;
    Eye(iEye).P = P;
end



