# Automatic dentate nuclei (DN) segmentation pipeline

## Description
This pipeline implements an automated method to segment the dentate nuclei (DN) from diffusion MRI data using a 2D CNN. It is implemented in MATLAB R2019a with the Deep Learning Toolbox.
The CNN was trained on high-resolution b0 images from the Human Connectome Project (HCP) and has been tested on clinical external datasets, including Temporal Lobe Epilepsy (TLE) patients.

![alt text](https://github.com/marta-gaviraghi/segmentDN/blob/master/figure/CNN_cap4_ok.png)

The pipeline consists of three scripts:

1) segment_DN_SUIT_1.m: extracts the dentate nucleus from the SUIT cerebellar atlas and registers T1 and B0 images into MNI space.

2) resampling_normalize_2.m: Resamples and normalizes the B0 image in the HCP space.

3) CNN_postprocessing_3.m: Performs CNN-based DN segmentation and applies a SUIT-based mask filter to remove false positives.

## Repository Structure
scripts/: Contains the MATLAB scripts for each processing step.

download/: Includes necessary reference files and templates.

## Requirements
- MATLAB (R2020 or later)
- FSL (FMRIB Software Library)

## Usage
Clone the repository:
```bash
      git clone https://github.com/marta-gaviraghi/segmentDN.git
```

Run the scripts in order:

#### segment_DN_SUIT_1.m
**Inputs:** T1 image, B0 image, download folder, output folder  
**Outputs:** DN segmentation in B0 space (`DN_diff_SUIT.nii.gz`)  

#### resampling_normalize_2.m
**Inputs:** B0 image, brain mask, download folder, output folder  
**Outputs:** Resampled B0 (`b0_125.nii.gz`), normalized B0 (`B0_N.nii.gz`)  

#### CNN_postprocessing_3.m
**Inputs:** Output folder, download folder, original B0 image  
**Outputs:** CNN segmentation (`DN_CNN_final.nii.gz`)

## Citation
For more details, see the original publication:  

Gaviraghi et al., 2021, Automatic Segmentation of Dentate Nuclei for Microstructure Assessment: Example of Application to Temporal Lobe Epilepsy Patients
DOI: 10.1007/978-3-030-73018-5_21

**If you use this code in your work, please cite the above paper.**


### CNN Architecture


![alt text](https://github.com/marta-gaviraghi/segmentDN/blob/master/figure/Figure_1.bmp)
