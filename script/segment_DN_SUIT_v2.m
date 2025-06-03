%% DN segmentation with ATLAS SUIT
%% REQUIRED:
%       - fsl: for isolate DN from atlas
%       - SUIT: in SPM toolbox
%       - "T1.nii": T1 image (this must be registred to b0 image)
%       - "suit_isolate_seg_gio.m" same script of suit_isolate_seg but return
%         bb_box coordintate of crop (available in Directoy "download")

%% INPUT
%       - dir_seg: path to directory that contain images that you want to
%         segment. In this directory there are N directory as N subjects to segment.
%         In each fold there are b0 and T1.
%       - suit_atlas: path to download file: Cerebellum-MNI_1mm.nii and
%         MNI152_T1_1mm.nii.gz (available in Directoy "download")
%       - T1_name: filename of T1-weighted image (not include the extension)
%       - nodif_name: filename of the mean b=0 image (i.e., the non-diffusion-weighted volume),
%         typically used as a reference and appears T2-weighted

%% OUTPUT
%       - "seg_den_suit.nii": DN segmentation obtain with atlas SUIT


function []=segment_DN_SUIT_v2(dir_seg, suit_atlas, T1_name, nodif_name)
%rmpath('/home/bcc/matlab/SMT/nifti-master');
%addpath('/home/bcc/matlab/NIfTI_20140122');

cd(dir_seg)

folderContents = dir;
folderContents(1:2)=[];

for k=1:length(folderContents)
    if folderContents(k).isdir
        myFolder = fullfile(pwd, folderContents(k).name);
        cd (myFolder);
        
        
        %% % Obtain DN segmentation in each subject's T1 space by transforming it from MNI space to T1-weighted space
        
        system(horzcat('fslmaths ', suit_atlas, '/Cerebellum-MNI_1mm.nii.gz -thr 29 -uthr 30 -bin dentati_suit.nii.gz'));
        
        disp('register T1-w image to MNI')
        system(horzcat('flirt -in ', T1_name, ' -ref ', suit_atlas, '/MNI152_T1_1mm.nii.gz -out T12MNI -omat T12MNI.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 12 -interp sinc -sincwidth 7 -sincwindow hanning'));
        
        system(horzcat('fnirt --in=', T1_name, ' --aff=T12MNI.mat --config=T1_2_MNI152_2mm.cnf --iout=T12MNI_fnirt --cout=T1toMNI_coef --fout=T12MNI_warp'));
        
        disp('inversion of the matrix')
        system(horzcat('invwarp -w T12MNI_warp.nii.gz -o MNI_warpcoef.nii.gz -r ', T1_name));
        
        disp('DN in the space of T1')
        
        system(horzcat('applywarp -i dentati_suit.nii.gz -r ', T1_name, ' -w MNI_warpcoef.nii.gz -o DN_T1_suit.nii.gz --interp=nn'));
        
        %% register the T1 to DW in oreder to have the segmentation in the space of diffusion
        system(horzcat('flirt -in ', nodif_name, ' -ref ', T1_name, ' -o diff2T1 -omat diff2T1.mat -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -bins 256 -cost mutualinfo -interp trilinear'));
        
        !convert_xfm -omat T12diff.mat -inverse diff2T1.mat
        
        system(horzcat('flirt -in ', T1_name, ' -ref ' , nodif_name, ' -o T1_nu2diff -applyxfm -init T12diff.mat -interp sinc -sincwidth 7 -sincwindow hanning'));
        
        disp('porto altas nello spazio soggetto diff')
        system(horzcat('flirt -in DN_T1_suit -ref ', nodif_name, ' -o seg_den_suit -applyxfm -init T12diff.mat -interp nearestneighbour'));
        
        
    end
    cd(dir_seg)
end

