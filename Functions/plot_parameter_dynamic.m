function plot_parameter_dynamic(MR, iEye)

% Initalize Figure
fig = figure;
fig.Position(3:4) = 700*[1,0.75];
ax(1) = subplot(3,1,1);
ax(2) = subplot(3,1,2);
ax(3) = subplot(3,1,3);
t = MR.t(MR.image_range);
set(ax(1:3), 'nextPlot', 'add', 'FontSize', 10, 'xLim', minmax(t))% + [0,10]) 
linkaxes(ax(1:3), 'x')
col = colormap('lines');

% Anterior/Posterior Translation
plot(ax(1), t, MR.pixel_mm * MR.max_b{iEye}(2,:), 'color', col(1,:))
ylabel(ax(1), 'Anterior/Posterior [mm]')

% Second Translation
if strcmp(MR.plane, 'axial')
    plot(ax(2), t, MR.pixel_mm * MR.max_b{iEye}(1,:), 'color', col(5,:))
    ylabel(ax(2), 'Medial/Lateral [mm]')
elseif strcmp(MR.plane, 'sagittal')
    plot(ax(2), t, MR.pixel_mm * MR.max_b{iEye}(3,:), 'color', col(5,:))
    ylabel(ax(2), 'Inferior/Superior [mm]')
end

% Rotation
if strcmp(MR.plane, 'axial')
    plot(ax(3), t, MR.max_b{iEye}(6,:), 'color', col(2,:))
    ylabel(ax(3), 'Horizontal Rotation [°]')
elseif strcmp(MR.plane, 'sagittal')
    plot(ax(3), t, MR.max_b{iEye}(4,:), 'color', col(2,:))
    ylabel(ax(3), 'Vertical Rotation [°]')
end
xlabel(ax(3), 'Time [s]')
