// clean_baseline_3.do
// =================
// project: GEHIP Plausibility Trial
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   the purpose of this do-file is to clean and standardize baseline data,
//   including:  - to define global treatment and survey variables
//               - to create female respondent level data set
//               - to create household level data set
//               - to create pregnancy history data set (***)


// read baseline data set
// pregnancy history data set
cd "${data}/clean"

use baseline_clean, replace

sort hhid
merge m:1 hhid using baseline_hh
drop if _merge != 3
keep womanid hhid multiple* duration* deliverydate* status* cry* sex* age_mo* age_yr* withmum* deathage* deathdate* lossdate* dob_mo dob_yr survey_date education religion marital_status agemarr q_wealth near_HF treatment endline urb district deacode 

// define time variable
g period = 0

label define lperiod 0 "pre" 1 "post"
label values period lperiod

// reshape to long format (observations correspond to individual births)
#delimit ;
reshape long multiple
             duration
             deliverydate_mo 
             deliverydate_yr 
             status         
             cry          
             sex             
             age_mo         
             age_yr         
             withmum         
             deathage_day    
             deathage_mo     
             deathage_yr     
             deathdate_mo    
             deathdate_yr    
             lossdate_mo     
             lossdate_yr, i(womanid) j(order);
#delimit cr

// generate birth id variable 
g childid = womanid + string(order, "%02.0f")

// drop empty birth observations
dropmiss multiple deliverydate_mo deliverydate_yr status, obs force

// generate variable representing parity of woman at time of birth
egen parity=rank(-order), by(womanid)
replace parity = parity - 1

// logic checks
// 1. birth status - recode to born alive if cried and limit data set to live births
replace status = 1 if cry == 1
drop if status != 1

// 2. year of birth - recode incorrect inputs (i.e. 99 = 1999) and limit data to births after Jan 1 2000
replace deliverydate_yr = deliverydate_yr + 2000 if deliverydate_yr < 10 & deliverydate_yr >= 0
replace deliverydate_yr = deliverydate_yr + 1900 if deliverydate_yr <= 99 & deliverydate_yr > 50
replace deliverydate_yr = deliverydate_yr + 1000 if deliverydate_yr > 900 & deliverydate_yr < 1000
replace deliverydate_yr = . if deliverydate_yr > 2011
replace deliverydate_yr = year(survey_date) - age_yr if mi(deliverydate_yr) & !mi(age_yr) & status == 1 & age_yr != 99
replace deliverydate_yr = deathdate_yr if mi(deliverydate_yr) & !mi(deathdate_yr) & (!mi(deathage_mo) | !mi(deathage_day))
replace deliverydate_yr = deathdate_yr - deathage_yr if mi(deliverydate_yr) & !mi(deathdate_yr) & !mi(deathage_day)

replace deliverydate_mo = .d if deliverydate_mo >= 17

g switch = deliverydate_mo if inlist(childid, "GT07033204", "GT09044202", "TN02007401")
replace deliverydate_mo = deathdate_mo if inlist(childid, "GT07033204", "GT09044202", "TN02007401")
replace deathdate_mo = switch if inlist(childid, "GT07033204", "GT09044202", "TN02007401")

// 3. deaths - generate variable to capture deaths (any non missing death info) and triangulate dates
g died = inlist(1, !mi(deathage_day), !mi(deathage_mo), !mi(deathage_yr), ///
                   !mi(deathdate_mo), !mi(deathdate_yr), !mi(lossdate_mo), ///
				   !mi(lossdate_yr))
replace deathdate_yr = deathdate_yr + 2000
replace deathdate_yr = deliverydate_yr + deathage_yr if mi(deathdate_yr) & !mi(deathage_yr) & deathage_yr + deliverydate_yr < 2011
replace deathdate_yr = deliverydate_yr if mi(deathdate_yr) & !mi(deathage_day)
replace deathdate_yr = deliverydate_yr if mi(deathdate_yr) & !mi(deathage_mo)
replace deathdate_yr = deliverydate_yr + deathage_yr if (mi(deathdate_yr) & died) | deathdate_yr < deliverydate_yr
replace deathdate_yr = lossdate_yr + 2000 if !mi(lossdate_yr)

replace died = 0 if (deathage_yr >= 6 & !mi(deathage_yr)) 
replace died = 0 if (deathdate_yr - deliverydate_yr) >= 6 & !mi(deathdate_yr)
replace deathdate_mo = lossdate_mo if !mi(lossdate_mo) & childid !="BE15071603"
replace deathdate_mo = . if deathdate_mo >= 17


// 4. cmc dates
g cmc_delivery = 12*(deliverydate_yr-1900) + deliverydate_mo if !mi(deliverydate_mo) & !mi(deliverydate_yr)
replace cmc_delivery = 12*(deliverydate_yr-1900) + 6 if mi(deliverydate_mo) 
replace cmc_delivery = 12*(deliverydate_yr-1900) if (mi(deliverydate_mo) | deliverydate_mo == .b) & (deathdate_mo < 6)

g cmc_death=.
replace cmc_death = 12*(deathdate_yr-1900) + deathdate_mo if deathdate_mo !=. & deathdate_yr !=.
replace cmc_death = 12*(deliverydate_yr-1900) + deliverydate_mo + deathage_mo if mi(deathdate_mo) & !mi(deathage_mo)
replace cmc_death = 12*(deliverydate_yr-1900) + deliverydate_mo if mi(deathdate_mo) & !mi(deathage_day)
replace cmc_death = 12*(deathdate_yr-1900) + 6 if died & mi(deathdate_mo) & mi(cmc_death)

g pmonths = cmc_death - cmc_delivery
replace pmonths = 1333 - cmc_delivery if !died | deathdate_yr > 2010
replace pmonths = 1333 - cmc_delivery + deathage_mo if pmonths < 0
replace pmonths = 59 if pmonths >= 60 & !mi(pmonths)

// 5. maternal age at time of birth
replace dob_mo = "" if dob_mo == "Dk"

// define month codes
#delimit ;
label define months 1 "January"
                    2 "February"
					3 "March"
					4 "April"
					5 "May"
					6 "June"
					7 "July"
					8 "August"
					9 "September"
					10 "October"
					11 "November"
					12 "December";
#delimit cr

encode dob_mo, gen(dob_mo2) label(months)
replace dob_yr = .d if dob_yr == 9999

g m_age = deliverydate_yr - dob_yr
replace m_age = deliverydate_yr - dob_yr - 1 if (dob_mo2 > deliverydate_mo) & !mi(dob_mo2)
drop if m_age < 15
replace m_age = round(m_age)

// note --> change marital status to reflect status at time of birth
replace marital_status = 0 if m_age < agemarr

// 6. multiple or singleton birth indicator
replace multiple = 0 if multiple == 1
replace multiple = 1 if multiple == 3 | multiple == 2

// label
label define lmultiple 0 "singleton" 1 "multiple" 
label values multiple lmultiple

// 7. variable for tracking secular changes in mortality
g secular = deliverydate_yr
drop if secular >= 2015
g time = cmc_delivery - 12*(2005-1900)

// categorical parity variable and maternal age variables
g cparity=.
replace cparity=0 if parity < 1
replace cparity=1 if parity >= 1 & parity < 2
replace cparity=2 if parity >=2 & parity < 5
replace cparity=3 if parity >= 5 & parity != .

egen cm_age = cut(m_age), at(14, 19.5, 34.5, 50) icodes

label define lage2 0 "15-20" 1 "20-34" 2 "35-49"
label values cm_age lage2
label define lparity2 0 "nulliparous" 1 "primipara" 2 "multipara" 3 "grand multipara"
label values cparity lparity2

// 8. birth spacing 
sort womanid parity
gen space = cmc_delivery - cmc_delivery[_n - 1]
replace space = 99 if parity == 0

g bspace = 0
replace bspace = 1 if space < 24
label define lbspace 0 "space >= 24 months" 1 "space < 24 months" 
label values bspace lbspace


// drop 1 observation with erroneous enumeration code and fix
// miscoding of another
drop if deacode == "BN785"
replace deacode = "GT727" if deacode == "GT779"
drop if deliverydate_yr < 2000 | deliverydate_yr > 2010 | mi(deliverydate_yr)
drop if deathdate_yr > 2010 & !mi(deathdate_yr)

// standardize trea
replace pmonths = 0.5 if pmonths == 0

g cduration = 0
replace cduration = 1 if duration < 9

label define lcduration 0 "9 months" 1 "< 9 months" 
label values cduration lcduration

// define additional outcome variables
g under5 = died

g infant = 0
replace infant = 1 if died & pmonths < 12

g pmonths_infant = 12
replace pmonths_infant = pmonths if infant | (pmonths <= 12 & !infant)

g pmonths_child = pmonths - 12
replace pmonths_child = . if pmonths < 12

g child = 0
replace child = 1 if died & !infant

g neonate = 0
replace neonate = 1 if died & pmonths <= 1

duplicates tag womanid cmc_delivery, generate(multiple2)
replace multiple = 1 if multiple2 > 0
replace multiple = 0 if multiple2 == 0

replace pmonths = 1 if pmonths == 0.5 | pmonths == 0
drop if secular > 2010


// output
#delimit ;
keep childid 
     womanid 
	 hhid 
	 sex 
	 multiple 
	 withmum 
	 m_age 
	 cm_age 
	 parity 
	 cparity
	 bspace
	 cduration
	 education 
	 religion 
	 marital_status 
	 q_wealth 
	 near_HF 
	 secular 
	 time
	 cmc_delivery 
	 treatment 
	 endline 
	 period 
	 urb 
	 district 
	 deacode 
	 under5 
	 infant 
	 neonate 
	 pmonths 
	 pmonths_infant; 
#delimit cr

save baseline_preg, replace
