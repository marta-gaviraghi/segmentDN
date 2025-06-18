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

function []=CNN_postprocessing_v3(path_seg, path_download, b0_name)
%CNN_POSTPROCESSING_V3 Segmentation and post-processing of the dentate nucleus (DN) from B0 images using CNN.
%
%   [] = CNN_postprocessing_v3(path_seg, path_download, b0_name)
%
%   INPUTS:
%       path_seg      - String: Path to the folder containing the segmentation files,
%                       including 'dentati_suit.nii.gz' and the transformation matrix 'b0_125.mat'.
%
%       path_download - String: Path to the folder containing the trained CNN model file 'rete1.mat'.
%
%       b0_name       - String: Name of the original B0 NIfTI file (e.g., 'b0.nii') used as the reference
%                       for resampling back to the original space using FLIRT.
%
%   DESCRIPTION:
%       This function performs segmentation of the dentate nucleus (DN) using a pre-trained convolutional
%       neural network (CNN), followed by a post-processing step using the SUIT segmentation as a mask.
%
%       Steps include:
%           - Loading and normalizing the B0 image
%           - Applying the CNN slice-by-slice for segmentation
%           - Mapping the segmented volume back to the original space using FLIRT
%           - Filtering the CNN output using a dilated SUIT-based DN mask
%           - Saving the final post-processed segmentation as 'dentati_filtrati_suit.nii.gz'
%
%   OUTPUT:
%       The function saves the post-processed DN segmentation in the specified segmentation path.
%
%   NOTE:
%       Make sure FSL tools (FLIRT, fslmaths, etc.) are installed and available in your system path.

cd(path_download)
load rete1.mat

cd(path_seg)

dentati_sa=zeros(86, 71, 66);

if exist('dentati_suit.nii.gz')
    %load b0 image after resampling and normalize
    !gunzip B0_N.nii.gz
    b0_struct=load_untouch_nii('B0_N.nii');
    b0=b0_struct.img;
    b0_test=b0(30:115, 10: 80, 5:70);
    !gzip B0_N.nii
    
    %segment using CNN
    for slice=1:66
        [C score]= semanticseg(b0_test(:,:,slice),net);
        dentati_sa_slice=uint8(C);
        %label the pixels classified as DN with 1 value and pixels
        %as background with 0 value
        dentati_sa_slice=dentati_sa_slice-1;
        dentati_sa(:,:,slice)=dentati_sa_slice;
        dentati_sa=uint8(dentati_sa);
        
        dent_sa_dim=zeros(145, 174, 145);
        dent_sa_dim(30:115, 10:80, 5:70)=dentati_sa;

    end
    
    dentati_sa1=b0_struct;
    dentati_sa1.img=dent_sa_dim;
    save_untouch_nii(dentati_sa1, 'dentati_CNN.nii');
    
    dentati_struct=load_untouch_nii('dentati_CNN.nii');
    dentati=dentati_struct.img;
    dentati=uint8(dentati);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %load DN segmented with SUIT: for the post process-phase
    
    
    %calculate inverse matrix -> for return to original dimension
    unix(horzcat('convert_xfm -omat ', path_seg,'/b0_125_inv.mat -inverse ', path_seg,'/b0_125.mat'));
    
    %use interpolation nearest neighbor because i want 0 or 1
    unix(horzcat('flirt -in ', path_seg, '/dentati_CNN.nii -applyxfm -init ', path_seg, '/b0_125_inv.mat -out ' , path_seg,'/DN_CNN.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref ', path_seg,'/', b0_name));
    

    %% dilated the DN obtain with SUIT (before filtered)
    !fslmaths seg_den_suit.nii -dilM -dilM seg_den_suit_dil.nii.gz
    gunzip('seg_den_suit_dil.nii.gz');
    maschera_dil_struct=load_untouch_nii('seg_den_suit_dil.nii');
    maschera_dil=maschera_dil_struct.img;
    gzip('seg_den_suit_dil.nii');
    delete('seg_den_suit_dil.nii');
    
    gunzip('DN_CNN.nii.gz');
    DN_CNN_struct=load_untouch_nii('DN_CNN.nii');
    DN_CNN=DN_CNN_struct.img;
    gzip('DN_CNN.nii');
    delete('DN_CNN.nii');
    
    maschera_vett=maschera_dil(:);
    dentati_sa_vett=DN_CNN(:);
    
    %maschera_vett=single(maschera_vett);
    
    dentati_filtrati_vett=maschera_vett.*dentati_sa_vett;
    
    dentati_filtrati=reshape(dentati_filtrati_vett, size(DN_CNN,1), size(DN_CNN,2), size(DN_CNN,3));
    
    sa_filtrata=maschera_dil_struct;
    sa_filtrata.img=dentati_filtrati;
    %save DN segmentation after post-processing phase
    save_untouch_nii(sa_filtrata, 'dentati_filtrati_suit.nii');
    gzip('dentati_filtrati_suit.nii');
   
else
    disp('segment DN with SUIT!!!')
    
end
