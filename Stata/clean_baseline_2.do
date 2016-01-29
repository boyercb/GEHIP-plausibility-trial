// clean_baseline_2.do
// =================
// project: GEHIP Plausibility Trial
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   the purpose of this do-file is to clean and standardize baseline data,
//   including:  - to define global treatment and survey variables
//               - to create female respondent level data set
//               - to create household level data set  (***)
//               - to create pregnancy history data set


// read baseline data set
// household data set
cd "${data}/clean"
use baseline_clean, replace

duplicates drop hhid, force

sort hhid
merge 1:1 hhid using baseline_hf

// recode categorical variables as dichotomous 
// note --> missing coded as zero
replace dwater=1 if dwater==2|dwater==3|dwater==4
replace dwater=0 if dwater>4

g flush=.
replace flush=1 if toilet==2|toilet==3|toilet==4
replace flush=0 if toilet==1|toilet==5|toilet==6|toilet==7|toilet==8|toilet==9|toilet==.

replace sh_toilet=0 if sh_toilet==1|sh_toilet==8|sh_toilet==.
replace sh_toilet=1 if sh_toilet==2

replace refuse=1 if refuse==2|refuse==3|refuse==4
replace refuse=0 if refuse>4

replace lwaste=0 if lwaste>2

// recode to zero if missing or no asset
foreach var of varlist radio tv computer clock mobile fridge vdeck freezer dvd bike motobike car {
	replace `var'=0 if `var'==8|`var'==2|`var'==.
	}
	
// pca command to generate index
pca flush sh_toilet radio tv computer clock mobile fridge vdeck freezer dvd motobike car drawnch
predict index1

// create 5 categories, and 3 categories using only the first PC
xtile q_wealth=index1, nq(5)
label define wealth 1 "Poorest" 2 "Poor" 3 "Better" 4 "Less poor" 5 "Least poor"
label values q_wealth wealth

sort hhid
keep formid hhid near_HF q_wealth treatment deacode
save baseline_hh, replace
