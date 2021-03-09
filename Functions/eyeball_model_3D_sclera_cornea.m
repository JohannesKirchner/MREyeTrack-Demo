function [x, vec, scl, vol, x0_crn] = eyeball_model_3D_sclera_cornea(x0, rad_scl, rot_scl, rad_crn, rot_crn, P)

% Sclera - Modelled as an ellipsoid described by 3 position, 3 rotation and 3
% radii parameter
R_scl  = rot_3D(rot_scl);
x0_scl = reshape(x0,3,1);
x_scl  = x0_scl + R_scl * map_ellipsoid(rad_scl, P.N_scl);

% Cornea - Also modelled as an ellipsoid with the center being fixed at a given 
% distance to eyeball body center. The exact coordinates of the center are then
% computed by assuming that the optical axis of the cornea runs through body
% center.
R_crn  = rot_3D(rot_crn);
x0_crn = x0_scl + P.cornea_center_px * R_crn * [0;-1;0];
x_crn  = x0_crn + R_crn * map_ellipsoid(rad_crn, P.N_crn);
  
% Combine sclera & cornea ellipsoid to the full eyeball model. In order to 
% do so, remove all sclera grid points lying inside the cornea ellipsoid 
% and vice versa.
out_crn = vecnorm( diag(1./rad_crn) * R_crn' * (x_scl - x0_crn) ) > 1;
x_scl   = x_scl(:,out_crn);
out_scl = vecnorm( diag(1./rad_scl) * R_scl' * (x_crn - x0_scl) ) > 1;
vol     = (4*pi/3)*prod(rad_crn)*sum(out_scl)/length(out_scl);
x_crn   = x_crn(:,out_scl);

% Calculate the normal vector for each grid point. The vectors are defined to
% point in the direction of increasing intensity. Therefore, the vectors at
% eye sclera & corneal border point inwards.
vec_scl = -R_scl * diag(1./rad_scl.^2) * R_scl' * (x_scl - x0_scl);
vec_scl = vec_scl ./ vecnorm(vec_scl);
vec_crn = -R_crn * diag(1./rad_crn.^2) * R_crn' * (x_crn - x0_crn);
vec_crn = vec_crn ./ vecnorm(vec_crn);

% Combine the two ellipsoids for the output, but introduce the logical variable
% 'scl' to keep track of grid point origin (sclera or cornea).
x   = [x_scl  , x_crn  ]; 
vec = [vec_scl, vec_crn];
scl = 1:length(x) <= length(x_scl);
end