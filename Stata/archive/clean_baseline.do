// clean_baseline.do
// =================
// project: GEHIP Plausibility Trial
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   the purpose of this do-file is to clean and standardize baseline data,
//   including:  - to define global treatment and survey variables
//               - to create female respondent level data set
//               - to create household level data set
//               - to create pregnancy history data set


// read baseline data set
cd "${data}/raw"
use baseline_raw, clear

// variable renames
//   old name    new name
ren  n102year    dob_yr
ren  n102month   dob_mo
ren  n103ishigh  education
ren  n106isyour  ethnicity
ren  n107isyour  religion
ren  n110isyour  marital_status
ren  n113doesyo  other_wife
ren  n212total   parity
ren  n404youse1  anccheck
ren  n411times1  pinkbookancvisits
ren  n417durin1  pregmalaria
ren  n501yougiv  delplace
ren  n506doctor  homeassistwho1
ren  n506midwif  homeassistwho2
ren  n506nurse   homeassistwho3
ren  n506ch      homeassistwho4
ren  n506office  homeassistwho5
ren  n506health  homeassistwho6
ren  n506traine  homeassistwho7
ren  n506chv     homeassistwho8
ren  n506untrai  homeassistwho9
ren  n506relati  homeassistwho10
ren  n506nobody  homeassistwho11
ren  n506others  homeassistwho12
ren  n511wasnam  csec
ren  n706isther  im_card
ren  n707vitami  vita1yes
ren  n707vitam1  vita2yes
ren  n707dpt3    dpt3yes
ren  n707measle  measlesyes
ren  n1001hasna  diarrhoea
ren  n1002aflui  orsask
ren  n1101inlas  malaria
ren  n1124aslee  itn
ren  finalvisit  survey_date
ren  formid      womanid
ren  typelocati  rururb
ren  n301youory  fpcheck
ren  n302whichm  cmethod
ren  n116howold  agemarr
ren  n131ismain  dwater
ren  n132kindto  toilet 
ren  n133doyous  sh_toilet
ren  n134howdoe  refuse
ren  n135howdoe  lwaste
ren  n136radio   radio
ren  n136televi  tv
ren  n136comput  computer
ren  n136clock   clock
ren  n136mobile  mobile
ren  n136refrig  fridge
ren  n136videod  vdeck
ren  n136freeze  freezer
ren  n136dvdvcd  dvd
ren  n136bicycl  bike
ren  n136motorc  motobike
ren  n136animal  drawnch
ren  n136carort  car

// rename pregnancy history variables
#delimit ;
for num 1/11:  

/* old names */
 ren (nXp1        
      nXp2a     
	  nXp2bm
	  nXp2by
	  nXp3
	  nXp4
	  nXp6
	  nXp7m 
	  nXp7y 
	  nXp8 
	  nXp9d
	  nXp9m
	  nXp9y
	  nXp10m
	  nXp10y
	  nXp11m
	  nXp11y)

/* new names */
	 (multipleX
	  durationX
      deliverydate_moX 
      deliverydate_yrX 
      statusX          
      cryX             
      sexX             
      age_moX          
      age_yrX          
      withmumX         
      deathage_dayX    
      deathage_moX     
      deathage_yrX     
      deathdate_moX    
      deathdate_yrX    
      lossdate_moX     
      lossdate_yrX);
#delimit cr
g compcode2 = string(real(compcode), "%03.0f")
g householdn2 = string(real(householdn), "%02.0f")

         /////////////////////////////////////////////////////////////
//=======////////////////////////// Part 1. //////////////////////////========//
         /////////////////////////////////////////////////////////////

// women data set

// define household id
g hhid=district1+"_"+eacode+"_"+compcode2+"_"+householdn2

// define treatment variable
g treatment = 0
replace treatment = 1 if inlist(district, "BONGO", "BUILSA", "GARU-TIMPANI")

label define ltreatment 0 "control" 1 "intervention"
label values treatment ltreatment

// define survey variable
g endline = 0

label define lendline 0 "baseline" 1 "endline"
label values endline lendline


// core and common indicators
// 4. ANC attendance (any)
recode anccheck (1 = 1) (2 = 0) (8 = .n)

label define lanccheck 0 "no visits" 1 ">= 1 visit"
label values anccheck lanccheck

// 4. ANC attendance (4+)
// true if pink book records 4 or more visits and not missing
g anc4plus = (pinkbookancvisits >= 4 & pinkbookancvisits != 88)
replace anc4plus = . if pinkbookancvisits == .

label define lanc4plus 0 "< 4 visits" 1 ">= 4 visits"
label values anc4plus lanc4plus

// 5. IPTp
recode pregmalaria (1 = 1) (2 = 0) (8 = .n) (9 = .d)

label define lpregmalaria 0 "no" 1 "yes"
label values pregmalaria lpregmalaria

// 6. skilled delivery
// true if assisted by doctor, nurse, or midwife (homeassistwho1-3) and
// in a health facility (delplace cat 3-8)
g skilled_del=.n
replace skilled_del = 1 if inlist(1, homeassistwho1, homeassistwho2, homeassistwho3)
replace skilled_del = 0 if inlist(1, homeassistwho4, homeassistwho5, homeassistwho6, ///
                                     homeassistwho7, homeassistwho8, homeassistwho9, ///
                                     homeassistwho10, homeassistwho11)
replace skilled_del = 0 if inlist(delplace, 1, 2, 9, 99)

label define lskill 0 "no" 1 "yes"
label values skilled_del lskill

// 7. c-sections
recode csec (1 = 1) (2 = 0) (8 = .n) (9 = .d)

label define lcsec 0 "no" 1 "yes"
label values csec lcsec 

// 8. modern conctraception
// edit check of current family planning method to yesno
replace fpcheck = . if fpcheck >= 3
replace fpcheck = 0 if fpcheck == 2

// generate indicator for current use of modern contraceptive method (cmethod)
g cmodern=.
replace cmodern = 0 if fpcheck == 0
replace cmodern = 1 if cmethod < 11
replace cmodern = 1 if cmethod == 14
replace cmethod = 0 if (cmethod > 10 & cmethod != .)

label define lmodern 0 "no" 1 "yes"
label values cmodern lmodern

// replace 0s with NAs
replace cmethod=. if cmethod==0 //what?

// 10. measles vaccine
g measles2 = .
replace measles2 = 1 if measlesyes != .
replace measles2 = 0 if measlesyes == . & im_card == 1
drop measlesyes
g measlesyes = measles2

label define lmeasles 0 "no" 1 "yes"
label values measlesyes lmeasles

// 11. DPT3 vaccine
g dpt3=.
replace dpt3=1 if dpt3yes!=.
replace dpt3=0 if dpt3yes==. & im_card==1
drop dpt3yes
g dpt3yes = dpt3

label define ldpt3 0 "no" 1 "yes"
label values dpt3yes ldpt3

// 12. antimalarial treatment
g antimalarial = inlist(1, n1104spfan, n1104chlor, n1104amodi, n1104quini, ///
                           n1104artem, n1104parac, n1104aspir, n1104ibupr, ///
						   n1107spfan, n1107chlor, n1107amodi, n1107quini, ///
						   n1107artem, n1107parac, n1107aspir, n1107ibupr)
replace antimalarial = . if malaria != 1

label define lanti 0 "no" 1 "yes"
label values antimalarial lanti

// 14. ORS treatment for diarrhoea
g ors=.
replace ors=1 if orsask==1
replace ors=0 if orsask==2
replace ors=0 if diarrhoea==1 & orsask==.

label define lors 0 "no" 1 "yes"
label values ors lors

// 15. vitamin A supplementation
g vitAsup = (vita1yes !=. & vita2yes !=. )

label define lvitA 0 "no" 1 "yes"
label values vitAsup lvitA

// 16. itn use
g childnet=.
replace childnet=1 if itn==1
replace childnet=0 if itn==2
replace childnet=. if itn>=3

label define lnet 0 "no" 1 "yes"
label values childnet lnet

// socio-economic variables
// 1. women's education
// generate scratch variable
g s_education=.
replace s_education=1 if education!=1 & education!=.
replace s_education=0 if education==1

// replace and drop
drop education
g education = s_education
drop s_education

// label
label define ledu 0 "no education" 1 "some education"
label values education ledu

// 2. religion
// generate scratch variable
g s_religion=.
replace s_religion=0 if religion==2
replace s_religion=1 if religion==1
replace s_religion=2 if religion==3
replace s_religion=3 if religion==4 | religion==5

// replace and drop
drop religion
g religion = s_religion
drop s_religion

// label
label define lreligion 0 "traditional" 1 "christianity" 2 "islam" 3 "other/none"
label values religion lreligion

// 3. marital status
// generate scratch variable
g s_marital=.
replace s_marital=0 if marital_status==1 | inrange(marital_status, 3, 6)
replace s_marital=1 if marital_status==2 & other_wife == 1
replace s_marital=2 if marital_status==2 & other_wife == 2

// replace and drop
drop marital_status
g marital_status = s_marital
drop s_marital

// label
label define lmarital 0 "unmarried" 1 "other wives" 2 "monogamous"
label values marital_status lmarital

// 4. parity
// generate scratch variable
g cparity=.
replace cparity=0 if parity == 0
replace cparity=1 if parity == 1
replace cparity=2 if parity >= 2 & parity < 5
replace cparity=3 if parity >=5

// label
label define lparity 0 "nulliparous" 1 "primipara" 2 "multipara" 3 "grand multipara"
label values cparity lparity

// 5. women's age
// generate scratch variable
destring dob_yr, replace
replace dob_mo = proper(dob_mo)
g dob_mo2 = month(date(dob_mo, "M"))
g survey_month = month(survey_date)
g survey_year = year(survey_date)
replace survey_month = 6 if survey_month == .
replace survey_year = 2011 if survey_year == .
g age =(survey_year+survey_month/12) - (dob_yr+dob_mo2/12)
replace age = (survey_year+survey_month/12) - (dob_yr) if dob_mo2 == .

g cage=.
replace cage = 0 if age >= 15 & age < 20
replace cage = 1 if age >= 20 & age < 25
replace cage = 2 if age >= 25 & age < 30
replace cage = 3 if age >= 30 & age < 35
replace cage = 4 if age >= 35 & age < 40
replace cage = 5 if age >= 40 & age < 45
replace cage = 6 if age >= 45 & age < 50

// label
label define lage 0 "15-19" 1 "20-24" 2 "25-29" 3 "30-34" 4 "35-39" 5 "40-44" 6 "45-49"
label values cage lage

// 6. rural vs. urban setting
g urb = .
replace urb = 1 if rururb == 1 | rururb == 2
replace urb = 0 if rururb == 3
label define lurb 0 "rural" 1 "urban"
label values urb lurb

// 7. district variable recode
g s_district = .
replace s_district = 1 if district == "BOLGATANGA"
replace s_district = 2 if district == "BONGO"
replace s_district = 3 if district == "BUILSA"
replace s_district = 6 if district == "GARU-TIMPANI"
replace s_district = 7 if district == "BAWKU WEST"
replace s_district = 8 if district == "TALENSI-NABDAM"
replace s_district = 9 if district == "BAWKU EAST"
drop district

g district = s_district
label define ldistrict 1 "Bolgatanga"           ///
                       2 "Bongo"                ///
                       3 "Builsa"               ///
                       4 "Kassena-Nankana East" ///
                       5 "Kassena-Nankana West" ///
                       6 "Garu Tempane"         ///
                       7 "Bawku West"           ///
                       8 "Talensi Nabdam"       ///
                       9 "Bawku East"
					   
label values district ldistrict

g deacode = eacode1

// add variable labels 
label variable womanid        "unique identifier for female respondent"
label variable hhid           "unique identifier for household"
label variable marital_status "what is your current marital status?"
label variable education      "did you receive any formal schooling?"
label variable religion       "what is your current religion?"
label variable parity         "how many pregnancies have you had in your lifetime?"
label variable cparity        "how many pregnancies have you had in your lifetime (cat)?"
label variable age            "what is your current age?"
label variable cage           "what is your current age (cat)?"
label variable anccheck       "attended at least one ANC appointment at last pregnancy"
label variable anc4plus       "attended at least four ANC appointments at last pregnancy"
label variable pregmalaria    "received IPTp during most recent pregnancy"
label variable skilled_del    "most recent pregnancy delivered in a facility with skilled provider?"
label variable csec           "most recent pregnancy delivered via c-section?"
label variable cmethod        "which method of contraception are you currently using?"
label variable cmodern        "use modern contraceptive method"
label variable measlesyes     "most recent child received measles vaccination?"
label variable dpt3yes        "most recent child received DPT3 vaccination?"
label variable antimalarial   "in last 2 weeks, was child treated with antimalarial if they were sick with malaria?"
label variable ors            "in last 2 weeks, was child treated with ORS if they were sick with diarrhea?"
label variable vitAsup        "was child given vitamin A supplements?"
label variable childnet       "did child sleep under ITN last night?"
label variable urb            "urban vs. rural residence"
label variable district       "administrative district of residence"
label variable deacode        "enumeration area code (cluster)"
label variable endline        "dummy for whether observation is from endline survey"
label variable treatment      "dummy for whether observation is in treatment group"


cd "${data}/clean"
save baseline_clean, replace
keep womanid cmodern cmethod age cage parity cparity district treatment endline education religion marital_status antimalarial vitAsup childnet ors dpt3yes measlesyes anccheck anc4plus pregmalaria skilled_del csec deacode urb
save baseline_women, replace

         /////////////////////////////////////////////////////////////
//=======////////////////////////// Part 2. //////////////////////////========//
         /////////////////////////////////////////////////////////////

// household data set

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
foreach var of varlist radio tv computer clock mobile fridge vdeck freezer dvd bike motobike drawnch car {
	replace `var'=0 if `var'==8|`var'==2|`var'==.
	}
	
// pca command to generate index
polychoricpca dwater flush radio tv computer clock mobile fridge vdeck freezer dvd bike motobike drawnch car, nscore(1) score(index)


// create 5 categories, and 3 categories using only the first PC
xtile q_wealth=index1, nq(5)
label define wealth 1 "Poorest" 2 "Poor" 3 "Better" 4 "Less poor" 5 "Least poor" 
label values q_wealth wealth

sort hhid
keep formid hhid near_HF q_wealth
save baseline_hh, replace

         /////////////////////////////////////////////////////////////
//=======////////////////////////// Part 3. //////////////////////////========//
         /////////////////////////////////////////////////////////////

// pregnancy history data set


use baseline_clean, replace

sort hhid
merge m:1 hhid using baseline_hh
drop if _merge != 3
keep womanid hhid multiple* duration* deliverydate* status* cry* sex* age_mo* age_yr* withmum* deathage* deathdate* lossdate* dob_mo dob_yr survey_date education religion marital_status agemarr q_wealth near_HF treatment endline urb district deacode 

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

g childid = womanid + string(order, "%02.0f")

// drop empty birth observations
dropmiss multiple deliverydate_mo deliverydate_yr status, obs force
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
drop if deliverydate_yr < 2005 | deliverydate_yr > 2009 | mi(deliverydate_yr)

replace deliverydate_mo = .d if deliverydate_mo >= 17

// 3. deaths - generate variable to capture deaths (any non missing death info) and triangulate dates
g died = inlist(1, !mi(deathage_day), !mi(deathage_mo), !mi(deathage_yr), ///
                   !mi(deathdate_mo), !mi(deathdate_yr), !mi(lossdate_mo), ///
				   !mi(lossdate_yr))

replace deathdate_yr = deathdate_yr + 2000
replace deathdate_yr = deliverydate_yr + deathage_yr if mi(deathdate_yr) & !mi(deathage_yr) & deathage_yr + deliverydate_yr < 2011
replace deathdate_yr = deliverydate_yr if mi(deathdate_yr) & !mi(deathage_day)
replace deathdate_yr = deliverydate_yr if mi(deathdate_yr) & !mi(deathage_mo)
replace deathdate_yr = deliverydate_yr + deathage_yr if (deathdate_yr > 2011 | deathdate_yr < 2005) & !mi(deathage_yr)
replace deathdate_yr = lossdate_yr + 2000 if !mi(lossdate_yr)

replace deathdate_mo = lossdate_mo if !mi(lossdate_mo)
replace deathdate_mo = .d if deathdate_mo >= 17

drop if deathdate_yr > 2010 & !mi(deathdate_yr)

// 4. cmc dates
g cmc_death=.
replace cmc_death = 12*(deathdate_yr-1900) + deathdate_mo if deathdate_mo !=. & deathdate_yr !=.
replace cmc_death = 12*(deliverydate_yr-1900) + deliverydate_mo + deathage_mo if mi(deathdate_mo) & !mi(deathage_mo)
replace cmc_death = 12*(deliverydate_yr-1900) + deliverydate_mo if mi(deathdate_mo) & !mi(deathage_day)
replace cmc_death = 12*(deathdate_yr-1900) + 6 if died & mi(deathdate_mo) & mi(cmc_death)

g cmc_delivery = 12*(deliverydate_yr-1900) + deliverydate_mo if !mi(deliverydate_mo) & !mi(deliverydate_yr)
replace cmc_delivery = 12*(deliverydate_yr-1900) + 6 if mi(deliverydate_mo)

g pmonths = cmc_death - cmc_delivery
replace pmonths = 1321 - cmc_delivery if !died | deathdate_yr > 2010
replace pmonths = 1321 - cmc_delivery + deathage_mo if pmonths < 0
replace pmonths = 59 if pmonths >= 60

// 5. age
replace dob_mo = "" if dob_mo == "Dk"

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

replace marital_status = 0 if m_age < agemarr

replace multiple = 0 if multiple == 1
replace multiple = 1 if multiple == 3 | multiple == 2

** label
label define lmultiple 0 "singleton" 1 "multiple" 
label values multiple lmultiple

g secular = deliverydate_yr
// output
keep childid womanid hhid sex multiple withmum m_age parity education religion marital_status q_wealth near_HF secular cmc_delivery treatment endline urb district deacode died pmonths
save baseline_preg, replace
