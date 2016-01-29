* -------------------------------------------------------------------- *
*           GEHIP Difference-in-Difference (DD) Estimation             *
* ==================================================================== *
* Authors: James F. Phillips, Christopher B. Boyer, Patrick O. Asuming *
*          Ayaga A. Bawah, and J. Koku Awoonor-Williams                *
* Date: June 13, 2015                                                  *
* Version 2.0                                                          *
* -------------------------------------------------------------------- *
* Description:                                                         *
*    This file merges baseline and endline core and common indicator   *
* data relating to GEHIP implementation and analyzes impact using the  *
* difference-in-differences estimator.                                 *
*                                                                      *
* requirements:   +  DD_baseline.dta                                   *
*                 +  DD_endline.dta                                    *
* -------------------------------------------------------------------- *

* Working directory
cd "${data}/clean"

* use data arranged by female respondent
use baseline_women, clear
append using endline_women
*drop if district == 1

cd "${tables}/unformatted/summary"

#delimit ;
table1 if endline == 0, by(treatment) 
  vars( marital_status cat \
		religion cat \
		education cat \
		) 
  saving("01a_bsummary.xls", sheet("women") replace);
table1 if endline == 1, by(treatment) 
  vars( marital_status cat \
		religion cat \
		education cat \
		) 
  saving("01b_esummary.xls", sheet("women") replace);
#delimit cr*/


g new_tx = SERC
replace new_tx = 3 if district == 1

label define ltx 0 "control" 1 "GEHIP" 2 "GEHIP + SERC" 3 "control (Bolgatanga)"
label values new_tx ltx

* descriptive statistics
tab treatment time, summarize(anccheck)
tab treatment time, summarize(anc4plus)
tab treatment time, summarize(pregmalaria)
tab treatment time, summarize(skilled_del)
tab treatment time, summarize(csec)
tab treatment time, summarize(cmodern)
tab treatment time, summarize(measlesyes)
tab treatment time, summarize(dpt3yes)
tab treatment time, summarize(antimalarial)
tab treatment time, summarize(ors)
tab treatment time, summarize(vitAsup)
tab treatment time, summarize(childnet)

* model building

* ----- Core Indicator 4: Antenatal Care ----- *
logit anccheck i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

logit anc4plus i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot


* ----- Core Indicator 5: IPTp During Pregnancy ----- *
logit pregmalaria i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 6: Skilled Birth Attendance ----- *
logit skilled_del i.time##i.SERC##i.near_HF, or cluster(deacode)
margins time##SERC##near_HF
marginsplot

logit skilled_del i.time##i.treatment i.marital_status i.cparity i.cage i.religion i.education i.wealth, or cluster(deacode)
margins time##SERC
marginsplot
* ----- Core Indicator 7: C-section Prevalence ----- *
logit csec i.time##i.SERC, or cluster(deacode)
margins time##SERC
marginsplot

logit csec i.time##i.treatment##i.near_Hosp, or cluster(deacode)
margins time##new_tx
marginsplot

* ----- Core Indicator 8: Modern Contraceptive Use ----- *
logit cmodern i.time##i.treatment i.marital_status i.cparity i.cage i.religion i.education i.wealth i.near_HF, or cluster(deacode)
logit cmodern i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 10: Measles Vaccination Coverage ----- *
logit measlesyes i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 11: DPT3 Vaccination Coverage ----- *
logit dpt3yes i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 12: Antimalarial Treatments ----- *
logit antimalarial i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 14: Oral Rehydration Salt Therapy ----- *
logit ors i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 15: 2 doses of Vitamin A ----- *
logit vitAsup i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

* ----- Core Indicator 16: Child ITN use (last night) ----- *
logit childnet i.time##i.treatment, or cluster(deacode)
margins time##treatment
marginsplot

*mlogit cmethod i.time##i.treatment i.marital_status i.cparity i.cage i.education i.wealth, rrr
