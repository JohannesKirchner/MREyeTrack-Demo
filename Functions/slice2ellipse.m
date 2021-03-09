function [pos, r, phi] = slice2ellipse(vec, v1, v2)

pos = project(vec(:,1), v1, v2);
r_1 = project(vec(:,2), v1, v2);
r_2 = project(vec(:,3), v1, v2);
r = [norm(r_1), norm(r_2)];
phi = atan2d(r_2(1), r_2(2));

function vec = project(vec, v1, v2)
    vec = [vec' * v1 / norm(v1),  vec' * v2 / norm(v2)];
end

end
