/*-------------------------------*
 |file:    master.do             |
 |project: GEHIP impact analysis |
 |author:  christopher boyer     |
 |date:    16 aug 2015           |
 *-------------------------------*
 
 description:
    This is the master do-file for the impact analysis of the GEHIP project in 
  Northern Ghana. This program replicates every step from cleaning the raw .dta 
  files through merging, reshaping, and process and impact analysis. The only
  intermediate step not included is the removal of PII and the calculation of 
  distances using household coordinates to protect the privacy of respondents.
*/

clear
version 13

/* ======== Global definitions ======== */
//global dir "~/Dropbox/ARCHeS/CU Practicum Ghana/2014/Christopher Boyer/projects"
global dir "C:/Users/cboyer.IPA/Dropbox/ARCHeS/CU Practicum Ghana/2014/Christopher Boyer/projects"
global proj "${dir}/GEHIP-plausibility-trial"
global data "${proj}/data"
global bin "${proj}/Stata"
global figures "${proj}/figures"
global tables "${proj}/tables"

/* ======== Section 1: Clean and merge data ======== */
cd "${bin}"
run 01_clean_baseline_women.do
cd "${bin}"
run 02_clean_baseline_hhs.do
cd "${bin}"
run 03_clean_baseline_births.do

cd "${bin}"
run 04_clean_endline_women.do
cd "${bin}"
run 05_clean_endline_hhs.do
cd "${bin}"
run 06_clean_endline_births.do

/* ======== Section 2: DiD analysis of CHPS scale up and DDCF indicators ======== */
cd "${bin}"
do 07_chps_scale_up.do
do 08_DDCF_indicators.do

/* ======== Section 3: GEHIP impact analysis ======== */
cd "${bin}"
do 09_GEHIP_impact.do
