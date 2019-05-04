% Preprocessing
img = importdata('Indian_pines.mat');
[height, width, dims] = size(img);
num_iters = 10000;

preloaded_times = [];
computed_times = [];

for patch_size = 1:2:15 % must always be odd numbered
    
    patch_padding = floor(patch_size/2);

    % make patch matrix
    patches_mat = zeros(width - 2 * patch_padding, height - 2 * patch_padding, patch_size * patch_size * dims);
    for j = patch_padding + 1: height - patch_padding
        for i = patch_padding + 1: width - patch_padding
            patches_mat(i, j, :) = get_patch(img, i, j, patch_padding, patch_size, dims);
        end
    end

    % extract patch from loaded matrix num_iters times
    tic
    for i=1:num_iters
        patch = patches_mat(11, 11, :);
    end
    preloaded_times = [preloaded_times toc];

    tic
    for i=1:num_iters
    patch = get_patch(img, 15, 15, patch_padding, patch_size, dims);
    end
    computed_times = [computed_times toc];
    
    fprintf('Patch size %i  done\n', patch_size);
end

%% Plot the data
figure; hold on;
xs = [1:2:15];
a1 = plot(xs, preloaded_times, 'r'); label1 = "Pre-loaded";
a2 = plot(xs, computed_times, 'g'); label2 = "Re-computed";
title('Amount of time taken to load/compute a patch 10000 times')
xlabel('Patch Size')
ylabel('Time Taken (s)')
legend([a1,a2], [label1, label2]);
savefig('load_compute_times_small.png')
%%
function patch = get_patch(img, center_x, center_y, padding, patch_size, dims)
    % Returns a patch from the image
    % Args: img          - the image
    %       center_pixel - the pixel in the center of the patch
    %       patch_size   - the length of a side of the patch
    %
    % patch_size is always odd
    % It is assumed that the patch is within the dimensions of the image
    raw_patch = img(center_x - padding: center_x + padding, ...
                center_y - padding: center_y + padding, ...
                :);
    patch = double(reshape(raw_patch, [patch_size * patch_size * dims, 1]));
end