function metric = normal_gradient_matching_3D_lens(b, grad, Eye, P)

% Apply the eyeball model parameters to generate grid points and normal
% vector orientations
[x, vec] = eyeball_model_3D_lens(b(1:3), b(4:6)*P.scaling, Eye, P);
        
% Project the grid points on the MRI image
x   = P.T' * x + P.img_center;
vec = P.T' * vec;
idx  = int32(x(1,:)) + (int32(x(2,:))-1) * P.imsz + (int32(x(3,:))-1) * P.imsz^2;
in_image = all(idx >= 1 & idx <= P.imsz^3);

% Calculate the inner product of the template with the MRI image gradients
if in_image
    metric = mean(sum(vec .* grad(idx,:)'));
else
    metric = 0;
end