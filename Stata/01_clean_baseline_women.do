// clean_baseline_1.do
// =================
// project: GEHIP Plausibility Trial
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   the purpose of this do-file is to clean and standardize baseline data,
//   including:  - to define global treatment and survey variables (***)
//               - to create female respondent level data set      (***)
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
#delimit ;
keep womanid 
     cmodern 
	 cmethod 
	 age 
	 cage 
	 parity 
	 cparity 
	 district 
	 treatment 
	 endline 
	 education 
	 religion 
	 marital_status 
	 antimalarial 
	 vitAsup 
	 childnet 
	 ors 
	 dpt3yes 
	 measlesyes 
	 anccheck 
	 anc4plus 
	 pregmalaria 
	 skilled_del 
	 csec 
	 deacode 
	 urb;
#delimit cr
save baseline_women, replace



