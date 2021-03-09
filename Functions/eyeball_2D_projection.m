function [x, vec, scl, lns, crn] = eyeball_2D_projection(pos, rot, Eye, P)

% The 2D projection of the eyeball is based on the precise 3D measurements.
% Overall position and rotation are considered as the dynamic parameters that 
% are feeded into the fitting process

% Adjust cornea center and lends indent to px spacing
cornea_center_px = Eye.P.segment_3D.cornea_center_mm / P.pixel_mm;
lens_indent_px   = Eye.P.segment_3D.lens_indent_mm / P.pixel_mm;

% 2D Sclera Projection
R_scl_3D  = rot_3D(reshape(rot,3,1) + reshape(Eye.rot_scl,3,1));
x0_scl_3D = reshape(pos, 3, 1) + reshape(Eye.x0_scl, 3, 1);
v_scl = ellipsoid2slice(x0_scl_3D, Eye.rad_scl, R2ang(R_scl_3D), P.T, P.d);

% 2D Cornea Projection
R_crn_3D  = rot_3D(reshape(rot,3,1) + reshape(Eye.rot_crn,3,1));
x0_crn_3D = x0_scl_3D + cornea_center_px * R_crn_3D * [0;-1;0];
v_crn = ellipsoid2slice(x0_crn_3D, Eye.rad_crn, R2ang(R_crn_3D), P.T, P.d);

% 2D Lens Projection
if isfield(Eye, 'rot_lns')
    R_lns_3D  = rot_3D(reshape(rot,3,1) + reshape(Eye.rot_lns,3,1));
    lam       = 1 / vecnorm( diag(1./Eye.rad_scl) * R_scl_3D' * R_lns_3D * [0;-1;0] );
    x0_lns_3D = x0_scl_3D + lam * R_lns_3D * [0;-1;0];
    v_lns = ellipsoid2slice(x0_lns_3D, Eye.rad_lns, R2ang(R_lns_3D), P.T, P.d);
else
    v_lns = [];
end

% Calculate grid points
if ~isempty(v_scl)
    % Sclera grid points
    v_scl = P.T' * v_scl;
    v_scl(:,1) = v_scl(:,1) + P.img_center;
    [x0_scl, rad_scl, phi_scl] = slice2ellipse(v_scl, [1;0;0], [0;1;0]);
    x0_scl = reshape(x0_scl, 2, 1);
    R_scl  = rot_2D(phi_scl);
    x_scl  = x0_scl + R_scl * map_ellipse(rad_scl, P.N_scl);
    
    % If the current parameter range intersects the lens, continue by mapping it too
    if ~isempty(v_lns)
        % Lens
        v_lns = P.T' * v_lns;
        v_lns(:,1) = v_lns(:,1) + P.img_center;
        [x0_lns, r_lns, phi_lns] = slice2ellipse(v_lns, [1;0;0], [0;1;0]);
        x0_lns = reshape(x0_lns,2,1);
        R_lns  = rot_2D(phi_lns);
        x_lns  = x0_lns + R_lns * map_ellipse(r_lns, P.N_lns);
        
        % Combine lens & sclera. In order to do so, remove all lens grid points
        % lying outside of the sclera minus indent
        in_scl  = in_ellipse(x_lns, x0_scl, rad_scl - lens_indent_px, phi_scl);
        x_lns   = x_lns(:,in_scl);
        
        % Normal Vectors of the lens grid points
        vec_lns = R_lns * diag(1./r_lns.^2) * R_lns' * (x_lns - x0_lns);
        vec_lns = vec_lns ./ vecnorm(vec_lns);
    else
        x_lns     = [];
        vec_lns   = [];
    end
    
    % If the current parameter range intersects the cornea, continue by mapping it too
    if ~isempty(v_crn)
        % Cornea
        v_crn = P.T' * v_crn;
        v_crn(:,1) = v_crn(:,1) + P.img_center;
        [x0_crn, r_crn, phi_crn] = slice2ellipse(v_crn, [1;0;0], [0;1;0]);
        x0_crn = reshape(x0_crn,2,1);
        R_crn  = rot_2D(phi_crn);
        x_crn  = x0_crn + R_crn * map_ellipse(r_crn, P.N_crn);
        
        % Combine cornea & body. In order to do so remove, all body grid points
        % lying inside the cornea ellipse and all cornea grid points lying 
        % inside of the body ellipse
        out_crn = ~in_ellipse(x_scl, x0_crn, r_crn, phi_crn);
        x_scl   = x_scl(:,out_crn);
        out_scl = ~in_ellipse(x_crn, x0_scl, rad_scl, phi_scl);
        x_crn   = x_crn(:,out_scl);
        
        % Normal Vectors of the cornea grid points
        vec_crn = -R_crn * diag(1./r_crn.^2) * R_crn' * (x_crn - x0_crn);
        vec_crn = vec_crn ./ vecnorm(vec_crn);
    else
        x_crn     = [];
        vec_crn   = [];
    end    
    
    % Normal Vectors of the sclera grid points
    vec_scl = -R_scl * diag(1./rad_scl.^2) * R_scl' * (x_scl - x0_scl);
    vec_scl = vec_scl ./ vecnorm(vec_scl);
    
    % Combination to joint variables
    x   = [x_scl  , x_lns  , x_crn  ];
    vec = [vec_scl, vec_lns, vec_crn];
    scl = [ true(1,size(x_scl,2)), false(1,size(x_lns,2)), false(1,size(x_crn,2))];
    lns = [false(1,size(x_scl,2)),  true(1,size(x_lns,2)), false(1,size(x_crn,2))];
    crn = [false(1,size(x_scl,2)), false(1,size(x_lns,2)),  true(1,size(x_crn,2))];  
else
    x   = [];
    vec = [];
    scl = []; 
    lns = [];
    crn = [];
end

end

function x = map_ellipse(r, N)
    phi = linspace(2*pi/N, 2*pi, N);
    
    x = [r(1) * cos(phi); ...
         r(2) * sin(phi)];
end