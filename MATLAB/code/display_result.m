function display_result(img, gray, corner_img)

figure;

%% 2. 256x256 Image
subplot(2,2,1);

imshow(img);

title('256x256 Image');

%% 3. Grayscale Image
subplot(2,2,2);

imshow(gray);

title('Grayscale Image');

%% 4. Corner-only Image
subplot(2,2,3);

imshow(corner_img);

title('Detected Corners');

%% 5. Overlay on Resized Image
subplot(2,2,4);

imshow(img);
hold on;

% Find corner coordinates
[rows, cols] = find(corner_img == 255);

% Plot corners
plot(cols, rows, 'r.', 'MarkerSize', 10);

title('FAST Corners Overlay');

end