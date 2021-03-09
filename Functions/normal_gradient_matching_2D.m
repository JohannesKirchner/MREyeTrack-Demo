function [metric, m_bdy, m_crn, m_lns] = normal_gradient_matching_2D(b, grad, Eye, P)

% Apply the eyeball model parameters to generate grid points and normal
% vector orientations 
[x, vec, bdy, lns, crn] = eyeball_2D_projection(b(1:3), b(4:6)*P.scaling, Eye, P); 

if ~isempty(x)
    % Project the grid points on the MRI image
    idx = int32(x(1,:)) + (int32(x(2,:))-1) * P.imsz(1);
    in_image = all(idx >= 1 & idx <= prod(P.imsz));
else
    in_image = false;
end

% Calculate the inner product of the template with the MRI image gradients
if in_image %&& length(unique(idx(lns))) > 5 && length(unique(idx(crn))) > 5
    m_bdy =  mean(sum(vec(:,bdy) .* grad(idx(bdy),:)'));
    m_lns =  mean(sum(vec(:,lns) .* grad(idx(lns),:)'));
    m_crn =  mean(sum(vec(:,crn) .* grad(idx(crn),:)'));
    metric = m_bdy + m_lns + m_crn;
%elseif in_image
%    m_bdy =  mean(sum(vec(:,bdy) .* grad(idx(bdy),:)'));
%    m_lns =  0;
%    m_crn =  0;
%    metric = 1.5*m_bdy;
else
    metric = -inf;
    m_bdy  = 0;
    m_lns  = 0;
    m_crn  = 0;
end

