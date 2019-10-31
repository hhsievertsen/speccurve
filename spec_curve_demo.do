* specification curve demo by Hans H. Sievertsen h.h.sievertsen@bristol.ac.uk, 29/10-2019

clear
cap program drop specchart
program specchart
syntax varlist, [replace] spec(string)
	* save current data
	tempfile temp
	save "`temp'",replace
	*dataset to store estimates
	if "`replace'"!=""{
			clear
			gen beta=.
			gen se=.
			gen spec_id=.
			gen u95=.
			gen u90=.
			gen l95=.
			gen l90=.
			save "estimates.dta",replace
	}	
	else{
		* load dataset
		use "estimates.dta",clear
	}
	* add observation
	local obs=_N+1
	set obs `obs'
	replace spec_id=`obs' if _n==`obs'
	* store estimates
	replace beta =_b[`varlist'] if  spec_id==`obs'
	replace se=_se[`varlist']   if  spec_id==`obs'
	replace u95=beta+invt(e(df_r),0.975)*se if  spec_id==`obs'
	replace u90=beta+invt(e(df_r),0.95)*se if  spec_id==`obs'
	replace l95=beta-invt(e(df_r),0.975)*se  if  spec_id==`obs'
	replace l90=beta-invt(e(df_r),0.95)*se  if  spec_id==`obs'
	* store specification
	foreach s in `spec'{
		cap gen `s'=1 			if  spec_id==`obs'
		cap replace `s'=1 		 if  spec_id==`obs'
	}
		save "estimates.dta",replace
	* restore dataset
	use `temp',clear
end


* run regressions 
	clear
	sysuse auto

* main spec
regress price weight    
specchart  weight,spec(main sample`i' linear) replace

* alternative specs
* loop over sample size
forval i=50(2)74{
	clear
	sysuse auto
	keep if _n<`i'
 * no covars
	* no covars + linear mpg
	qui: regress price weight  mpg
	specchart  weight,spec(covars linear sample`i') 

	* no covars + quadratric mpg
	qui: regress price weight    c.mpg##c.mpg
	specchart  weight,spec(covars quadratic sample`i') 

	* no covars + cubic mpg
	qui: regress price weight    c.mpg##c.mpg##c.mpg
	specchart  weight,spec(covars cubic sample`i') 
	
	* no covars + quartic mpg
	qui: regress price weight    c.mpg##c.mpg##c.mpg##c.mpg
	specchart  weight,spec(covars quartic sample`i') 

 * with covars
	* w. covars + linear mpg
	qui: regress price weight    length  turn trunk  displacement
	specchart  weight,spec( linear sample`i') 

	* w. covars + quadratric mpg
	qui: regress price weight    c.mpg##c.mpg  length  turn trunk  displacement
	specchart  weight,spec( quadratic sample`i') 

	* w. covars + cubic mpg  
	qui: regress price weight    c.mpg##c.mpg##c.mpg  length  turn trunk  displacement
	specchart  weight,spec( cubic sample`i') 

	* w. covars + mpg length
	qui: regress price weight c.mpg##c.mpg##c.mpg##c.mpg  length  turn trunk  displacement
	specchart  weight,spec( quartic sample`i') 
}

* create chart
use "estimates.dta",clear
* drop duplicates 
duplicates drop covars cubic linear quadratic quartic sample*, force
/* sort specification by category */
gsort -quartic -cubic -quadratic -linear -covars ///
	-sample74 -sample72 -sample70 -sample68 -sample66 ///
	-sample64 -sample62 -sample60 -sample58 -sample56 ///
	-sample54 -sample52 -sample50, mfirst
/* sort estimates by coefificent size, uncomment to activate sort by category */
sort beta
* rank
gen rank=_n
* gen indicators and scatters
	local scoff=" "
	local scon=" "
	local ind=-1.5
	foreach var in covars linear quadratic cubic quartic   {
	   cap gen i_`var'=`ind'
	   local ind=`ind'-0.4
	   local scoff="`scoff' (scatter i_`var' rank,msize(vsmall) mcolor(gs10))" 
	   local scon="`scon' (scatter i_`var' rank if `var'==1,msize(vsmall) mcolor(black))" 
	}
	* samples
	local ind=`ind'-0.6
	forval i=50(2)74{
		cap gen i_sample`i'=`ind'
		local ind=`ind'-0.4
	   local scoff="`scoff' (scatter i_sample`i' rank,msize(vsmall) mcolor(gs10))" 
	   local scon="`scon' (scatter i_sample`i' rank if sample`i'==1,msize(vsmall) mcolor(black))" 
	}


* plot
tw  (scatter beta rank if main==1, mcolor(blue) msymbol(D)  msize(small)) ///  main spec 
   (rbar u95 l95 rank, fcolor(gs12) lcolor(gs12) lwidth(none)) /// 95% CI
   (rbar u90 l90 rank, fcolor(gs6) lcolor(gs16) lwidth(none)) /// 90% CI
   (scatter beta rank, mcolor(black) msymbol(D) msize(small)) ///  point estimates
   `scoff' `scon' /// indicators for spec
  (scatter beta rank if main==1, mcolor(blue) msymbol(D)  msize(small)) ///  main spec 
  (scatter i_sample74 rank if main==1,msize(vsmall) mcolor(blue))  ///
  (scatter i_linear rank if main==1,msize(vsmall) mcolor(blue))  ///
   ,legend (order(1 "Main spec." 4 "Point estimate" 2 "95% CI" 3 "90% CI") region(lcolor(white)) ///
	pos(12) ring(1) rows(1) size(vsmall) symysize(small) symxsize(small)) ///
   xtitle(" ") ytitle(" ") ///
   yscale(noline) xscale(noline) ylab(0(2)9,noticks nogrid angle(horizontal)) xlab("", noticks)  ///
   graphregion (fcolor(white) lcolor(white)) plotregion(fcolor(white) lcolor(white))
   
* now add stuff to the y axis  
gr_edit .yaxis1.add_ticks -1. `"Specification             "', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -1.5 `"Covariates"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -1.9 `"Linear"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -2.3 `"Quadratic"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -2.7 `"Cubic"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -3.1 `"Quartic"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )

gr_edit .yaxis1.add_ticks -3.6 `"Sample                     "', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -4.1 `"<=50"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -4.5 `"<=52"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -4.9 `"<=54"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -5.3 `"<=56"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -5.7 `"<=58"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -6.1 `"<=60"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -6.5 `"<=62"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -6.9 `"<=64"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -7.3 `"<=66"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -7.7 `"<=68"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -8.1 `"<=70"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -8.5 `"<=72"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )
gr_edit .yaxis1.add_ticks -8.9 `"<=74"', custom tickset(major) editstyle(tickstyle(textstyle(size(vsmall))) )

gr_edit .yaxis1.add_ticks 9 `"Coefficient"', custom tickset(major) editstyle(tickstyle(textstyle(size(small))) )
