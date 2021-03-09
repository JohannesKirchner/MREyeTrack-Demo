function plot_2D_segmentation(MR, Eye, iEye)
% Interactive plotting of the 2D segmentation in axial. You can go through 
% all images with a slider

% Adjust Eye to pixel spacing
Eye = Eye(iEye);
Eye.x0_scl  = Eye.x0_scl  / MR.pixel_mm;
Eye.rad_scl = Eye.rad_scl / MR.pixel_mm;
Eye.x0_crn  = Eye.x0_crn  / MR.pixel_mm;
Eye.rad_crn = Eye.rad_crn / MR.pixel_mm;
Eye.x0_lns  = Eye.x0_lns  / MR.pixel_mm;
Eye.rad_lns = Eye.rad_lns / MR.pixel_mm;

% Extract relevant information for plotting
t = MR.t(MR.image_range);
img = MR.image{iEye}(:,:,MR.image_range);
b   = MR.max_b{iEye};
P = MR.P{iEye};

% Initialize Figure
t0 = 1;
fig = figure;
fig.Position(3:4) = 700*[0.95,1];
for i = 1:16
    ax(i) = subplot('position', [rem(i-1,4)*0.25 + 0.01, 1-ceil(i/4)*0.23 - 0.02, 0.23, 0.21]);
end
set(ax, 'NextPlot', 'add')
draw_image([], [], ax, img, t, b, Eye, P)


% Slice Slider
fig_size   = get(gcf,'Position');
slider_pos = [0.35*fig_size(3), 10, round(0.25*fig_size(3)), 20];
txt_pos    = slider_pos + [0,28,0,-5];
button_pos = [slider_pos(1)+slider_pos(3)+20,15,90,30];
txt = uicontrol('Style', 'text','Position', txt_pos,'String',sprintf('Starting at t = %.3f s', t(t0)), 'FontSize', 13);
max_sld = length(MR.image_range)-15;
uicontrol('Style', 'slider','Min',1,'Max',max_sld,'Value',1,'SliderStep',[1/(max_sld-1), 10/(max_sld-1)],'Position', slider_pos,'Callback', {@SliceSlider, txt, t});
uicontrol('Position',button_pos,'String','Draw Images','Tag','button','Callback',{@draw_image, ax, img, t, b, Eye, P});


function draw_image(~, ~, ax, img, t, b, Eye, P)

for iAx = 1:length(ax)
    cla(ax(iAx))
    j = iAx + t0-1;
    
    title(ax(iAx), sprintf('t = %.3f s', t(j)))
    imshow(img(:,:,j), [0,1.5], 'Parent', ax(iAx))
    
    [x,~,bdy,lns,crn] = eyeball_2D_projection(b(1:3,j),b(4:6,j),Eye,P);
    plot(ax(iAx), x(2,bdy), x(1,bdy), '.', 'color', [0.9922,0.6941,0.2784])
    plot(ax(iAx), x(2,crn), x(1,crn), '.', 'color', [0.4588,0.7333,0.9922])
    plot(ax(iAx), x(2,lns), x(1,lns), '.', 'color', [0.4313,0.7961,0.2353])
end

end


function SliceSlider(hObj, ~, txt, t)
    t0 = round(get(hObj,'Value'));
    set(txt, 'String', sprintf('Starting at t = %.3f', t(t0)));
end

end
