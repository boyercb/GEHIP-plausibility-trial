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
  distances using household coordinates.
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
run clean_baseline_1.do
cd "${bin}"
run clean_baseline_2.do
cd "${bin}"
run clean_baseline_3.do

cd "${bin}"
run clean_endline_1.do
cd "${bin}"
run clean_endline_2.do
cd "${bin}"
run clean_endline_3.do

/* ======== Section 2: DDCF analysis ======== */
cd "${bin}"
*do DDCF.do

/* ======== Section 3: DiD+CHPS analysis ======== */
cd "${bin}"
do DiD+CHPS_minoredits.do
