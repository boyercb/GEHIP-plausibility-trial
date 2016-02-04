/*-------------------------------*
 |file:    chps_scaleup.do       |
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

cd "${data}/clean"
use person_period.dta, replace

cd "${tables}/unformatted/"

lincom _cons
local e00 = r(estimate)
local se00 = r(se)
lincom _cons + 1.treatment
local e10 = r(estimate)
local se10 = r(se)
lincom _cons + 1.period
local e01 = r(estimate)
local se01 = r(se)
lincom _cons + 1.treatment#1.period
local e11 = r(estimate)
local se11 = r(se)

outreg2 using myfile, excel replace addstat("Pre Control", `e00',"se" ,`se00', "Pre Tx", `e10',"se" ,`se10',  "Post Control", `e01',"se" ,`se01', "Post Tx", `e11',"se",`se11')


