function mreyetrack_2D

addpath('Functions')

filename = 'bSSFP_Slow_Blink_Sagittal';
%filename = 'bSSFP_Saccade_Axial';
%filename = 'bSSFP_Blink_Saccade_Axial';

%% Load raw MR data & Eye struct from 3D segmentation 
MR_2D_raw = load(sprintf('Data/%s', filename));
if exist('Data/Eye.mat', 'file')
    load('Data/Eye', 'Eye')
else
    error('You need to run "mreyetrack_3D" first to ')
end

%% Find eyeball center & crop the images
% Performs a fast radial symmetry transform for a typcial eyeball size in
% order to locate the eyeballs. This works very reliably but can be a few 
% mm off from the actual eyeball center. Nevertheless, use this location to 
% crop the images and as a starting point for the algorithm.
P.cropping.radial_symmetry_mm = 12;
P.cropping.window_size_mm     = 35;
MR_2D = crop_image(MR_2D_raw, P);

%% bFFE-Scan Eyeball segmentation
P.segment_2D.plot_segmentation = 1;
P.segment_2D.print_progress    = 1;
P.segment_2D.include_torsion   = 0;
P.segment_2D.scaling_mm2deg    = [0.5, 1, 5, 10, 50];
MR_2D = segment_2D(MR_2D, Eye, P);
save('Data/MR_2D', 'MR_2D')