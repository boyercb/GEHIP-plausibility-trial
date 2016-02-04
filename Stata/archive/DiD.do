// DiD.do
// project: GEHIP Endline analysis
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   the purpose of this analysis is to...
//     - perform difference-in-difference analysis of GEHIP impact
//     - perform difference-in-difference analysis of core indicators
//     - generate charts and tables for publication

// read baseline pregnancy history, append endline
cd "${data}/clean"
use baseline_preg, clear
append using endline_preg

replace pmonths = 1 if pmonths == 0.5 | pmonths == 0
cd "${tables}/unformatted/DiD"

g period2 = period * 2
replace period2 = 1 if period == 0 & endline == 1

label define lperiod2 0 "2005 - 2010 (baseline)" 1 "2005 - 2010 (endline)" 2 "2011 - 2014"
label values period2 lperiod2

egen deaths = sum(under5), by(secular treatment)
by childid, sort: g nvals = _n == 1
egen births = sum(nvals), by(secular treatment)
gen mortality = deaths/births*1000
sort secular
twoway (connected mortality secular if treatment == 1) (connected mortality secular if treatment == 0), legend(label(1 "treatment") label(2 "control")) title("Under 5 mortality in comparison areas UER, Ghana 2000 - 2014") ytitle("Deaths per 1000 live births")


// table 1: summary statistics for socio-demographic variables by treatment status
#delimit ;
table1 if period == 0, by(treatment) 
  vars( sex cat \ 
        multiple cat \ 
		cparity cat \
		cm_age cat \
		cduration cat \
		bspace cat \
		marital_status cat \
		religion cat \
		education cat \
		q_wealth cat \ 
		urb cat \
		near_HF contn ) 
  saving("01a_bsummary.xls", replace);
  
table1 if period == 1, by(treatment) 
  vars( sex cat \ 
        multiple cat \ 
		cparity cat \
		cm_age cat \
	    cduration cat \
		bspace cat \
		marital_status cat \
		religion cat \
		education cat \
		q_wealth cat \ 
	    urb cat \
		near_HF contn ) 
  saving("01b_esummary.xls", replace);
#delimit cr

*stset pmonths, failure(under5) id(childid) 
*stcox i.treatment##i.period i.sex i.multiple i.cparity i.cm_age i.marital_status i.religion i.education i.urb i.q_wealth near_HF, cluster(deacode)

eststo clear

encode childid, g(id)

// table 2: under 5 mortality (0q5)
save "${data}/clean/unsplit", replace
use "${data}/clean/unsplit", replace
*stset exit_under5, failure(under5) id(childid) enter(cmc_delivery)
prsnperd id pmonths under5, cswitch
g GEHIP = 0
replace GEHIP = 1 if treatment==1 & cmc >= 1333
drop _d51
logit _Y _d1-_d59 i.treatment i.period i.GEHIP, cluster(deacode) or
pwcompare treatment period GEHIP
eststo: quietly logit _Y _d1-_d59 i.treatment i.period i.GEHIP sec, cluster(deacode) or
eststo: quietly logit _Y _d1-_d59 i.treatment i.period i.GEHIP i.sex i.multiple##i.cduration i.bspace i.cm_age i.cparity i.marital_status i.religion i.education i.q_wealth near_HF sec, cluster(deacode) or
esttab using 02_DiD_under5.csv, label wide ci(2) b(2) ///
        title("Under 5 mortality (0q5)") ///
	    nonumbers eform replace          ///
	    mtitles("Crude" "Adjusted")      ///
		scalars(ll_0 ll chi2)
		
eststo clear

// table 3: child mortality (1q4)
use "${data}/clean/unsplit", replace
g pmonths_1q4 = pmonths - 12
drop if pmonths_1q4 < 0
g child = under5
prsnperd id pmonths_1q4 child, cswitch
g GEHIP = 0
replace GEHIP = 1 if treatment==1 & cmc >= 1333
eststo: quietly logit _Y _d1-_d47 i.treatment i.period i.GEHIP sec, cluster(deacode) or
eststo: quietly logit _Y _d1-_d47 i.treatment i.period i.GEHIP i.sex i.multiple##i.cduration i.bspace i.cm_age i.cparity i.marital_status i.religion i.education i.q_wealth near_HF sec, cluster(deacode) or
esttab using 03_DiD_child.csv, label wide ci(2) b(2) ///
        title("Under 5 mortality (0q5)") ///
	    nonumbers eform replace          ///
	    mtitles("Crude" "Adjusted")      ///
		scalars(ll_0 ll chi2)
eststo clear

// table 4: infant mortality (0q1)
use "${data}/clean/unsplit", replace
g pmonths_0q12 = pmonths_infant
prsnperd id pmonths_infant infant, cswitch
g GEHIP = 0
replace GEHIP = 1 if treatment==1 & cmc >= 1333
eststo: quietly logit _Y _d1-_d11 i.treatment i.period i.GEHIP sec, cluster(deacode) or
eststo: quietly logit _Y _d1-_d11 i.treatment i.period i.GEHIP i.sex i.multiple##i.cduration i.bspace i.cm_age i.cparity i.marital_status i.religion i.education i.q_wealth near_HF sec, cluster(deacode) or
esttab using 04_DiD_infant.csv, label wide ci(2) b(2)   ///
        title("Infant mortality (0q1)") ///
	    nonumbers eform replace          ///
	    mtitles("Crude" "Adjusted")      ///
		scalars(ll_0 ll chi2)
eststo clear
/*
logit _Y _d1-_d12 i.treatment i.period i.GEHIP i.sec, cluster(deacode) or 
predict y
twoway (line y _period if treatment == 1, sort)  (line y _period if treatment == 0, sort) , by(period, compact) yscale(log)

stset pmonths, failure(under5) id(childid)
stsplit interval, every(1)
drop if pmonths < 0 
g cmc = cmc_delivery + pmonths
replace sec = int(cmc_delivery/12)
g GEHIP = 0
replace GEHIP = 1 if treatment==1 & cmc >= 1333

replace period = 1 if cmc >= 1333
replace GEHIP = 0 if treatment==1 & cmc >= 1333 & pmonths > 12

label define lGEHIP 0 "ref" 1 "post # intervention"
label values GEHIP lGEHIP

replace under5 = 0 if mi(under5)
/*
fp <pmonths>, replace: logit under5 <pmonths>, cluster(deacode)
logit under5 pmonths_1 pmonths_2  i.period##i.treatment i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.religion i.education i.q_wealth near_HF, cluster(deacode) or
*logit under5 agesp* i.treatment##i.period i.sex i.multiple i.cparity i.marital_status i.religion near_HF i.q_wealth, cluster(deacode) or
*logit under5 i.pmonths i.treatment##i.period, cluster(deacode) or nocons
fp <pmonths>: logit under5 <pmonths> i.period##i.treatment, cluster(deacode)
predict y
twoway (line y pmonths if treatment == 1, sort)  (line y pmonths if treatment == 0, sort) , by(period, compact) yscale(log)

*/


*cloglog under5 agesp* i.treatment##i.period i.sex i.multiple i.cparity i.cm_age i.marital_status i.religion i.education i.q_wealth near_HF, cluster(deacode) eform
stset age1, failure(under5) id(childid) enter(age0)
eststo: quietly stcox i.treatment i.period i.GEHIP, cluster(deacode)
eststo: quietly stcox i.treatment i.period i.GEHIP i.sex i.multiple i.cparity i.cm_age i.marital_status i.religion i.education i.urb i.q_wealth near_HF, cluster(deacode)

esttab using 02_under5.csv, label wide ci(2) b(2) ///
        title("Under 5 mortality (0q5)") ///
	    nonumbers eform replace          ///
	    mtitles("Crude" "Adjusted")      ///
		scalars(ll_0 ll chi2)
*estat phtest, log detail
stcox i.treatment i.period i.GEHIP i.sex i.multiple i.cparity i.marital_status i.religion i.education i.q_wealth near_HF, efron cluster(deacode)
stcurve, hazard at1(GEHIP=0) at2(GEHIP=1)
streg i.treatment i.period i.GEHIP, cluster(deacode) d(weibull)

eststo clear


// table 3: infant mortality (0q1)
use unsplit, replace
drop if pmonths < 0
stset exit_infant, failure(infant) id(childid) enter(cmc_delivery)
stsplit cmc_grant, at(1333)
g GEHIP = 0
replace GEHIP = 1 if treatment==1 & cmc_grant >= 1333
replace period = 1 if cmc_grant >= 1333

duplicates tag childid, generate(dups)
label define lGEHIP 0 "ref" 1 "post # intervention"
label values GEHIP lGEHIP

g pmonths_inf = _t - _t0
g age0 = 0 
replace age0 = cmc_grant - cmc_delivery if cmc_grant >= 1333 & dups != 0
g age1 = _t - cmc_delivery

replace GEHIP = 0 if treatment == 1 & cmc_grant >= 1333 & age0 > 1
replace period = 1 if cmc_delivery >= 1333
stset age1, failure(infant) id(childid) enter(age0)
eststo: quietly stcox i.treatment i.period i.GEHIP, cluster(deacode)
eststo: quietly stcox i.treatment i.period i.GEHIP i.sex i.cparity i.multiple i.marital_status i.religion i.education i.q_wealth near_HF, cluster(deacode)
esttab using 04_infant.csv, label wide ci(2) b(2)   ///
        title("Infant mortality (0q1)") ///
	    nonumbers eform replace         ///
	    mtitles("Crude" "Adjusted")     ///
		scalars(ll_0 ll chi2)
stcox i.treatment i.period i.GEHIP i.sex i.multiple i.cduration i.bspace i.cparity i.marital_status i.religion i.education i.q_wealth near_HF, cluster(deacode)

eststo clear

// table 4: neonatal mortality*/

use unsplit, replace

eststo: quietly logit neonate i.treatment##i.period, or cluster(deacode)
eststo: quietly logit neonate i.treatment##i.period i.sex i.multiple i.cparity i.multiple i.marital_status i.religion i.education i.q_wealth near_HF, or cluster(deacode)
esttab using 05_neonate.csv, label wide ci(2) b(2)  ///
        title("Neonatal mortality")     ///
	    nonumbers eform replace         ///
	    mtitles("Crude" "Adjusted")     ///
		scalars(ll_0 ll chi2)
		
logit neonate i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.religion i.education i.q_wealth near_HF, cluster(deacode) or
eststo clear
