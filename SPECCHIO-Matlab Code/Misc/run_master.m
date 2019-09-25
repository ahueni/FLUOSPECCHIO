%% Trial script to run the test function compute_VIs

% load the provided workspace
load('ws_test_compute_VIs.mat');

% run the function using as input a single apparent reflectance spectrum
[VIs_1spectrum] = compute_VIs(wvl,rapp_1spectrum);

% run the function using as input n apparent reflectance spectra provided as a (wvl x measurements) matrix
[VIs_50spectra] = compute_VIs(wvl,rapp_50spectra);