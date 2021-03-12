function [metric, m_scl, m_crn] = normal_gradient_matching_3D_sclera_cornea(b, grad, P)

% Apply the eyeball model parameters to generate grid points and normal
% vector orientations
[x, vec, bdy, vol] = eyeball_model_3D_sclera_cornea(b(1:3), b(4:6), b(7:9)*P.scaling, b(10:12), b(13:15)*P.scaling, P);
        
% Project the grid points on the MRI image
x   = P.T' * x + P.img_center;
vec = P.T' * vec;
idx  = int32(x(1,:)) + (int32(x(2,:))-1) * P.imsz + (int32(x(3,:))-1) * P.imsz^2;
in_image = all(idx >= 1 & idx <= P.imsz^3);

% Calculate the inner product of the template with the MRI image gradients,
% ensure a minimal corneal volume to save some computation time
if in_image && vol > 100
    m_scl = mean(sum(vec(:, bdy) .* grad(idx( bdy),:)'));
    m_crn = mean(sum(vec(:,~bdy) .* grad(idx(~bdy),:)'));
    
    metric = m_scl + m_crn;
else
    metric = -inf;
    m_scl = [];
    m_crn = [];
end