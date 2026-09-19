# Running the retained figure/statistics scripts

This folder contains the retained R Markdown scripts and their local helper files.

1. Set the working directory to this `figs_code` folder.
2. Make sure the required R packages used by the script are installed.
3. Open and knit the selected `.Rmd` file, or run its code chunks from this folder.

Input workbooks are stored in the sibling folder `../figs_data/`. Generated figures are written to `./02_fig/` (with questionnaire pattern figures in `./02_fig/ques_pattern_fig/`).

The scripts in this package use relative paths and do not require the original `LeoResearch` directory layout. The original research files were not modified.

This package contains figure/statistics scripts and their input workbooks; it does not include the large Stan `.Rdata` fit objects used for model refitting.
