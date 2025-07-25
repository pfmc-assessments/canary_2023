#V3.30
#C file created using the SS_writectl function in the R package r4ss
#C file write time: 2023-02-23 16:53:24
#
0 # 0 means do not read wtatage.ss; 1 means read and usewtatage.ss and also read and use growth parameters
1 #_N_Growth_Patterns
1 #_N_platoons_Within_GrowthPattern
2 # recr_dist_method for parameters
1 # not yet implemented; Future usage:Spawner-Recruitment; 1=global; 2=by area
3 # number of recruitment settlement assignments 
0 # unused option
# for each settlement assignment:
#_GPattern	month	area	age
1	1	1	0	#_recr_dist_pattern1
1	1	2	0	#_recr_dist_pattern2
1	1	3	0	#_recr_dist_pattern3
#
0 #_N_movement_definitions goes here if N_areas > 1
6 #_Nblock_Patterns
2 2 1 2 2 1 #_blocks_per_pattern
#_begin and end years of blocks
2001 2010 2011 2022
2003 2020 2021 2022
2001 2022
2004 2014 2015 2022
2006 2020 2021 2022
1891 1891
#
# controls for all timevary parameters 
1 #_env/block/dev_adjust_method for all time-vary parms (1=warn relative to base parm bounds; 3=no bound check)
#
# AUTOGEN
1 1 1 1 1 # autogen: 1st element for biology, 2nd for SR, 3rd for Q, 4th reserved, 5th for selex
# where: 0 = autogen all time-varying parms; 1 = read each time-varying parm line; 2 = read then autogen if parm min==-12345
#
# setup for M, growth, maturity, fecundity, recruitment distibution, movement
#
0 #_natM_type:_0=1Parm; 1=N_breakpoints;_2=Lorenzen;_3=agespecific;_4=agespec_withseasinterpolate;_5=Maunder_M;_6=Age-range_Lorenzen
#_no additional input for selected M option; read 1P per morph
1 # GrowthModel: 1=vonBert with L1&L2; 2=Richards with L1&L2; 3=age_specific_K_incr; 4=age_specific_K_decr;5=age_specific_K_each; 6=NA; 7=NA; 8=growth cessation
1 #_Age(post-settlement)_for_L1;linear growth below this
999 #_Growth_Age_for_L2 (999 to use as Linf)
-999 #_exponential decay for growth above maxage (value should approx initial Z; -999 replicates 3.24; -998 to not allow growth above maxage)
0 #_placeholder for future growth feature
#
0 #_SD_add_to_LAA (set to 0.1 for SS2 V1.x compatibility)
0 #_CV_Growth_Pattern:  0 CV=f(LAA); 1 CV=F(A); 2 SD=F(LAA); 3 SD=F(A); 4 logSD=F(A)
2 #_maturity_option:  1=length logistic; 2=age logistic; 3=read age-maturity matrix by growth_pattern; 4=read age-fecundity; 5=disabled; 6=read length-maturity
2 #_First_Mature_Age
2 #_fecundity option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
1 #_parameter_offset_approach (1=none, 2= M, G, CV_G as offset from female-GP1, 3=like SS2 V1.x)
#
#_growth_parms
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env_var&link	dev_link	dev_minyr	dev_maxyr	dev_PH	Block	Block_Fxn
 0.02	     0.2	   0.0643	   -2.74	 0.31	3	  2	0	0	   0	   0	0.5	0	0	#_NatM_p_1_Fem_GP_1  
    2	      15	   9.0468	       4	   50	0	  3	0	0	   0	   0	0.5	0	0	#_L_at_Amin_Fem_GP_1 
   50	      70	  60.0427	      60	   50	0	  3	0	0	   0	   0	0.5	0	0	#_L_at_Amax_Fem_GP_1 
 0.02	    0.21	 0.128749	    0.14	   50	0	  3	0	0	   0	   0	0.5	0	0	#_VonBert_K_Fem_GP_1 
 0.02	    0.21	 0.109118	    0.15	   50	0	  4	0	0	   0	   0	0.5	0	0	#_CV_young_Fem_GP_1  
 0.01	    0.21	    0.028	   0.028	   50	0	  4	0	0	   0	   0	0.5	0	0	#_CV_old_Fem_GP_1    
    0	     0.1	 1.19e-05	1.19e-05	   50	6	-50	0	0	   0	   0	0.5	0	0	#_Wtlen_1_Fem_GP_1   
    2	       4	     3.09	    3.09	   50	6	-50	0	0	   0	   0	0.5	0	0	#_Wtlen_2_Fem_GP_1   
    9	      12	    10.87	   10.87	0.055	6	-50	0	0	   0	   0	0.5	0	0	#_Mat50%_Fem_GP_1    
   -3	       3	    -0.25	   -0.25	   50	6	-50	0	0	   0	   0	0.5	0	0	#_Mat_slope_Fem_GP_1 
1e-10	     0.1	7.218e-08	-16.4441	0.135	3	-50	0	0	   0	   0	0.5	0	0	#_Eggs_alpha_Fem_GP_1
    2	       6	    4.043	   4.043	  0.3	6	-50	0	0	   0	   0	0.5	0	0	#_Eggs_beta_Fem_GP_1 
 0.02	     0.2	   0.0643	   -2.74	 0.31	6	-50	0	0	   0	   0	0.5	0	0	#_NatM_p_1_Mal_GP_1  
    0	      15	        0	       0	   50	6	-50	0	0	   0	   0	0.5	0	0	#_L_at_Amin_Mal_GP_1 
   50	      70	  60.0427	      60	   50	0	  3	0	0	   0	   0	0.5	0	0	#_L_at_Amax_Mal_GP_1 
 0.02	    0.21	 0.128749	    0.14	   50	0	  3	0	0	   0	   0	0.5	0	0	#_VonBert_K_Mal_GP_1 
 0.02	    0.21	 0.109118	    0.15	   50	0	  4	0	0	   0	   0	0.5	0	0	#_CV_young_Mal_GP_1  
 0.01	    0.21	    0.028	   0.028	   50	0	  4	0	0	   0	   0	0.5	0	0	#_CV_old_Mal_GP_1    
    0	     0.1	 1.08e-05	1.08e-05	   50	6	-50	0	0	   0	   0	0.5	0	0	#_Wtlen_1_Mal_GP_1   
    2	       4	    3.118	   3.118	   50	6	-50	0	0	   0	   0	0.5	0	0	#_Wtlen_2_Mal_GP_1   
    0	     999	        1	       1	   50	6	-50	0	0	   0	   0	0.5	0	0	#_RecrDist_GP_1      
   -7	       7	        0	       1	   50	0	 -1	0	0	   0	   0	  0	0	0	#_RecrDist_Area_1    
   -7	       7	  1.10278	       1	   50	0	  1	0	1	1933	2022	  5	0	0	#_RecrDist_Area_2    
   -7	       7	 0.536153	       1	   50	0	  1	0	1	1933	2022	  5	0	0	#_RecrDist_Area_3    
    0	     999	        1	       1	   50	6	-50	0	0	   0	   0	0.5	0	0	#_RecrDist_month_1   
   -1	       1	        1	       1	   50	6	-50	0	0	1980	1983	0.5	0	0	#_CohortGrowDev      
1e-06	0.999999	      0.5	     0.5	  0.5	0	-99	0	0	   0	   0	  0	0	0	#_FracFemale_GP_1    
#_timevary MG parameters
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE
1e-04	   2	0.5	0.5	0.5	6	-5	#_RecrDist_Area_2_dev_se      
-0.99	0.99	  0	  0	0.5	6	-6	#_RecrDist_Area_2_dev_autocorr
1e-04	   2	0.5	0.5	0.5	6	-5	#_RecrDist_Area_3_dev_se      
-0.99	0.99	  0	  0	0.5	6	-6	#_RecrDist_Area_3_dev_autocorr
# info on dev vectors created for MGparms are reported with other devs after tag parameter section
#
#_seasonal_effects_on_biology_parms
0 0 0 0 0 0 0 0 0 0 #_femwtlen1,femwtlen2,mat1,mat2,fec1,fec2,Malewtlen1,malewtlen2,L1,K
#_ LO HI INIT PRIOR PR_SD PR_type PHASE
#_Cond -2 2 0 0 -1 99 -2 #_placeholder when no seasonal MG parameters
#
3 #_Spawner-Recruitment; 2=Ricker; 3=std_B-H; 4=SCAA;5=Hockey; 6=B-H_flattop; 7=survival_3Parm;8=Shepard_3Parm
1 # 0/1 to use steepness in initial equ recruitment calculation
0 # future feature: 0/1 to make realized sigmaR a function of SR curvature
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn # parm_name
   7	  11	7.95802	 8.5	  50	0	  1	0	0	0	0	0	0	0	#_SR_LN(R0)  
0.21	0.99	   0.72	0.72	0.16	2	 -6	0	0	0	0	0	0	0	#_SR_BH_steep
   0	   2	    0.5	 0.4	  50	6	-50	0	0	0	0	0	0	0	#_SR_sigmaR  
  -5	   5	      0	   0	  50	6	-50	0	0	0	0	0	0	0	#_SR_regime  
   0	   2	      0	   1	  50	6	-50	0	0	0	0	0	0	0	#_SR_autocorr
#_no timevary SR parameters
1 #do_recdev:  0=none; 1=devvector (R=F(SSB)+dev); 2=deviations (R=F(SSB)+dev); 3=deviations (R=R0*dev; dev2=R-f(SSB)); 4=like 3 with sum(dev2) adding penalty
1960 # first year of main recr_devs; early devs can preceed this era
2014 # last year of main recr_devs; forecast devs start in following year
5 #_recdev phase
1 # (0/1) to read 13 advanced options
1933 #_recdev_early_start (0=none; neg value makes relative to recdev_start)
5 #_recdev_early_phase
6 #_forecast_recruitment phase (incl. late recr) (0 value resets to maxphase+1)
1 #_lambda for Fcast_recr_like occurring before endyr+1
1965.76 #_last_yr_nobias_adj_in_MPD; begin of ramp
1978 #_first_yr_fullbias_adj_in_MPD; begin of plateau
2012 #_last_yr_fullbias_adj_in_MPD
2014 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS sets bias_adj to 0.0 for fcast yrs)
0.8025 #_max_bias_adj_in_MPD (-1 to override ramp and set biasadj=1.0 for all estimated recdevs)
0 #_period of cycles in recruitment (N parms read below)
-5 #min rec_dev
5 #max rec_dev
0 #_read_recdevs
#_end of advanced SR options
#
#_placeholder for full parameter lines for recruitment cycles
# read specified recr devs
#_Yr Input_value
#
#Fishing Mortality info
0.2 # F ballpark
-1999 # F ballpark year (neg value to disable)
3 # F_Method:  1=Pope; 2=instan. F; 3=hybrid (hybrid is recommended)
4 # max F or harvest rate, depends on F_Method
5 # N iterations for tuning F in hybrid method (recommend 3 to 7)
#
#_initial_F_parms; count = 0
#
#_Q_setup for fleets with cpue or survey data
#_fleet	link	link_info	extra_se	biasadj	float  #  fleetname
   16	1	0	0	0	1	#_16_CA_NWFSC           
   17	1	0	0	0	1	#_17_OR_NWFSC           
   18	1	0	0	0	1	#_18_WA_NWFSC           
   19	1	0	0	0	1	#_19_CA_Tri_early       
   20	1	0	0	0	1	#_20_OR_Tri_early       
   21	1	0	0	0	1	#_21_WA_Tri_early       
   22	1	0	0	0	1	#_22_CA_Tri_late        
   23	1	0	0	0	1	#_23_OR_Tri_late        
   24	1	0	0	0	1	#_24_WA_Tri_late        
   25	1	0	1	0	1	#_25_CA_prerec          
   26	1	0	1	0	1	#_26_OR_prerec          
   27	1	0	1	0	1	#_27_WA_prerec          
   28	1	0	0	0	1	#_28_coastwide_NWFSC    
   29	1	0	0	0	1	#_29_coastwide_Tri_early
   30	1	0	0	0	1	#_30_coastwide_Tri_late 
   31	1	0	0	0	1	#_31_coastwide_prerec   
-9999	0	0	0	0	0	#_terminator            
#_Q_parms(if_any);Qunits_are_ln(q)
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn  #  parm_name
-25	25	  0.355139	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_16_CA_NWFSC(16)           
-25	25	 -0.603442	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_17_OR_NWFSC(17)           
-25	25	-0.0907719	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_18_WA_NWFSC(18)           
-25	25	   2.04584	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_19_CA_Tri_early(19)       
-25	25	  -0.60096	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_20_OR_Tri_early(20)       
-25	25	 -0.538458	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_21_WA_Tri_early(21)       
-25	25	   3.91123	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_22_CA_Tri_late(22)        
-25	25	  -0.46186	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_23_OR_Tri_late(23)        
-25	25	 -0.989914	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_24_WA_Tri_late(24)        
-25	25	  -8.34504	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_25_CA_prerec(25)          
  0	 3	  0.514511	0.1	99	0	 2	0	0	0	0	0	0	0	#_Q_extraSD_25_CA_prerec(25)         
-25	25	  -8.29858	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_26_OR_prerec(26)          
  0	 3	  0.391149	0.1	99	0	 2	0	0	0	0	0	0	0	#_Q_extraSD_26_OR_prerec(26)         
-25	25	  -9.04758	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_27_WA_prerec(27)          
  0	 3	   0.98698	0.1	99	0	 2	0	0	0	0	0	0	0	#_Q_extraSD_27_WA_prerec(27)         
-25	25	   2.42704	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_28_coastwide_NWFSC(28)    
-25	25	   3.27912	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_29_coastwide_Tri_early(29)
-25	25	   5.13859	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_30_coastwide_Tri_late(30) 
-25	25	  -6.60196	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_31_coastwide_prerec(31)   
#_no timevary Q parameters
#
#_size_selex_patterns
#_Pattern	Discard	Male	Special
24	0	0	 0	#_1 1_CA_TWL               
24	0	0	 0	#_2 2_OR_TWL               
24	0	0	 0	#_3 3_WA_TWL               
24	0	0	 0	#_4 4_CA_NTWL              
24	0	0	 0	#_5 5_OR_NTWL              
15	0	0	 3	#_6 6_WA_NTWL              
24	0	0	 0	#_7 7_CA_REC               
24	0	0	 0	#_8 8_OR_REC               
24	0	0	 0	#_9 9_WA_REC               
24	0	0	 0	#_10 10_CA_ASHOP           
15	0	0	10	#_11 11_OR_ASHOP           
15	0	0	10	#_12 12_WA_ASHOP           
15	0	0	 1	#_13 13_CA_FOR             
15	0	0	 2	#_14 14_OR_FOR             
15	0	0	 3	#_15 15_WA_FOR             
24	0	0	 0	#_16 16_CA_NWFSC           
15	0	0	16	#_17 17_OR_NWFSC           
15	0	0	16	#_18 18_WA_NWFSC           
24	0	0	 0	#_19 19_CA_Tri_early       
15	0	0	19	#_20 20_OR_Tri_early       
15	0	0	19	#_21 21_WA_Tri_early       
24	0	0	 0	#_22 22_CA_Tri_late        
15	0	0	22	#_23 23_OR_Tri_late        
15	0	0	22	#_24 24_WA_Tri_late        
 0	0	0	 0	#_25 25_CA_prerec          
 0	0	0	 0	#_26 26_OR_prerec          
 0	0	0	 0	#_27 27_WA_prerec          
15	0	0	16	#_28 28_coastwide_NWFSC    
15	0	0	19	#_29 29_coastwide_Tri_early
15	0	0	22	#_30 30_coastwide_Tri_late 
 0	0	0	 0	#_31 31_coastwide_prerec   
#
#_age_selex_patterns
#_Pattern	Discard	Male	Special
10	0	0	0	#_1 1_CA_TWL               
10	0	0	0	#_2 2_OR_TWL               
10	0	0	0	#_3 3_WA_TWL               
10	0	0	0	#_4 4_CA_NTWL              
10	0	0	0	#_5 5_OR_NTWL              
10	0	0	0	#_6 6_WA_NTWL              
10	0	0	0	#_7 7_CA_REC               
10	0	0	0	#_8 8_OR_REC               
10	0	0	0	#_9 9_WA_REC               
10	0	0	0	#_10 10_CA_ASHOP           
10	0	0	0	#_11 11_OR_ASHOP           
10	0	0	0	#_12 12_WA_ASHOP           
10	0	0	0	#_13 13_CA_FOR             
10	0	0	0	#_14 14_OR_FOR             
10	0	0	0	#_15 15_WA_FOR             
10	0	0	0	#_16 16_CA_NWFSC           
10	0	0	0	#_17 17_OR_NWFSC           
10	0	0	0	#_18 18_WA_NWFSC           
10	0	0	0	#_19 19_CA_Tri_early       
10	0	0	0	#_20 20_OR_Tri_early       
10	0	0	0	#_21 21_WA_Tri_early       
10	0	0	0	#_22 22_CA_Tri_late        
10	0	0	0	#_23 23_OR_Tri_late        
10	0	0	0	#_24 24_WA_Tri_late        
10	0	0	0	#_25 25_CA_prerec          
10	0	0	0	#_26 26_OR_prerec          
10	0	0	0	#_27 27_WA_prerec          
10	0	0	0	#_28 28_coastwide_NWFSC    
10	0	0	0	#_29 29_coastwide_Tri_early
10	0	0	0	#_30 30_coastwide_Tri_late 
10	0	0	0	#_31 31_coastwide_prerec   
#
#_SizeSelex
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn  #  parm_name
13.001	65	     44	99	99	0	  4	0	0	0	0	0	1	2	#_SizeSel_P_1_1_CA_TWL(1)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_1_CA_TWL(1)        
     0	 9	5.54518	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_3_1_CA_TWL(1)        
     0	 9	5.17048	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_4_1_CA_TWL(1)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_1_CA_TWL(1)        
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_1_CA_TWL(1)        
13.001	65	     47	99	99	0	  4	0	0	0	0	0	1	2	#_SizeSel_P_1_2_OR_TWL(2)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_2_OR_TWL(2)        
     0	 9	5.63479	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_3_2_OR_TWL(2)        
     0	 9	5.02388	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_4_2_OR_TWL(2)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_2_OR_TWL(2)        
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_2_OR_TWL(2)        
13.001	65	     48	99	99	0	  4	0	0	0	0	0	1	2	#_SizeSel_P_1_3_WA_TWL(3)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_3_WA_TWL(3)        
     0	 9	5.66296	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_3_3_WA_TWL(3)        
     0	 9	4.96981	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_4_3_WA_TWL(3)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_3_WA_TWL(3)        
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_3_WA_TWL(3)        
13.001	65	     36	99	99	0	  4	0	0	0	0	0	2	2	#_SizeSel_P_1_4_CA_NTWL(4)       
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_4_CA_NTWL(4)       
     0	 9	 5.2575	99	99	0	  5	0	0	0	0	0	2	2	#_SizeSel_P_3_4_CA_NTWL(4)       
     0	 9	5.48064	99	99	0	  5	0	0	0	0	0	2	2	#_SizeSel_P_4_4_CA_NTWL(4)       
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_4_CA_NTWL(4)       
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_4_CA_NTWL(4)       
13.001	65	     35	99	99	0	  4	0	0	0	0	0	4	2	#_SizeSel_P_1_5_OR_NTWL(5)       
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_5_OR_NTWL(5)       
     0	 9	5.21494	99	99	0	  5	0	0	0	0	0	4	2	#_SizeSel_P_3_5_OR_NTWL(5)       
     0	 9	5.51343	99	99	0	  5	0	0	0	0	0	4	2	#_SizeSel_P_4_5_OR_NTWL(5)       
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_5_OR_NTWL(5)       
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_5_OR_NTWL(5)       
13.001	65	     34	99	99	0	  4	0	0	0	0	0	3	2	#_SizeSel_P_1_7_CA_REC(7)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_7_CA_REC(7)        
     0	 9	5.17048	99	99	0	  5	0	0	0	0	0	3	2	#_SizeSel_P_3_7_CA_REC(7)        
     0	 9	5.54518	99	99	0	  5	0	0	0	0	0	3	2	#_SizeSel_P_4_7_CA_REC(7)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_7_CA_REC(7)        
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_7_CA_REC(7)        
13.001	65	     34	99	99	0	  4	0	0	0	0	0	4	2	#_SizeSel_P_1_8_OR_REC(8)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_8_OR_REC(8)        
     0	 9	5.17048	99	99	0	  5	0	0	0	0	0	4	2	#_SizeSel_P_3_8_OR_REC(8)        
     0	 9	5.54518	99	99	0	  5	0	0	0	0	0	4	2	#_SizeSel_P_4_8_OR_REC(8)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_8_OR_REC(8)        
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_8_OR_REC(8)        
13.001	65	     35	99	99	0	  4	0	0	0	0	0	5	2	#_SizeSel_P_1_9_WA_REC(9)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_9_WA_REC(9)        
     0	 9	5.21494	99	99	0	  5	0	0	0	0	0	5	2	#_SizeSel_P_3_9_WA_REC(9)        
     0	 9	5.51343	99	99	0	  5	0	0	0	0	0	5	2	#_SizeSel_P_4_9_WA_REC(9)        
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_9_WA_REC(9)        
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_9_WA_REC(9)        
13.001	65	     48	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_10_CA_ASHOP(10)    
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_10_CA_ASHOP(10)    
     0	 9	5.51343	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_10_CA_ASHOP(10)    
     0	 9	5.21494	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_10_CA_ASHOP(10)    
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_10_CA_ASHOP(10)    
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_10_CA_ASHOP(10)    
13.001	65	     41	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_16_CA_NWFSC(16)    
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_16_CA_NWFSC(16)    
     0	 9	5.44674	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_16_CA_NWFSC(16)    
     0	 9	5.29832	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_16_CA_NWFSC(16)    
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_16_CA_NWFSC(16)    
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_16_CA_NWFSC(16)    
13.001	65	     43	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_19_CA_Tri_early(19)
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_19_CA_Tri_early(19)
     0	 9	5.51343	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_19_CA_Tri_early(19)
     0	 9	5.21494	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_19_CA_Tri_early(19)
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_19_CA_Tri_early(19)
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_19_CA_Tri_early(19)
13.001	65	     39	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_22_CA_Tri_late(22) 
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_22_CA_Tri_late(22) 
     0	 9	5.37528	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_22_CA_Tri_late(22) 
     0	 9	5.37528	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_22_CA_Tri_late(22) 
   -99	99	    -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_22_CA_Tri_late(22) 
   -99	99	   -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_22_CA_Tri_late(22) 
#_AgeSelex
#_No age_selex_parm
# timevary selex parameters 
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE
13.001	65	     44	99	99	0	4	#_SizeSel_P_1_1_CA_TWL(1)_BLK1repl_2001 
13.001	65	     44	99	99	0	4	#_SizeSel_P_1_1_CA_TWL(1)_BLK1repl_2011 
     0	 9	5.54518	99	99	0	5	#_SizeSel_P_3_1_CA_TWL(1)_BLK1repl_2001 
     0	 9	5.54518	99	99	0	5	#_SizeSel_P_3_1_CA_TWL(1)_BLK1repl_2011 
     0	 9	5.17048	99	99	0	5	#_SizeSel_P_4_1_CA_TWL(1)_BLK1repl_2001 
     0	 9	5.17048	99	99	0	5	#_SizeSel_P_4_1_CA_TWL(1)_BLK1repl_2011 
13.001	65	     47	99	99	0	4	#_SizeSel_P_1_2_OR_TWL(2)_BLK1repl_2001 
13.001	65	     47	99	99	0	4	#_SizeSel_P_1_2_OR_TWL(2)_BLK1repl_2011 
     0	 9	5.63479	99	99	0	5	#_SizeSel_P_3_2_OR_TWL(2)_BLK1repl_2001 
     0	 9	5.63479	99	99	0	5	#_SizeSel_P_3_2_OR_TWL(2)_BLK1repl_2011 
     0	 9	5.02388	99	99	0	5	#_SizeSel_P_4_2_OR_TWL(2)_BLK1repl_2001 
     0	 9	5.02388	99	99	0	5	#_SizeSel_P_4_2_OR_TWL(2)_BLK1repl_2011 
13.001	65	     48	99	99	0	4	#_SizeSel_P_1_3_WA_TWL(3)_BLK1repl_2001 
13.001	65	     48	99	99	0	4	#_SizeSel_P_1_3_WA_TWL(3)_BLK1repl_2011 
     0	 9	5.66296	99	99	0	5	#_SizeSel_P_3_3_WA_TWL(3)_BLK1repl_2001 
     0	 9	5.66296	99	99	0	5	#_SizeSel_P_3_3_WA_TWL(3)_BLK1repl_2011 
     0	 9	4.96981	99	99	0	5	#_SizeSel_P_4_3_WA_TWL(3)_BLK1repl_2001 
     0	 9	4.96981	99	99	0	5	#_SizeSel_P_4_3_WA_TWL(3)_BLK1repl_2011 
13.001	65	     36	99	99	0	4	#_SizeSel_P_1_4_CA_NTWL(4)_BLK2repl_2003
13.001	65	     36	99	99	0	4	#_SizeSel_P_1_4_CA_NTWL(4)_BLK2repl_2021
     0	 9	 5.2575	99	99	0	5	#_SizeSel_P_3_4_CA_NTWL(4)_BLK2repl_2003
     0	 9	 5.2575	99	99	0	5	#_SizeSel_P_3_4_CA_NTWL(4)_BLK2repl_2021
     0	 9	5.48064	99	99	0	5	#_SizeSel_P_4_4_CA_NTWL(4)_BLK2repl_2003
     0	 9	5.48064	99	99	0	5	#_SizeSel_P_4_4_CA_NTWL(4)_BLK2repl_2021
13.001	65	     35	99	99	0	4	#_SizeSel_P_1_5_OR_NTWL(5)_BLK4repl_2004
13.001	65	     35	99	99	0	4	#_SizeSel_P_1_5_OR_NTWL(5)_BLK4repl_2015
     0	 9	5.21494	99	99	0	5	#_SizeSel_P_3_5_OR_NTWL(5)_BLK4repl_2004
     0	 9	5.21494	99	99	0	5	#_SizeSel_P_3_5_OR_NTWL(5)_BLK4repl_2015
     0	 9	5.51343	99	99	0	5	#_SizeSel_P_4_5_OR_NTWL(5)_BLK4repl_2004
     0	 9	5.51343	99	99	0	5	#_SizeSel_P_4_5_OR_NTWL(5)_BLK4repl_2015
13.001	65	     34	99	99	0	4	#_SizeSel_P_1_7_CA_REC(7)_BLK3repl_2001 
     0	 9	5.17048	99	99	0	5	#_SizeSel_P_3_7_CA_REC(7)_BLK3repl_2001 
     0	 9	5.54518	99	99	0	5	#_SizeSel_P_4_7_CA_REC(7)_BLK3repl_2001 
13.001	65	     34	99	99	0	4	#_SizeSel_P_1_8_OR_REC(8)_BLK4repl_2004 
13.001	65	     34	99	99	0	4	#_SizeSel_P_1_8_OR_REC(8)_BLK4repl_2015 
     0	 9	5.17048	99	99	0	5	#_SizeSel_P_3_8_OR_REC(8)_BLK4repl_2004 
     0	 9	5.17048	99	99	0	5	#_SizeSel_P_3_8_OR_REC(8)_BLK4repl_2015 
     0	 9	5.54518	99	99	0	5	#_SizeSel_P_4_8_OR_REC(8)_BLK4repl_2004 
     0	 9	5.54518	99	99	0	5	#_SizeSel_P_4_8_OR_REC(8)_BLK4repl_2015 
13.001	65	     35	99	99	0	4	#_SizeSel_P_1_9_WA_REC(9)_BLK5repl_2006 
13.001	65	     35	99	99	0	4	#_SizeSel_P_1_9_WA_REC(9)_BLK5repl_2021 
     0	 9	5.21494	99	99	0	5	#_SizeSel_P_3_9_WA_REC(9)_BLK5repl_2006 
     0	 9	5.21494	99	99	0	5	#_SizeSel_P_3_9_WA_REC(9)_BLK5repl_2021 
     0	 9	5.51343	99	99	0	5	#_SizeSel_P_4_9_WA_REC(9)_BLK5repl_2006 
     0	 9	5.51343	99	99	0	5	#_SizeSel_P_4_9_WA_REC(9)_BLK5repl_2021 
# info on dev vectors created for selex parms are reported with other devs after tag parameter section
#
0 #  use 2D_AR1 selectivity(0/1):  experimental feature
#_no 2D_AR1 selex offset used
# Tag loss and Tag reporting parameters go next
0 # TG_custom:  0=no read; 1=read if tags exist
#_Cond -6 6 1 1 2 0.01 -4 0 0 0 0 0 0 0  #_placeholder if no parameters
#
# Input variance adjustments factors: 
#_Data_type	Fleet	Value
    4	 1	0.286935	#_Variance_adjustment_list1 
    5	 1	0.820717	#_Variance_adjustment_list2 
    4	 2	0.272592	#_Variance_adjustment_list3 
    5	 2	0.375911	#_Variance_adjustment_list4 
    4	 3	0.124484	#_Variance_adjustment_list5 
    5	 3	0.217902	#_Variance_adjustment_list6 
    4	 4	0.283865	#_Variance_adjustment_list7 
    4	 5	0.085148	#_Variance_adjustment_list8 
    4	 6	 1.53673	#_Variance_adjustment_list9 
    4	 7	0.100668	#_Variance_adjustment_list10
    4	 8	0.157348	#_Variance_adjustment_list11
    5	 8	0.368951	#_Variance_adjustment_list12
    4	 9	0.795923	#_Variance_adjustment_list13
    5	 9	0.412478	#_Variance_adjustment_list14
    4	11	0.173127	#_Variance_adjustment_list15
    5	11	0.457995	#_Variance_adjustment_list16
    4	12	0.254879	#_Variance_adjustment_list17
    5	12	0.372282	#_Variance_adjustment_list18
    4	16	0.065818	#_Variance_adjustment_list19
    4	17	0.071817	#_Variance_adjustment_list20
    4	18	0.084605	#_Variance_adjustment_list21
    4	19	0.221732	#_Variance_adjustment_list22
    4	20	0.103909	#_Variance_adjustment_list23
    4	21	0.085025	#_Variance_adjustment_list24
    4	22	 0.42445	#_Variance_adjustment_list25
    4	23	0.070767	#_Variance_adjustment_list26
    4	24	0.044152	#_Variance_adjustment_list27
    5	 4	0.764043	#_Variance_adjustment_list28
    5	 5	0.560581	#_Variance_adjustment_list29
    5	 6	 1.44604	#_Variance_adjustment_list30
    5	16	0.992946	#_Variance_adjustment_list31
    5	17	0.270159	#_Variance_adjustment_list32
    5	18	0.364329	#_Variance_adjustment_list33
    5	19	0.303361	#_Variance_adjustment_list34
    5	20	0.091755	#_Variance_adjustment_list35
    5	21	0.921193	#_Variance_adjustment_list36
    5	22	0.203506	#_Variance_adjustment_list37
    5	23	0.216315	#_Variance_adjustment_list38
    5	24	0.656744	#_Variance_adjustment_list39
-9999	 0	       0	#_terminator                
#
1 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 36 changes to default Lambdas (default value is 1.0)
#_like_comp	fleet	phase	value	sizefreq_method
    1	28	1	0	1	#_Surv_28_coastwide_NWFSC_Phz1                        
    1	29	1	0	1	#_Surv_29_coastwide_Tri_early_Phz1                    
    1	30	1	0	1	#_Surv_30_coastwide_Tri_late_Phz1                     
    1	31	1	0	1	#_Surv_31_coastwide_prerec_Phz1                       
    4	28	1	0	1	#_length_28_coastwide_NWFSC_sizefreq_method_1_Phz1    
    4	29	1	0	1	#_length_29_coastwide_Tri_early_sizefreq_method_1_Phz1
    4	30	1	0	1	#_length_30_coastwide_Tri_late_sizefreq_method_1_Phz1 
    4	31	1	0	1	#_length_31_coastwide_prerec_sizefreq_method_1_Phz1   
    5	28	1	0	1	#_age_28_coastwide_NWFSC_Phz1                         
    5	29	1	0	1	#_age_29_coastwide_Tri_early_Phz1                     
    5	30	1	0	1	#_age_30_coastwide_Tri_late_Phz1                      
    5	31	1	0	1	#_age_31_coastwide_prerec_Phz1                        
    4	 1	1	1	1	#_length_1_CA_TWL_sizefreq_method_1_Phz1              
    4	 2	1	1	1	#_length_2_OR_TWL_sizefreq_method_1_Phz1              
    4	 3	1	1	1	#_length_3_WA_TWL_sizefreq_method_1_Phz1              
    4	 4	1	1	1	#_length_4_CA_NTWL_sizefreq_method_1_Phz1             
    4	 5	1	1	1	#_length_5_OR_NTWL_sizefreq_method_1_Phz1             
    4	 6	1	1	1	#_length_6_WA_NTWL_sizefreq_method_1_Phz1             
    4	 7	1	1	1	#_length_7_CA_REC_sizefreq_method_1_Phz1              
    4	 8	1	1	1	#_length_8_OR_REC_sizefreq_method_1_Phz1              
    4	 9	1	1	1	#_length_9_WA_REC_sizefreq_method_1_Phz1              
    4	10	1	0	1	#_length_10_CA_ASHOP_sizefreq_method_1_Phz1           
    4	11	1	1	1	#_length_11_OR_ASHOP_sizefreq_method_1_Phz1           
    4	12	1	1	1	#_length_12_WA_ASHOP_sizefreq_method_1_Phz1           
    5	 1	1	1	1	#_age_1_CA_TWL_Phz1                                   
    5	 2	1	1	1	#_age_2_OR_TWL_Phz1                                   
    5	 3	1	1	1	#_age_3_WA_TWL_Phz1                                   
    5	 4	1	1	1	#_age_4_CA_NTWL_Phz1                                  
    5	 5	1	1	1	#_age_5_OR_NTWL_Phz1                                  
    5	 6	1	1	1	#_age_6_WA_NTWL_Phz1                                  
    5	 7	1	0	1	#_age_7_CA_REC_Phz1                                   
    5	 8	1	1	1	#_age_8_OR_REC_Phz1                                   
    5	 9	1	1	1	#_age_9_WA_REC_Phz1                                   
    5	10	1	0	1	#_age_10_CA_ASHOP_Phz1                                
    5	11	1	1	1	#_age_11_OR_ASHOP_Phz1                                
    5	12	1	1	1	#_age_12_WA_ASHOP_Phz1                                
-9999	 0	0	0	0	#_terminator                                          
#
0 # 0/1 read specs for more stddev reporting
#
999
