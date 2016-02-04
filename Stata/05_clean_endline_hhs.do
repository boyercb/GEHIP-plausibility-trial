// clean_endline_2.do
// project: GEHIP Endline analysis
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   clean and create household data set

cd "${data}/clean"
use endline_clean, replace
drop if district==4|district==5

duplicates drop hhid, force
sort hhid
merge m:1 hhid using eacodes
drop if _merge == 2
drop _merge

drop treatment
g treatment=.
replace treatment=1 if district==2|district==3|district==6
replace treatment=0 if treatment!=1
label define ltreatment 0 "control" 1 "intervention"
label values treatment ltreatment

// recode categorical variables as dichotomous 
// note --> missing coded as zero
replace water=1 if water==2|water==3|water==4
replace water=0 if water>4

g dcart = cart
g flush=.
replace flush=1 if toilet==2|toilet==3|toilet==4
replace flush=0 if toilet==1|toilet==5|toilet==6|toilet==7|toilet==8|toilet==9|toilet==.

replace toiletshare=0 if toiletshare==1|toiletshare==8|toiletshare==.
replace toiletshare=1 if toiletshare==2
/*
replace refuse=1 if refuse==2|refuse==3|refuse==4
replace refuse=0 if refuse>4

replace lwaste=0 if lwaste>2
*/
// recode to zero if missing or no asset
foreach var of varlist radio hcomp clock mobile fridge video freezer dvd motobike car dcart {
	replace `var'=0 if `var'==8|`var'==2|`var'==.
	}
	
// pca command to generate index
pca flush toiletshare water radio hcomp clock mobile fridge video freezer dvd motobike car dcart
predict index1

// create 5 categories, and 3 categories using only the first PC
xtile q_wealth=index1, nq(5) 
label define wealth 1 "Poorest" 2 "Poor" 3 "Better" 4 "Less poor" 5 "Least poor"
label values q_wealth wealth

sort hhid
keep hhid q_wealth treatment deacode
cd "${data}/clean"
save endline_hh, replace
