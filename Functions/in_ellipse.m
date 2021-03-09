function inside = in_ellipse(x, x0, r, phi)
    inside = vecnorm( diag(1./r) * rot_2D(-phi) * (x - reshape(x0,2,1)) ) < 1;
end