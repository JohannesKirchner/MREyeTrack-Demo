function S = fast_radial_symmetry_transform_3D(image, r, alpha)
% Generalization to 3D of the 'Fast Radial Symmetry Transform' as proposed 
% by S. De Zanet et al. in "Landmark Detection for Fusion of Fundus and MRI
% Toward a Patient-Specific Multimodal Eye Model", IEEE Transactions on
% biomedical engineering, 2015

% Default Parameter
if nargin < 3
    alpha = 2;
end

% Determine Image gradient vectors and their norm
imsz = size(image);
[x, y, z] = ndgrid(1:imsz(1), 1:imsz(2), 1:imsz(3));
[g_y, g_x, g_z] = imgradientxyz(image, 'sobel');
g_norm = sqrt(g_x.^2 + g_y.^2 + g_z.^2);
valid = g_norm(:) > 0;

% Perform the fast radial symmetry transform
nR  = length(r);
S_n = zeros([imsz,nR]);
for n = 1:nR
    O_n = zeros(imsz);
    
    pve = [x(valid), y(valid), z(valid)] + round(r(n) * [g_x(valid), g_y(valid), g_z(valid)] ./ g_norm(valid));
    
    idx = pve(:,1) + (pve(:,2)-1)*imsz(1) + (pve(:,3)-1)*prod(imsz(1:2));
    
    in_image = idx >= 1 & idx <= prod(imsz);
    idx = idx(in_image);
    
    for i = 1:length(idx)
        O_n(idx(i)) = O_n(idx(i)) + 1;
    end
    
    F_n = (O_n / max(abs(O_n(:)))).^alpha;
    
    S_n(:,:,:,n) = imgaussfilt3(F_n, r(n)/4);
end
S = sum(S_n, 4)/nR;