function x = map_ellipsoid(r, N)

% Almost equiplanar Ellipsoid mapping with fibonacci lattice
grid  = 0:N-1;
phi   = pi * (1+sqrt(5)) * grid;
theta = acos(1-2*grid/N);

x = [r(1) * cos(phi) .* sin(theta); ...
     r(2) * sin(phi) .* sin(theta); ...
     r(3) * cos(theta)            ];
end