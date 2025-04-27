% Define a function to create the GUI
function stage3_sample()
    % Create figure and axes
    fig = figure('Name', 'X-ray Image Processing App', 'Position', [100, 100, 1200, 800]);
    ax1 = axes('Parent', fig, 'Position', [0.05, 0.55, 0.4, 0.4]);
    ax2 = axes('Parent', fig, 'Position', [0.55, 0.55, 0.4, 0.4]);
    ax3 = axes('Parent', fig, 'Position', [0.05, 0.05, 0.4, 0.4]);
    

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
                            'Position', [20, 480, 120, 30], 'Callback', @denoiseImage);
     uicontrol('Style', 'pushbutton', 'String', 'Edge Detection', ...
                                    'Position', [160, 480, 120, 30], 'Callback', @edgeDetection);
     uicontrol('Style', 'pushbutton', 'String', 'Rotate Image', ...
                            'Position', [300, 480, 120, 30], 'Callback', @rotateImage);
     uicontrol('Style', 'pushbutton', 'String', 'Intensity Peak Search', ...
                                'Position', [440, 480, 150, 30], 'Callback', @peakSearch);
     uicontrol('Style', 'pushbutton', 'String', '3D Visualization', ...
                                'Position', [600, 480, 150, 30], 'Callback', @visualization);

    % Callback functions for each button
    function denoiseImage(~, ~)
    % Denoise the image using guided filter
    % Implement guided filter denoising with given parameters
    guided_filtered_img = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);
    gaussian_filtered_img = imgaussfilt(img, 2); % Apply Gaussian filter with sigma = 2
    bilateral_filtered_img = imbilatfilt(img); % Apply bilateral filter
    
   fig1 =  figure('Name','Filters','Position',[30, 30, 800, 300]);
     ax4 = axes('Parent', fig1, 'Position', [0.10, 0.25, 0.4, 0.4]);
     ax5 = axes('Parent', fig1, 'Position', [0.25, 0.25, 0.4, 0.4]);
  % subplot(1,1,1);
     imshow(gaussian_filtered_img,'Parent',ax4)
    title( 'GAUSSIAN FILTER IMAGE');
   % subplot(1,1,2);
    imshow(bilateral_filtered_img,'Parent',ax5);
    title( 'BILATERAL FILTER IMAGE');

    % Update displayed images
        imshow(guided_filtered_img, 'Parent', ax1);
        title(ax1, 'GUIDED FILTER IMAGE');
  
end

    function edgeDetection(~, ~)
        % Edge detection using multi-scale Canny edge detector
        % Implement multi-scale Canny edge detection with given parameters
        edged_img = edge(denoised_img, 'Canny', [0.1 0.8], 1:0.5:4.5);
        
        % Update displayed image
        imshow(edged_img, 'Parent', ax2);
        title(ax2, 'Edge Detected Image');
    end

    function rotateImage(~, ~)
        % Rotate the image to align prominent edges vertically
        
        % Rotate the image by 90 degrees
        rotated_img = imrotate(edged_img, 90);
        
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
        title(ax3, '3D Visualization of Intensity Peaks');
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
