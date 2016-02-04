/*-------------------------------*
 |file:    DiD.do           |
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

orth_out sex multiple cduration bspace cparity cm_age urb education religion marital_status q_wealth if period == 1, by(treatment) pcompare count vce(cluster deacode)
orth_out sex multiple cduration bspace cparity cm_age urb education religion marital_status q_wealth if period == 0, by(treatment) pcompare count vce(cluster deacode)

// <============== Section 2: Under 5 Mortality (0q5) Analysis =============> //

// generate numeric id 
encode childid, g(id)

// save intermediate step
save "${data}/clean/unsplit_chps", replace
use "${data}/clean/unsplit_chps", replace
/*
g nonmissing=(sex!=.&multiple!=.&cduration!=.&bspace!=.&cm_age!=.&cparity!=.&marital_status!=.&education!=.&religion!=.&q_wealth!=.&near_HF!=.)
*dthaz period treatment GEHIP, truncate(50)

stset pmonths, id(id) failure(under5)
g GEHIP = period * time

gen age_at_split = 1336 - cmc_delivery
replace age_at_split = 1 if age_at_split > 12 
replace age_at_split = 1 if age_at_split < 0 

expand 2 if age_at_split > 1, gen(dup)
replace _t0 = age_at_split if dup

replace GEHIP = 1 if _t >= age_at_split & treatment == 1
replace GEHIP = 0 if _t < age_at_split & treatment == 1
replace period = 1 if _t >= age_at_split
replace period = 1 if _t < age_at_split
g tXGEHIP = _t * GEHIP

local path = "${tables}/unformatted"
stcox i.treatment i.period i.GEHIP, cluster(deacode) efron
*/
/*
mi set wide
mi register imputed q_wealth religion marital_status cm_age education near_HF sex
g txXperiod = treatment * period
set seed 774563
replace sex = sex - 1
label define s 0 "male" 1 "female"
label values sex s
mi impute chained (mlogit) q_wealth religion marital_status cm_age (logit) sex education (regress) near_HF = treatment period txXperiod multiple cduration bspace cparity, add(20)
*/

// dthaz function for quickly reshaping to discrete time
// observations are child-months from 1 to 59
prsnperd id pmonths under5, cswitch 

// keep track of secular date (for merging)
g date = _period + cmc_delivery

// refine definition of exposure to be 
/*replace period = 0
replace period = 1 if cmc_delivery >= 1336
replace period = 1 if date >= 1336  & _period < 12
*/
replace period = 1 if cmc_delivery >= 1336 & endline == 1
replace period = 0 if cmc_delivery < 1336

gen GEHIPage = 0
replace GEHIPage = _period if date == 1336
egen age_exp = max(GEHIPage), by(id)
g GEHIP = period * treatment

// merge CHPS scale up information
// (i.e. distance to nearest CHPS by month)
cd "${data}/clean"

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

save "person_period.dta", replace

// define chps dummy variable for child residing less than 4 km from CHPS facility
g chps = 0
replace chps = 1 if chps_km < 4

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
*drop _d51

**define observations without missing information for regression
g nonmissing=(sex!=.&multiple!=.&cduration!=.&bspace!=.&cm_age!=.&cparity!=.&marital_status!=.&education!=.&q_wealth!=.&near_HF!=.)
*dthaz period treatment GEHIP, truncate(50)

stset _period, id(id) failure(_Y) 
g tXGEHIP = _t * GEHIP

local fout  "${tables}/unformatted/DiD_sensitivity.xml"
stcox i.treatment i.period i.GEHIP, cluster(deacode) efron
sts list, by(treatment period) saving("${tables}/unformatted/survival_tables.dta")
preserve 
use "${tables}/unformatted/survival_tables.dta", replace
export excel using "${tables}/unformatted/survival_tables.xlsx", firstrow(var) replace
restore
estat phtest, detail
stcox i.treatment i.period i.GEHIP, cluster(deacode) efron
local fout  "${tables}/unformatted/DiD_sensitivity.xml"
outreg2 using "`fout'", excel replace sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP tXGEHIP, cluster(deacode) efron 
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP tXGEHIP if nonmissing, cluster(deacode) efron 
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))

local fout  "${tables}/unformatted/DiD_under5.xml"
g chpsXGEHIP = chps * GEHIP
g chpsXperiod = chps * period
g chpsXtreatment = chps * treatment
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel replace sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP i.chps i.chpsXtreatment i.chpsXperiod i.chpsXtreatment i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))


/*
replace period = 1 if date >= 1336 
replace period = 0 if date < 1336 
replace GEHIP = period * treatment
replace tXGEHIP = _t * GEHIP

local path = "${tables}/unformatted"
stcox i.treatment i.period i.GEHIP, cluster(deacode) efron
outreg2 using "`path'/DiD_sensitivity_exp.xml", excel replace sideway ci eform
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
outreg2 using "`path'/DiD_sensitivity_exp.xml", excel append sideway ci eform
stcox i.treatment i.period i.GEHIP tXGEHIP, cluster(deacode) efron 
outreg2 using "`path'/DiD_sensitivity_exp.xml", excel append sideway ci eform
stcox i.treatment i.period i.GEHIP tXGEHIP if nonmissing, cluster(deacode) efron 
outreg2 using "`path'/DiD_sensitivity_exp.xml", excel append sideway ci eform
*/
*stset _period, id(childid) failure(_Y)
*stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) 

*sts list, by(treatment period) saving("${tables}/unformatted/survival_tables.txt")
*logit _Y _d1-_d58 i.treatment i.period i.GEHIP if nonmissing==1, cluster(deacode) or
*logit _Y _d1-_d58 i.treatment i.period i.GEHIP if nonmissing==1, or

*nlcom exp(_b[1.treatment] + _b[1.period] + _b[1.treatment#1.period]) - exp(_b[1.treatment]) - exp(_b[1.period]) + 1

*margins i.treat, expression(predict(xb)*12*5)
*marginsplot
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
tempname mem
tempfile temp
postfile `mem' str32 variable or_pre str32 ci_pre or_post str32 ci_post using `temp'
lincom 1.period
local ci_low: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
post `mem' ("Control") (1.0) ("ref") (exp(`r(estimate)')) ("("+"`ci_low'"+", "+"`ci_hi'"+ ")")
lincom 1.treatment
local est1 = `r(estimate)'
local ci_low1: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi1: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
lincom 1.treatment + 1.period + 1.GEHIP
local est2 = `r(estimate)'
local ci_low2: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi2: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
post `mem' ("GEHIP") (exp(`est1')) ("("+"`ci_low1'"+", "+"`ci_hi1'"+ ")") (exp(`est2')) ("("+"`ci_low2'"+", "+"`ci_hi2'"+ ")")
postclose `mem'
preserve
use `temp', replace
format or_pre %5.3f
format or_post %5.3f
export excel using "${tables}/unformatted/GEHIP_Lincom_Results.xlsx", replace
restore

/*
// sensitivity analysis
eststo clear
mi estimate, or post: quietly logit _Y _d1-_d58 i.treatment##i.period, cluster(deacode)
eststo model1
mi estimate, or post: quietly logit _Y _d1-_d58 i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode)
eststo model2
mi estimate, or post: quietly logit _Y _d1-_d58 i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode)
eststo model3
esttab using "${tables}/unformatted/GEHIP_mi.csv", label wide ci(2) b(2) ///
    title("Under 5 mortality (0q5)") ///
	nonumbers eform replace          ///
	mtitles("(1)" "(2)" "(3)")      ///
	scalars(ll_0 ll chi2)
eststo clear
*/
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

replace period = 1 if date >= 1336 & endline == 1
replace period = 0 if date < 1336

g GEHIP = period * treatment
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

**define observations without missing information for regression
g nonmissing=(sex!=.&multiple!=.&cduration!=.&bspace!=.&cm_age!=.&cparity!=.&marital_status!=.&education!=.&q_wealth!=.&near_HF!=.)

drop _d37
stset _period, id(id) failure(_Y) 
g tXGEHIP = _t * GEHIP

local fout  "${tables}/unformatted/DiD_child.xml"
g chpsXGEHIP = chps * GEHIP
g chpsXperiod = chps * period
g chpsXtreatment = chps * treatment
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel replace sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP i.chps i.chpsXtreatment i.chpsXperiod i.chpsXtreatment i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))

drop _d37
stset _period, id(id) failure(_Y) 
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
tempname mem
tempfile temp
postfile `mem' str32 variable or_pre str32 ci_pre or_post str32 ci_post using `temp'
lincom 1.period
local ci_low: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
post `mem' ("Control") (1.0) ("ref") (exp(`r(estimate)')) ("("+"`ci_low'"+", "+"`ci_hi'"+ ")")
lincom 1.treatment
local est1 = `r(estimate)'
local ci_low1: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi1: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
lincom 1.treatment + 1.period + 1.GEHIP
local est2 = `r(estimate)'
local ci_low2: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi2: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
post `mem' ("GEHIP") (exp(`est1')) ("("+"`ci_low1'"+", "+"`ci_hi1'"+ ")") (exp(`est2')) ("("+"`ci_low2'"+", "+"`ci_hi2'"+ ")")
postclose `mem'
preserve
use `temp', replace
format or_pre %5.3f
format or_post %5.3f
export excel using "${tables}/unformatted/GEHIP_Lincom_Results.xlsx", replace sheet("child")
restore
/*
cd "${tables}/unformatted/CHPS_scale_up"
eststo clear
eststo: quietly logit _Y _d1-_d47 i.treatment##i.period if nonmissing==1, cluster(deacode) or
eststo: quietly logit _Y _d1-_d47 i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
eststo: quietly logit _Y _d1-_d47 i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
esttab using 03_DiD+CHPS_child.csv, label wide ci(2) b(2) ///
        title("Child mortality (1q4)") ///
	    nonumbers eform replace          ///
	    mtitles("(1)" "(2)" "(3)")      ///
		scalars(ll_0 ll chi2)
eststo clear
*/
// <============= Section 4: Infant Mortality (0q1) Analysis ===============> //

cd "${data}/clean"
use "${data}/clean/unsplit_chps", replace
g pmonths_0q12 = pmonths_infant
prsnperd id pmonths_infant infant, cswitch
g date = _period + cmc_delivery

replace period = 1 if cmc_delivery >= 1336 & endline == 1
replace period = 0 if cmc_deliver < 1336

g GEHIP = treatment * period
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

**define observations without missing information for regression
g nonmissing=(sex!=.&multiple!=.&cduration!=.&bspace!=.&cm_age!=.&cparity!=.&marital_status!=.&education!=.&q_wealth!=.&near_HF!=.)

stset _period, id(id) failure(_Y) 
g tXGEHIP = _t * GEHIP

local fout  "${tables}/unformatted/DiD_infant.xml"
g chpsXGEHIP = chps * GEHIP
g chpsXperiod = chps * period
g chpsXtreatment = chps * treatment
stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel replace sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF if nonmissing, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
stcox i.treatment i.period i.GEHIP i.chps i.chpsXtreatment i.chpsXperiod i.chpsXtreatment i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF, cluster(deacode) efron
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
cd "${tables}/unformatted/CHPS_scale_up"

stcox i.treatment i.period i.GEHIP if nonmissing, cluster(deacode) efron
tempname mem
tempfile temp
postfile `mem' str32 variable or_pre str32 ci_pre or_post str32 ci_post using `temp'
lincom 1.period
local ci_low: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
post `mem' ("Control") (1.0) ("ref") (exp(`r(estimate)')) ("("+"`ci_low'"+", "+"`ci_hi'"+ ")")
lincom 1.treatment
local est1 = `r(estimate)'
local ci_low1: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi1: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
lincom 1.treatment + 1.period + 1.GEHIP
local est2 = `r(estimate)'
local ci_low2: di %5.3f exp(`r(estimate)' - 1.96 * `r(se)')
local ci_hi2: di %5.3f exp(`r(estimate)' + 1.96 * `r(se)')
post `mem' ("GEHIP") (exp(`est1')) ("("+"`ci_low1'"+", "+"`ci_hi1'"+ ")") (exp(`est2')) ("("+"`ci_low2'"+", "+"`ci_hi2'"+ ")")
postclose `mem'
preserve
use `temp', replace
format or_pre %5.3f
format or_post %5.3f
export excel using "${tables}/unformatted/GEHIP_Lincom_Results.xlsx", replace sheet("infant")
restore
/*
eststo clear
eststo: quietly logit _Y _d1-_d11 i.treatment##i.period if nonmissing==1, cluster(deacode) or
eststo: quietly logit _Y _d1-_d11 i.treatment##i.period i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
eststo: quietly logit _Y _d1-_d11 i.treatment##i.period##i.chps i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.religion i.q_wealth near_HF, cluster(deacode) or
esttab using 04_DiD+CHPS_infant.csv, label wide ci(2) b(2) ///
        title("Infant mortality (0q1)") ///
	    nonumbers eform replace          ///
	    mtitles("(1)" "(2)" "(3)")      ///
		scalars(ll_0 ll chi2)
eststo clear
*/
// <=============== Section 5: Neonatal Mortality Analysis ================> //

cd "${data}/clean"
use "${data}/clean/unsplit_chps", replace

g date = cmc_delivery
replace period = 1 if cmc_delivery >= 1336 & endline == 1
replace period = 0 if cmc_delivery < 1336
g GEHIP = treatment * period
g tx2 = inlist(district, 2, 3)
g period2 = 1 if cmc_delivery >= 1363 
replace period2 = 0 if cmc_delivery < 1363
g SERC = tx2 * period2

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

local fout "${tables}/unformatted/DiD_neonate.xml"
g chpsXGEHIP = chps * GEHIP
g chpsXperiod = chps * period
g chpsXtreatment = chps * treatment

logit neonate i.period i.period2 i.treatment i.GEHIP i.SERC, cluster(deacode)
outreg2 using "`fout'", excel replace sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
logit neonate i.period i.treatment i.GEHIP i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF, cluster(deacode) or
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
logit neonate i.period i.treatment i.GEHIP i.sex i.multiple i.cduration i.bspace i.cm_age i.cparity i.marital_status i.education i.q_wealth near_HF, cluster(deacode) or
outreg2 using "`fout'", excel append sideway ci eform addstat("No. Subjects", e(N_sub), "No. Clusters", e(N_clust), "Log-likelihood", e(ll), "Chi-squared", e(chi2), "df", e(df_m))
/*
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
*/
