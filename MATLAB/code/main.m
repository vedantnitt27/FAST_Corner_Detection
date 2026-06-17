clc;
clear;
close all;

%% Read image
[img] = read_image(['' ...
'E:\Matlab_projects\FAST_Corner_Detection\Urban_Corner datasets\Images_128\3.png']);

%% Convert to grayscale
gray = grayscale_conversion(img);

%% FAST corner detection
corner_img = fast_algorithm(gray);

corner_img = nms_img(corner_img);

corner_img = edge_rejection(gray, corner_img);

evaluate_fast(img,corner_img, ['' ...
'E:\Matlab_projects\FAST_Corner_Detection\Urban_Corner datasets\Ground Truth_128\3.txt']);

%% Display results
display_result(img, gray, corner_img);