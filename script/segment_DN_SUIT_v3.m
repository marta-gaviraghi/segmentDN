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

function []=segment_DN_SUIT_v3(path_seg, path_download, T1_name, b0_name)
% SEGMENT_DN_SUIT_V3 Segments the dentate nucleus (DN) using the SUIT atlas and registers it to diffusion space.
%
%   [] = segment_DN_SUIT_v3(path_seg, path_download, T1_name, b0_name)
%
%   INPUTS:
%       path_seg      - String: Path to the subject's working directory where outputs will be saved.
%
%       path_download - String: Path to the folder containing the SUIT atlas and MNI template files:
%                               - 'Cerebellum-MNI_1mm.nii.gz'
%                               - 'MNI152_T1_1mm.nii.gz'
%                               - 'T1_2_MNI152_2mm.cnf' (FNIRT config file)
%
%       T1_name       - String: Filename of the subject's T1-weighted image (NIfTI format).
%
%       b0_name       - String: Filename of the subject's diffusion B0 image (NIfTI format).
%
%   DESCRIPTION:
%       This function performs the segmentation of the dentate nucleus (DN) based on the SUIT atlas in MNI space.
%       It transforms the DN label from MNI space to the subject's T1 space using nonlinear registration (FNIRT),
%       then aligns the DN segmentation from T1 space into the subject’s diffusion (B0) space using FLIRT.
%
%       Key steps include:
%           - Thresholding the SUIT cerebellar atlas to extract DN label
%           - Registering the subject's T1 image to MNI space (FLIRT + FNIRT)
%           - Inverting the warp to map the atlas from MNI to subject T1 space
%           - Registering the DN label to diffusion space
%
%   OUTPUT:
%       The function saves the following files in `path_seg`:
%           - 'dentati_suit.nii.gz'   : Binary DN label in MNI space
%           - 'DN_T1_suit.nii.gz'     : DN label mapped to subject's T1 space
%           - 'seg_den_suit.nii.gz'   : DN label mapped to subject's diffusion space
%           - Various intermediate registration files (.mat, .nii.gz)
%
%   NOTE:
%       Requires FSL (FLIRT, FNIRT) to be installed and available in the system path.

cd(path_seg)

    
%% % Obtain DN segmentation in each subject's T1 space by transforming it from MNI space to T1-weighted space

system(horzcat('fslmaths ', path_download, '/Cerebellum-MNI_1mm.nii.gz -thr 29 -uthr 30 -bin dentati_suit.nii.gz'));

disp('register T1-w image to MNI')
system(horzcat('flirt -in ', path_seg,'/', T1_name, ' -ref ', path_download, '/MNI152_T1_1mm.nii.gz -out T12MNI -omat T12MNI.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -interp sinc -sincwidth 7 -sincwindow hanning'));

system(horzcat('fnirt --in=', path_seg,'/', T1_name, ' --aff=T12MNI.mat --config=T1_2_MNI152_2mm.cnf --iout=T12MNI_fnirt --cout=T1toMNI_coef --fout=T12MNI_warp'));

disp('inversion of the matrix')
system(horzcat('invwarp -w T12MNI_warp.nii.gz -o MNI_warpcoef.nii.gz -r ', T1_name));

disp('DN in the space of T1')

system(horzcat('applywarp -i dentati_suit.nii.gz -r ', T1_name, ' -w MNI_warpcoef.nii.gz -o DN_T1_suit.nii.gz --interp=nn'));

%% register the T1 to DW in oreder to have the segmentation in the space of diffusion
system(horzcat('flirt -in ', b0_name, ' -ref ', T1_name, ' -o diff2T1 -omat diff2T1.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -bins 256 -cost mutualinfo -interp trilinear'));

!convert_xfm -omat T12diff.mat -inverse diff2T1.mat

system(horzcat('flirt -in ', T1_name, ' -ref ' , b0_name, ' -o T1_nu2diff -applyxfm -init T12diff.mat -interp sinc -sincwidth 7 -sincwindow hanning'));

disp('porto altas nello spazio soggetto diff')
system(horzcat('flirt -in DN_T1_suit -ref ', b0_name, ' -o seg_den_suit -applyxfm -init T12diff.mat -interp nearestneighbour'));


end

