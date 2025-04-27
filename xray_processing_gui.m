% Define a function to create the GUI
function xray_processing_gui()
    % Create figure and axes
     scrsz = get(groot,"ScreenSize");
    fig = figure('Name', 'Image Processing GUI','Position', scrsz,'Color',[.2,.4,.8] );
    ax1 = axes('Parent', fig, 'Position', [0.05, 0.55, 0.4, 0.4]);
    ax2 = axes('Parent', fig, 'Position', [0.55, 0.55, 0.4, 0.4]);
    ax3 = axes('Parent', fig, 'Position', [0.05, 0.05, 0.9, 0.4]);

    % Load an example X-ray image
    img = imread('Xray.jpg'); % Provide the path to your example image
    imshow(img, 'Parent', ax1);
    title(ax1, 'Original X-ray Image');
    
    % Initialize variables
    denoised_img = [];
    edged_img = [];
    rotated_img = [];
    peaks_3d = [];
    
    % Create buttons for each processing step
     uicontrol('Style', 'pushbutton', 'String', 'Denoise Image', ...
                            'Position', [20, 20, 120, 30], 'Callback', @denoiseImage);
     uicontrol('Style', 'pushbutton', 'String', 'Edge Detection', ...
                                    'Position', [160, 20, 120, 30], 'Callback', @edgeDetection);
     uicontrol('Style', 'pushbutton', 'String', 'Rotate Image', ...
                            'Position', [300, 20, 120, 30], 'Callback', @rotateImage);
     uicontrol('Style', 'pushbutton', 'String', 'Intensity Peak Search', ...
                                'Position', [440, 20, 150, 30], 'Callback', @peakSearch);
     uicontrol('Style', 'pushbutton', 'String', '3D Visualization', ...
                                'Position', [600, 20, 150, 30], 'Callback', @visualization);

    % Callback functions for each button
    function denoiseImage(~,~)
        % Denoise the image using guided filter
        % Implement guided filter denoising with given parameters
        denoised_img = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);
        
        % Update displayed image
        imshow(denoised_img, 'Parent', ax2);
        title(ax2, 'Denoised Image');
    end

   function edgeDetection(~, ~)
    % Initialize variables
    max_probability = -1;
    optimal_edges = [];
    
    % Loop through different standard deviations
    for sigma = 1:0.5:4.5
        % Loop through different thresholds
        for threshold = 0.1:0.1:0.8
            % Edge detection using Canny algorithm
            edges = edge(denoised_img, 'Canny', threshold, sigma);
            
            % Compute probability for edges
            probability = mean(edges(:)); % Assuming edges are binary
            
            % Update maximum probability and optimal edges
            if probability > max_probability
                max_probability = probability;
                optimal_edges = edges;
            end
        end
    end
    
    % Update displayed image with optimal edges
    edged_img = optimal_edges;
    imshow(edged_img, 'Parent', ax2);
    title(ax2, 'Edge Detected Image');
end


   function rotateImage(~, ~)
    % Rotate the image to align prominent edges vertically
    
    % Rotate the image by 90 degrees
    rotated_img = imrotate(edged_img, 90);
    
    % Perform Sobel operator on the result of Canny edge detector
    [Gmag, Gdir] = imgradient(edged_img, 'sobel');
    
    % Calculate gradient magnitudes and sort them
    [sorted_Gmag, idx] = sort(Gmag(:), 'descend');
    
    % Select the upper 20 percent of gradient magnitudes
    num_pixels = round(0.2 * numel(sorted_Gmag));
    top_20_percent_idx = idx(1:num_pixels);
    
    % Extract gradient directions corresponding to the selected pixels
    selected_Gdir = Gdir(top_20_percent_idx);
    
    % Draw histogram of gradient directions
    figure('Name', 'Gradient Directions-HISTOGRAM');
    histogram(selected_Gdir, 180); % 180 bins for angles from -90 to 90 degrees
    xlabel('Gradient Direction');
    ylabel('Frequency');
    title('Histogram of Gradient Directions');
    
    % Update displayed image
    imshow(rotated_img, 'Parent', ax2);
    title(ax2, 'Rotated Image');
end


    function peakSearch(~, ~)
        % Search along each row of the image to find intensity peaks
        
        % Apply median filter with window size of 5
        smoothed_img = medfilt2(rotated_img, [1 5]);
        
        % Find local maxima in intensity values
        peaks_3d = zeros(size(rotated_img));
        for i = 1:size(rotated_img, 1)
            row_intensity = smoothed_img(i, :);
            max_intensity = max(row_intensity);
            threshold = 2/3 * max_intensity;
            
            peaks_indices = find(row_intensity > threshold);
            peaks_3d(i, peaks_indices) = row_intensity(peaks_indices);
        end
        
        % Update displayed image
        surf(ax3, peaks_3d);
        xlabel(ax3, 'Column');
        ylabel(ax3, 'Row');
        zlabel(ax3, 'Intensity');
        title(ax3, 'Search of Intensity Peaks');
    end

    function visualization(~, ~)
        % Visualize intensity peaks in 3D
        if ~isempty(peaks_3d)
            figure;
            surf(peaks_3d);
            xlabel('Column');
            ylabel('Row');
            zlabel('Intensity');
            title('3D Visualization of Intensity Peaks');
        else
            disp('Please perform intensity peak search first.');
        end
    end
end

% Call the function to create the GUI
%xray_processing_gui();
