# Control file for 2009 canary assessment update
# updated to run in SSv3.20

# Morph setup
1	# Number of growth patterns
1	# N sub morphs within growth patterns

### BEGIN SPATIAL MODEL HERE
3 # Number of recruitment assignments
0 # Recruitment interaction requested?
1 1 1 # Recruitment assignment to GP 1, seas 1, area 1
1 1 2 # Recruitment assignment to GP 1, seas 1, area 2
1 1 3 # Recruitment assignment to GP 1, seas 1, area 3

# BEGIN NO MOVEMENT
0 # N movement definitions
# END NO MOVEMENT

# BEGIN MOVEMENT
#4 # N movement definitions
#3 # First age that moves
# Season, GP, source area, destination area, min-age, max-age
#1 1 1 2 3 9.3
#1 1 2 1 3 9.3
#1 1 2 3 3 9.3
#1 1 3 2 3 9.3
# END MOVEMENT
### END SPATIAL MODEL HERE

# Time block setup
2	# Number of time block designs for time varying parameters
1 2 # Number of blocks per design
2000 2014                   # Block Design 15: ITQ
2000 2010 2011 2014

# Mortality and growth specifications
0.5 	# Fraction female at birth
1	# M setup: 0=single Par,1=N_breakpoints,2=Lorenzen,3=agespecific;_4=agespec_withseasinterpolate
2	# Number of M breakpoints
6 14	# Ages at M breakpoints
1 	# Growth model: 1=VB with L1 and L2, 2=VB with A0 and Linf, 3=Richards, 4=Read vector of L@A 
1	# Age for growth Lmin
30	# Age for growth Lmax
0.0 	# SD constant added to LAA (0.1 mimics v1.xx for compatibility only) 
0 	# Variability about growth: 0=CV~f(LAA) [mimic v1.xx], 1=CV~f(A), 2=SD~f(LAA), 3=SD~f(A)
6 	# maturity option: 1=length logistic, 2=age logistic, 3=read maturity at age for each growth pattern
6.80E-06	1.39E-05	2.85E-05	5.83E-05	0.000119295	0.000244164	0.000499664	0.001022235	0.002090105	0.004268391	0.008695585	0.01762724	0.035380676	0.069649514	0.132204702	0.235558822	0.381109289	0.54588792	0.692065911	0.796225088	0.859413184	0.894075434	0.912045701	0.921089804	0.925573571	0.927779894	0.928861558	0.929390891	0.929649701	0.929776188
2 	# First age allowed to mature
1   # fecundity option (1=linear eggs/kg relationship; EJ recommendation)
0  	# hermaphro
3	# mg parm offset option: 
1	# mg parm adjust method 1=do V1.23 approach, 2=use logistic transform between bounds approach

# Mortality and growth parameters
# Lo	Hi	Init	Prior	Prior	Prior	Param	Env	Use	Dev	Dev	Dev	Block	block
# bnd	bnd  	value	mean	type	SD	phase	var	dev	minyr	maxyr	SD	design	switch
# Females
0.04	  0.08	  0.0521	 -2.9551	3   0.5323	-50	0	0	0	0	0.5	0	0	#M1_natM_young
0	      0.9	    0.45	   0.4	    -1	50	     3	0	0	0	0	0.5	0	0	#M1_natM_old_as_exponential_offset(rel_young)
2	      15      3.8	     4	      -1	50	     2	0	0	0	0	0.5	0	0	#M1_Lmin
50	    70	    60.0	   60	      -1	50	     2	0	0	0	0	0.5	0	0	#M1_Lmax
0.02	  0.21	  0.14	   0.14	    -1	50	     2	0	0	0	0	0.5	0	0	#M1_VBK
0.02	  0.21	  0.14	   0.15	    -1	50	     2	0	0	0	0	0.5	0	0	#M1_CV-young
-3	    3	     -1.3	     -1.3	    -1	50	     2	0	0	0	0	0.5	0	0	#M1_CV-old_as_exponential_offset(rel_young)
# Males
-3	    3	      0	       0	      0	  50	    -50	0	0	0	0	0.5	0	0	#M2_natM_young_as_exponential_offset(rel_morph_1)
-3	    3       0	       0	      0	  50	    -50	0	0	0	0	0.5	0	0	#M2_natM_old_as_exponential_offset(rel_young)
-3      3	      0	       0	      0	  50	    -50	0	0	0	0	0.5	0	0	#M2_Lmin_as_exponential_offset
-3      3	      -0.12	   0	      -1	50	      2	0	0	0	0	0.5	0	0	#M2_Lmax_as_exponential_offset
-3      3	      0.24	   0	      -1	50	      2	0	0	0	0	0.5	0	0	#M2_VBK_as_exponential_offset
-3      3	      0.04	   0	      -1	50	      2	0	0	0	0	0.5	0	0	#M2_CV-young_as_exponential_offset(rel_CV-young_for_morph_1)
-3      3	      -1.3	   0	      -1	50	      2	0	0	0	0	0.5	0	0	#M2_CV-old_as_exponential_offset(rel_CV-young)
# Weight-Length and maturity parameters (L in cm, W in kg)
# Lo	Hi	Init	Prior	Prior	Prior	Param	Env	Use	Dev	Dev	Dev	Block	block
# bnd	bnd  	value	mean	type	SD	phase	var	dev	minyr	maxyr	SD	design	switch
# Females
0	      1	      1.180e-5 1.55E-05 0	  50	   -50	0	0	0	0	0.5	0	0	#Female wt-len-1
2	      4	      3.094	   3.03	    0	  50	   -50	0	0	0	0	0.5	0	0	#Female wt-len-2
40	    41	    40.5	   40.5	    0	  50	   -50	0	0	0	0	0.5	0	0	#Female mat-len-1
-3	    3	     -0.25	  -0.25	    0	  50	   -50	0	0	0	0	0.5	0	0	#Female mat-len-2
-3	    3	      0.2619	 1.0	    0	  50	   -50	0	0	0	0	0.5	0	0	#Female eggs/gm intercept
-1	    1	      0.0217	 0.0	    0	  50	   -50	0	0	0	0	0.5	0	0	#Female eggs/gm slope
# Males
0	      1	      1.064e-5 1.55E-05 0	  50	   -50	0	0	0	0	0.5	0	0	#Female wt-len-1
2	      4	      3.123	   3.03	    0	  50	   -50	0	0	0	0	0.5	0	0	#Female wt-len-2

# Distribute recruitment among growth pattern x area x season
0	999	1	1	0	50	-50	0	0	0	0	0.5	0	0	# GP 1
#-4	4	-0.3567 1	-1	50 -1	0	1	1960	2014	0.5	0	0	# Area 1
#-4	4	-1.6094 1	-1	50 -1	0	1	1960	2014	0.5	0	0	# Area 1
#-4	4	-2.3026 1	-1	50 -1	0	1	1960	2014	0.5	0	0	# Area 1
#-4	4	-0.3567 1	-1	50 -1	0	0 0 0 0	0	0	# Area 1
#-4	4	-1.6094 1	-1	50 -1	0	0 0 0 0	0	0	# Area 1
#-4	4	-2.3026 1	-1	50 -1	0	0 0 0 0	0	0	# Area 1
-7	7	0 1	-1	50 -1	0	0 0 0 0	0	0	# Area 1
-7	7	0 1	-1	50 1	0	1	1933	2014	0.5	0	0	# Area 1
-7	7	0 1	-1	50 1	0	1	1933	2014	0.5	0	0	# Area 1
0	999	1	1	0	50	-50	0	0	0	0	0.5	0	0	# Season 1
# Cohort growth (K) deviation parameter
-1	1	1	1	0	50	-50	0	0	1980	1983	0.5	0	0

# Movement parameters (M=0.04 -> -3.135
#-10000	5	-6.908	1	-1	50	-6	0	0	0	0	0	0	0
#-8	0	-4.605	1	-1	50	6	0	0	0	0	0	0	0
#-10000	5	-9999	1	-1	50	-6	0	0	0	0	0	0	0
#-10000	5	-9999	1	-1	50	-6	0	0	0	0	0	0	0
#-10000	5	-9999	1	-1	50	-6	0	0	0	0	0	0	0
#-10000	5	-9999	1	-1	50	-6	0	0	0	0	0	0	0
#-10000	5	-9999	1	-1	50	-6	0	0	0	0	0	0	0
#-10000	5	-9999	1	-1	50	-6	0	0	0	0	0	0	0
#
# MGparm_seas_effects: Seasonal effects on biology parameters (0=none)
 0 0 0 0 0 0 0 0 0 0

5 # Phase for MG_devs (only needed if some MG is time-varying)
 
# Spawner-recruit parameters
3	# S-R function: 1=null, 2=Ricker, 3=standard B-H, 4=no steepness or bias adjustment; 5=Hockey stock; 6=flat-top BH
# Lo	Hi	Init	Prior	Prior	Prior	Param
# bnd	bnd	value	mean	type	SD	phase
 7	11	8.5	8.5	-1	50	1	# Ln(R0)
 0.21	0.99	0.773	0.4	0	50	-6	# Steepness
 0	2	0.5	0.4	0	50	-50	# Sigma R
 -5	5	0	0	0	50	-50	# Environmental link coefficient
 -5	5	0	0	0	50	-50	# Initial equilibrium offset to virgin
 0 	2 	0 	1 	0 	50 	-50    	# Autocorrelation in rec devs
0 # index of environmental variable to be used
0 # env target parameter: 1=rec devs, 2=R0, 3=steepness
1 # rec dev type: 0=none, 1=devvector (zero-sum), 2=simple deviations (no sum constraint)

# Recruitment residuals
1960	# Start year recruitment residuals
2014	# End year recruitment residuals
5	# Phase for rec-devs

1 # Read 11 advanced recruitment options: 0=no, 1=yes
1933	# first year for early rec devs
5 	# phase for early rec devs
5	# Phase for forecast recruit deviations
1 	# Lambda for forecast recr devs before endyr+1
 1965.7575 #_last_early_yr_nobias_adj_in_MPD                   
 1978.0000 #_first_yr_fullbias_adj_in_MPD                      
 2012 #_last_yr_fullbias_adj_in_MPD                       
 2014 #_first_recent_yr_nobias_adj_in_MPD                 
    0.8025 #_max_bias_adj_in_MPD (1.0 to mimic pre-2009 models)
0	# placeholder
-5	# Lower bound rec devs
5	# Upper bound rec devs
0 # read intitial values for rec devs

# Fishing mortality setup
0.2 	# F ballpark
-1999 	# F ballpark year
1 	# F method:  1=Pope's; 2=Instan. F; 3=Hybrid (recommended)
0.9 	# max F or harvest rate, depends on F_Method

# Initial F setup by fishing fleet
# Lo	Hi	Init	Prior	P_type	SD	Phase
0	1	0	0.01	-1	50	-50 # 1_CA_TWL       
0	1	0	0.01	-1	50	-50 # 2_OR_TWL       
0	1	0	0.01	-1	50	-50 # 3_WA_TWL       
0	1	0	0.01	-1	50	-50 # 4_CA_NTWL      
0	1	0	0.01	-1	50	-50 # 5_OR_NTWL      
0	1	0	0.01	-1	50	-50 # 6_WA_NTWL      
0	1	0	0.01	-1	50	-50 # 7_CA_REC       
0	1	0	0.01	-1	50	-50 # 8_OR_REC       
0	1	0	0.01	-1	50	-50 # 9_WA_REC       
0	1	0	0.01	-1	50	-50 # 10_CA_AHSOP    
0	1	0	0.01	-1	50	-50 # 11_OR_ASHOP    
0	1	0	0.01	-1	50	-50 # 12_WA_ASHOP    
0	1	0	0.01	-1	50	-50 # 13_CA_FOR      
0	1	0	0.01	-1	50	-50 # 14_OR_FOR      
0	1	0	0.01	-1	50	-50 # 15_WA_FOR      
0	1	0	0.01	-1	50	-50 # 16_CA_NWFSC    
0	1	0	0.01	-1	50	-50 # 17_OR_NWFSC    
0	1	0	0.01	-1	50	-50 # 18_WA_NWFSC    
0	1	0	0.01	-1	50	-50 # 19_CA_Tri_early
0	1	0	0.01	-1	50	-50 # 20_OR_Tri_early
0	1	0	0.01	-1	50	-50 # 21_WA_Tri_early
0	1	0	0.01	-1	50	-50 # 22_CA_Tri_late 
0	1	0	0.01	-1	50	-50 # 23_OR_Tri_late 
0	1	0	0.01	-1	50	-50 # 24_WA_Tri_late 
                    
# Catchability (Q_setup)
# A=do power: 0=skip, survey is prop. to abundance, 1= add par for non-linearity
# B=env. link: 0=skip, 1= add par for env. effect on Q
# C=extra SD: 0=skip, 1= add par. for additive constant to input SE (in ln space)
# D=type: <0=mirror lower abs(#) fleet, 0=no par Q is median unbiased, 1=no par Q is mean unbiased, 2=estimate par for ln(Q)
# 	   3=ln(Q) + set of devs about ln(Q) for all years. 4=ln(Q) + set of devs about Q for indexyr-1
# E=Units: 0=numbers, 1=biomass
# F=err_type 0=lognormal, >0=T-dist. DF=input value
#Den-dep env-var extra_se Q_type		
0	0	0	0	# 1_CA_TWL       
0	0	0	0	# 2_OR_TWL       
0	0	0	0	# 3_WA_TWL       
0	0	0	0	# 4_CA_NTWL      
0	0	0	0	# 5_OR_NTWL      
0	0	0	0	# 6_WA_NTWL      
0	0	0	0	# 7_CA_REC       
0	0	0	0	# 8_OR_REC       
0	0	0	0	# 9_WA_REC       
0	0	0	0	# 10_CA_AHSOP    
0	0	0	0	# 11_OR_ASHOP    
0	0	0	0	# 12_WA_ASHOP    
0	0	0	0	# 13_CA_FOR      
0	0	0	0	# 14_OR_FOR      
0	0	0	0	# 15_WA_FOR      
0	0	0	0	# 16_CA_NWFSC    
0	0	0	0	# 17_OR_NWFSC    
0	0	0	0	# 18_WA_NWFSC    
0	0	0	0	# 19_CA_Tri_early
0	0	0	0	# 20_OR_Tri_early
0	0	0	0	# 21_WA_Tri_early
0	0	0	0	# 22_CA_Tri_late 
0	0	0	0	# 23_OR_Tri_late 
0	0	0	0	# 24_WA_Tri_late 
0	0	1	0	# 25_CA_prerec
0	0	1	0	# 26_OR_prerec
0	0	1	0	# 27_WA_prerec
0	0	0	0	# 28_Coastwide_NWFSC 
0	0	0	0	# 29_Coastwide_Tri_early 
0	0	0	0	# 30_Coastwide_Tri_late
0	0	0	0	# 31_Coastwide_prerec
        
# Catchability parameter lines
0     3   0.4     0.1     -1         99         2       # Q_extraSD_14_pre-recruit 
0     3   0.4     0.1     -1         99         2       # Q_extraSD_14_pre-recruit 
0     3   0.4     0.1     -1         99         2       # Q_extraSD_14_pre-recruit 

# Selectivity section
# Size-based setup 
# A=Selex option: 1-24
# B=Do_retention: 0=no, 1=yes
# C=Male offset to female: 0=no, 1=yes, 2=Female offset to male
# D=Mirror selex (#)
# A   B C D
  24  0 0 0		# 1_CA_TWL       
  15  0 0 1		# 2_OR_TWL       
  15  0 0 1		# 3_WA_TWL       

  24  0 0 0		# 4_CA_NTWL      
  15  0 0 4		# 5_OR_NTWL      
  15  0 0 4		# 6_WA_NTWL      

  24  0 0 0		# 7_CA_REC       
  15  0 0 7		# 8_OR_REC       
  15  0 0 7		# 9_WA_REC       

  24  0 0 0		# 10_CA_AHSOP    
  15  0 0 10	# 11_OR_ASHOP    
  15  0 0 10	# 12_WA_ASHOP    

  15  0 0 1		# 13_CA_FOR      
  15  0 0 13	# 14_OR_FOR      
  15  0 0 13	# 15_WA_FOR      

  24  0 0 0		# 16_CA_NWFSC    
  15  0 0 16	# 17_OR_NWFSC    
  15  0 0 16	# 18_WA_NWFSC    

  24  0 0 0		# 19_CA_Tri_early
  15  0 0 19	# 20_OR_Tri_early
  15  0 0 19	# 21_WA_Tri_early

  24  0 0 0		# 22_CA_Tri_late 
  15  0 0 22	# 23_OR_Tri_late 
  15  0 0 22	# 24_WA_Tri_late 

  32  0 0 0		# 25_CA_prerec 
  32  0 0 0		# 26_OR_prerec 
  32  0 0 0		# 27_WA_prerec 

  15  0 0 16		# 28_Coastwide_NWFSC
  15  0 0 19		# 29_Coastwide_Tri_early
  15  0 0 22		# 30_Coastwide_Tri_late
  32  0 0 0		# 31_Coastwide_prerec
            
# Age-based setup
  10 0 0 0	# 1_CA_TWL       
  10 0 0 0	# 2_OR_TWL       
  10 0 0 0	# 3_WA_TWL       
  10 0 0 0	# 4_CA_NTWL      
  10 0 0 0	# 5_OR_NTWL      
  10 0 0 0	# 6_WA_NTWL      
  10 0 0 0	# 7_CA_REC       
  10 0 0 0	# 8_OR_REC       
  10 0 0 0	# 9_WA_REC       
  10 0 0 0	# 10_CA_AHSOP    
  10 0 0 0	# 11_OR_ASHOP    
  10 0 0 0	# 12_WA_ASHOP    
  10 0 0 0	# 13_CA_FOR      
  10 0 0 0	# 14_OR_FOR      
  10 0 0 0	# 15_WA_FOR      
  10 0 0 0	# 16_CA_NWFSC    
  10 0 0 0	# 17_OR_NWFSC    
  10 0 0 0	# 18_WA_NWFSC    
  10 0 0 0	# 19_CA_Tri_early
  10 0 0 0	# 20_OR_Tri_early
  10 0 0 0	# 21_WA_Tri_early
  10 0 0 0	# 22_CA_Tri_late 
  10 0 0 0	# 23_OR_Tri_late 
  10 0 0 0	# 24_WA_Tri_late 
  10 0 0 0	# 25_CA_prerec
  10 0 0 0	# 26_CA_prerec
  10 0 0 0	# 27_CA_prerec
  10 0 0 0	# 28_coastwide_NWFSC
  10 0 0 0	# 29_coastwide_Tri_early
  10 0 0 0	# 30_coastwide_Tri_late
  10 0 0 0	# 31_coastwide_prerec


# Selectivity and retention parameters
# Lo	Hi	Init	Prior	Prior	Prior	Param	Env	Use	Dev	Dev	Dev	Block	block
# bnd	bnd 	value	mean	type	SD	phase	var	dev	minyr	maxyr	SD	design	switch (0: multiplicative; 1: additive; 2: replace)

# 1CA_S_trwl double normal
13.1   65	   40	    50	  -1	50	  4	  0	0	0	0	0	2	2	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	2	2	# Asc WIDTH exp
0.0	   9.0	 0.001  2.6	  -1	50	  5	  0	0	0	0	0	2 2	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	-1.0	  5	    -1	50  	5	  0	0	0	0	0	2	2	# FINAL (logistic)

#TWL retention  (i.e., 1-discard_rate)			                                  			    		                      	      	      	  					
#_LO  HI    INIT  PRIOR PR_type SD   PHASE   env-var use_dev dev_min dev_max dev_std Block   Block_Fxn
#0 		70		27		35		-1				99		 6			0				0				0				0				0				14				2						#Inflection               
#0.1		10		2			1			-1				99		 6			0				0				0				0				0				14				2						#Slope                    # 1 means that parm’ = baseparm + blockparm
#0.001	1			0.95	1			-1				99		 6			0				0				0				0				0				14				2						#Asymptotic retention     # 2 means that parm’ = blockparm
#0			0			0			0			-1				99		-3			0				0				0				0				0				0				0	          #Male offset To inflection

# 4_CA_NTWL double normal
13.001 65	   40	    50	  -1	50	  4	  0	0	0	0	0	1 2	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	1 2	# Asc WIDTH exp
0.0	   9.0	 9.0	  2.6	  -1	50	  5	  0	0	0	0	0	1 2	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	 5.0	  5	    -1	50    5	  0	0	0	0	0	1 2	# FINAL (logistic)

# NONTWL retention curve (i.e., 1-discard_rate)			                                  			    		                      	      	      	  					
#_LO  HI    INIT  PRIOR PR_type SD   PHASE   env-var use_dev dev_min dev_max dev_std Block   Block_Fxn
#0 		70		27		35		-1				99		 6			0				0				0				0				0				15				2						#Inflection               
#0.1		10		2			1			-1				99		 6			0				0				0				0				0				15				2						#Slope                    # 1 means that parm’ = baseparm + blockparm
#0.001	1			0.95	1			-1				99		-2			0				0				0				0				0				14				2						#Asymptotic retention     # 2 means that parm’ = blockparm
#0			0			0			0			-1				99		-3			0				0				0				0				0				0				0	          #Male offset To inflection

# 7_CA_REC double normal
13.001 65	   40	    50	  -1	50	  4	  0	0	0	0	0	0 0	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	0 0	# Asc WIDTH exp
0.0	   9.0	 2.5	  2.6	  -1	50	  5	  0	0	0	0	0	0 0	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	-1.0	  5	    -1	50  	5	  0	0	0	0	0	0 0	# FINAL (logistic)

# 10_CA_AHSOP double normal
13.001 65	   40	    50	  -1	50	  4	  0	0	0	0	0	0	0	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	0	0	# Asc WIDTH exp
0.0	   9.0	 0.001  2.6	  -1	50	  5	  0	0	0	0	0	0	0	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	 5.0	  5	    -1	50    5	  0	0	0	0	0	0	0	# FINAL (logistic)

# 13_CA_FOR double normal
#20	   80	   40	    50	  -1	50	  4	  0	0	0	0	0	0	0	# PEAK
#-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
#0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	0	0	# Asc WIDTH exp
#0.0	   9.0	 2.5	  2.6	  -1	50	  5	  0	0	0	0	0	0	0	# Desc WIDTH exp
#-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
#-5.0	 5.0	-1.0	  5	    -1	50  	5	  0	0	0	0	0	0	0	# FINAL (logistic)
#
# 16_CA_NWFSC double normal
13.001 65	   40	    50	  -1	50	  4	  0	0	0	0	0	0	0	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 8.99	  4.2	  -1	50	  5	  0	0	0	0	0	0	0	# Asc WIDTH exp
0.0	   9.0	 9.0	  2.6	  -1	50	  5	  0	0	0	0	0	0	0	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	 5.0	  5	    -1	50    5	  0	0	0	0	0	0	0	# FINAL (logistic)

# 19_CA_Tri_early double normal
13.001 65	   40	    50	  -1	50	  4	  0	0	0	0	0	0	0	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	0	0	# Asc WIDTH exp
0.0	   9.0	 0.01	  2.6	  -1	50	  5	  0	0	0	0	0	0	0	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	-1.0	  5	    -1	50  	5	  0	0	0	0	0	0	0	# FINAL (logistic)

# 22_CA_Tri_late double normal
13.001 65	   40	    50	  -1	50	  4	  0	0	0	0	0	0	0	# PEAK
-9.0	 4.0	-4	   -4	    -1	50   -50	0	0	0	0	0	0	0	# TOP (logistic)
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  0	0	0	0	0	0	0	# Asc WIDTH exp
0.0	   9.0	 0.0	  2.6	  -1	50	  5	  0	0	0	0	0	0	0	# Desc WIDTH exp
-9.0	 5.0	-9.0	 -9.0	  -1	50	 -50	0	0	0	0	0	0	0	# INIT (logistic)
-5.0	 5.0	 4.99	  5	    -1	50    5	  0	0	0	0	0	0	0	# FINAL (logistic)

############################

1	# Selex block setup: 0=Read one line apply all, 1=read one line each parameter

# 1CA_TWL double normal
13.001 65	   40	    50	  -1	50	  4	  	# PEAK
13.001 65	   40	    50	  -1	50	  4	  	# PEAK
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  	# Asc WIDTH exp
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  	# Asc WIDTH exp
0.0	   9.0	 0.001  2.6	  -1	50	  5	  	# Desc WIDTH exp
0.0	   9.0	 0.001  2.6	  -1	50	  5	  	# Desc WIDTH exp
-5.0	 5.0	-1.0	  5	    -1	50  	5	    # FINAL (logistic)
-5.0	 5.0	-1.0	  5	    -1	50  	5	    # FINAL (logistic)

# 4CA_NONTWL double normal
13.001 65	   40	    50	  -1	50	  4	  	# PEAK
0.0	   9.0	 4.3	  4.2	  -1	50	  5	  	# Asc WIDTH exp
0.0	   9.0	 9.0    2.6	  -1	50	  5	  	# Desc WIDTH exp
-5.0	 5.0	 5.0	  5	    -1	50    5	    # FINAL (logistic)

# 7CA_Rec double normal
#12	   65	   40	    50	  -1	50	  4	  	# PEAK
#0.0	   9.0	 4.3	  4.2	  -1	50	  5	  	# Asc WIDTH exp
#0.0	   9.0	 9.0    2.6	  -1	50	  5	  	# Desc WIDTH exp
#-5.0	 5.0	-1.0	  5	    -1	50    5	    # FINAL (logistic)

## ADD Block lines here (7 params per line: LO  HI    INIT  PRIOR PR_type SD   PHASE)
# TWL retention 
#0 		70		27		35		-1				99		 6   # inflection
#0 		70		0.001	35		-1				99		-6   # inflection
#0.1		10		2			1			-1				99     6   # slope
#0.1		10		2			1			-1				99     6   # slope
#0.001	1			0.8	  1			-1				99		 6   # asymptote 
#0.001	1			1.0	  1			-1				99		-6   # asymptote 
# NONTWL retention 
#0 		70		27		35		-1				99		 6   # inflection
#0.1		10		2			1			-1				99     6   # slope
#0.001	1			0.8 	1			-1				99		 6   # asymptote
#0.001	1			0.8 	1			-1				99		 6   # asymptote

1 # Selex parm adjust method 1=do V1.23 approach, 2=use new logistic approach
0 # Tagging flag: 0=none,1=read parameters for tagging

### Likelihood related quantities ###
# variance/sample size adjustment by fleet
1 # Do variance adjustments 
#1   2    3    4    5    6    7    8    9    10   11   12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   #
0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000
0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000
0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000	0.0000
0.1280	0.1280	0.1280	0.3250	0.3250	0.3250	0.0920	0.0920	0.0920	0.1760	0.1760	0.1760	1.0000	1.0000	1.0000	0.0810	0.0810	0.0810	0.0930	0.0930	0.0930	0.1140	0.1140	0.1140	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000
0.2660	0.2660	0.2660	1.0000	1.0000	1.0000	0.1000	0.1000	0.1000	0.2350	0.2350	0.2350	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000
1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000	1.0000

# removed for SSv3.20: 30   	# DF For discard T-distribution (discard_like)
# removed for SSv3.20: 30   	# DF For meanbodywt T-distribution (DF_for_meanbodywt_like)
1	# Max number of lambda phases: read this number of values for each component below
1	# SD offset (CPUE, discard, mean body weight, recruitment devs): 0=omit log(s) term, 1=include

36 # N changes to default Lambdas = 1.0
# Component codes:  
#  1=survey
#  2=discard
#  3=mean body weight
#  4=length frequency
#  5=age frequency
#  6=Weight frequency
#  7=size at age
#  8=catch
#  9=initial equilibrium catch
#  10=rec devs
#  11=parameter priors
#  12=parameter deviations
#  13=Crash penalty
#  14=Morph composition
#  15=Tag composition
#  16=Tag return
# Component fleet/survey  phase  value  wtfreq_method
1 28 1 0 1 # Turn off coastwide index
1 29 1 0 1 # Turn off coastwide index
1 30 1 0 1 # Turn off coastwide index
1 31 1 0 1 # Turn off coastwide index

4 28 1 0 1 # Turn off coastwide lengths
4 29 1 0 1 # Turn off coastwide lengths
4 30 1 0 1 # Turn off coastwide lengths
4 31 1 0 1 # Turn off coastwide lengths

5 28 1 0 1 # Turn off coastwide ages
5 29 1 0 1 # Turn off coastwide ages
5 30 1 0 1 # Turn off coastwide ages
5 31 1 0 1 # Turn off coastwide ages

# Emphasis factors
4	1	1	0.7034	1
4	2	1	0.4561	1
4	3	1	0.4429	1
4	4	1	0.9871	1
4	5	1	0.7753	1
4	6	1	0.5091	1
4	7	1	1.0000	1
4	8	1	1.0000	1
4	9	1	0.8585	1
4	10	1	0.8889	1
4	11	1	0.5509	1
4	12	1	0.5351	1
5	1	1	0.2966	1
5	2	1	0.5439	1
5	3	1	0.5571	1
5	4	1	0.0129	1
5	5	1	0.2247	1
5	6	1	0.4909	1
5	7	1	0.0000	1
5	8	1	0.0000	1
5	9	1	0.1415	1
5	10	1	0.1111	1
5	11	1	0.4491	1
5	12	1	0.4649	1


0 # extra SD

999 # end file marker
