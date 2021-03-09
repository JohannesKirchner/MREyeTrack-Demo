function vec = ellipsoid2slice(x0, rad, rot, T, d)

% Intersection with Body
x0 = reshape(x0, 3, 1);
S = diag(rad);
R = rot_3D(rot);

% Scale to centered unit sphere in order to find the circular intersection.
% Start by calculating the new plane normal vector and create an arbitrary
% orthonormal set based on that vector.
n = T(:,3);
m0 = S * R' * n / vecnorm(S * R' * n);
m1 = cross(m0, T(:,2));
m1 = m1 / vecnorm(m1);
m2 = cross(m1, m0);
m2 = m2 / vecnorm(m2);
% del is the distance from circle to sphere center and rho is the circle
% radius
del = (d - n'*x0) / vecnorm(S * R' * n);
rho = sqrt(1 - del^2);
% now rescale (granted there is an intersection) to the original coordinate
% system to determine the intersection with the ellipsoid
if isreal(rho) && rho > 0
    u1_pre = R * S * rho * m1;
    u2_pre = R * S * rho * m2;
    vec(:,1) = x0 + R * S * del * m0;
    
    % the two directional vectors are the conjugate diameters and not
    % necessarily perpendicular. We need to rotate them, such that they are
    % orthogonal and match the vertices
    alpha0 = 0.5*atan(2*u1_pre'*u2_pre / (u1_pre'*u1_pre - u2_pre'*u2_pre));
    vec(:,2) =  u1_pre * cos(alpha0) + u2_pre * sin(alpha0);
    vec(:,3) = -u1_pre * sin(alpha0) + u2_pre * cos(alpha0);
else
    vec = [];
end