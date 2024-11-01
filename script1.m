clc;
clear;
close all;

%Parameters
laplace_filter_factor = 0.5;
gaussian_filter_sigma = 5;
gaussian_filter_size = 15;
cut_off_frequency = 36;

% get one slice of the dicom file
dicom_file = 'SubjectB_T1_DICOM\IMG0069.dcm'; % choose one slice of the dicom file
image_data = dicomread(dicom_file);
image_data = im2double(image_data);% change to double format to process 

% show the original image
figure;
imshow(image_data, []);
title('Original Image');

% 1. high frequency pass filter
% here we create the high pass laplace filter
hp_filter = fspecial('laplacian', laplace_filter_factor); % laplace high pass filter, 0.5 is the operator, the higher, the edge of the target in image is sharper
high_pass_img = imfilter(image_data, hp_filter, 'replicate', 'conv'); % apply the dilter to the image. replicate is to copy the value of boundary pixels while convolution

% show the high pass filtered image
figure;
subplot(2,2,1);
imshow(high_pass_img, []);
title('High Pass Filtered Image');

% 2. low frequency pass filter
% here we create the low pass gaussian filter
lp_filter = fspecial('gaussian', [gaussian_filter_size gaussian_filter_size], gaussian_filter_sigma); % size of the filter is [15, 15], 5 is standard deviation, the bigger the size and deviation, the smoother,
low_pass_img = imfilter(image_data, lp_filter, 'replicate', 'conv');

% show low pass filter result
subplot(2,2,2);
imshow(low_pass_img, []);
title('Low Pass Filtered Image');

% 3. add gaussian noise
noisy_img = imnoise(image_data, 'gaussian', 0, 5e-8); % the mean of the noise is 0 to make sure the brightness of the image unchanged, variance is 5e-8

% show the noise image
subplot(2,2,3);
imshow(noisy_img, []);
title('Image with Gaussian Noise');

% 4. denoising in frequency domain with low pass filter
% transform to frequency domain
noisy_img_fft = fftshift(fft2(noisy_img));% move the low frequency to the center, and high frequency will be in the boundary

% design a low pass filter to denoise
[rows, cols] = size(noisy_img);
[u, v] = meshgrid(-floor(cols/2):floor((cols-1)/2), -floor(rows/2):floor((rows-1)/2));% creat the 2d matrix to store the location of all points in graph
D = sqrt(u.^2 + v.^2); % get the distance of all points
D0 = cut_off_frequency; % cut off frequency, lower than this frequency will keep, higher will be decline
low_pass_filter = exp(-(D.^2) / (2 * (D0^2)));

% apply the low pass filter
smoothed_fft = noisy_img_fft .* low_pass_filter; % by multiply the frequency domain element with the filter to revalue the element

% transform to space domain
smoothed_img = real(ifft2(ifftshift(smoothed_fft)));

% show the graph after denoising
subplot(2,2,4);
imshow(smoothed_img, []);
title('Filtered Image after Noise Reduction');

% show the gaussian filter
figure;
imshow(low_pass_filter, []);
title('Gaussian Low Pass Filter');
colorbar;