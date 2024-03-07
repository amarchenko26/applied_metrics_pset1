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
observations for each state-year combination)? Visualize the timing of primary belt laws.
Are there any reversals of these laws? Are there "never-treated" states? How do the timing
of primary and secondary belt laws relate to each other? 
***********************************/

* Check if balanced
xtset state year
spbalance // data are strongly balanced


* Check missings
summarize
misstable summarize // no missings


* Count switchers
sort state year
by state: gen switch_p = primary[_n] - primary[_n-1]
replace switch_p = 0 if missing(switch_p)
count if switch_p == -1 // no states switched primary laws


by state: gen switch_s = secondary[_n] - secondary[_n-1]
count if switch_s == -1 // 11 states switched secondary


* Year first treated
gen first_treat_temp = 0
replace first_treat_temp = year if switch_p == 1 
by state: egen first_treat = max(first_treat_temp)
drop first_treat_temp


* Count never-treated
by state: egen years_treated = total(primary)
tab state if years_treated == 0 // about half sample never treated


* See how many years between primary and secondary laws
gen year_s = year if switch_s == 1
gen year_p = year if switch_p == 1

by state: egen year_s_enact = max(year_s)
by state: egen year_p_enact = max(year_p)

by state: gen diff_timing = year_p_enact - year_s_enact
drop year_p year_s

hist diff_timing, title("Timing difference between primary and secondary laws") xtick(0(1)18) xtitle("Difference in years (primary - secondary)") 

graph export "$figures/timing_diff.png", replace 	


* Visualize when states first enact laws
xtline primary, i(state) t(year) overlay xtitle("Year") title("States enacting primary seat belt laws") xtick(1980(1)2005)

graph export "$figures/timing_primary.png", replace 	

hist year_p_enact, title("Year states first enact primary laws") xtick(1985(5)2005) xtitle("Year enacted") 

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

* Create a variable to identify never treated states
gen never_treated = missing(year_p_enact)

gen K = year - first_treat
replace K = K-2000 if never_treated == 1

* Collapse the data to get mean of y for each K value by treatment status
collapse (mean) mean_y = y, by(K never_treated)

* Now plot both treated and never treated lines from the collapsed data

twoway line mean_y K if never_treated == 0 ///
	|| line mean_y K if never_treated == 1, ///
	legend(label(1 "Treated States") label(2 "Never Treated States")) ///
	title("Parallel Trends Plot") ///
	xlabel(-22(3)20) ylabel(, format(%9.0g)) ///
	xtitle("Years Relative to Treatment") ytitle("Mean of y") ///
	xline(0)

graph export "$figures/parallel.png", replace 	




	



/***********************************
(d) [6 points] Using regression, estimate the dynamic effect of primary belt laws on the out-
come for each of the horizons where a reasonable sample is available. Then compare your
estimates to ones from the Borusyak, Jaravel, and Spiess (2024) imputation estimator. Do the
results mostly agree?
***********************************/



	
	
did_imputation y state year first_treat, pretrend(6) autosample
event_plot, default_look graph_opt(xtitle("Periods prior to primary law enactment") ytitle("Average causal effect") ///
	title("Borusyak et al. (2021) event study plot") xlabel(-5(1)5))



csdid y primary, ivar(state) time(year) gvar(first_treat)
csdid_stats pretrend

local years 1987 1996 1998 2000
foreach year in `years' {
	csdid_plot, group(`year') title("Dynamic effects of treatment for `year' cohort")
	graph export "$figures/event_study_`year'.png", replace 	

}




br state year primary switch_p first_treat










