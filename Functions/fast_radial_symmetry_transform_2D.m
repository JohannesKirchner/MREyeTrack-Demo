function S = fast_radial_symmetry_transform_2D(image, r, luminance, alpha)
% Implementation of the 'Fast Radial Symmetry Transform' as proposed by 
% G. Loy and A. Zelinsky, “Fast Radial Symmetry Operator for Detecting 
% Points of Interest”, IEEE Transactions on pattern analysis and machine 
% intelligence, 2003
%
% The nomenclature in this code is as close as possible to the original
% paper. Parameters and minor adjustments are chosen such that our task,
% the segmentation of the human eyeball in MRI images, is optimized.
%
% We chose to include only the Orientation projection O_n and not
% the Magnitude projection M_n (as suggested by the authors), because the
% eye is highly symmetrical but does not necessarily have the highest
% intensity in MRI images. We also collected only negatively-affected or 
% positively-affected pixel (chooseable with the parameter luminance being 
% 1 or -1) in order to segment the eyeball more accurately.
%
% r may be a vector of integer radii of interest, typically chosen such 
% that it covers radii of 11-13mm. By default, luminance is 1 (may depend 
% on the specific MRI sequence) and alpha is 2

% Default Parameter
if nargin < 4
    alpha = 2;
    if nargin < 3
        luminance = 1;
    end
end

% Determine Image gradient vectors and their norm
[g_y, g_x] = imgradientxy(image, 'sobel');
g_norm = sqrt(g_x.^2 + g_y.^2);
imsz = size(image);

% Perform the fast radial symmetry transform
nR  = length(r);
S_n = zeros([imsz,nR]);
for n = 1:nR
    O_n = zeros(imsz);
    for iX = 1:imsz(1)
        for iY = 1:imsz(2)
            if g_norm(iX,iY) > 0
                vec = round([g_x(iX,iY),g_y(iX,iY)] * r(n) / g_norm(iX,iY));
                
                pve = [iX,iY] + luminance*vec;
                
                if pve(1) >= 1 && pve(1) <= imsz(1) && pve(2) >= 1 && pve(2) <= imsz(2)
                    O_n(pve(1),pve(2)) = O_n(pve(1),pve(2)) + luminance;
                end
            end
        end
    end
    F_n = sign(O_n) .* (O_n / max(abs(O_n(:)))).^alpha;
    
    A_n = fspecial('gaussian', [r(n), r(n)], r(n)/4);
    
    S_n(:,:,n) = imfilter(F_n, A_n);
end
S = sum(S_n, 3)/nR;