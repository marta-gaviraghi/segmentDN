# Automatic segmentation of dentate nuclei
### Implemented in Matlab19a using the Deep Learning Toolbox

![alt text](https://github.com/marta-gaviraghi/segmentDN/blob/master/CNN_cap4_ok.png)

N.B. put path with '' (single comma)
example: '/media/bcc/bcc-data/MARTA/HCP'

Three function: resampling_normalize.m, CNN_postprocessing.m and segment_DN_SUIT.m

-----------------------------------------------------------------------------------------
### 1) resampling_normalize(dir_seg, ref_img)

resampling and normalize the b0 image
		- resampling image (that you want to segment) to spatial resolution of HCP (this resolution is that was used for CNN training)
		- intensity normalize: mean=0 and std=1 for the voxels that belong to brain -> it is required a mask of the brain

REQUIRED:
- flirt (FSL)
- image HCP (as refrence for resampling) "SIGNAL.nii.gz" (available in Directoy download)

INPUT: 
- dir_seg: directory with content N directory as N subjects to segment. In each directory there are: b0("b0.nii.gz") and mask oF brain ("brain_mask.nii.gz").
- ref_img: path to b0 of HCP to use as reference; path must end with "/SIGNAL.nii.gz"

OUTPUT:
- b0 resampled, name "b0_125.nii.gz"
- b0 resampled and normalized, name "B0_N.nii"

-----------------------------------------------------------------------------------------
### 2) CNN_postprocessing(dir_seg, path_CNN)

segment DN using CNN and clear FP using segmentation DN obteined with SUIT

REQUIRED:
- DN segmented with SUIT: "dentati_suit.nii.gz" (if you have not use script "segment_DN_SUIT.m")
- fsl (fslmath for dilatate DN of SUIT)
- check to have matRead.m and dicePixelClassificationLayer.m (available in Directoy download)

INPUT:
- dir_seg: path to directory that contain images that you want to segment
- path_CNN: path to Directoy download where are "rete.mat" 

OUTPUT:
- "DN_CNN" segmentation obtained with CNN to your resolution

-----------------------------------------------------------------------------------------
### 3) segment_DN_SUIT(dir_seg)

DN segmentation with ATLAS SUIT

REQUIRED:
- fsl: for isolate DN from atlas 
- SUIT: in SPM toolbox
- "T1.nii": T1 image (this must be registred to b0 image)
- "suit_isolate_seg_gio.m" same script of suit_isolate_seg but return bb_box coordintate of crop (available in Directoy download)

INPUT:
- dir_seg: path to directory that contain images that you want to segment, In this directory there are N directory as N subjects to 	  segment. In each of N directory there are b0 and T1
- suit_atlas: path to Cerebellum-SUIT.nii.gz (available in Directoy "download") this path have to end with "/Cerebellum-SUIT.nii.gz"
       
OUTPUT:
- "seg_den_suit.nii": DN segmentation obtain with atlas SUIT
    
