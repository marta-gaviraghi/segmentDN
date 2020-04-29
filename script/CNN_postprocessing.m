%% segment DN using CNN and clear FP using segmentation DN obteined with SUIT

%% NEED:
%       - DN segment with SUIT: "dentati_suit.nii.gz" (if you have not use
%         script "segment_DN_SUIT.m")
%       - fsl (fslmath for dilatate DN of SUIT)
%       - check to have matRead.m and dicePixelClassificationLayer.m (available in Directoy download)

%% INPUT:
%       - dir_seg: path to directory that contain images that you want to segment
%       - path_CNN: path to "rete.mat" (available in Directoy download)

%% OUTPUT:
%       (- "dentati_CNN.nii" segmentation obtaind with CNN)
%       (- "dentati_filtrati_suit.nii" segmentation after filtring (clean))
%       - "DN_CNN" segmentation DN at original resolution

function []=CNN_postprocessing(dir_seg, path_CNN)
cd(path_CNN)
load rete.mat

cd(dir_seg)

folderContents = dir;
folderContents(1:2)=[];

dentati_sa=zeros(86, 71, 66);

for k=1:length(folderContents)
    if folderContents(k).isdir
        myFolder = fullfile(pwd, folderContents(k).name);
        cd (myFolder);
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
                
                %save image of DN segmentation as nifti file
                dentati_sa1=dentati_MG_struct;
                dentati_sa1.img=dent_sa_dim;
                save_untouch_nii(dentati_sa1, 'dentati_CNN.nii');
            end
            
            dentati_struct=load_untouch_nii('dentati_CNN.nii');
            dentati=dentati_struct.img;
            dentati=uint8(dentati);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %load DN segmented with SUIT: for the post process-phase
            gunzip('dentati_suit.nii.gz');
            delete('dentati_suit.nii.gz');
            
            maschera_struct=load_untouch_nii('dentati_suit.nii');
            maschera=maschera_struct.img;
            
            gzip('dentati_suit.nii');
            delete('dentati_suit.nii');
            
            %% dilated the DN obtain with SUIT (before filtered)
            !fslmaths seg_den_suit.nii -dilM -dilM seg_den_suit_dil.nii.gz
            gunzip('seg_den_suit_dil.nii.gz');
            delete('seg_den_suit_dil.nii.gz');
            
            maschera_dil_struct=load_untouch_nii('seg_den_suit_dil.nii');
            maschera_dil=maschera_dil_struct.img;
            
            gzip('seg_den_suit_dil.nii');
            delete('seg_den_suit_dil.nii');
            
            maschera_vett=maschera_dil(:);
            dentati_sa_vett=dentati(:);
            
            maschera_vett=uint8(maschera_vett);
            
            dentati_filtrati_vett=maschera_vett.*dentati_sa_vett;
            
            dentati_filtrati=reshape(dentati_filtrati_vett, 145, 174, 145);
            
            sa_filtrata=dentati_struct;
            sa_filtrata.img=dentati_filtrati;
            %save DN segmentation after post-processing phase
            save_untouch_nii(sa_filtrata, 'dentati_filtrati_suit.nii');
            %calculate inverse matrix -> for return to original dimension
            unix(horzcat('/usr/share/fsl/5.0/bin/convert_xfm -omat ', myFolder,'/b0_125_inv.mat -inverse ', myFolder,'/b0_125.mat'));
            
            %use interpolation nearest neighbor because i want 0 or 1
            unix(horzcat('/usr/share/fsl/5.0/bin/flirt -in ', myFolder, '/dentati_filtrati_suit.nii -applyxfm -init ', myFolder, '/b0_125_inv.mat -out ' , myFolder,'/DN_CNN.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref ', myFolder,'/b0.nii.gz'));
            
        else
            disp('segment DN with SUIT!!!')
            
        end
    end
    cd(dir_seg)
end
end
