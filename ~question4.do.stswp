/*
 Author: Anya Marchenko
 Date: Spring 2024

 This .do file runs the code for Problem Set 1, Q4, Applied Metrics, Peter Hull  
 
*/

***********************************
* Load data  
***********************************	

clear all 

use "/Users/anyamarchenko/Documents/GitHub/applied_metrics_pset1/anderson.dta", clear

global figures "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/Apps/Overleaf/Applied Metrics - Pset 1/figures"


***********************************
* Load packages  
***********************************	

/*
ssc install drdid
ssc install csdid
ssc install did_imputation
ssc install reghdfe
*/


/***********************************
(a) Load the dataset and summarize the data. Is the panel balanced (i.e., complete
observations for each state-year combination)? Visualize the timing of primary belt laws. Are there any reversals of these laws? Are there "never-treated" states? How do the timing of primary and secondary belt laws relate to each other? 
***********************************/
sort state year

xtset state year
spbalance // data are strongly balanced

summarize
misstable summarize // no missings

* Count switchers
local vars "primary secondary"

foreach var in `vars' {
    by state: gen switch_`var' = `var'[_n] - `var'[_n-1]
    replace switch_`var' = 0 if missing(switch_`var')
    count if switch_`var' == -1 // 0 states switched primary, 11 secondary
}
ren switch_primary switch_p
ren switch_secondary switch_s

* Year first treated
local prefixes "p s"

foreach pre in `prefixes' {
	gen year_`pre' = year if switch_`pre' == 1
    by state: egen first_treat_`pre' = max(year_`pre')
    drop year_`pre'
	sum first_treat_`pre'
	di "The average year primary/secondary law enacted was " `r(mean)'
	// 1993 for primary
	// 1989 for secondary
}

* Never treated wrt primary 
gen never_treated = missing(first_treat_p)
tab state if never_treated == 1 // 30 states never treated


* Years between primary and secondary laws
by state: gen diff_timing = first_treat_p - first_treat_s



****** Figures

hist diff_timing, title("Timing difference between primary and secondary laws") xtick(0(1)18) xtitle("Difference in years (primary - secondary)") 

graph export "$figures/timing_diff.png", replace 	


* Visualize when states first enact laws
xtline primary, i(state) t(year) overlay xtitle("Year") title("States enacting primary seat belt laws") xtick(1980(1)2005)

graph export "$figures/timing_primary.png", replace 	

hist first_treat_p, title("Year states first enact primary laws") xtick(1985(5)2005) xtitle("Year enacted") 

graph export "$figures/timing_primary2.png", replace 	

*twoway bar state max_year_p, barwidth(0.5) || scatter state max_year_p, mlabel(state) mlabposition(0) mlabcolor(black) 


* Visualize when states first enact laws
xtline secondary, i(state) t(year) overlay xtitle("Year") title("States enacting secondary seat belt laws") xtick(1980(1)2005)

graph export "$figures/timing_secondary.png", replace 	





/***********************************
(b) Define the outcome as log traffic fatalities per capita. Plot this outcome in a way that may be helpful for later difference-in-differences (DiD) analyses. From this graph, can you say anything about the plausibility of the parallel trends assumption, as well as the likely effects of primary belt laws? 
***********************************/

gen y = ln(fatalities / population)
la var y "Log traffic fatalities per capita"

gen K = year - 2000 // pick random year to compare against
replace K = year - first_treat_p if !missing(first_treat_p)

set graphics on
preserve
collapse (mean) mean_y = y, by(K never_treated)

twoway line mean_y K if never_treated == 0 ///
	|| line mean_y K if never_treated == 1, ///
	legend(label(1 "Treated States") label(2 "Never Treated States")) ///
	title("Parallel Trends Plot") ///
	xlabel(-22(3)20) ylabel(, format(%9.0g)) ///
	xtitle("Years Relative to Treatment") ytitle("Mean of log fatalities") ///
	xline(0)

graph export "$figures/parallel.png", replace 	
restore



/***********************************
(c) Test the parallel trends assumption in any manner you find feasible and useful. Summarize the test and your findings. Do secondary belt laws pose a problem for a simple DiD analysis? If so, test whether that problem is likely to be significant. If not, explain why not.
***********************************/

* First 6 pretrends not significant 
did_imputation y state year first_treat_p, pretrend(6) autosample

coefplot, drop(_cons tau) ////
	xline(0) xtitle("Coefficient on pretrend") ///
	title("Pretrends test using Borusyak et al. (2024)")

graph export "$figures/pretrend_test.png", replace 	


event_plot, default_look ///
	graph_opt(xtitle("Periods prior to primary law enactment") ///
	ytitle("Average causal effect") ///
	title("Borusyak et al. (2024) event study plot") xlabel(-5(1)5))




/***********************************
(d) [6 points] Using regression, estimate the dynamic effect of primary belt laws on the out-
come for each of the horizons where a reasonable sample is available. Then compare your
estimates to ones from the Borusyak, Jaravel, and Spiess (2024) imputation estimator. Do the
results mostly agree?
***********************************/


csdid y primary, ivar(state) time(year) gvar(first_treat_p)
csdid_stats pretrend

local years 1987 1996 1998 2000
foreach year in `years' {
	csdid_plot, group(`year') title("Dynamic effects of treatment for `year' cohort")
	graph export "$figures/event_study_`year'.png", replace 	

}




br state year primary switch_p first_treat










