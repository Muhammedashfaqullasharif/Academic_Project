% Create GUI function
function createGUI()
    % Create figure and axes
    fig = figure('Name', 'X-ray Image Processing', 'Position', [100, 100, 800, 600]);
    ax2 = axes('Parent', fig, 'Position', [0.1, 0.1, 0.8, 0.8]);

    % Load an example X-ray image
    img = imread('Xray.jpg'); % Provide the path to your example image

    % Create button for denoising
     uicontrol('Style', 'pushbutton', 'String', 'Denoise Image', ...
                            'Position', [20, 20, 120, 30], 'Callback', @denoiseImage);

    % Callback function for denoising
    function denoiseImage(~, ~)
        % Denoise the image using guided filter
        % Implement guided filter denoising with given parameters
        denoised_img = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);

        % Update displayed image
        imshow(denoised_img, 'Parent', ax2);
        title(ax2, 'Denoised Image');
    end
end

% Call the GUI function to create the GUI
%createGUI();
