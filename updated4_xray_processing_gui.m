function updated4_xray_processing_gui()
    % Create figure and axes
    fig = figure('Name', 'X-ray Image Processing App', 'Position', [100, 100, 1000, 800]);
    ax1 = axes('Parent', fig, 'Position', [0.05, 0.2, 0.4, 0.7]);
    ax_output = axes('Parent', fig, 'Position', [0.55, 0.1, 0.4, 0.8]);

    % Load an example X-ray image
    img = []; % Initialize as empty
    imshow([], 'Parent', ax1);
    title(ax1, 'Original X-ray Image');
    
    % Create a panel for buttons
    btn_panel = uipanel('Title', 'Processing Steps', 'Position', [0.05, 0.05, 0.4, 0.1]);

    % Create a tab group for output previews
    tab_group = uitabgroup('Parent', fig, 'Position', [0.55, 0.05, 0.4, 0.85]); % Adjusted height

    % Shared variables
    smoothed_img = [];
    enhanced_edges = [];
    peak_locations = [];
    intensity_surface = [];

    % Create buttons for each processing step
    btn_input = uicontrol('Parent', btn_panel, 'Style', 'pushbutton', 'String', 'Input Image', ...
                            'Position', [10, 10, 100, 30], 'Callback', @selectImage);
    btn1 = uicontrol('Parent', btn_panel, 'Style', 'pushbutton', 'String', 'Smoothing', ...
                            'Position', [120, 10, 100, 30], 'Callback', @smoothing);
    btn2 = uicontrol('Parent', btn_panel, 'Style', 'pushbutton', 'String', 'Edge Detection', ...
                                    'Position', [230, 10, 100, 30], 'Callback', @performEdgeDetection);
    btn3 = uicontrol('Parent', btn_panel, 'Style', 'pushbutton', 'String', 'Image Rotation', ...
                            'Position', [340, 10, 100, 30], 'Callback', @rotateImage);
    btn4 = uicontrol('Parent', btn_panel, 'Style', 'pushbutton', 'String', 'Peak Search', ...
                                'Position', [450, 10, 100, 30], 'Callback', @performPeakSearch);
    
    % Add a button for "Boundaries"
    btn5 = uicontrol('Parent', btn_panel, 'Style', 'pushbutton', 'String', 'Boundaries', ...
                     'Position', [560, 10, 100, 30], 'Callback', @drawBoundaries);

    % Callback functions
    function selectImage(~, ~)
        [file, path] = uigetfile({'.jpg;.jpeg;*.png'}, 'Select an Image File');
        if file ~= 0
            img = imread(fullfile(path, file));
            imshow(img, 'Parent', ax1);
            title(ax1, 'Original X-ray Image');
        end
    end

    function smoothing(~, ~)
        if isempty(img)
            disp('Please select an image first.');
            return;
        end

        % Perform smoothing using guided filter
        smoothed_img = imguidedfilter(img, img);
        
        % Update displayed image
        axes(ax_output);
        imshow(smoothed_img);
        title(ax_output, 'Guided Filter Smoothing');
        axis(ax_output, 'equal');

        % Create a tab for preview
        tab1 = uitab(tab_group, 'Title', 'Guided Filter Smoothing');
        ax_tab1 = axes('Parent', tab1);
        imshow(smoothed_img, 'Parent', ax_tab1);
        title(ax_tab1, 'Guided Filter Smoothing');
    end

    function performEdgeDetection(~, ~)
        if isempty(img) || isempty(smoothed_img)
            disp('Please select an image first and perform smoothing.');
            return;
        end

        % Call edge detection function
        performEdgeDetectionInternal();
    end

    function performEdgeDetectionInternal()
    % Check if smoothed_img is grayscale
    if ndims(smoothed_img) == 3 && size(smoothed_img, 3) == 3
        % Convert smoothed image to grayscale
        gray_img = rgb2gray(smoothed_img);
    elseif ndims(smoothed_img) == 2
        % If already grayscale, no need to convert
        gray_img = smoothed_img;
    else
        % Handle other cases
        disp('Unsupported image format.');
        return;
    end

    % Initialize the combined edge map
    combined_edge_map = zeros(size(gray_img));

    % Define parameters for Canny edge detection
    thresholds = [0.05, 0.1, 0.15, 0.2]; % Adjust threshold values
    std_deviations = [0.5, 1, 1.5, 2]; % Adjust standard deviations

    % Apply Canny edge detection multiple times with different parameters
    for i = 1:numel(thresholds)
        for j = 1:numel(std_deviations)
            % Apply Canny edge detection
            edge_map = edge(gray_img, 'Canny', thresholds(i), std_deviations(j));

            % Accumulate edge probabilities
            combined_edge_map = combined_edge_map + double(edge_map);
        end
    end

    % Average the edge probabilities
    combined_edge_map = combined_edge_map / (numel(thresholds) * numel(std_deviations));

    % Apply Otsu thresholding to separate strong from weak edges
    threshold = graythresh(combined_edge_map); % Compute Otsu threshold
    edges_binary = imbinarize(combined_edge_map, threshold); % Binarize the edge map

    % Enhance edges using morphological operations
    se = strel('disk', 4);
    enhanced_edges = imclose(edges_binary, se);

    % Update displayed image
    axes(ax_output);
    imshow(enhanced_edges);
    title(ax_output, 'Enhanced Edge Map (Disk Size 3)');
    axis(ax_output, 'equal');

    % Create a tab for preview
    tab1 = uitab(tab_group, 'Title', 'Enhanced Edge Map (Disk Size 3)');
    ax_tab1 = axes('Parent', tab1);
    imshow(enhanced_edges, 'Parent', ax_tab1);
    title(ax_tab1, 'Enhanced Edge Map (Disk Size 3)');
end


    function rotateImage(~, ~)
        if isempty(img)
            disp('Please select an image first.');
            return;
        end

        if isempty(enhanced_edges)
            disp('Please perform edge detection first.');
            return;
        end

        % Perform Sobel operator on the edge-detected image
        [Gmag, Gdir] = imgradient(enhanced_edges, 'sobel');

        % Sort gradient magnitudes and select the upper 20%
        sorted_Gmag = sort(Gmag(:), 'descend');
        threshold_idx = round(0.2 * numel(sorted_Gmag));
        threshold_value = sorted_Gmag(threshold_idx);

        % Select high gradient directions
        high_gradient_dirs = Gdir(Gmag >= threshold_value);

        % Draw histogram of gradient directions
        histogram_edges = -90:5:90;
        histogram_values = histcounts(high_gradient_dirs, histogram_edges);

        % Find the peak in the histogram
        [~, peak_idx] = max(histogram_values);
        prominent_direction = histogram_edges(peak_idx);

        % Rotate the image by the prominent direction
        rotated_img = imrotate(img, -prominent_direction, 'crop');

        % Update displayed image
        axes(ax_output);
        imshow(rotated_img);
        title(ax_output, 'Rotated Image');
        axis(ax_output, 'equal');

        % Create a tab for preview
        tab3 = uitab(tab_group, 'Title', 'Rotated Image');
        ax_tab3 = axes('Parent', tab3);
        imshow(rotated_img, 'Parent', ax_tab3);
        title(ax_tab3, 'Rotated Image');

        % Display rotation status in the command window
        if prominent_direction ~= 0
            disp('Image rotated.');
        else
            disp('Image not rotated.');
        end

        % Display histogram graph in the output window
        tab4 = uitab(tab_group, 'Title', 'Histogram');
        ax_tab4 = axes('Parent', tab4);
        bar(ax_tab4, histogram_edges(1:end-1), histogram_values);
        title(ax_tab4, 'Histogram of Gradient Directions');
        xlabel(ax_tab4, 'Gradient Direction');
        ylabel(ax_tab4, 'Frequency');
    end

    function performPeakSearch(~, ~)
        if isempty(img) || isempty(enhanced_edges)
            disp('Please select an image first and perform edge detection.');
            return;
        end
        
        % Calculate 2D and 3D intensity peaks
        calculate2DPeaks();
        calculate3DPeaks();
    end

    function calculate2DPeaks()
        % Calculate intensity along each column
        intensities = sum(double(enhanced_edges), 1);
        
        % Find peaks in intensity
        [pks, locs] = findpeaks(intensities);
        
        % Plot intensity peaks
        figure;
        plot(1:length(intensities), intensities, 'b', 'LineWidth', 2);
        hold on;
        plot(locs, pks, 'ro', 'MarkerSize', 10);
        title('Intensity Peaks Along Columns');
        xlabel('Column Index');
        ylabel('Intensity');
        legend({'Intensity', 'Peaks'});
    end

    function calculate3DPeaks()
        % Convert the image to grayscale
        grayscale_img = rgb2gray(img);
        
        % Get size of the image
        [rows, cols] = size(grayscale_img);
        
        % Create grid of row and column indices
        [X, Y] = meshgrid(1:cols, 1:rows);
        
        % Flatten image and indices
        intensities = double(grayscale_img(:));
        X = X(:);
        Y = Y(:);
        
        % Define color map
        cmap = parula(256);
        
        % Normalize intensities to [0, 1]
        normalized_intensities = (intensities - min(intensities)) / (max(intensities) - min(intensities));
        
        % Assign colors based on intensity levels
        colors = interp1(linspace(0, 1, size(cmap, 1)), cmap, normalized_intensities);
        
        % Plot 3D intensity peaks
        figure;
        scatter3(X, Y, intensities, 50, colors, 'filled');
        title('3D Intensity Peaks');
        xlabel('Column Index');
        ylabel('Row Index');
        zlabel('Intensity');
        colormap(cmap);
        c = colorbar;
        c.Label.String = 'Intensity';
    end

   function drawBoundaries(~, ~)
    % Check if enhanced edges are available
    if isempty(enhanced_edges)
        disp('Please perform edge detection first.');
        return;
    end
    
    % Create a copy of the original image for boundary drawing
    boundaries_img = img;
    
    % Find boundaries in the binary enhanced edge map
    [B, L] = bwboundaries(enhanced_edges, 'noholes');
    
    % Define a length threshold for outer boundaries
    length_threshold = 100; % Adjust this threshold based on your data
    
    % Initialize a cell array for outer boundaries
    outer_boundaries = {};
    
    % Filter outer boundaries based on length
    for k = 1:length(B)
        boundary = B{k}; % Retrieve each boundary
        if length(boundary) > length_threshold
            % If the boundary is longer than the threshold, consider it an outer boundary
            outer_boundaries{end + 1} = boundary;
        end
    end
    
    % Display the original image and draw outer boundaries on it
    axes(ax_output);
    imshow(boundaries_img);
    hold on;
    
    % Draw each outer boundary with a red line
    for k = 1:length(outer_boundaries)
        boundary = outer_boundaries{k};
        plot(boundary(:, 2), boundary(:, 1), 'r', 'LineWidth', 2);
    end
    
    % Set the title for the output axes
    title(ax_output, 'Outer Bone Boundaries');
    hold off;
    
    % Create a new tab for preview
    tab_boundaries = uitab(tab_group, 'Title', 'Outer Bone Boundaries');
    ax_boundaries = axes('Parent', tab_boundaries);
    imshow(boundaries_img, 'Parent', ax_boundaries);
    hold on;
    
    % Draw outer boundaries on the new tab
    for k = 1:length(outer_boundaries)
        boundary = outer_boundaries{k};
        plot(ax_boundaries, boundary(:, 2), boundary(:, 1), 'r', 'LineWidth', 0.5);
    end
    
    % Set the title for the new tab
    title(ax_boundaries, 'Outer Bone Boundaries');
    hold off;
end

end
