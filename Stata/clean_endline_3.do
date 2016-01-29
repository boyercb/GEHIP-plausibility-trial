// clean_endline_3.do
// project: GEHIP Endline analysis
// author: Christopher Boyer
// date: 16 Aug 2015
// description:
//   clean and create pregnancy history data set

cd "${data}/clean"

* use data arranged by pregnancy; drop current pregnancies, lost pregnancies, 
* stillbirths, women with no children, and women from KNE or KNW
use endline_clean, clear
drop if currpreg==1
drop if outcome==3
drop if district==4|district==5
drop if havechildren==0
drop if outcome==2 & signoflife==2

sort hhid
merge m:1 hhid using endline_hh
drop if _merge == 2
drop _merge
sort hhid
merge m:1 hhid using eacodes
drop if _merge == 2
drop _merge
sort hhid
merge m:1 hhid using endline_hf
drop if _merge == 2

// drop 1 observation with erroneous enumeration code and fix
// miscoding of another
drop if deacode == "BN785"
replace deacode = "GT727" if deacode == "GT779"



* ========== section 2: DD variables ============= *

* generate treatment variable
drop treatment
g treatment=.
replace treatment=1 if district==2|district==3|district==6
replace treatment=0 if treatment!=1
*label define ltreatment 0 "control" 1 "intervention"
label values treatment ltreatment

// define survey variable
g endline = 1

label define lendline 0 "baseline" 1 "endline"
label values endline lendline

// define time variable
g period = 0
replace period = 1 if cmc > 1330


label define lperiod 0 "pre" 1 "post"
label values period lperiod
* ========== section 3: panel and outcome variables ============= *

replace deathdate_year = 2007 if childid=="uuid:9b9d9259-8c74-459d-98c5-c6b6ca004b40/womanID[1]/section2-repeat_preghist[2]"
ren cmc cmc_delivery
g mo_int = month(today)
g yr_int = year(today)
replace yr_int = 2015 if yr_int == 2012 & mo_int == 1
replace yr_int = 2014 if yr_int == 2012
g cmc_int = 12*(yr_int-1900) + mo_int

g cmc_death=.
replace cmc_death = 12*(deathdate_year-1900) + deathdate_mo if deathdate_mo !=. | deathdate_year !=.
replace cmc_death = cmc_delivery if outcome==2 & signoflife==1
replace cmc_death = cmc_delivery + deathage_mo if (cmc_death < cmc_delivery) & (cmc_delivery - cmc_death < 12) & !mi(cmc_delivery)

g switch = cmc_delivery if childid == "uuid:8fc40627-fbad-4654-8585-bd8910e37c0e/womanID[1]/section2-repeat_preghist[3]"
replace cmc_delivery = cmc_death if childid == "uuid:8fc40627-fbad-4654-8585-bd8910e37c0e/womanID[1]/section2-repeat_preghist[3]"
replace cmc_death = switch if childid == "uuid:8fc40627-fbad-4654-8585-bd8910e37c0e/womanID[1]/section2-repeat_preghist[3]"
drop switch

g pmonths_death=.
replace pmonths_death= cmc_death - cmc_delivery if cmc_death !=.
replace pmonths_death=0.5 if pmonths==0

**create outcome indicator variables for under5, infant, and neonatal deaths
gen under5 = 0
replace under5 = 1 if cmc_death != . & pmonths_death < 60
gen infant = 0
replace infant = 1 if cmc_death != . & pmonths_death <= 12
gen neonate = 0
replace neonate = 1 if cmc_death != . & pmonths_death <= 1

* create censoring variables
g pmonths_under5=59
replace pmonths_under5 = pmonths_death if under5==1
replace pmonths_under5 = cmc_int - cmc_delivery if cmc_int - cmc_delivery <=59 & !under5

g pmonths_infant=12
replace pmonths_infant = pmonths_death if infant==1
replace pmonths_infant = cmc_int - cmc_delivery if cmc_int - cmc_delivery <=12 & !infant

g pmonths_neonate=1
replace pmonths_neonate = pmonths_death if neonate==1
replace pmonths_neonate = cmc_int - cmc_delivery if cmc_int - cmc_delivery <=1 & !neonate

* create entrance and exit variables
g enter = cmc_delivery
g exit_under5 = cmc_delivery + pmonths_under5
g exit_infant = cmc_delivery + pmonths_infant
g exit_neonate = cmc_delivery + pmonths_neonate

replace pmonths_under5 = 59 if pmonths_under5 >= 60


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


* ==== 4. women's age  ==== *
** generate scratch variable
ren birthyear dob_year
ren birthmonth dob_month
destring dob_month, replace
replace dob_month = 6 if dob_month == .
g mdob_cmc = 12*(dob_year-1900) + dob_month
g m_age =(cmc_delivery - mdob_cmc)/12
drop if m_age < 15
replace m_age = round(m_age)

egen cm_age = cut(m_age), at(14, 19.5, 34.5, 50) icodes

label define lage 0 "15-20" 1 "20-34" 2 "35-49"
label values cm_age lage

replace marital_status = 0 if m_age < agemarr

* ====  5. parity  ==== *
** generate scratch variable
egen parity=rank(m_age), by(womanid)
replace parity = parity - 1
g cparity=.
replace cparity=0 if parity < 1
replace cparity=1 if parity >= 1 & parity < 2
replace cparity=2 if parity >=2 & parity < 5
replace cparity=3 if parity >= 5 & parity != .

** label
label define lparity2 0 "nulliparous" 1 "primipara" 2 "multipara" 3 "grand multipara"
label values cparity lparity2

* ==== 6. rural vs. urban  ==== *
g urb = .
replace urb = 1 if rururb == 1 | rururb == 2
replace urb = 0 if rururb == 3
label define lurb 0 "rural" 1 "urban" 
label values urb lurb

* ==== 7. multiple birth ==== *
replace multiple = 0 if multiple == 1
replace multiple = 1 if multiple == 3 | multiple == 2

** label
label define lmultiple 0 "singleton" 1 "multiple" 
label values multiple lmultiple

* ==== 8. birth spacing ==== *
sort womanid parity
gen space = cmc_delivery - cmc_delivery[_n - 1]
replace space = 99 if parity == 0

g bspace = 0
replace bspace = 1 if space < 24
label define lbspace 0 "space >= 24 months" 1 "space < 24 months" 
label values bspace lbspace

drop if cmc_delivery < 1260

g died = under5
g pmonths = pmonths_under5
g secular = deliverydate_year
drop if secular >= 2015
g time = cmc_delivery - 12*(2005-1900)

duplicates tag womanid cmc_delivery, generate(multiple2)
replace multiple = 1 if multiple2 > 0
replace multiple = 0 if multiple2 == 0

g cduration = 0
replace cduration = 1 if duration < 9

label define lcduration 0 "9 months" 1 "< 9 months" 
label values cduration lcduration

replace pmonths = 1 if pmonths == 0.5 | pmonths == 0
drop if secular > 2015

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

save endline_preg, replace
