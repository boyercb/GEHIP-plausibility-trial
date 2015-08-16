// master.do
// project: GEHIP Endline analysis
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//     master do-file for the difference-in-difference (DID) analysis of GEHIP

clear
version 13

/* ======== Global definitions ======== */
global dir "~/Dropbox/ARCHeS/CU Practicum Ghana/2014/Christopher Boyer/GEHIP"
global data "${dir}/data"
global bin "${dir}/Stata"
global figures "${dir}/figures"
global tables "${dir}/tables"

/* ======== Section 1: Clean and merge data ======== */
do clean

/* ======== Section 2: Baseline analysis ======== */
do baseline

/* ======== Section 3: Endline analysis ======== */
do endline

/* ======== Section 4: DID analysis ======== */
do DID
