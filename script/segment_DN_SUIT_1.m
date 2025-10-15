% ------------------------------------------------------------------------------
% Author: Marta Gaviraghi
% Contact: marta.gaviraghi01@universitadipavia.it
% Date: last version - June 2025
%
% Description:
%   This script is part of a pipeline for the automatic segmentation 
%   of the dentate nuclei (DN) using CCN
%
% Citation:
%   If you use this code in your research or software, please cite the following paper:
%
%   Gaviraghi et al 2021
%   Automatic Segmentation of Dentate Nuclei for Microstructure Assessment:
%   Example of Application to Temporal Lobe Epilepsy Patients.
%   https://doi.org/10.1007/978-3-030-73018-5_21
%   In Computational Diffusion MRI (CDMRI 2020), MICCAI 2020 Workshop.
%   Mathematics and Visualization, pp. 263–278.
% ------------------------------------------------------------------------------

function [] = segment_DN_SUIT_1(T1, b0, path_download, output_path)

% Code 1 of the dentate nucleus (DN) segmentation pipeline
%
% INPUTS:
%   T1            - Full path to the T1-weighted image (NIfTI)
%   b0            - Full path to the B0 diffusion image (NIfTI)
%   path_download - Path to the folder containing SUIT atlas and MNI templates
%   output_path   - Path to the folder where all outputs will be saved
%
% All generated files will be saved in output_path

cd(output_path); % Switch to the output folder

%% Extract DN from SUIT cerebellum atlas
system(horzcat('fslmaths ', path_download, '/Cerebellum-MNI_1mm.nii.gz -thr 29 -uthr 30 -bin DN_suit_MNI.nii.gz'));

%% Register T1 to MNI space
disp('Registering T1-weighted image to MNI space...')
system(horzcat('flirt -in ', T1, ' -ref ', path_download, '/MNI152_T1_1mm.nii.gz -out T12MNI -omat T12MNI.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -interp sinc -sincwidth 7 -sincwindow hanning'));
system(horzcat('fnirt --in=', T1, ' --aff=T12MNI.mat --config=', path_download, '/T1_2_MNI152_2mm.cnf --iout=T12MNI_fnirt --cout=T1toMNI_coef --fout=T12MNI_warp'));

%% Invert the warp
disp('Inverting the warp...')
system(horzcat('invwarp -w T12MNI_warp.nii.gz -o MNI_warpcoef.nii.gz -r ', T1));

%% Map DN to T1 space
system(horzcat('applywarp -i DN_suit_MNI.nii.gz -r ', T1, ' -w MNI_warpcoef.nii.gz -o DN_T1_suit.nii.gz --interp=nn'));

%% Register T1 to B0 to bring DN into diffusion space
system(horzcat('flirt -in ', b0, ' -ref ', T1, ' -o diff2T1 -omat diff2T1.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -bins 256 -cost mutualinfo -interp trilinear'));

!convert_xfm -omat T12diff.mat -inverse diff2T1.mat

system(horzcat('flirt -in ', T1, ' -ref ', b0, ' -o T1_nu2diff -applyxfm -init T12diff.mat -interp sinc -sincwidth 7 -sincwindow hanning'));

%% Map DN to B0 space
disp('Mapping DN atlas to diffusion space...')
system(horzcat('flirt -in DN_T1_suit -ref ', b0, ' -o DN_diff_SUIT -applyxfm -init T12diff.mat -interp nearestneighbour'));

end
