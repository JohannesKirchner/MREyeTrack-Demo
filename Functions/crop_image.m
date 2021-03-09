function MR = crop_image(MR, P)


fprintf('\n###### Image Cropping ######\nPeform fast radial symmetry transform...\n')

%% Split data into left and right
% Depending on whether the bSSFP sequence in question was recorded in the axial
% or sagittal plane, there will be either two or one eyes present in the
% images. The 3D T2 scan is acquired sagitally but contains both eyes
% as well. Store the right eye at first cell position and the left eye at
% second cell position (all sagittal scans only used the right eye).
img = {};
if isempty(MR.sampling_interval)
    n = floor(size(MR.image,3)/2);
    img{1} = MR.image(:,:,n+1:end);
    img{2} = MR.image(:,:,  1:n  );
else
    MR.image = MR.image(:,:,51:end);
    if strcmp(MR.plane, 'axial')
        n = floor(size(MR.image,2)/2);
        img{1} = MR.image(:,   1:n  , :);
        img{2} = MR.image(:, n+1:end, :);
    else
        n = 0;
        img{1} = MR.image;
    end
end
MR.image = [];


for iSide = 1:length(img)
    fprintf('Eye %d/%d ', iSide, length(img))
    %% Finding eyeball position
    % Use the fast radial symmetry transform with a typical radius in order to
    % find the center position of the eye.
    eyeball_radius = round(P.cropping.radial_symmetry_mm / MR.pixel_mm);
    if isempty(MR.sampling_interval)
        S = fast_radial_symmetry_transform_3D(img{iSide}, eyeball_radius);
        [~, pos] = max(S(:));
        [posRow, posCol, pos3] = ind2sub(size(S), pos);
    else
        S = fast_radial_symmetry_transform_2D(img{iSide}(:,:,1), eyeball_radius);
        [~, pos] = max(S(:));
        [posRow, posCol] = ind2sub(size(S), pos);
    end
    
    
    %% Crop image
    % Crop the images around eyeball center to reduce data size.
    cropping_window = P.cropping.window_size_mm / MR.pixel_mm;
    idx_crop  = -floor(cropping_window/2) : floor(cropping_window/2);
    if isempty(MR.sampling_interval)
        img{iSide} = double(img{iSide}(posRow+idx_crop, posCol+idx_crop, pos3+idx_crop));
        MR.position{iSide} = [posRow, posCol, pos3+(2-iSide)*n];
    else
        img{iSide} = double(img{iSide}(posRow+idx_crop, posCol+idx_crop,:));
        MR.position{iSide} = [posRow, posCol+(iSide-1)*n];
    end
    
    
    %% Norm image intensities
    % Normalize image intensities to the mean intensity around eyeball
    % center
    idx_center = floor(cropping_window/2)+1 + (-2:2);
    if isempty(MR.sampling_interval)
        center = img{iSide}(idx_center, idx_center, idx_center);
        MR.mean_intensity{iSide} = mean(center(:));
    else
        center = img{iSide}(idx_center, idx_center, 1);
        MR.mean_intensity{iSide} = mean(center(:));
    end
    MR.image{iSide} = img{iSide} / MR.mean_intensity{iSide};
    
    fprintf('completed\n')
end