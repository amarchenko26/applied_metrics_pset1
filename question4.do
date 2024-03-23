/*
 Author: Anya Marchenko
 Date: Spring 2024

 This .do file runs the code for Problem Set 1, Q4, Applied Metrics, Peter Hull  
 
*/

***********************************
* Define paths  
***********************************	

global figures "/Users/anyamarchenko/CEGA Dropbox/Anya Marchenko/Apps/Overleaf/Pset 1 (Spring 2024, Applied Metrics, Peter Hull)/figures"


// deletes & remakes figures folder
shell if [ -d "$figures" ]; then rm -r "$figures"; fi; mkdir -p "$figures"


***********************************
* Load data  
***********************************	

clear all 
use "/Users/anyamarchenko/Documents/GitHub/applied_metrics_pset1/anderson.dta", clear

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

* Count reversals
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



// Figures

* Visualize when states first enact laws
graph dot first_treat_s first_treat_p, over(state, label(labsize(*.50))) ///
	legend(label(1 "Secondary law") label(2 "Primary law")) ///
	yscale(noline) ytitle("Year") ///
	ytick(1980(1)2005, grid) ylabel(1980(5)2005) exclude0 ///
	yline(1993, lcolor(red)) ///
	yline(1989, lcolor(blue)) ///
	note("Vertical lines indicate mean enactment year, 1989 for secondary, 1993 for primary") ///
	noextend
graph export "$figures/dots.png", replace 	


* Histograms
xtline primary, ///
	i(state) t(year) overlay xtitle("Year") ///
	title("States enacting primary seat belt laws") xtick(1980(1)2005)
graph export "$figures/timing_primary.png", replace 	

hist first_treat_p, ///
	title("Year states first enact primary laws") ///
	xtick(1985(5)2005) xtitle("Year enacted") 
graph export "$figures/timing_primary2.png", replace 	

xtline secondary, ///
	i(state) t(year) overlay xtitle("Year") ///
	title("States enacting secondary seat belt laws") xtick(1980(1)2005)
graph export "$figures/timing_secondary.png", replace 	

hist diff_timing, ///
	title("Timing difference between primary and secondary laws") ///
	xtick(0(1)18) xtitle("Difference in years (primary - secondary)") 
graph export "$figures/timing_diff.png", replace 	


drop diff_timing








/***********************************
(b) Define the outcome as log traffic fatalities per capita. Plot this outcome in a way that may be helpful for later difference-in-differences (DiD) analyses. From this graph, can you say anything about the plausibility of the parallel trends assumption, as well as the likely effects of primary belt laws? 
***********************************/

gen y = ln(fatalities / population)
la var y "Ln traffic fatalities per capita"

preserve
collapse (mean) mean_y = y, by(year never_treated)

twoway line mean_y year if never_treated == 0 ///
	|| line mean_y year if never_treated == 1, ///
	legend(label(1 "Treated States") label(2 "Never Treated States")) ///
	title("Parallel Trends Plausibility") ///
	ylabel(, format(%9.0g)) ///
	xtitle("Year") ytitle("ln(fatalities per capita)") ///
	xline(1993) note("Vertical line indicates mean year primary laws passed")
	
graph export "$figures/parallel.png", replace 	
restore





/***********************************
(c) Test the parallel trends assumption in any manner you find feasible and useful. Summarize the test and your findings. Do secondary belt laws pose a problem for a simple DiD analysis? If so, test whether that problem is likely to be significant. If not, explain why not.
***********************************/

* Test for pretrends, first 6 pretrends not significant 
did_imputation y state year first_treat_p, pretrend(6) autosample

coefplot, drop(_cons tau) ////
	xline(0) xtitle("Coefficient on pretrend") ///
	title("Pretrends test, no controls") ///
	note("Using Borusyak et al. (2024) did_imputation package")
 
graph export "$figures/pretrend_test.png", replace 	


* Pretrends w controls for secondary laws, pretrends still not significant
did_imputation y state year first_treat_p, pretrend(6) autosample fe(secondary)

coefplot, drop(_cons tau) ////
	xline(0) xtitle("Coefficient on pretrend") ///
	title("Pretrends test, controling for secondary laws") ///
	note("Using Borusyak et al. (2024) did_imputation package")

graph export "$figures/pretrend_test_fe.png", replace 	




/***********************************
(d) [6 points] Using regression, estimate the dynamic effect of primary belt laws on the outcome for each of the horizons where a reasonable sample is available. Then compare your
estimates to ones from the Borusyak, Jaravel, and Spiess (2024) imputation estimator. Do the results mostly agree?
***********************************/

******** 1) Event study regression *********************************************

* gen lag var
g time_to_treat = year - first_treat_p
tab time_to_treat, gen(lag_dummy) 

* Keep lags -7 to 7
drop lag_dummy1-lag_dummy15 lag_dummy31-lag_dummy42

ren lag_dummy16 lag_neg7
ren lag_dummy17 lag_neg6
ren lag_dummy18 lag_neg5
ren lag_dummy19 lag_neg4
ren lag_dummy20 lag_neg3
ren lag_dummy21 lag_neg2
ren lag_dummy22 lag_neg1
ren lag_dummy23 lag_0
ren lag_dummy24 lag_1
ren lag_dummy25 lag_2
ren lag_dummy26 lag_3
ren lag_dummy27 lag_4
ren lag_dummy28 lag_5
ren lag_dummy29 lag_6
ren lag_dummy30 lag_7

* Gen event-study dummy
g es = primary*lag_0
forvalues i=1/7{
	replace lag_`i' = 0 if missing(first_treat_p)
	replace es = primary*lag_`i'
}

forvalues i=1/7{
	replace lag_neg`i' = 0 if missing(first_treat_p)
	replace es = primary*lag_neg`i'
}

* Run event-study
reghdfe y i.primary#i.lag_neg4 ///
		  i.primary#i.lag_neg3 ///
		  i.primary#i.lag_neg2 /// // skip -1
		  i.primary#i.lag_0 ///
		  i.primary#i.lag_1 ///
		  i.primary#i.lag_2 ///
		  i.primary#i.lag_3 ///
		  i.primary#i.lag_4, absorb(state year) vce(cluster state)

estimates store model
estfe . model, labels(state "State FE" year "Year FE")
return list
// esttab model using "eventstudy.tex", style(tex) replace //uncomment to replace table


		  
******** 1b) Event-study using Callaway and Sant'Anna (2021) *******************

gen gvar = first_treat_p
replace gvar = 0 if never_treated == 1 // csdid expects gvar to = 0 for never treated

csdid y primary, ivar(state) time(year) gvar(gvar)

loc years 1984 1986 1987 1991 1993 1996 1998 2000
foreach year in `years' {
	csdid_plot, group(`year') title("Dynamic effects of treatment for `year' cohort")
	graph export "$figures/event_study_`year'.png", replace 	
}

csdid y primary, ivar(state) time(year) gvar(gvar) agg(simple) // ATT = -.068



******** 2) Dynamic effect using Borusyak **************************************

did_imputation y state year first_treat_p, ///
	horizons(0/7) ///
	pretrends(5) minn(0) ///
	avgeffectsby(primary)
	
	
	

/***********************************
(e) [4 points] Check the sensitivity of both estimates in (d) to including 
state-specific linear trends in your model of untreated potential outcomes.
***********************************/

******** 1) Event study + state linear trends 
reghdfe y i.primary#i.lag_neg4 ///
		  i.primary#i.lag_neg3 ///
		  i.primary#i.lag_neg2 /// // skip -1
		  i.primary#i.lag_0 ///
		  i.primary#i.lag_1 ///
		  i.primary#i.lag_2 ///
		  i.primary#i.lag_3 ///
		  i.primary#i.lag_4 ///
		  c.year#i.state ///
		  beer ///
		  totalvmt ///
		  precip ///
		  snow32 ///
		  rural_speed ///
		  urban_speed, ///
		  absorb(year) vce(cluster state) keepsing
		  
estimates store model2
esttab model2 using "eventstudy_controls.tex", ///
	style(tex) replace ///
	starlevels(* .1 ** .05 *** .01 )

******** 2) Check with Borusyak + state linear trends 

* 2) Check with Borusyak 
did_imputation y state year first_treat_p, ///
	horizons(0/7) ///
	pretrends(5) minn(0) ///
	avgeffectsby(primary) ///
	unitcontrols(year)

drop lag*



/***********************************
(f) [6 points] Estimate the ``static'' TWFE regression which specifies treatment as only affecting outcomes in the current period. Estimate and plot the total weight this regression places on treated observations at each horizon. In what way are these weights informative? Compare these to the sample weights of each horizon. In your view, does the static regression coefficient provide a useful summary of causal effects in this setting?
***********************************/

// Static TWFE
reghdfe y primary, ///
	vce(cluster state) absorb(state year) 
	
// Estimate residuals
predict resid, residuals
	
// Calculate weights
g num = primary * resid  // weight numerator
egen den = total(num)	 // weights denominator
g weights = num / den

drop num den

* Plot regression weights
preserve 
collapse (mean) mean_weight = weights, by(time_to_treat)

scatter mean_weight time_to_treat, ///
	xtitle("Time to treatment") ///
	ytitle("Mean weights") ///
	title("Regression weights on treated observations by horizon")

graph export "$figures/weights.png", replace 	
restore

* Calculate sampling weights
egen den = total(primary) //182 is denominator 

preserve
drop if missing(time_to_treat) //otherwise collapse will include missing as value
g x = 1
collapse (count) num = x, by(time_to_treat)
g samp_weights = num / 182

scatter samp_weights time_to_treat, ///
	xtitle("Time to treatment") ///
	ytitle("Mean weights") ///
	title("Sampling weights by horizon")

graph export "$figures/sample_weights.png", replace 	
restore


