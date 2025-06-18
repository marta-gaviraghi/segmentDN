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

function []=resampling_normalize_v3(path_seg, ref_img, b0_name, mask_brain, path_download)

% RESAMPLING_NORMALIZE_V3 Resamples and normalizes a B0 image for dentate nucleus segmentation.
%
%   [] = resampling_normalize_v3(path_seg, ref_img, b0_name, mask_brain, path_download)
%
%   INPUTS:
%       path_seg      - String: Path to the folder containing the subject's B0 image and brain mask.
%
%       ref_img       - String: Filename of the reference image (e.g., template) used for resampling.
%
%       b0_name       - String: Filename of the original B0 NIfTI image to be resampled and normalized.
%
%       mask_brain    - String: Filename of the brain mask NIfTI image in the same space as the B0 image.
%
%       path_download - String: Path to the folder containing the reference image - space HCP- (used in FLIRT).
%
%   DESCRIPTION:
%       This script performs two main steps:
%
%       1.Resampling:
%           - The B0 image is aligned to a standard space (e.g., 1.25mm) using FSL's FLIRT tool.
%           - The corresponding brain mask is resampled using the same transformation matrix.
%
%       2. Intensity Normalization:
%           - The B0 image is normalized to zero mean and unit standard deviation within the brain mask.
%           - Any NaN values in the B0 image are replaced with 0.
%
%       The final normalized image is saved as 'B0_N.nii.gz' in the same folder.
%
%   OUTPUT:
%       The function does not return variables but saves the following files in 'path_seg':
%           - 'b0_125.nii.gz' : Resampled B0 image
%           - 'b0_125.mat'    : Transformation matrix
%           - 'maschera_125.nii.gz' : Resampled brain mask
%           - 'B0_N.nii.gz'   : Normalized B0 image
%
%   NOTE:
%       Requires FSL to be installed and available in the system path.

cd(path_seg)
%% 1)resampling
unix(horzcat('flirt -in ' , path_seg, '/', b0_name, ' -ref ' , path_download,'/', ref_img,' -out ', path_seg, '/b0_125.nii.gz -omat ', path_seg, '/b0_125.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp sinc -sincwidth 7 -sincwindow hanning'));
unix(horzcat('flirt -in ' , path_seg, '/', mask_brain, ' -applyxfm -init ', path_seg, '/b0_125.mat -out ', path_seg, '/maschera_125.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref ' , path_seg, '/b0_125.nii.gz'));
    
!gunzip b0_125.nii.gz
b0_struct=load_untouch_nii('b0_125.nii');
b0=b0_struct.img;
!gzip b0_125.nii
    
%if in b0 there are NaN value these voxel are replace with 0 value
b0_vett=b0(:);

b0_vett(isnan(b0_vett))=0;

!gunzip maschera_125.nii.gz
maschera_struct=load_untouch_nii('maschera_125.nii');
maschera=maschera_struct.img;
!gzip maschera_125.nii
    
%% 2) intensity normalize of b0 (after resampling)
maschera_vett=maschera(:);
index=find(maschera_vett==1);
b0_cervello=b0_vett(index);
media_cervello=mean(b0_cervello);
std_cervello=std(b0_cervello);
b0_3d=reshape(b0_vett, 145, 174, 145);

b0_norm(:,:,:)=(b0_3d(:,:,:)-media_cervello)/std_cervello;

b0_n=b0_struct;
b0_n.img=b0_norm;

save_untouch_nii(b0_n, 'B0_N.nii');

!gzip *.nii

end

