%% this script: 1) resampling and 2) normalize
%1) resampling image (that you want to segment) to spatial resolution of HCP
%   this resolution is used for trainig CNN
%2) intensity normalize: mean=0 and std=1 for the voxel that belong to brain

%% NEED:
%       - flirt
%       - image HCP (as refrence for resampling) "SIGNAL.nii.gz" (available
%         in Directoy download)

%% INPUT:
%       - dir_seg: directory with content N dir as N subject to segment
%          in each dir there are: b0 (b0.nii.gz) and mask of brain
%          (brain_mask.nii.gz)
%       - ref_img: b0 of HCP to use as reference

%N.B. put path with ''
%% OUTPUT:
%       - b0 resampling name "b0_125.nii.gz" and
%       - b0 normalize, name "B0_N.nii"

% example dir_seg: '/media/bcc/bcc-data/MARTA/TLE/HC'
%         ref_img: '/media/bcc/bcc-data/MARTA/immagini_ok/100307/SIGNAL.nii.gz'

function []=resampling_normalize(dir_seg, ref_img)


%cd /media/bcc/bcc-data/MARTA/TLE/
cd(dir_seg)


folderContents = dir;
folderContents(1:2)=[];
count=0;

for k=1:length(folderContents)
    myFolder = fullfile(pwd, folderContents(k).name);
    cd (myFolder);
    
    %% 1)resampling
    unix(horzcat('/usr/share/fsl/5.0/bin/flirt -in ' , myFolder, '/b0.nii.gz -ref', ref_img,' -out ', myFolder, '/b0_125.nii.gz -omat ', myFolder, '/b0_125.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp sinc -sincwidth 7 -sincwindow hanning'));
    unix(horzcat('/usr/share/fsl/5.0/bin/flirt -in ' , myFolder, '/brain_mask.nii.gz -applyxfm -init ', myFolder, '/b0_125.mat -out ', myFolder, '/maschera_125.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref ' , myFolder, '/b0_125.nii.gz'));
    
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
    cd(dir_seg)
end

end