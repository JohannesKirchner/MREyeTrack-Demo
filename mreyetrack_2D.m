function mreyetrack_2D

addpath('Functions')

%% Choose participant and sequence
participant = 'P1';
%sequence = 'bSSFP_Saccade_Axial';
sequence = 'bSSFP_Slow_Blink_Sagittal';

%% Load raw MR data & Eye struct from 3D segmentation 
MR_2D_raw = load(sprintf('Data/%s/%s', participant, sequence));
if exist(sprintf('Data/%s/Eye.mat', participant), 'file')
    load(sprintf('Data/%s/Eye.mat', participant), 'Eye')
else
    error('You need to run "mreyetrack_3D" first to establish the 3D eyeball model!')
end

%% Find eyeball center & crop the images
% Performs a fast radial symmetry transform for a typcial eyeball size in
% order to locate the eyeballs. This works very reliably but can be a few 
% mm off from the actual eyeball center. Nevertheless, use this location to 
% crop the images and as a starting point for the algorithm.
P.cropping.radial_symmetry_mm = 12;
P.cropping.window_size_mm     = 35;
MR_2D = crop_image(MR_2D_raw, P);

%% bSSFP Eyeball projection segmentation
% estimate eye motion in the dynamic bSSFP by finding the optimal 2D
% projection of the 3D eyeball model. In order to find the global solution, 
% various scalings  between parameters of unit mm and  deg are considered. 
% Number of grid points per pixel is also adjustable.
P.segment_2D.plot_segmentation = 1;
P.segment_2D.include_torsion   = 0;
P.segment_2D.grid_points_px    = 4;
P.segment_2D.scaling_mm2deg    = [0.5, 1, 5, 10, 50];
MR_2D = segment_2D(MR_2D, Eye, P);
save(sprintf('Data/%s/%s_analysed', participant, sequence), 'MR_2D')