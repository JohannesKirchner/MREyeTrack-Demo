function plot_3D_segmentation(MR, Eye, iEye)
% Plots the segmentation in axial, coronal & sagittal slices and the 3D 
% grid points on top of the 3D MR image. Slice position is adjustable
% through a slice slider

% Adjust Eye to pixel spacing
Eye = Eye(iEye);
Eye.x0_scl  = Eye.x0_scl  / MR.pixel_mm;
Eye.rad_scl = Eye.rad_scl / MR.pixel_mm;
Eye.x0_crn  = Eye.x0_crn  / MR.pixel_mm;
Eye.rad_crn = Eye.rad_crn / MR.pixel_mm;
if isfield(Eye,'x0_lns')
    Eye.x0_lns  = Eye.x0_lns  / MR.pixel_mm;
    Eye.rad_lns = Eye.rad_lns / MR.pixel_mm;
end

% 3D Image
img = MR.image{iEye};
P = Eye.P;

% Initialize Figure
fig = figure;
fig.Position(3:4) = 700*[1,1];
for i = 1:4
    ax(i) = subplot(2,2,i);
end
set(ax, 'nextPlot', 'add')
title(ax(1), 'Axial Slice', 'Fontsize', 15)
title(ax(2), 'Coronal Slice', 'Fontsize', 15)
title(ax(3), 'Sagittal Slice', 'Fontsize', 15)
title(ax(4), '3D Grid Points', 'Fontsize', 15)

% Slice Slider
fig_size = get(gcf,'Position');
for i = 1:3
    ax_pos = get(ax(i),'Position');
    slider_pos = [ax_pos(1)*fig_size(3) + 35, ax_pos(2)*fig_size(4) - 40, ...
                  round(0.75*fig_size(3)*ax_pos(3)), 20];
    txt_pos = slider_pos + [0,20,0,-5];
    txt = uicontrol('Style', 'text', ...
        'Position', txt_pos, ...
        'String', sprintf('Slice# %d / %d',P.img_center(i), P.imsz), ...
        'FontSize', 10);
    uicontrol('Style', 'slider', ...
        'Min', 1, ...
        'Max', P.imsz, ...
        'Value', P.img_center(i), ...
        'SliderStep', [1/(P.imsz-1), 10/(P.imsz-1)], ...
        'Position', slider_pos, ...
        'Callback', {@SliceSlider, img, Eye, ax, P, txt, i});
end

% Plot axial, coronal & sagittal slices
for i = 1:3
    map_slice(i, P.img_center(i), img, Eye, ax, P);
end

% Plot 3D grid points
[x, ~, scl] = eyeball_model_3D_sclera_cornea(Eye.x0_scl, Eye.rad_scl, Eye.rot_scl, Eye.rad_crn, Eye.rot_crn, P);
scatter3(ax(4), -.5 + x(1, scl), .5 + x(2, scl), -.5 + x(3, scl), 1, [0.9922,0.6941,0.2784])
scatter3(ax(4), -.5 + x(1,~scl), .5 + x(2,~scl), -.5 + x(3,~scl), 1, [0.4588,0.7333,0.9922])
if isfield(Eye,'x0_lns')
    y = eyeball_model_3D_lens(Eye.rad_lns, Eye.rot_lns, Eye, P);
    scatter3(ax(4), -.5 + y(1, :), .5 + y(2, :), -.5 + y(3, :), 1, [0.4313,0.7961,0.2353])
end
[gx,gy] = meshgrid(-floor(P.imsz/2):floor(P.imsz/2));
surf(ax(4), -gx,gy,zeros(size(gx)),squeeze(img(36,:,:)))
surf(ax(4), zeros(size(gx)),gx,-gy,squeeze(img(:,:,36)))
colormap(ax(4), 'gray')

end

function SliceSlider(hObj, ~, img, Eye, ax, P, txt, i)
    d = round(get(hObj,'Value'));
    map_slice(i, d, img, Eye, ax, P)
    set(txt, 'String', sprintf('Slice# %d / %d', d, size(img,i)));
end

function map_slice(iAx, d, img, Eye, ax, P)
    cla(ax(iAx))
    if iAx == 1
        img = squeeze(img(d,:,:));
        v_n = [1;0;0];
        v_1 = [0;1;0];
        v_2 = [0;0;1];
    elseif iAx == 2
        img = squeeze(img(:,d,:));
        v_n = [0;1;0];
        v_1 = [1;0;0];
        v_2 = [0;0;1];
    elseif iAx == 3
        img = squeeze(img(:,:,d));
        v_n = [0;0;1];
        v_1 = [1;0;0];
        v_2 = [0;1;0];
    end
    imshow(img, [0,1.5], 'Parent', ax(iAx))
    
    P.T = P.T * [v_1,v_2,v_n];
    P.d = d - P.img_center(iAx);
    
    [x, ~, bdy, lns, crn] = eyeball_2D_projection([0,0,0], [0,0,0], Eye, P);
    if ~isempty(x)
        plot(ax(iAx), x(2,bdy), x(1,bdy), '.', 'color', [0.9922,0.6941,0.2784])
        plot(ax(iAx), x(2,crn), x(1,crn), '.', 'color', [0.4588,0.7333,0.9922])
        plot(ax(iAx), x(2,lns), x(1,lns), '.', 'color', [0.4313,0.7961,0.2353])
    end
    
    P.T = P.T / [v_1,v_2,v_n];
end