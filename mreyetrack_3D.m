function mreyetrack_3D

addpath('Functions')

%% Load raw MR data
MR_3D_raw = load('Data/T2_weighted_3D_scan');

%% Find eyeball center & crop the images
% Performs a fast radial symmetry transform for a typcial eyeball size in
% order to locate both eyeballs. This works very reliably but can be a few 
% mm off from the actual eyeball center. Nevertheless, use this location to 
% crop the images and as a starting point for the algorithm.
P.cropping.radial_symmetry_mm = 12;
P.cropping.window_size_mm     = 35;
MR_3D = crop_image(MR_3D_raw, P);
save('Data/MR_3D', 'MR_3D')

%% 3D Eyeball Model segmentation
% use the high-definition T2-weighted 3D scan for an accurate segmentation 
% of sclera, cornea and lens as ellipsoids. Cornea center is fixed at a
% choosable distance to sclera center. Lens indentation can also be defined 
% in the parameters.

% In order to find the global solution, various
% initial position and scaling options are considered. The results are stored in the 'Eye' structure.
P.segment_3D.plot_segmentation = 1;
P.segment_3D.cornea_center_mm  = 7;
P.segment_3D.lens_indent_mm    = 1.5;
P.segment_3D.grid_points_px    = 4;
P.segment_3D.scaling_mm2deg    = [0.5, 1, 5, 10, 50];
P.segment_3D.min_crn_volume    = 200;
Eye = segment_3D_sclera_cornea(MR_3D, P);
Eye = segment_3D_lens(MR_3D, Eye);
save('Data/Eye', 'Eye')