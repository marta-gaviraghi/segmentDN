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
%       - suit_atlas: path to Cerebellum-SUIT.nii.gz (available in Directoy "download")
%         this path have to end with /Cerebellum-SUIT.nii.gz 
       
%% OUTPUT
%       - "seg_den_suit.nii": DN segmentation obtain with atlas SUIT


function []=segment_DN_SUIT(dir_seg, suit_atlas)
%rmpath('/home/bcc/matlab/SMT/nifti-master');
%addpath('/home/bcc/matlab/NIfTI_20140122');

spm fmri

cd(dir_seg)

folderContents = dir;
folderContents(1:2)=[];

for k=1:length(folderContents)
    myFolder = fullfile(pwd, folderContents(k).name);
    cd (myFolder);
    if isfile('T1.nii') || isfile('T1.nii.gz')
        
        %% isolate cerebellum
        !gunzip T1.nii.gz
        input = {'T1.nii'};
        bb=suit_isolate_seg_gio(input, 'keeptempfiles', 1);
        save('bounding_box.mat','bb');
        
        %% register the celebellum cropped (T1) with tamplate of SUIT
        suit_normalize('c_T1.nii', 'mask', 'c_T1_pcereb.nii')
        
        %% thank inverse trasformation registed SUIT altas in subject space 
        suit_reslice_inv(suit_atlas,'mc_T1_snc.mat')
        
        !fslmaths iCerebellum-SUIT.nii -thr 29 -uthr 30 -bin dentati_suit.nii.gz
        %trasform the dimension of segmentation of DN obtained with SUIT to
        %original dimension (before crop to isolate cerebellum, the same of
        %b0_125.nii
        !gunzip dentati_suit.nii.gz
        dentati_struct=load_untouch_nii('dentati_suit.nii');
        dentati_suit=dentati_struct.img;
        dentati_suit=uint8(dentati_suit);
        !gzip dentati_suit.nii
        
        !gunzip T1.nii.gz
        T1_struct=load_untouch_nii('T1.nii');
        !gzip T1.nii
            
        vett_x=bb.x;
        x_min=vett_x(1);
        x_max=vett_x(end);
        
        vett_y=bb.y;
        y_min=vett_y(1);
        y_max=vett_y(end);
        
        vett_z=bb.z;
        z_min=vett_z(1);
        z_max=vett_z(end);
        
        if z_min<=0
            z_min=-z_min+1;
            for canc=1:z_min
                dentati_suit(:,:, canc)=[];
            end
            z_min=1;

            dim=zeros(145, 174, 145);
            dim(x_min:x_max, y_min:y_max, z_min:z_max)=dentati_suit;
            
            den_suit=T1_struct;
            den_suit.img=dim;
            save_untouch_nii(den_suit, 'seg_den_suit.nii');
            
            !gzip *.nii
        else

            dim=zeros(145, 174, 145);
            dim(x_min:x_max, y_min:y_max, z_min:z_max)=dentati_suit;
            
            den_suit=T1_struct;
            den_suit.img=dim;
            save_untouch_nii(den_suit, 'seg_den_suit.nii');
            
            !gzip *.nii
        end
        
    else
        fprintf('%%%%%%%%%%%%%%%%\nNOT exist T1 for: %s', myFolder);
    end
    
    cd(dir_seg)
end

