function Eye = segment_3D_lens(MR, Eye)
% Finds the optimal eyeball model parameter for the lens according to 
% normal gradient matching and adds the results to the "Eye" structure.

% Transfer lens indent to pixel spacing
P = Eye(1).P;
P.lens_indent_px = P.segment_3D.lens_indent_mm / MR.pixel_mm;

% Initial estimation of eyeball parameters are based on typical anatomical 
% human eyeball values. Parameters that will be estimated here are (radii 
% lens, rotation lens) each in x,y,z directions.
rad_lt_lns = 5 / MR.pixel_mm;
rad_tv_lns = 5 / MR.pixel_mm;
b0 = [rad_tv_lns, rad_lt_lns, rad_tv_lns, ...
      0         , 0         , 0         ];
  
% lower & upper boundaries
max_rot = 45;
max_rad = 3 / MR.pixel_mm;
max_b = [max_rad , max_rad, max_rad, ...
         max_rot , max_rot, max_rot];
lb = b0 - max_b;
ub = b0 + max_b;

    
%% Eyeball segmentation 
fprintf('\n\n###### 3D Eyeball Segmentation - Lens ######\n')
n_sca = length(P.segment_3D.scaling_mm2deg);
for iEye = 1:numel(MR.image)
    fprintf('Segmenting Eye %d/%d...\n', iEye, numel(MR.image))
    
    % Transfer Eye to px
    Eye(iEye).x0_scl  = Eye(iEye).x0_scl  / MR.pixel_mm;
    Eye(iEye).rad_scl = Eye(iEye).rad_scl / MR.pixel_mm;
    Eye(iEye).x0_crn  = Eye(iEye).x0_crn  / MR.pixel_mm;
    Eye(iEye).rad_crn = Eye(iEye).rad_crn / MR.pixel_mm;
    
    % Calculate the image gradients. Careful, the output of imgradientxyz
    % is ordered (col,row,3)! Throughout the algorithm, we always use the
    % (row,col,3) order.
    img = MR.image{iEye};
    [g_y, g_x, g_z] = imgradientxyz(img, 'central');
    grad = [g_x(:), g_y(:), g_z(:)];
    
    % We used a generalized patternsearch algorithm to find the global minimum.
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
                           'PollMethod', 'GPSPositiveBasis2N');
    P.N_lns = round(P.segment_3D.grid_points_px * 4*pi*rad_tv_lns^2); 
    b   = nan(n_sca, size(b0,2));
    GoF = nan(n_sca, 1);
    sca = nan(n_sca, 1);
    
    % Loop over each scaling. To use different scalings are helpful to find
    % the global minimum, because the patternsearch algorithm treats each
    % parameter as dimensionless, i.e. doesn't differentiate between
    % parameters expressed in degrees or mm. In order to find the global
    % minimum, different degree to mm scalings can be used.
    for iSca = 1:n_sca
        fprintf('Scaling %d/%d ', iSca, n_sca)
        
        P.scaling = P.segment_3D.scaling_mm2deg(iSca);
        b0(4:6) = b0(4:6) / P.scaling;
        lb(4:6) = lb(4:6) / P.scaling;
        ub(4:6) = ub(4:6) / P.scaling;
        
        iB = patternsearch(@(b) -normal_gradient_matching_3D_lens(b, grad, Eye(iEye), P), ...
                                b0, [], [], [], [], lb, ub, options);
        
        fval = normal_gradient_matching_3D_lens(iB, grad, Eye(iEye), P);
        
        iB(4:6) = iB(4:6) * P.scaling;
        b0(4:6) = b0(4:6) * P.scaling;
        lb(4:6) = lb(4:6) * P.scaling;
        ub(4:6) = ub(4:6) * P.scaling;
        
        GoF(iSca) = fval;
        b(iSca,:) = iB;
        sca(iSca) = P.segment_3D.scaling_mm2deg(iSca);
        
        fprintf('completed\n')
    end
    [~, max_sca] = max(GoF);
    
    % Store results in a structure
    max_b = b(max_sca, :);
    [~, ~, x0_lns] = eyeball_model_3D_lens(max_b(1:3), max_b(4:6), Eye(iEye), P);
    Eye(iEye).x0_lns  = x0_lns' * MR.pixel_mm;
    Eye(iEye).rad_lns = max_b(1:3) * MR.pixel_mm;
    Eye(iEye).rot_lns = max_b(4:6);
    Eye(iEye).fit_lens.b        = b;
    Eye(iEye).fit_lens.GoF      = GoF;
    Eye(iEye).fit_lens.scaling  = sca;
    Eye(iEye).fit_lens.best_sca = max_sca;
    Eye(iEye).P = P;
    
    % Transfer back to mm
    Eye(iEye).x0_scl  = Eye(iEye).x0_scl  * MR.pixel_mm;
    Eye(iEye).rad_scl = Eye(iEye).rad_scl * MR.pixel_mm;
    Eye(iEye).x0_crn  = Eye(iEye).x0_crn  * MR.pixel_mm;
    Eye(iEye).rad_crn = Eye(iEye).rad_crn * MR.pixel_mm;
    
    % plot the fit if desired
    if P.segment_3D.plot_segmentation
        plot_3D_segmentation(MR, Eye, iEye)
    end
end



