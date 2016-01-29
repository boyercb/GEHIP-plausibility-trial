/*-------------------------------*
 |file:    DiD+CHPS.do           |
 |project: GEHIP impact analysis |
 |author:  christopher boyer     |
 |date:    16 aug 2015           |
 *-------------------------------*
 description:
   the objectives of this analysis are...
     - to merge baseline and endline pregnancy histories
	 - to create summary tables
     - to reshape data into discrete time observations per child
	   by month of age using prsnperd from dthaz package
     - perform crude and adjusted difference-in-difference analysis of GEHIP
	   for under5, child, infant, and neonatal mortality
	 - analyze impact of scale-up of CHPS on mortality
     - generate charts and tables for publication
*/



// read baseline pregnancy history, append endline
cd "${data}/clean"
use baseline_preg, clear
append using endline_preg

cd "${tables}/unformatted/summary"
// table 1: summary statistics for socio-demographic variables by treatment status
#delimit ;
table1 if endline == 0, by(treatment)
  vars( sex cat \
        multiple cat \
		cduration cat \
		bspace cat \
		cparity cat \
		cm_age cat \
	  )
  saving("01a_bsummary.xls", sheet("child") replace);
table1 if endline == 1, by(treatment)
  vars( sex cat \
        multiple cat \
	    cduration cat \
		bspace cat \
		cparity cat \
		cm_age cat \
	  )
  saving("01b_esummary.xls", sheet("child") replace);
#delimit cr*/

// <============== Section 2: Under 5 Mortality (0q5) Analysis =============> //
cd "${data}/clean"

// generate numeric id
encode childid, g(id)

// save intermediate step
save "${data}/clean/unsplit_chps", replace
use "${data}/clean/unsplit_chps", replace

// dthaz function for quickly reshaping to discrete time
// observations are child-months from 1 to 59
prsnperd id pmonths under5, cswitch

// keep track of secular date (for merging)
g date = _period + cmc_delivery

// refine definition of exposure to be
replace period = 1 if date - _period > 1333
replace period = 0 if date - _period <= 1333

// merge CHPS scale up information
// (i.e. distance to nearest CHPS by month)

// baseline
sort hhid
merge m:1 hhid date using baseline_chps
drop if _merge == 2
drop _merge

// endline
sort hhid
merge m:1 hhid date using endline_chps, update
drop if _merge == 2
drop _merge

// define kilometers to nearest CHPS
g chps_km = km_to_nid
replace chps_km = . if chps_km > 1000

// replace a few bad gps points with mean for enumeration area (<10)
egen avg_km = mean(chps_km), by(deacode)
replace chps_km = avg_km if missing(chps_km)

// define chps dummy variable for child residing less than 4 km from CHPS facility
g chps = 0
replace chps = 1 if chps_km < 3

label define lchps 0 "chps >= 4 km" 1 "chps < 4 km"
label values chps lchps

// drop month dummy with no variation
drop _d51

/*  !!!!
    Note: this section generates the fractional polynomial plot used to
    determine where to place the cut-off for chps exposure dummy. It is
    commented out because it takes a long time to run.

fp <chps_km>, replace: logit _Y _d1-_d58 <chps_km>, cluster(deacode)
fp plot
fp predict logOR4
fp predict se, stdp
save "${data}/clean/chps_km_spline", replace
*/

// run models and output results to table
drop _d51
cd "${tables}/unformatted/CHPS_scale_up"
eststo clear
eststo: quietly logit _Y _d1-_d58 i.treatment##i.period, cluster(deacode) or
eststo: quietly logit _Y _d1-_d58 i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
eststo: quietly logit _Y _d1-_d58 i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
esttab using 02_DiD+CHPS_under5.csv, label wide ci(2) b(2) ///
        title("Under 5 mortality (0q5)") ///
	    nonumbers eform replace          ///
	    mtitles("(1)" "(2)" "(3)")      ///
		scalars(ll_0 ll chi2)
eststo clear

cd "${data}/clean"
keep hhid date treatment period deacode
duplicates drop hhid date, force
save "split_hh", replace

// <============== Section 3: Child Mortality (1q4) Analysis ===============> //

// table 3: child mortality (1q4)
cd "${data}/clean"
use "unsplit_chps", replace
g pmonths_1q4 = pmonths - 12
drop if pmonths_1q4 < 0
g child = under5
prsnperd id pmonths_1q4 child, cswitch
g date = _period + cmc_delivery

replace period = 1 if date - _period > 1333
replace period = 0 if date - _period <= 1333

// merge scale up information
sort hhid
merge m:1 hhid date using baseline_chps
drop if _merge == 2
drop _merge

sort hhid
merge m:1 hhid date using endline_chps, update
drop if _merge == 2
drop _merge

g chps_km = km_to_nid
replace chps_km = . if chps_km > 1000

egen avg_km = mean(chps_km), by(deacode)
replace chps_km = avg_km if missing(chps_km)
g chps = 0
replace chps = 1 if chps_km < 3

label define lchps 0 "chps >= 4 km" 1 "chps < 4 km"
label values chps lchps

drop _d37
cd "${tables}/unformatted/CHPS_scale_up"
eststo clear
eststo: quietly logit _Y _d1-_d47 i.treatment##i.period, cluster(deacode) or
eststo: quietly logit _Y _d1-_d47 i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
eststo: quietly logit _Y _d1-_d47 i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
esttab using 03_DiD+CHPS_child.csv, label wide ci(2) b(2) ///
        title("Child mortality (1q4)") ///
	    nonumbers eform replace          ///
	    mtitles("(1)" "(2)" "(3)")      ///
		scalars(ll_0 ll chi2)
eststo clear

// <============= Section 4: Infant Mortality (0q1) Analysis ===============> //

cd "${data}/clean"
use "${data}/clean/unsplit_chps", replace
g pmonths_0q12 = pmonths_infant
prsnperd id pmonths_infant infant, cswitch
g date = _period + cmc_delivery

replace period = 1 if date - _period > 1333
replace period = 0 if date - _period <= 1333

// merge scale up information
sort hhid
merge m:1 hhid date using baseline_chps
drop if _merge == 2
drop _merge

sort hhid
merge m:1 hhid date using endline_chps, update
drop if _merge == 2
drop _merge

g chps_km = km_to_nid
replace chps_km = . if chps_km > 1000

egen avg_km = mean(chps_km), by(deacode)
replace chps_km = avg_km if missing(chps_km)
g chps = 0
replace chps = 1 if chps_km < 4

label define lchps 0 "chps >= 4 km" 1 "chps < 4 km"
label values chps lchps

cd "${tables}/unformatted/CHPS_scale_up"

eststo clear
eststo: quietly logit _Y _d1-_d11 i.treatment##i.period, cluster(deacode) or
eststo: quietly logit _Y _d1-_d11 i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
eststo: quietly logit _Y _d1-_d11 i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
esttab using 04_DiD+CHPS_infant.csv, label wide ci(2) b(2) ///
        title("Infant mortality (0q1)") ///
	    nonumbers eform replace          ///
	    mtitles("(1)" "(2)" "(3)")      ///
		scalars(ll_0 ll chi2)
eststo clear

// <=============== Section 5: Neonatal Mortality Analysis ================> //

cd "${data}/clean"
use "${data}/clean/unsplit_chps", replace

g date = cmc_delivery

// merge scale up information
sort hhid
merge m:1 hhid date using baseline_chps
drop if _merge == 2
drop _merge

sort hhid
merge m:1 hhid date using endline_chps, update
drop if _merge == 2
drop _merge

g chps_km = km_to_nid
replace chps_km = . if chps_km > 1000

egen avg_km = mean(chps_km), by(deacode)
replace chps_km = avg_km if missing(chps_km)
g chps = 0
replace chps = 1 if chps_km < 4

label define lchps 0 "chps >= 4 km" 1 "chps < 4 km"
label values chps lchps

cd "${tables}/unformatted/CHPS_scale_up"

logit neonate i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or

eststo clear
eststo: quietly logit neonate i.treatment##i.period, cluster(deacode) or
eststo: quietly logit neonate i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
eststo: quietly logit neonate i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
esttab using 04_DiD+CHPS_infant.csv, label wide ci(2) b(2) ///
        title("Infant mortality (0q1)") ///
	    nonumbers eform replace          ///
	    mtitles("(1)" "(2)" "(3)")      ///
		scalars(ll_0 ll chi2)
eststo clear


// <================= Section 6: GEHIP impact on CHPS km ===================> //


use baseline_chps, replace
sort hhid
merge m:m hhid using "${data}/clean/baseline_hh", update
drop if _merge == 2
drop _merge
append using endline_chps
append using endline_chps2
sort hhid
merge m:m hhid using "${data}/clean/endline_hh", update
drop if _merge == 2
drop _merge

g period = 0
replace period = 1 if date > 1333

g chps_km = km_to_nid
replace chps_km = . if chps_km > 1000

egen avg_km = mean(chps_km), by(deacode)
replace chps_km = avg_km if missing(chps_km)
reg chps_km treatment##period, cluster(hhid)
qreg chps_km treatment##period, quantile(0.25)
qreg chps_km treatment##period, quantile(0.50)
qreg chps_km treatment##period, quantile(0.75)
qreg chps_km treatment##period, quantile(0.9)




