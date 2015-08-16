// clean_baseline.do
// project: GEHIP Endline analysis
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

// define treatment variable
g treatment = 0
replace treatment = 1 if district in ("BONGO", "BUILSA", "GARU-TIMPANI")

label define ltreatment 0 "control" 1 "intervention"
label variable
label values treatment ltreatment

// define survey variable
g endline = 0

label define lendline 0 "baseline" 1 "endline"
label values endline lendline

// ===== Female respondent data set ===== //

// variable renames
//   old name    new name
ren  n102year    dob_year
ren  n102month   dob_month
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
ren  wlthind5    wealth
ren  typelocati  rururb

// core and common

// clean and create household data set

// clean and create pregnancy history data set
