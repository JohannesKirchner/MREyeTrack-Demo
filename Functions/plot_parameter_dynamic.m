function plot_parameter_dynamic(MR, iEye)

% Initalize Figure
fig = figure;
fig.Position(3:4) = 700*[1,0.75];
ax(1) = subplot(3,4,1:3);
ax(2) = subplot(3,4,5:7);
ax(3) = subplot(3,4,9:11);
ax(4) = subplot(4,4,4);
ax(5) = subplot(4,4,8);
ax(6) = subplot(4,4,12);
ax(7) = subplot(4,4,16);
t = MR.t(MR.image_range);
set(ax(1:3), 'nextPlot', 'add', 'FontSize', 18, 'xLim', minmax(t))% + [0,10]) 
linkaxes(ax(1:3), 'x')

% Translation
plot(ax(1), t, MR.max_b{iEye}(1,:))
plot(ax(1), t, MR.max_b{iEye}(2,:))
plot(ax(1), t, MR.max_b{iEye}(3,:))
legend(ax(1), 'x_0','y_0','z_0', 'location', 'NorthEast')
title(ax(1), 'Translation')
ylabel(ax(1), 'Position [mm]')

% Rotation
plot(ax(2), t, MR.max_b{iEye}(4,:))
plot(ax(2), t, MR.max_b{iEye}(5,:))
plot(ax(2), t, MR.max_b{iEye}(6,:))
legend(ax(2), 'Vertical','Torsional','Horizontal', 'location', 'NorthEast')
title(ax(2), 'Rotation')
ylabel(ax(2), 'Orientation [°]')

% Metric
plot(ax(3), t, MR.max_GoF{iEye}(1,:))
plot(ax(3), t, MR.max_GoF{iEye}(2,:))
plot(ax(3), t, MR.max_GoF{iEye}(3,:))
plot(ax(3), t, MR.max_GoF{iEye}(4,:))
legend(ax(3), 'Overall','Sclera','Cornea','Lens', 'location', 'NorthEast')
title(ax(3), 'Goodness of Fit')
xlabel(ax(3), 'Time [s]')
ylabel(ax(3), 'Metric [ ]')

% Best Scaling
[~, idx_max_GoF] = max(squeeze(MR.GoF{iEye}(1,:,:)));
histogram(ax(4), idx_max_GoF)
title(ax(4), 'Best Overall Metric')
[~, idx_max_GoF] = max(squeeze(MR.GoF{iEye}(2,:,:)));
histogram(ax(5), idx_max_GoF)
title(ax(5), 'Best Sclera Metric')
[~, idx_max_GoF] = max(squeeze(MR.GoF{iEye}(3,:,:)));
histogram(ax(6), idx_max_GoF)
title(ax(6), 'Best Lens Metric')
[~, idx_max_GoF] = max(squeeze(MR.GoF{iEye}(4,:,:)));
histogram(ax(7), idx_max_GoF)
title(ax(7), 'Best Cornea Metric')
