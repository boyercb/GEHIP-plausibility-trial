// clean_endline.do
// project: GEHIP Endline analysis
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//     clean and standardize variables in endline data sets

// read baseline data set
cd "${data}/raw"
use endline_raw, replace

// define treatment variable
g treatment = 0
replace treatment = 1 if district in (2, 3, 6)

label define ltreatment 0 "control" 1 "intervention"
label variable treatment "dummy for whether observation is in treatment group"
label values treatment ltreatment

// define survey variable
g endline = 1

label define lendline 0 "baseline" 1 "endline"
label variable endline "dummy for whether observation is from endline survey"
label values endline lendline

// ===== Female respondent data set ===== //

// 8. modern conctraception
// edit check of current family planning method to yesno
replace fpcheck = . if fpcheck >= 3
replace fpcheck = 0 if fpcheck == 2

// generate indicator for current use of modern contraceptive method (cmethod)
g cmodern=.
replace cmodern = 0 if fpcheck == 0
replace cmodern = 1 if cmethod < 11
replace cmodern = 1 if cmethod == 14
replace cmethod = 0 if (cmethod > 10 & cmethod != .) | (cmethod1 > 10 & cmethod1 != . ) // check this

label variable cmodern "Use modern contraceptive method"
label define lmodern 0 "no" 1 "yes"
label values cmodern lmodern

* core indicator 10: measles vaccine *
g measles2=.
replace measles2=1 if measlesyes==1
replace measles2=0 if measlesyes==2
drop measlesyes
g measlesyes = measles2

* core indicator 11: DPT3 vaccine *
g dpt3=.
replace dpt3=1 if dpt3yes==1
replace dpt3=0 if dpt3yes==2
drop dpt3yes
g dpt3yes = dpt3

* core indicator 12: antimalarial treatment *

replace prescribed1="88" if prescribed1=="other"
replace prescribed2="88" if prescribed2=="other"
replace prescribed3="88" if prescribed3=="other"

destring prescribed1, replace
destring prescribed2, replace
destring prescribed3, replace

* core indicator 14: ORS *
g ors2=.
replace ors2=1 if ors==1
replace ors2=0 if ors==2
replace ors2=0 if diarrhoea==1 & ors==.
drop ors
g ors = ors2

g antimalarial=(prescribed1<7|prescribed2<7|prescribed3<7|prescribed4<7|prescribed5<7)
replace antimalarial=. if malaria!=1

* core indicator 15: vitamin A supplementation *
g vitAsup = (vita1yes == 1 & vita2yes == 1)

* core indicator 16: ITN use *
g childnet2=.
replace childnet2=1 if childnet==1
replace childnet2=0 if childnet==2
replace childnet2=. if childnet==3
drop childnet
g childnet = childnet2

* ========== section 4: socio-demographic indicators ============= *

* ==== 1. women's education ==== *
** generate scratch variable
g s_education=.
replace s_education=1 if edu!=1 & edu!=.
replace s_education=0 if edu==1

** replace and drop
drop edu
g education = s_education
drop s_education

** label
label define ledu 0 "no education" 1 "some education"
label values education ledu


* ====  2. religion  ==== *
** generate scratch variable
g s_religion=.
replace s_religion=0 if religion==2
replace s_religion=1 if religion==1
replace s_religion=2 if religion==3
replace s_religion=3 if religion==4 | religion==5

** replace and drop
drop religion
g religion = s_religion
drop s_religion

** label
label define lreligion 0 "traditional" 1 "christianity" 2 "islam" 3 "other/none"
label values religion lreligion

* ==== 3. marital status ==== *
** generate scratch variable
g s_marital=.
replace s_marital=0 if evermarr==2 | inrange(currmarrstat, 2, 5)
replace s_marital=1 if currmarrstat==1 & otherwives == 1
replace s_marital=2 if currmarrstat==1 & otherwives == 2
tab s_marital

** replace and drop
drop currmarrstat
g marital_status = s_marital
drop s_marital

** label
label define lmarital 0 "unmarried" 1 "other wives" 2 "monogamous"
label values marital_status lmarital

* ====  4. parity  ==== *
** generate scratch variable
ren numbirths parity
g cparity=.
replace cparity=0 if parity == 0
replace cparity=1 if parity == 1
replace cparity=2 if parity >= 2 & parity < 5
replace cparity=3 if parity >=5

** label
label define lparity 0 "nulliparous" 1 "primipara" 2 "multipara" 3 "grand multipara"
label values cparity lparity

* ==== 5. women's age  ==== *
** generate scratch variable
ren birthyear dob_year
ren birthmonth dob_month
ren submissiondate survey_date

destring dob_month, replace

g survey_month = month(survey_date)
g survey_year = year(survey_date)

replace survey_month = 12 if survey_month==.
replace survey_year = 2014 if survey_year==.
g age =(survey_year+survey_month/12) - (dob_year+dob_month/12)

g cage=.
replace cage=0 if age >= 15 & age < 20
replace cage=1 if age >= 20 & age < 25
replace cage=2 if age >= 25 & age < 30
replace cage=3 if age >= 30 & age < 35
replace cage=4 if age >= 35 & age < 40
replace cage=5 if age >= 40 & age < 45
replace cage=6 if age >= 45 & age < 50

** label
label define lage 0 "15-19" 1 "20-24" 2 "25-29" 3 "30-34" 4 "35-39" 5 "40-44" 6 "45-49"
label values cage lage

* ==== 6. rural vs. urban  ==== *
g urb = .
replace urb = 1 if rururb == 1 | rururb == 2
replace urb = 0 if rururb == 3
label define lurb 0 "rural" 1 "urban"
label values urb lurb

* facility delivery *
*g hospital_del = 0
*replace hospital_del=1 if delplace==3

keep womanid cmodern cmethod age cage parity cparity district SERC treatment time education religion marital_status wealth antimalarial vitAsup childnet ors dpt3yes measlesyes anccheck anc4plus pregmalaria skilled_del csec eacode deacode urb near_HF near_Hosp
cd "${data}/clean"
save endline_women, replace

// clean and create household data set
save endline_hh, replace

