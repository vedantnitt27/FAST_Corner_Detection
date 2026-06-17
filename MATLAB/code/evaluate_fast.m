function [Precision, Recall, Fscore, Le] = evaluate_fast(img, corner_img, gt_file)

%% Load Ground Truth

gt = load(gt_file);

%% Extract detected corners

[det_y, det_x] = find(corner_img ==255);

detected = [det_x det_y];

%% Matching threshold

thresh = 5;

%% Initialize metrics

TP = 0;
FP = 0;

matched_gt = zeros(size(gt,1),1);

distance_sum = 0;

%% Compare detected corners with GT

for i = 1:size(detected,1)

    dx = detected(i,1);
    dy = detected(i,2);

    found_match = 0;

    for j = 1:size(gt,1)

        % Ground truth coordinates
        gx = gt(j,2);
        gy = gt(j,1);

        % Euclidean distance
        d = sqrt((dx-gx)^2 + (dy-gy)^2);

        % Match found
        if d <= thresh && matched_gt(j)==0

            TP = TP + 1;

            matched_gt(j) = 1;

            distance_sum = distance_sum + d;

            found_match = 1;

            break;

        end

    end

    % False positive
    if found_match == 0

        FP = FP + 1;

    end

end

%% False negatives

FN = sum(matched_gt == 0);

%% Metrics

Precision = TP / (TP + FP);

Recall = TP / (TP + FN);

if (Precision + Recall) > 0

    Fscore = 2 * Precision * Recall / (Precision + Recall);

else

    Fscore = 0;

end

%% Localization Error

if TP > 0

    Le = distance_sum / TP;

else

    Le = 0;

end

%% Display Metrics

disp(' ');
disp('===== FAST Evaluation =====');

fprintf('True Positives  = %d\n', TP);
fprintf('False Positives = %d\n', FP);
fprintf('False Negatives = %d\n', FN);

fprintf('Precision = %.4f\n', Precision);
fprintf('Recall    = %.4f\n', Recall);
fprintf('F-score   = %.4f\n', Fscore);

fprintf('Localization Error = %.4f pixels\n', Le);

%% Visualization

figure;

%% 1. Original Image
subplot(2,2,1);

imshow(img);

title('Input Image');

%% 2. Ground Truth Corners
subplot(2,2,2);

imshow(img);
hold on;

% GT plotted consistently as (x,y)
plot(gt(:,2), gt(:,1), ...
    'go', ...
    'MarkerSize', 10, ...
    'LineWidth', 2);

title('Ground Truth Corners');

%% 3. Detected FAST Corners
subplot(2,2,3);

imshow(img);
hold on;

plot(det_x, det_y, ...
    'r.', ...
    'MarkerSize', 15);

title('Detected FAST Corners');

%% 4. GT vs FAST Overlay
subplot(2,2,4);

imshow(img);
hold on;

% Ground Truth
plot(gt(:,2), gt(:,1), ...
    'go', ...
    'MarkerSize', 10, ...
    'LineWidth', 2);

% Detected FAST corners
plot(det_x, det_y, ...
    'r.', ...
    'MarkerSize', 15);

title('GT vs FAST Comparison');

legend({'Ground Truth','FAST Detection'});

end