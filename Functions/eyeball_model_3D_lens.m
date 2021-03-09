function [x_lns, vec_lns, x0_lns] = eyeball_model_3D_lens(rad_lns, rot_lns, Eye, P)

% Body - Modelled as an ellipsoid described by 3 position, 3 rotation and 3
% radii parameter
R_scl   = rot_3D(Eye.rot_scl);
x0_scl  = reshape(Eye.x0_scl,3,1);
rad_scl = Eye.rad_scl;

% Lens - Also modelled as an ellipsoid with fixed position at the border of the 
% eye body. The exact coordinates of the center are then computed by assuming 
% that the optical axis of the lens runs through body center. Lens radii and 3D 
% rotation are then the actual variables of the lens ellipsoid.
R_lns  = rot_3D(rot_lns);
lam    = 1 / vecnorm( diag(1./rad_scl) * R_scl' * R_lns * [0;-1;0] );
x0_lns = x0_scl + lam * R_lns * [0;-1;0];
x_lns  = x0_lns + R_lns * map_ellipsoid(rad_lns, P.N_lns);

% Outer Curvature Lens

  
% We only model the inner curvature of the lens. In order to do so, remove all 
% lens grid points lying inside the body ellipsoid (minus an indent parameter).
rad_scl = rad_scl - P.lens_indent_px;
in_bdy = vecnorm( diag(1./rad_scl) * R_scl' * (x_lns - x0_scl) ) < 1;
x_lns  = x_lns(:,in_bdy);

% Calculate the normal vector for each grid point. The vectors are defined to
% point in the direction of increasing intensity. Therefore, the vectors at
% lens border point outwards.
vec_lns = R_lns * diag(1./rad_lns.^2) * R_lns' * (x_lns - x0_lns);
vec_lns = vec_lns ./ vecnorm(vec_lns);
end