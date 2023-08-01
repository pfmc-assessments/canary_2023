#V3.30
#C file created using the SS_writectl function in the R package r4ss
#C file write time: 2023-02-23 16:53:24
#
0 # 0 means do not read wtatage.ss; 1 means read and usewtatage.ss and also read and use growth parameters
1 #_N_Growth_Patterns
1 #_N_platoons_Within_GrowthPattern
4 # recr_dist_method for parameters
1 # not yet implemented; Future usage:Spawner-Recruitment; 1=global; 2=by area
1 # number of recruitment settlement assignments 
0 # unused option
# for each settlement assignment:
#_GPattern	month	area	age
1	1	1	0	#_recr_dist_pattern1
#
#_Cond 0 # N_movement_definitions goes here if N_areas > 1
#_Cond 1.0 # first age that moves (real age at begin of season, not integer) also cond on do_migration>0
#_Cond 1 1 1 2 4 10 # example move definition for seas=1, morph=1, source=1 dest=2, age1=4, age2=10
#
6 #_Nblock_Patterns
3 2 2 2 1 1 #_blocks_per_pattern
#_begin and end years of blocks
2000 2010 2011 2016 2017 2022
2000 2019 2020 2022
2004 2016 2017 2022
2004 2014 2015 2022
2006 2020
2000 2019
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
 0.02	     0.2	0.0776377	   -2.74	 0.31	3	  2	0	0	0	0	0	0	0	#_NatM_p_1_Fem_GP_1  
    2	      15	  8.16063	       4	   50	0	  3	0	0	0	0	0	0	0	#_L_at_Amin_Fem_GP_1 
   50	      70	  59.2157	      60	   50	0	  3	0	0	0	0	0	0	0	#_L_at_Amax_Fem_GP_1 
 0.02	    0.21	 0.139011	    0.14	   50	0	  3	0	0	0	0	0	0	0	#_VonBert_K_Fem_GP_1 
 0.02	    0.21	0.0898625	    0.15	   50	0	  4	0	0	0	0	0	0	0	#_CV_young_Fem_GP_1  
 0.01	    0.21	0.0386633	   0.028	   50	0	  4	0	0	0	0	0	0	0	#_CV_old_Fem_GP_1    
    0	     0.1	 1.19e-05	1.19e-05	   50	0	-50	0	0	0	0	0	0	0	#_Wtlen_1_Fem_GP_1   
    2	       4	     3.09	    3.09	   50	0	-50	0	0	0	0	0	0	0	#_Wtlen_2_Fem_GP_1   
    9	      12	    10.87	   10.87	0.055	0	-50	0	0	0	0	0	0	0	#_Mat50%_Fem_GP_1    
   -3	       3	   -0.688	  -0.688	   50	0	-50	0	0	0	0	0	0	0	#_Mat_slope_Fem_GP_1 
1e-10	     0.1	7.218e-08	-16.4441	0.135	0	-50	0	0	0	0	0	0	0	#_Eggs_alpha_Fem_GP_1
    2	       6	    4.043	   4.043	  0.3	0	-50	0	0	0	0	0	0	0	#_Eggs_beta_Fem_GP_1 
 0.02	     0.2	   0.0643	   -2.74	 0.31	3	-50	0	0	0	0	0	0	0	#_NatM_p_1_Mal_GP_1  
    0	      15	        0	       0	   50	0	-50	0	0	0	0	0	0	0	#_L_at_Amin_Mal_GP_1 
   50	      70	  53.7305	      60	   50	0	  3	0	0	0	0	0	0	0	#_L_at_Amax_Mal_GP_1 
 0.02	    0.21	 0.162337	    0.14	   50	0	  3	0	0	0	0	0	0	0	#_VonBert_K_Mal_GP_1 
 0.02	    0.21	0.0976229	    0.15	   50	0	  4	0	0	0	0	0	0	0	#_CV_young_Mal_GP_1  
 0.01	    0.21	0.0462806	   0.028	   50	0	  4	0	0	0	0	0	0	0	#_CV_old_Mal_GP_1    
    0	     0.1	 1.08e-05	1.08e-05	   50	0	-50	0	0	0	0	0	0	0	#_Wtlen_1_Mal_GP_1   
    2	       4	    3.118	   3.118	   50	0	-50	0	0	0	0	0	0	0	#_Wtlen_2_Mal_GP_1   
   -1	       1	        1	       1	   50	0	-50	0	0	0	0	0	0	0	#_CohortGrowDev      
1e-06	0.999999	      0.5	     0.5	  0.5	0	-99	0	0	0	0	0	0	0	#_FracFemale_GP_1    
#_no timevary MG parameters
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
   7	  11	8.22989	 8.5	  50	0	  1	0	0	0	0	0	0	0	#_SR_LN(R0)  
0.21	0.99	   0.72	0.72	0.16	2	 -6	0	0	0	0	0	0	0	#_SR_BH_steep
   0	   2	    0.5	 0.4	  50	0	-50	0	0	0	0	0	0	0	#_SR_sigmaR  
  -5	   5	      0	   0	  50	0	-50	0	0	0	0	0	0	0	#_SR_regime  
   0	   2	      0	   1	  50	0	-50	0	0	0	0	0	0	0	#_SR_autocorr
#_no timevary SR parameters
1 #do_recdev:  0=none; 1=devvector (R=F(SSB)+dev); 2=deviations (R=F(SSB)+dev); 3=deviations (R=R0*dev; dev2=R-f(SSB)); 4=like 3 with sum(dev2) adding penalty
1960 # first year of main recr_devs; early devs can preceed this era
2022 # last year of main recr_devs; forecast devs start in following year
5 #_recdev phase
1 # (0/1) to read 13 advanced options
1892 #_recdev_early_start (0=none; neg value makes relative to recdev_start)
5 #_recdev_early_phase
6 #_forecast_recruitment phase (incl. late recr) (0 value resets to maxphase+1)
1 #_lambda for Fcast_recr_like occurring before endyr+1
1965.76 #_last_yr_nobias_adj_in_MPD; begin of ramp
1978 #_first_yr_fullbias_adj_in_MPD; begin of plateau
2020 #_last_yr_fullbias_adj_in_MPD
2022 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS sets bias_adj to 0.0 for fcast yrs)
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
   28	1	 0	0	0	1	#_28_coastwide_NWFSC    
   29	1	 0	0	0	0	#_29_coastwide_Tri_early
   30	2	29	0	0	0	#_30_coastwide_Tri_late 
   31	1	 0	1	0	1	#_31_coastwide_prerec   
-9999	0	 0	0	0	0	#_terminator            
#_Q_parms(if_any);Qunits_are_ln(q)
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE	env-var	use_dev	dev_mnyr	dev_mxyr	dev_PH	Block	Blk_Fxn  #  parm_name
-25	25	-0.779131	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_28_coastwide_NWFSC(28)    
-25	25	 -1.29613	  0	 1	0	 2	0	0	0	0	0	0	0	#_LnQ_base_29_coastwide_Tri_early(29)
-25	25	 -1.29613	  0	 1	0	 2	0	0	0	0	0	0	0	#_LnQ_base_30_coastwide_Tri_late(30) 
-25	25	 -2.76255	  0	 1	0	-1	0	0	0	0	0	0	0	#_LnQ_base_31_coastwide_prerec(31)   
  0	 3	 0.504921	0.1	99	0	 2	0	0	0	0	0	0	0	#_Q_extraSD_31_coastwide_prerec(31)  
#_no timevary Q parameters
#
#_size_selex_patterns
#_Pattern	Discard	Male	Special
24	0	4	 0	#_1 1_CA_TWL               
24	0	4	 0	#_2 2_OR_TWL               
15	0	0	 2	#_3 3_WA_TWL               
24	0	4	 0	#_4 4_CA_NTWL              
24	0	4	 0	#_5 5_OR_NTWL              
24	0	4	 0	#_6 6_WA_NTWL              
24	0	4	 0	#_7 7_CA_REC               
24	0	4	 0	#_8 8_OR_REC               
24	0	4	 0	#_9 9_WA_REC               
24	0	4	 0	#_10 10_CA_ASHOP           
15	0	0	10	#_11 11_OR_ASHOP           
15	0	0	10	#_12 12_WA_ASHOP           
15	0	0	 1	#_13 13_CA_FOR             
15	0	0	 2	#_14 14_OR_FOR             
15	0	0	 3	#_15 15_WA_FOR             
 0	0	0	 0	#_16 16_CA_NWFSC           
 0	0	0	 0	#_17 17_OR_NWFSC           
 0	0	0	 0	#_18 18_WA_NWFSC           
 0	0	0	 0	#_19 19_CA_Tri_early       
 0	0	0	 0	#_20 20_OR_Tri_early       
 0	0	0	 0	#_21 21_WA_Tri_early       
 0	0	0	 0	#_22 22_CA_Tri_late        
 0	0	0	 0	#_23 23_OR_Tri_late        
 0	0	0	 0	#_24 24_WA_Tri_late        
 0	0	0	 0	#_25 25_CA_prerec          
 0	0	0	 0	#_26 26_OR_prerec          
 0	0	0	 0	#_27 27_WA_prerec          
24	0	4	 0	#_28 28_coastwide_NWFSC    
24	0	4	 0	#_29 29_coastwide_Tri_early
15	0	0	29	#_30 30_coastwide_Tri_late 
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
13.001	65	 45.2923	99	99	0	  4	0	0	0	0	0	1	2	#_SizeSel_P_1_1_CA_TWL(1)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_1_CA_TWL(1)                     
     0	 9	 4.31004	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_3_1_CA_TWL(1)                     
     0	 9	 3.48156	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_4_1_CA_TWL(1)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_1_CA_TWL(1)                     
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_1_CA_TWL(1)                     
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_1_CA_TWL(1)               
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_1_CA_TWL(1)               
    -9	 9	 1.40121	 0	50	0	  5	0	0	0	0	0	1	2	#_SizeSel_PFemOff_3_1_CA_TWL(1)               
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_1_CA_TWL(1)               
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_1_CA_TWL(1)               
13.001	65	  49.484	99	99	0	  4	0	0	0	0	0	1	2	#_SizeSel_P_1_2_OR_TWL(2)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_2_OR_TWL(2)                     
     0	 9	 4.18325	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_3_2_OR_TWL(2)                     
     0	 9	 2.60804	99	99	0	  5	0	0	0	0	0	1	2	#_SizeSel_P_4_2_OR_TWL(2)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_2_OR_TWL(2)                     
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_2_OR_TWL(2)                     
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_2_OR_TWL(2)               
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_2_OR_TWL(2)               
    -9	 9	  2.2559	 0	50	0	  5	0	0	0	0	0	1	2	#_SizeSel_PFemOff_3_2_OR_TWL(2)               
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_2_OR_TWL(2)               
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_2_OR_TWL(2)               
13.001	65	 36.4791	99	99	0	  4	0	0	0	0	0	2	2	#_SizeSel_P_1_4_CA_NTWL(4)                    
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_4_CA_NTWL(4)                    
     0	 9	  4.2639	99	99	0	  5	0	0	0	0	0	2	2	#_SizeSel_P_3_4_CA_NTWL(4)                    
     0	 9	 4.64103	99	99	0	  5	0	0	0	0	0	2	2	#_SizeSel_P_4_4_CA_NTWL(4)                    
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_4_CA_NTWL(4)                    
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_4_CA_NTWL(4)                    
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_4_CA_NTWL(4)              
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_4_CA_NTWL(4)              
    -9	 9	0.702408	 0	50	0	  5	0	0	0	0	0	2	2	#_SizeSel_PFemOff_3_4_CA_NTWL(4)              
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_4_CA_NTWL(4)              
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_4_CA_NTWL(4)              
13.001	65	 31.0559	99	99	0	  4	0	0	0	0	0	6	2	#_SizeSel_P_1_5_OR_NTWL(5)                    
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_5_OR_NTWL(5)                    
    -9	 9	-7.36158	99	99	0	  5	0	0	0	0	0	6	2	#_SizeSel_P_3_5_OR_NTWL(5)                    
    -9	 9	 6.18587	99	99	0	  5	0	0	0	0	0	6	2	#_SizeSel_P_4_5_OR_NTWL(5)                    
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_5_OR_NTWL(5)                    
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_5_OR_NTWL(5)                    
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_5_OR_NTWL(5)              
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_5_OR_NTWL(5)              
    -9	 9	 7.98354	 0	50	0	  5	0	0	0	0	0	6	2	#_SizeSel_PFemOff_3_5_OR_NTWL(5)              
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_5_OR_NTWL(5)              
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_5_OR_NTWL(5)              
13.001	65	 46.3744	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_6_WA_NTWL(6)                    
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_6_WA_NTWL(6)                    
    -9	 9	 3.43912	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_6_WA_NTWL(6)                    
    -9	 9	 2.53845	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_6_WA_NTWL(6)                    
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_6_WA_NTWL(6)                    
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_6_WA_NTWL(6)                    
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_6_WA_NTWL(6)              
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_6_WA_NTWL(6)              
    -9	 9	 2.87698	 0	50	0	  5	0	0	0	0	0	0	0	#_SizeSel_PFemOff_3_6_WA_NTWL(6)              
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_6_WA_NTWL(6)              
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_6_WA_NTWL(6)              
13.001	65	 28.8139	99	99	0	  4	0	0	0	0	0	3	2	#_SizeSel_P_1_7_CA_REC(7)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_7_CA_REC(7)                     
     0	 9	 3.47872	99	99	0	  5	0	0	0	0	0	3	2	#_SizeSel_P_3_7_CA_REC(7)                     
     0	 9	 4.82554	99	99	0	  5	0	0	0	0	0	3	2	#_SizeSel_P_4_7_CA_REC(7)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_7_CA_REC(7)                     
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_7_CA_REC(7)                     
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_7_CA_REC(7)               
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_7_CA_REC(7)               
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	3	2	#_SizeSel_PFemOff_3_7_CA_REC(7)               
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_7_CA_REC(7)               
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_7_CA_REC(7)               
13.001	65	 30.9417	99	99	0	  4	0	0	0	0	0	4	2	#_SizeSel_P_1_8_OR_REC(8)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_8_OR_REC(8)                     
    -9	 9	  3.1314	99	99	0	  5	0	0	0	0	0	4	2	#_SizeSel_P_3_8_OR_REC(8)                     
    -9	 9	 3.23693	99	99	0	  5	0	0	0	0	0	4	2	#_SizeSel_P_4_8_OR_REC(8)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_8_OR_REC(8)                     
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_8_OR_REC(8)                     
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_8_OR_REC(8)               
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_8_OR_REC(8)               
    -9	 9	 2.31032	 0	50	0	  5	0	0	0	0	0	4	2	#_SizeSel_PFemOff_3_8_OR_REC(8)               
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_8_OR_REC(8)               
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_8_OR_REC(8)               
13.001	65	 34.9639	99	99	0	  4	0	0	0	0	0	5	2	#_SizeSel_P_1_9_WA_REC(9)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_9_WA_REC(9)                     
    -9	 9	 3.32032	99	99	0	  5	0	0	0	0	0	5	2	#_SizeSel_P_3_9_WA_REC(9)                     
    -9	 9	 5.26733	99	99	0	  5	0	0	0	0	0	5	2	#_SizeSel_P_4_9_WA_REC(9)                     
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_9_WA_REC(9)                     
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_9_WA_REC(9)                     
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_9_WA_REC(9)               
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_9_WA_REC(9)               
    -9	 9	 2.46743	 0	50	0	  5	0	0	0	0	0	5	2	#_SizeSel_PFemOff_3_9_WA_REC(9)               
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_9_WA_REC(9)               
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_9_WA_REC(9)               
13.001	65	 43.5526	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_10_CA_ASHOP(10)                 
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_10_CA_ASHOP(10)                 
     0	 9	 2.46968	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_10_CA_ASHOP(10)                 
     0	 9	 2.88819	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_10_CA_ASHOP(10)                 
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_10_CA_ASHOP(10)                 
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_10_CA_ASHOP(10)                 
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_10_CA_ASHOP(10)           
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_10_CA_ASHOP(10)           
    -9	 9	 2.32625	 0	50	0	  5	0	0	0	0	0	0	0	#_SizeSel_PFemOff_3_10_CA_ASHOP(10)           
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_10_CA_ASHOP(10)           
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_10_CA_ASHOP(10)           
13.001	65	 49.1264	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_28_coastwide_NWFSC(28)          
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_28_coastwide_NWFSC(28)          
     0	 9	 7.02849	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_28_coastwide_NWFSC(28)          
     0	 9	 1.74668	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_28_coastwide_NWFSC(28)          
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_28_coastwide_NWFSC(28)          
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_28_coastwide_NWFSC(28)          
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_28_coastwide_NWFSC(28)    
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_28_coastwide_NWFSC(28)    
    -9	 9	 2.67984	 0	50	0	  5	0	0	0	0	0	0	0	#_SizeSel_PFemOff_3_28_coastwide_NWFSC(28)    
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_28_coastwide_NWFSC(28)    
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_28_coastwide_NWFSC(28)    
13.001	65	 59.0435	99	99	0	  4	0	0	0	0	0	0	0	#_SizeSel_P_1_29_coastwide_Tri_early(29)      
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_2_29_coastwide_Tri_early(29)      
     0	 9	 6.58358	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_3_29_coastwide_Tri_early(29)      
     0	 9	 5.42918	99	99	0	  5	0	0	0	0	0	0	0	#_SizeSel_P_4_29_coastwide_Tri_early(29)      
   -99	99	     -15	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_5_29_coastwide_Tri_early(29)      
   -99	99	    -999	99	99	0	-99	0	0	0	0	0	0	0	#_SizeSel_P_6_29_coastwide_Tri_early(29)      
   -25	25	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_1_29_coastwide_Tri_early(29)
    -9	 9	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_2_29_coastwide_Tri_early(29)
    -9	 9	 3.18945	 0	50	0	  5	0	0	0	0	0	0	0	#_SizeSel_PFemOff_3_29_coastwide_Tri_early(29)
   -99	99	       0	 0	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_4_29_coastwide_Tri_early(29)
     0	 2	       1	 1	50	0	-99	0	0	0	0	0	0	0	#_SizeSel_PFemOff_5_29_coastwide_Tri_early(29)
#_AgeSelex
#_No age_selex_parm
# timevary selex parameters 
#_LO	HI	INIT	PRIOR	PR_SD	PR_type	PHASE
13.001	65	 45.2923	99	99	0	  4	#_SizeSel_P_1_1_CA_TWL(1)_BLK1repl_2000       
13.001	65	 45.2923	99	99	0	  4	#_SizeSel_P_1_1_CA_TWL(1)_BLK1repl_2011       
13.001	65	 45.2923	99	99	0	  4	#_SizeSel_P_1_1_CA_TWL(1)_BLK1repl_2017       
     0	 9	 4.31004	99	99	0	  5	#_SizeSel_P_3_1_CA_TWL(1)_BLK1repl_2000       
     0	 9	 4.31004	99	99	0	  5	#_SizeSel_P_3_1_CA_TWL(1)_BLK1repl_2011       
     0	 9	 4.31004	99	99	0	  5	#_SizeSel_P_3_1_CA_TWL(1)_BLK1repl_2017       
     0	 9	 3.48156	99	99	0	  5	#_SizeSel_P_4_1_CA_TWL(1)_BLK1repl_2000       
     0	 9	 3.48156	99	99	0	  5	#_SizeSel_P_4_1_CA_TWL(1)_BLK1repl_2011       
     0	 9	 3.48156	99	99	0	  5	#_SizeSel_P_4_1_CA_TWL(1)_BLK1repl_2017       
    -9	 9	 1.40121	 0	50	0	  5	#_SizeSel_PFemOff_3_1_CA_TWL(1)_BLK1repl_2000 
    -9	 9	 1.40121	 0	50	0	  5	#_SizeSel_PFemOff_3_1_CA_TWL(1)_BLK1repl_2011 
    -9	 9	 1.40121	 0	50	0	  5	#_SizeSel_PFemOff_3_1_CA_TWL(1)_BLK1repl_2017 
13.001	65	  49.484	99	99	0	  4	#_SizeSel_P_1_2_OR_TWL(2)_BLK1repl_2000       
13.001	65	  49.484	99	99	0	  4	#_SizeSel_P_1_2_OR_TWL(2)_BLK1repl_2011       
13.001	65	  49.484	99	99	0	  4	#_SizeSel_P_1_2_OR_TWL(2)_BLK1repl_2017       
     0	 9	 4.18325	99	99	0	  5	#_SizeSel_P_3_2_OR_TWL(2)_BLK1repl_2000       
     0	 9	 4.18325	99	99	0	  5	#_SizeSel_P_3_2_OR_TWL(2)_BLK1repl_2011       
     0	 9	 4.18325	99	99	0	  5	#_SizeSel_P_3_2_OR_TWL(2)_BLK1repl_2017       
     0	 9	 2.60804	99	99	0	  5	#_SizeSel_P_4_2_OR_TWL(2)_BLK1repl_2000       
     0	 9	 2.60804	99	99	0	  5	#_SizeSel_P_4_2_OR_TWL(2)_BLK1repl_2011       
     0	 9	 2.60804	99	99	0	  5	#_SizeSel_P_4_2_OR_TWL(2)_BLK1repl_2017       
    -9	 9	  2.2559	 0	50	0	  5	#_SizeSel_PFemOff_3_2_OR_TWL(2)_BLK1repl_2000 
    -9	 9	  2.2559	 0	50	0	  5	#_SizeSel_PFemOff_3_2_OR_TWL(2)_BLK1repl_2011 
    -9	 9	  2.2559	 0	50	0	  5	#_SizeSel_PFemOff_3_2_OR_TWL(2)_BLK1repl_2017 
13.001	65	 36.4791	99	99	0	  4	#_SizeSel_P_1_4_CA_NTWL(4)_BLK2repl_2000      
13.001	65	 36.4791	99	99	0	  4	#_SizeSel_P_1_4_CA_NTWL(4)_BLK2repl_2020      
     0	 9	  4.2639	99	99	0	  5	#_SizeSel_P_3_4_CA_NTWL(4)_BLK2repl_2000      
     0	 9	  4.2639	99	99	0	  5	#_SizeSel_P_3_4_CA_NTWL(4)_BLK2repl_2020      
     0	 9	 4.64103	99	99	0	  5	#_SizeSel_P_4_4_CA_NTWL(4)_BLK2repl_2000      
     0	 9	 4.64103	99	99	0	  5	#_SizeSel_P_4_4_CA_NTWL(4)_BLK2repl_2020      
    -9	 9	0.702408	 0	50	0	  5	#_SizeSel_PFemOff_3_4_CA_NTWL(4)_BLK2repl_2000
    -9	 9	0.702408	 0	50	0	  5	#_SizeSel_PFemOff_3_4_CA_NTWL(4)_BLK2repl_2020
13.001	65	 31.0559	99	99	0	  4	#_SizeSel_P_1_5_OR_NTWL(5)_BLK6repl_2000      
    -9	 9	-7.36158	99	99	0	  5	#_SizeSel_P_3_5_OR_NTWL(5)_BLK6repl_2000      
    -9	 9	 6.18587	99	99	0	  5	#_SizeSel_P_4_5_OR_NTWL(5)_BLK6repl_2000      
    -9	 9	 7.98354	 0	50	0	  5	#_SizeSel_PFemOff_3_5_OR_NTWL(5)_BLK6repl_2000
13.001	65	 28.8139	99	99	0	  4	#_SizeSel_P_1_7_CA_REC(7)_BLK3repl_2004       
13.001	65	 28.8139	99	99	0	  4	#_SizeSel_P_1_7_CA_REC(7)_BLK3repl_2017       
     0	 9	 3.47872	99	99	0	  5	#_SizeSel_P_3_7_CA_REC(7)_BLK3repl_2004       
     0	 9	 3.47872	99	99	0	  5	#_SizeSel_P_3_7_CA_REC(7)_BLK3repl_2017       
     0	 9	 4.82554	99	99	0	  5	#_SizeSel_P_4_7_CA_REC(7)_BLK3repl_2004       
     0	 9	 4.82554	99	99	0	  5	#_SizeSel_P_4_7_CA_REC(7)_BLK3repl_2017       
    -9	 9	       0	 0	50	0	-99	#_SizeSel_PFemOff_3_7_CA_REC(7)_BLK3repl_2004 
    -9	 9	       0	 0	50	0	-99	#_SizeSel_PFemOff_3_7_CA_REC(7)_BLK3repl_2017 
13.001	65	 30.9417	99	99	0	  4	#_SizeSel_P_1_8_OR_REC(8)_BLK4repl_2004       
13.001	65	 30.9417	99	99	0	  4	#_SizeSel_P_1_8_OR_REC(8)_BLK4repl_2015       
    -9	 9	  3.1314	99	99	0	  5	#_SizeSel_P_3_8_OR_REC(8)_BLK4repl_2004       
    -9	 9	  3.1314	99	99	0	  5	#_SizeSel_P_3_8_OR_REC(8)_BLK4repl_2015       
    -9	 9	 3.23693	99	99	0	  5	#_SizeSel_P_4_8_OR_REC(8)_BLK4repl_2004       
    -9	 9	 3.23693	99	99	0	  5	#_SizeSel_P_4_8_OR_REC(8)_BLK4repl_2015       
    -9	 9	       0	 0	50	0	-99	#_SizeSel_PFemOff_3_8_OR_REC(8)_BLK4repl_2004 
    -9	 9	 2.31032	 0	50	0	  5	#_SizeSel_PFemOff_3_8_OR_REC(8)_BLK4repl_2015 
13.001	65	 34.9639	99	99	0	  4	#_SizeSel_P_1_9_WA_REC(9)_BLK5repl_2006       
    -9	 9	 3.32032	99	99	0	  5	#_SizeSel_P_3_9_WA_REC(9)_BLK5repl_2006       
    -9	 9	 5.26733	99	99	0	  5	#_SizeSel_P_4_9_WA_REC(9)_BLK5repl_2006       
    -9	 9	 2.46743	 0	50	0	  5	#_SizeSel_PFemOff_3_9_WA_REC(9)_BLK5repl_2006 
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
    4	 1	0.240492	#_Variance_adjustment_list1 
    5	 1	 1.25386	#_Variance_adjustment_list2 
    4	 2	0.257366	#_Variance_adjustment_list3 
    5	 2	 0.24574	#_Variance_adjustment_list4 
    4	 3	0.198837	#_Variance_adjustment_list5 
    5	 3	0.210923	#_Variance_adjustment_list6 
    4	 4	0.211897	#_Variance_adjustment_list7 
    4	 5	  0.0833	#_Variance_adjustment_list8 
    4	 6	 1.66921	#_Variance_adjustment_list9 
    4	 7	0.157959	#_Variance_adjustment_list10
    5	 8	 1.48788	#_Variance_adjustment_list11
    4	 9	 0.93728	#_Variance_adjustment_list12
    5	 9	0.818006	#_Variance_adjustment_list13
    4	11	0.190467	#_Variance_adjustment_list14
    5	11	0.473512	#_Variance_adjustment_list15
    4	12	0.103997	#_Variance_adjustment_list16
    5	12	 0.10624	#_Variance_adjustment_list17
    4	16	   0.081	#_Variance_adjustment_list18
    4	17	   0.081	#_Variance_adjustment_list19
    4	18	   0.081	#_Variance_adjustment_list20
    4	19	   0.093	#_Variance_adjustment_list21
    4	20	   0.093	#_Variance_adjustment_list22
    4	21	   0.093	#_Variance_adjustment_list23
    4	22	   0.114	#_Variance_adjustment_list24
    4	23	   0.114	#_Variance_adjustment_list25
    4	24	   0.114	#_Variance_adjustment_list26
    4	 8	0.258734	#_Variance_adjustment_list27
    4	28	0.046829	#_Variance_adjustment_list28
    4	29	0.103277	#_Variance_adjustment_list29
    4	30	0.046847	#_Variance_adjustment_list30
    5	 4	0.515112	#_Variance_adjustment_list31
    5	 5	0.700894	#_Variance_adjustment_list32
    5	 6	 1.09996	#_Variance_adjustment_list33
    5	28	0.205077	#_Variance_adjustment_list34
    5	29	0.118712	#_Variance_adjustment_list35
    5	30	0.183054	#_Variance_adjustment_list36
-9999	 0	       0	#_terminator                
#
1 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 0 changes to default Lambdas (default value is 1.0)
-9999 0 0 0 0 # terminator
#
0 # 0/1 read specs for more stddev reporting
#
999
