#V3.30.21.00;_safe;_compile_date:_Feb 10 2023;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.1
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:https://vlab.noaa.gov/group/stock-synthesis
#_Source_code_at:_https://github.com/nmfs-stock-synthesis/stock-synthesis

#C file created using the SS_writectl function in the R package r4ss
#C file write time: 2023-02-23 16:53:24
#_data_and_control_files: data.ss // control_modified.ss
0  # 0 means do not read wtatage.ss; 1 means read and use wtatage.ss and also read and use growth parameters
1  #_N_Growth_Patterns (Growth Patterns, Morphs, Bio Patterns, GP are terms used interchangeably in SS3)
1 #_N_platoons_Within_GrowthPattern 
#_Cond 1 #_Platoon_within/between_stdev_ratio (no read if N_platoons=1)
#_Cond  1 #vector_platoon_dist_(-1_in_first_val_gives_normal_approx)
#
4 # recr_dist_method for parameters:  2=main effects for GP, Area, Settle timing; 3=each Settle entity; 4=none (only when N_GP*Nsettle*pop==1)
1 # not yet implemented; Future usage: Spawner-Recruitment: 1=global; 2=by area
1 #  number of recruitment settlement assignments 
0 # unused option
#GPattern month  area  age (for each settlement assignment)
 1 1 1 0
#
#_Cond 0 # N_movement_definitions goes here if Nareas > 1
#_Cond 1.0 # first age that moves (real age at begin of season, not integer) also cond on do_migration>0
#_Cond 1 1 1 2 4 10 # example move definition for seas=1, morph=1, source=1 dest=2, age1=4, age2=10
#
6 #_Nblock_Patterns
 2 2 2 2 1 1 #_blocks_per_pattern 
# begin and end years of blocks
 2000 2010 2011 2022
 2000 2019 2020 2022
 2004 2016 2017 2022
 2004 2014 2015 2022
 2006 2020
 2000 2019
#
# controls for all timevary parameters 
1 #_time-vary parm bound check (1=warn relative to base parm bounds; 3=no bound check); Also see env (3) and dev (5) options to constrain with base bounds
#
# AUTOGEN
 1 1 1 1 1 # autogen: 1st element for biology, 2nd for SR, 3rd for Q, 4th reserved, 5th for selex
# where: 0 = autogen time-varying parms of this category; 1 = read each time-varying parm line; 2 = read then autogen if parm min==-12345
#
#_Available timevary codes
#_Block types: 0: P_block=P_base*exp(TVP); 1: P_block=P_base+TVP; 2: P_block=TVP; 3: P_block=P_block(-1) + TVP
#_Block_trends: -1: trend bounded by base parm min-max and parms in transformed units (beware); -2: endtrend and infl_year direct values; -3: end and infl as fraction of base range
#_EnvLinks:  1: P(y)=P_base*exp(TVP*env(y));  2: P(y)=P_base+TVP*env(y);  3: P(y)=f(TVP,env_Zscore) w/ logit to stay in min-max;  4: P(y)=2.0/(1.0+exp(-TVP1*env(y) - TVP2))
#_DevLinks:  1: P(y)*=exp(dev(y)*dev_se;  2: P(y)+=dev(y)*dev_se;  3: random walk;  4: zero-reverting random walk with rho;  5: like 4 with logit transform to stay in base min-max
#_DevLinks(more):  21-25 keep last dev for rest of years
#
#_Prior_codes:  0=none; 6=normal; 1=symmetric beta; 2=CASAL's beta; 3=lognormal; 4=lognormal with biascorr; 5=gamma
#
# setup for M, growth, wt-len, maturity, fecundity, (hermaphro), recr_distr, cohort_grow, (movement), (age error), (catch_mult), sex ratio 
#_NATMORT
0 #_natM_type:_0=1Parm; 1=N_breakpoints;_2=Lorenzen;_3=agespecific;_4=agespec_withseasinterpolate;_5=BETA:_Maunder_link_to_maturity;_6=Lorenzen_range
  #_no additional input for selected M option; read 1P per morph
#
1 # GrowthModel: 1=vonBert with L1&L2; 2=Richards with L1&L2; 3=age_specific_K_incr; 4=age_specific_K_decr; 5=age_specific_K_each; 6=NA; 7=NA; 8=growth cessation
1 #_Age(post-settlement)_for_L1;linear growth below this
999 #_Growth_Age_for_L2 (999 to use as Linf)
-999 #_exponential decay for growth above maxage (value should approx initial Z; -999 replicates 3.24; -998 to not allow growth above maxage)
0  #_placeholder for future growth feature
#
0 #_SD_add_to_LAA (set to 0.1 for SS2 V1.x compatibility)
0 #_CV_Growth_Pattern:  0 CV=f(LAA); 1 CV=F(A); 2 SD=F(LAA); 3 SD=F(A); 4 logSD=F(A)
#
2 #_maturity_option:  1=length logistic; 2=age logistic; 3=read age-maturity matrix by growth_pattern; 4=read age-fecundity; 5=disabled; 6=read length-maturity
2 #_First_Mature_Age
2 #_fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
1 #_parameter_offset_approach for M, G, CV_G:  1- direct, no offset**; 2- male=fem_parm*exp(male_parm); 3: male=female*exp(parm) then old=young*exp(parm)
#_** in option 1, any male parameter with value = 0.0 and phase <0 is set equal to female parameter
#
#_growth_parms
#_ LO HI INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
# Sex: 1  BioPattern: 1  NatMort
 0.02 0.2 0.0807017 -2.74 0.31 3 1 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 2 15 8.24195 4 50 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 50 70 59.1861 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.02 0.21 0.138795 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.02 0.21 0.0878791 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.21 0.0380507 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 0 0.1 1.19e-05 1.19e-05 50 0 -50 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 2 4 3.09 3.09 50 0 -50 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 9 12 10.87 10.87 0.055 0 -50 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 3 -0.688 -0.688 50 0 -50 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 1e-10 0.1 7.218e-08 -16.4441 0.135 0 -50 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 2 6 4.043 4.043 0.3 0 -50 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.02 0.2 0.0643 -2.74 0.31 3 -50 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 0 15 0 0 50 0 -50 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 50 70 53.7727 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.02 0.21 0.161206 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.02 0.21 0.0948936 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.21 0.0474597 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 0 0.1 1.08e-05 1.08e-05 50 0 -50 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 2 4 3.118 3.118 50 0 -50 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
# Hermaphroditism
#  Recruitment Distribution 
#  Cohort growth dev base
 -1 1 1 1 50 0 -50 0 0 0 0 0 0 0 # CohortGrowDev
#  Movement
#  Age Error from parameters
#  catch multiplier
#  fraction female, by GP
 1e-06 0.999999 0.5 0.5 0.5 0 -99 0 0 0 0 0 0 0 # FracFemale_GP_1
#  M2 parameter for each predator fleet
#
#_no timevary MG parameters
#
#_seasonal_effects_on_biology_parms
 0 0 0 0 0 0 0 0 0 0 #_femwtlen1,femwtlen2,mat1,mat2,fec1,fec2,Malewtlen1,malewtlen2,L1,K
#_ LO HI INIT PRIOR PR_SD PR_type PHASE
#_Cond -2 2 0 0 -1 99 -2 #_placeholder when no seasonal MG parameters
#
3 #_Spawner-Recruitment; Options: 1=NA; 2=Ricker; 3=std_B-H; 4=SCAA; 5=Hockey; 6=B-H_flattop; 7=survival_3Parm; 8=Shepherd_3Parm; 9=RickerPower_3parm
1  # 0/1 to use steepness in initial equ recruitment calculation
0  #  future feature:  0/1 to make realized sigmaR a function of SR curvature
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn #  parm_name
 7 11 8.7 8.5 50 0 -1 0 0 0 0 0 0 0 # SR_LN(R0)
          0.21          0.99          0.72          0.72          0.16             2         -6          0          0          0          0          0          0          0 # SR_BH_steep
             0             2           0.5           0.4            50             0        -50          0          0          0          0          0          0          0 # SR_sigmaR
            -5             5             0             0            50             0        -50          0          0          0          0          0          0          0 # SR_regime
             0             2             0             1            50             0        -50          0          0          0          0          0          0          0 # SR_autocorr
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
 2022 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS3 sets bias_adj to 0.0 for fcast yrs)
 0.8025 #_max_bias_adj_in_MPD (typical ~0.8; -3 sets all years to 0.0; -2 sets all non-forecast yrs w/ estimated recdevs to 1.0; -1 sets biasadj=1.0 for all yrs w/ recdevs)
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
# all recruitment deviations
#  1892E 1893E 1894E 1895E 1896E 1897E 1898E 1899E 1900E 1901E 1902E 1903E 1904E 1905E 1906E 1907E 1908E 1909E 1910E 1911E 1912E 1913E 1914E 1915E 1916E 1917E 1918E 1919E 1920E 1921E 1922E 1923E 1924E 1925E 1926E 1927E 1928E 1929E 1930E 1931E 1932E 1933E 1934E 1935E 1936E 1937E 1938E 1939E 1940E 1941E 1942E 1943E 1944E 1945E 1946E 1947E 1948E 1949E 1950E 1951E 1952E 1953E 1954E 1955E 1956E 1957E 1958E 1959E 1960R 1961R 1962R 1963R 1964R 1965R 1966R 1967R 1968R 1969R 1970R 1971R 1972R 1973R 1974R 1975R 1976R 1977R 1978R 1979R 1980R 1981R 1982R 1983R 1984R 1985R 1986R 1987R 1988R 1989R 1990R 1991R 1992R 1993R 1994R 1995R 1996R 1997R 1998R 1999R 2000R 2001R 2002R 2003R 2004R 2005R 2006R 2007R 2008R 2009R 2010R 2011R 2012R 2013R 2014R 2015R 2016R 2017R 2018R 2019R 2020R 2021R 2022R 2023F 2024F 2025F 2026F 2027F 2028F 2029F 2030F 2031F 2032F 2033F 2034F
#  -0.0425254 -0.0450213 -0.0476569 -0.0504401 -0.0533785 -0.0564793 -0.0597501 -0.0631992 -0.0668348 -0.0706648 -0.0746966 -0.0789375 -0.0833949 -0.0880768 -0.0929899 -0.0981436 -0.103546 -0.109208 -0.115143 -0.121372 -0.127922 -0.134811 -0.142037 -0.149589 -0.15747 -0.165686 -0.174251 -0.183185 -0.192509 -0.202231 -0.212348 -0.222832 -0.233655 -0.244795 -0.256221 -0.267862 -0.279649 -0.291497 -0.303364 -0.315241 -0.327143 -0.339218 -0.351682 -0.364859 -0.379146 -0.394773 -0.411597 -0.429081 -0.446627 -0.463165 -0.478585 -0.492664 -0.50447 -0.512869 -0.517579 -0.520654 -0.521505 -0.518989 -0.512332 -0.501717 -0.486989 -0.468082 -0.444606 -0.415412 -0.378895 -0.332622 -0.276867 -0.217791 0.0198856 0.026979 -0.0432058 -0.157268 -0.247592 -0.26026 -0.168565 0.0199088 0.143903 -0.119554 -0.422836 -0.4348 -0.123662 0.0668481 -0.164545 -0.135521 0.0657735 -0.301304 -0.00454971 -0.0719812 -0.633303 -0.0175619 -0.17255 -0.347391 -0.0083166 -0.0162905 -0.106874 0.0593942 0.111837 0.376494 0.333567 0.210402 0.471149 0.118104 0.451979 0.597096 0.565002 0.181054 0.160229 -0.020499 0.103347 0.363845 0.236045 0.602631 0.216343 -0.385614 -0.056779 0.484751 -0.512786 -0.110851 0.186727 0.0262153 0.117025 0.329954 -0.297428 -0.304938 -0.0568717 -0.729951 -0.772028 -0.11272 0.090555 0.354572 0.226779 0 0 0 0 0 0 0 0 0 0 0 0
#
#Fishing Mortality info 
0.2 # F ballpark value in units of annual_F
-1999 # F ballpark year (neg value to disable)
3 # F_Method:  1=Pope midseason rate; 2=F as parameter; 3=F as hybrid; 4=fleet-specific parm/hybrid (#4 is superset of #2 and #3 and is recommended)
4 # max F (methods 2-4) or harvest fraction (method 1)
5  # N iterations for tuning in hybrid mode; recommend 3 (faster) to 5 (more precise if many fleets)
#
#_initial_F_parms; for each fleet x season that has init_catch; nest season in fleet; count = 0
#_for unconstrained init_F, use an arbitrary initial catch and set lambda=0 for its logL
#_ LO HI INIT PRIOR PR_SD  PR_type  PHASE
#
# F rates by fleet x season
# Yr:  1892 1893 1894 1895 1896 1897 1898 1899 1900 1901 1902 1903 1904 1905 1906 1907 1908 1909 1910 1911 1912 1913 1914 1915 1916 1917 1918 1919 1920 1921 1922 1923 1924 1925 1926 1927 1928 1929 1930 1931 1932 1933 1934 1935 1936 1937 1938 1939 1940 1941 1942 1943 1944 1945 1946 1947 1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034
# seas:  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
# 1_CA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000173523 0.000266799 0.000286004 0.000222667 0.000224206 0.000175194 0.000155465 0.000184031 0.000101012 6.97561e-05 0.000229708 0.000298078 0.000370028 0.000683191 0.000596015 0.000832903 0.000573778 0.000787491 0.000681902 0.000703571 0.000425983 0.000654849 0.000674081 0.000901637 0.000743322 0.000596437 0.000146357 0.000736491 0.0031692 0.00755442 0.00721192 0.00299014 0.00348341 0.00313755 0.0028906 0.00594649 0.0043356 0.00422224 0.00308235 0.0033556 0.00335196 0.00389244 0.00528699 0.00402431 0.00314394 0.00249092 0.00251444 0.00357863 0.00226364 0.00303265 0.00222645 0.00307549 0.00293648 0.00719256 0.00771944 0.011618 0.0144552 0.0113728 0.0145112 0.0158658 0.0173611 0.0169727 0.0252559 0.0129059 0.0193347 0.0255845 0.0412832 0.0296892 0.0250276 0.0213692 0.0114455 0.0149311 0.0174706 0.0155859 0.030771 0.0154338 0.0269536 0.0117262 0.0155804 0.0152481 0.0231151 0.0172426 0.0145956 0.00854003 0.00146606 0.000968865 0.00138176 0.000100104 0.00018474 0.000235167 0.00069902 0.00148325 0.00070953 0.000111787 3.10243e-05 1.83826e-05 2.81007e-05 7.39695e-05 9.34998e-05 0.000324966 0.00012862 0.00338517 0.00622556 0.00777599 0.00321435 0.00340502 0.00393896 0.0045591 0.004743 0.0110942 0.011034 0.0109856 0.0109369 0.0108762 0.0108275 0.0107791 0.0107187 0.0106705 0.0106223
# 2_OR_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1.28878e-05 7.95388e-06 3.27195e-07 6.43237e-06 2.36183e-05 4.6474e-05 0 6.74943e-05 0.00156687 0.00243955 0.00464164 0.0165529 0.0299419 0.0485213 0.0315165 0.020353 0.0148876 0.0132143 0.0141764 0.0133543 0.0141532 0.0151407 0.0196214 0.0202049 0.0307032 0.0329224 0.023089 0.0258609 0.0315435 0.0292693 0.0349761 0.0204573 0.0317378 0.0263262 0.0304533 0.00507026 0.0292644 0.00942195 0.0194046 0.0252063 0.0244075 0.0304462 0.0195386 0.013969 0.00899778 0.0209457 0.0657536 0.0524133 0.118928 0.0882556 0.186911 0.198234 0.0827784 0.0726247 0.0736823 0.113317 0.135143 0.142601 0.106314 0.233308 0.221381 0.254718 0.115098 0.0832328 0.104957 0.07383 0.0805626 0.0410768 0.00288749 0.00131326 0.00171767 0.000901043 0.000381477 0.000728964 0.000739555 0.00014569 0.000185034 0.000285798 0.000140892 0.0001211 0.000248202 0.00021669 0.000355645 0.00137396 0.000554433 0.00472379 0.00545509 0.00601224 0.00569452 0.00676842 0.00957172 0.00917743 0.00938232 0.0169739 0.016882 0.0168082 0.0167341 0.0166416 0.0165674 0.0164934 0.0164011 0.0163274 0.0162538
# 3_WA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6.44392e-07 0 4.90792e-06 3.82643e-05 4.97315e-05 4.47962e-05 6.67007e-05 7.057e-05 0.000157774 5.97056e-05 0.00117544 0.00387558 0.00166018 0.0182736 0.00971788 0.005259 0.00876655 0.0109297 0.0107592 0.00921675 0.00899359 0.00398026 0.0058271 0.00562179 0.00550877 0.00469138 0.00609454 0.00696986 0.0064519 0.007831 0.0111577 0.009135 0.00681368 0.0153476 0.0216409 0.0108154 0.018752 0.0181876 0.0165138 0.018762 0.00522806 0.0118504 0.0184405 0.0255602 0.0194937 0.0163607 0.0494959 0.0264726 0.0304316 0.0230672 0.0216429 0.0374396 0.0388298 0.0690048 0.0624626 0.074789 0.0786238 0.108192 0.110307 0.112174 0.111979 0.0446044 0.0236666 0.0231723 0.0253363 0.0251371 0.0231155 0.0145077 0.000925021 0.000607205 0.00138138 0.000579204 0.000389999 0.00112921 0.000411916 0.000172686 0.000131184 0.000205607 0.000240408 0.000139342 0.000187357 0.00016323 7.43653e-05 0.000132143 0.000164047 0.00118972 0.00490233 0.0020219 0.00240738 0.00222898 0.00310921 0.00326682 0.00333975 0.00591124 0.00587923 0.00585353 0.00582775 0.00579551 0.00576969 0.00574392 0.00571177 0.0056861 0.00566045
# 4_CA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000657312 0.00106675 0.00110875 0.000647614 0.000703673 0.000633554 0.000593171 0.000720768 0.000878271 0.00108788 0.00128607 0.00104364 0.000911128 0.000623602 0.00089364 0.000877935 0.000733706 0.000295453 0.000414771 0.000635199 0.000578777 0.000371187 0.000383874 0.00037052 0.000277109 0.00036246 0.000273148 0.000231535 0.000891415 0.00226671 0.00244257 0.000575098 0.00114915 0.000453724 0.000375915 0.000620102 0.000476582 0.000282443 0.000702293 0.000167864 0.000265503 0.000297633 0.000393064 0.000275167 0.000354793 0.000289987 0.000416229 0.000385119 0.000356347 0.000388408 0.00030736 0.000322645 0.000201178 0.000784159 0.000491413 0.000869303 0.00168071 0.000808925 0.00209746 0.00153538 0.00217809 0.00263319 0.00671723 0.00618744 0.00481872 0.00909884 0.00256646 0.00435416 0.0041377 0.00796355 0.00411416 0.003891 0.00443549 0.0189499 0.0195158 0.0162817 0.0138101 0.0121448 0.0102371 0.011147 0.0114828 0.00916455 0.00697126 0.00254137 0.00144129 0.00109399 1.06287e-05 0.000205188 0.000222929 0.000143627 0.000226489 0.000278233 9.31677e-05 0.000116154 0.00036424 0.000883124 0.000279451 0.00041317 0.000282769 0.000329069 0.000190256 0.000430237 0.000436984 0.000619848 0.00120522 0.00169676 0.00155995 0.00616624 0.00635857 0.00307464 0.00305784 0.00304432 0.0030308 0.00301398 0.00300055 0.00298715 0.00297041 0.00295703 0.00294365
# 5_OR_NTWL 7.18069e-05 7.18112e-05 7.18153e-05 1.84816e-05 4.46604e-06 4.59407e-06 2.61083e-06 4.35829e-06 6.11276e-06 8.00023e-06 9.77177e-06 1.15528e-05 1.34697e-05 1.52716e-05 1.70845e-05 1.8909e-05 2.08728e-05 2.27225e-05 2.45855e-05 2.6591e-05 2.84834e-05 3.03914e-05 3.24459e-05 3.43888e-05 3.63573e-05 3.83586e-05 4.05206e-05 4.25721e-05 4.46444e-05 4.68766e-05 4.90017e-05 5.11576e-05 5.34838e-05 5.57113e-05 5.79825e-05 5.98806e-05 0.000100604 0.000173524 0.000159363 0.000128919 4.13918e-05 6.86618e-05 7.46225e-05 6.75941e-05 0.000162955 0.00019589 0.000195129 0.000112235 0.000251013 0.000339699 0.000477954 0.00120615 0.000319287 0.000213066 0.000274964 0.000143852 0.000242354 0.000165477 0.000157459 0.000124049 0.000120735 6.42986e-05 7.66212e-05 9.69537e-05 6.32411e-05 0.000140936 2.88286e-05 6.02548e-05 4.07631e-05 0.000115366 0.000107018 9.67377e-05 2.23136e-05 0.000162327 0.000111285 0.000317161 0.000289993 0.000645349 0.000250571 0.000512008 0.000666328 0.000712138 0.000914948 0.000490986 0.000663998 0.000826651 0.00133574 0.00396577 0.00240963 0.00277954 0.00558219 0.0128276 0.00929818 0.00973662 0.00807176 0.0134702 0.0121577 0.0129909 0.0185418 0.0226508 0.0157664 0.0419144 0.0107888 0.00966858 0.012952 0.0189588 0.0181069 0.00835336 0.00142563 0.0012416 5.14047e-05 4.94429e-05 0.000587902 0.000181873 0.00025988 0.000171646 7.23971e-05 0.000240113 7.67735e-05 0.000313374 0.000132862 0.000191799 0.000125692 0.000216651 0.000440283 0.000362862 0.000273459 0.000388924 0.000176566 0.000153362 0.000258404 0.0007354 0.000728881 0.000591485 0.00058828 0.000585708 0.000583134 0.00057992 0.000577349 0.000574779 0.00057157 0.000569004 0.00056644
# 6_WA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000527348 0.000473099 0.000687436 0.000700013 0.000659837 0.000343254 0.000447092 0.000310413 0.000468259 0.000133798 0.00012182 5.76398e-05 3.89595e-05 0.000261198 0.000158001 0.000209736 0.000399533 0.000236989 0.000121212 0.000211104 0.000327305 0.000169209 0.000105394 6.85309e-05 5.37236e-05 8.97723e-05 4.08631e-05 2.62223e-05 0.000202051 0.000201045 0.000127456 0.000126768 0.000126218 0.000125665 0.000124972 0.000124416 0.00012386 0.000123168 0.000122614 0.000122062
# 7_CA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000136952 0.000276665 0.00032089 0.00043283 0.000547286 0.000664281 0.000783995 0.000905761 0.00103149 0.00123844 0.00123262 0.00109193 0.00159046 0.00149066 0.000804027 0.000782848 0.000657856 0.000906183 0.00160878 0.00130885 0.00265933 0.00349954 0.00433562 0.00521564 0.00462635 0.00400433 0.00508946 0.00621765 0.00699568 0.00659003 0.0112135 0.00900336 0.00694463 0.00479335 0.0057254 0.00588159 0.00509429 0.00734451 0.00770456 0.00800548 0.00857953 0.00955933 0.0121141 0.0104854 0.0135795 0.0158966 0.0174141 0.0177477 0.0201805 0.0194255 0.019023 0.0213967 0.0201263 0.0190282 0.0355352 0.0144054 0.0153337 0.0239942 0.0342718 0.0355156 0.0301408 0.0194753 0.0303019 0.0294263 0.0278415 0.0280925 0.022112 0.0273992 0.00981185 0.0162159 0.00427962 0.0103047 0.0118384 0.00502454 0.000934704 0.00276017 0.00291147 0.00151501 0.00325615 0.00279592 0.00136692 0.00329086 0.00304546 0.00377096 0.00343353 0.0028624 0.00431519 0.00499382 0.0041707 0.0088996 0.00645646 0.00761822 0.00854193 0.00864692 0.00811346 0.0134567 0.0134232 0.0199178 0.0198086 0.0197205 0.0196329 0.0195241 0.0194374 0.0193506 0.0192422 0.0191555 0.0190687
# 8_OR_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000452527 0.000931959 0.00147012 0.00203281 0.00255066 0.00310685 0.00372547 0.00402302 0.00527611 0.00596473 0.0036426 0.00478429 0.00266392 0.00545409 0.00369665 0.00303877 0.00369452 0.00238141 0.00338373 0.00475528 0.00633944 0.00475664 0.0055999 0.00340393 0.0043591 0.00663653 0.00389798 0.00305724 0.00156015 0.00125351 0.00124031 0.000302236 0.000438282 0.000227519 0.000232566 0.000276529 0.000359303 0.000469163 0.000312808 0.00029409 0.000397778 0.0003006 0.00133244 0.000883565 0.00246316 0.00371039 0.00335397 0.00540239 0.00357433 0.0055318 0.00661266 0.00657682 0.0108073 0.0107482 0.0107006 0.0106531 0.010594 0.0105468 0.0104998 0.0104409 0.0103938 0.0103468
# 9_WA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.4554e-05 3.47212e-05 4.46473e-05 5.45913e-05 6.46447e-05 7.46598e-05 8.53567e-05 9.66731e-05 0.000108852 4.93315e-05 0.00012836 0.000194918 0.000146693 9.95739e-05 9.12138e-05 0.000107566 0.000210137 0.000398213 0.000201321 0.000342731 0.000371904 0.000386657 0.000648267 0.000663307 0.000795606 0.00171074 0.00173508 0.000980187 0.000774277 0.000700157 0.000634534 0.00103544 0.000581966 0.000423764 0.000335486 0.00013491 0.000115949 4.8621e-05 6.86191e-05 6.85919e-05 5.56865e-05 4.47106e-05 4.13545e-05 7.52269e-05 7.76566e-05 6.57528e-05 6.50801e-05 9.24086e-05 0.000141071 0.000119276 0.000285126 0.000230667 0.000717307 0.000442482 0.000838791 0.00089593 0.00109777 0.00110366 0.00175183 0.00174233 0.0017347 0.00172706 0.00171753 0.00170991 0.00170229 0.00169278 0.00168518 0.00167758
# 10_CA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.08052e-05 1.56115e-06 2.23756e-05 0.000168835 3.94833e-06 3.73339e-06 3.21197e-06 0 2.54146e-06 0 1.5406e-05 2.97521e-05 7.05417e-06 2.66924e-06 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# 11_OR_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000374564 7.03837e-05 0.000577224 0.000581268 0.000472126 8.89239e-05 1.44772e-05 0.000153816 9.395e-05 0.000379239 7.28552e-05 0.000219016 0.0003553 0.000166824 0.00025395 0.000277601 1.37349e-05 2.67784e-05 0.000110452 2.30126e-05 2.79694e-06 5.85647e-05 2.92074e-05 7.50654e-06 2.3164e-05 9.06458e-05 0.000192196 1.75844e-05 0.000305157 3.40555e-05 2.78553e-05 0.000105445 3.09762e-05 1.67684e-06 1.5753e-06 4.88581e-07 4.60251e-06 3.539e-06 1.58178e-05 3.30894e-06 9.2953e-06 7.16486e-05 0.00011875 2.75165e-05 7.96956e-06 0.000120842 0.000156659 0.000563869 0.000576287 0.000189417 0.000188394 0.000187574 0.000186749 0.000185714 0.000184885 0.000184058 0.000183028 0.000182205 0.000181384
# 12_WA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.70952e-05 1.61319e-05 9.56559e-05 1.98276e-05 0.00177872 0.00195853 0.000170234 0.00023217 0.00032446 0.000559511 0.00021472 0.000111571 0.000215152 0.000233558 0.000331163 0.000115482 0.000661037 3.98886e-05 0.00013705 0.00033993 0.000553772 0.000723845 0.000215232 0.000253634 0.000225691 5.05551e-05 4.96134e-05 5.84726e-05 3.96164e-05 1.4461e-05 0.000189948 0.000140854 5.98613e-05 5.22782e-05 1.42678e-05 2.43306e-05 1.11152e-05 5.37702e-06 1.17202e-05 0.000189869 9.94823e-05 0.000167037 2.73242e-05 9.92759e-05 5.68998e-05 0.000778676 0.000795825 0.000212142 0.000210996 0.000210078 0.000209154 0.000207995 0.000207066 0.00020614 0.000204986 0.000204065 0.000203145
# 13_CA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00152701 0.00384763 0.0153095 0.000181401 0 0 0.000458975 0.0132961 0.00544047 0.00229686 0.00179162 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# 14_OR_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0470858 0.0219503 0.00958478 0.00166737 0.00238904 0.00382951 0.0103115 0.0172225 0.00270507 0.00474564 0.00383715 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# 15_WA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00368214 0.00300232 0.00365294 0.000400168 0.000916343 0.00227174 0.00220498 0.00223073 0.00961802 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
#
#_Q_setup for fleets with cpue or survey data
#_1:  fleet number
#_2:  link type: (1=simple q, 1 parm; 2=mirror simple q, 1 mirrored parm; 3=q and power, 2 parm; 4=mirror with offset, 2 parm)
#_3:  extra input for link, i.e. mirror fleet# or dev index number
#_4:  0/1 to select extra sd parameter
#_5:  0/1 for biasadj or not
#_6:  0/1 to float
#_   fleet      link link_info  extra_se   biasadj     float  #  fleetname
        28         1         0         0         0         1  #  28_coastwide_NWFSC
        29         1         0         0         0         0  #  29_coastwide_Tri_early
        30         2        29         0         0         0  #  30_coastwide_Tri_late
        31         1         0         1         0         1  #  31_coastwide_prerec
-9999 0 0 0 0 0
#
#_Q_parms(if_any);Qunits_are_ln(q)
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
           -25            25      -1.36786             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_28_coastwide_NWFSC(28)
           -25            25      -1.32196             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_29_coastwide_Tri_early(29)
           -25            25      -1.32196             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_30_coastwide_Tri_late(30)
           -25            25       -3.5178             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_31_coastwide_prerec(31)
             0             3      0.504119           0.1            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_31_coastwide_prerec(31)
#_no timevary Q parameters
#
#_size_selex_patterns
#Pattern:_0;  parm=0; selex=1.0 for all sizes
#Pattern:_1;  parm=2; logistic; with 95% width specification
#Pattern:_5;  parm=2; mirror another size selex; PARMS pick the min-max bin to mirror
#Pattern:_11; parm=2; selex=1.0  for specified min-max population length bin range
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_6;  parm=2+special; non-parm len selex
#Pattern:_43; parm=2+special+2;  like 6, with 2 additional param for scaling (average over bin range)
#Pattern:_8;  parm=8; double_logistic with smooth transitions and constant above Linf option
#Pattern:_9;  parm=6; simple 4-parm double logistic with starting length; parm 5 is first length; parm 6=1 does desc as offset
#Pattern:_21; parm=2+special; non-parm len selex, read as pairs of size, then selex
#Pattern:_22; parm=4; double_normal as in CASAL
#Pattern:_23; parm=6; double_normal where final value is directly equal to sp(6) so can be >1.0
#Pattern:_24; parm=6; double_normal with sel(minL) and sel(maxL), using joiners
#Pattern:_2;  parm=6; double_normal with sel(minL) and sel(maxL), using joiners, back compatibile version of 24 with 3.30.18 and older
#Pattern:_25; parm=3; exponential-logistic in length
#Pattern:_27; parm=special+3; cubic spline in length; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=special+3+2; cubic spline; like 27, with 2 additional param for scaling (average over bin range)
#_discard_options:_0=none;_1=define_retention;_2=retention&mortality;_3=all_discarded_dead;_4=define_dome-shaped_retention
#_Pattern Discard Male Special
 24 0 4 0 # 1 1_CA_TWL
 24 0 4 0 # 2 2_OR_TWL
 15 0 0 2 # 3 3_WA_TWL
 24 0 4 0 # 4 4_CA_NTWL
 24 0 4 0 # 5 5_OR_NTWL
 24 0 4 0 # 6 6_WA_NTWL
 24 0 4 0 # 7 7_CA_REC
 24 0 4 0 # 8 8_OR_REC
 24 0 4 0 # 9 9_WA_REC
 24 0 4 0 # 10 10_CA_ASHOP
 15 0 0 10 # 11 11_OR_ASHOP
 15 0 0 10 # 12 12_WA_ASHOP
 15 0 0 1 # 13 13_CA_FOR
 15 0 0 2 # 14 14_OR_FOR
 15 0 0 3 # 15 15_WA_FOR
 0 0 0 0 # 16 16_CA_NWFSC
 0 0 0 0 # 17 17_OR_NWFSC
 0 0 0 0 # 18 18_WA_NWFSC
 0 0 0 0 # 19 19_CA_Tri_early
 0 0 0 0 # 20 20_OR_Tri_early
 0 0 0 0 # 21 21_WA_Tri_early
 0 0 0 0 # 22 22_CA_Tri_late
 0 0 0 0 # 23 23_OR_Tri_late
 0 0 0 0 # 24 24_WA_Tri_late
 0 0 0 0 # 25 25_CA_prerec
 0 0 0 0 # 26 26_OR_prerec
 0 0 0 0 # 27 27_WA_prerec
 24 0 4 0 # 28 28_coastwide_NWFSC
 24 0 4 0 # 29 29_coastwide_Tri_early
 15 0 0 29 # 30 30_coastwide_Tri_late
 0 0 0 0 # 31 31_coastwide_prerec
#
#_age_selex_patterns
#Pattern:_0; parm=0; selex=1.0 for ages 0 to maxage
#Pattern:_10; parm=0; selex=1.0 for ages 1 to maxage
#Pattern:_11; parm=2; selex=1.0  for specified min-max age
#Pattern:_12; parm=2; age logistic
#Pattern:_13; parm=8; age double logistic. Recommend using pattern 18 instead.
#Pattern:_14; parm=nages+1; age empirical
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_16; parm=2; Coleraine - Gaussian
#Pattern:_17; parm=nages+1; empirical as random walk  N parameters to read can be overridden by setting special to non-zero
#Pattern:_41; parm=2+nages+1; // like 17, with 2 additional param for scaling (average over bin range)
#Pattern:_18; parm=8; double logistic - smooth transition
#Pattern:_19; parm=6; simple 4-parm double logistic with starting age
#Pattern:_20; parm=6; double_normal,using joiners
#Pattern:_26; parm=3; exponential-logistic in age
#Pattern:_27; parm=3+special; cubic spline in age; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=2+special+3; // cubic spline; with 2 additional param for scaling (average over bin range)
#Age patterns entered with value >100 create Min_selage from first digit and pattern from remainder
#_Pattern Discard Male Special
 10 0 0 0 # 1 1_CA_TWL
 10 0 0 0 # 2 2_OR_TWL
 10 0 0 0 # 3 3_WA_TWL
 10 0 0 0 # 4 4_CA_NTWL
 10 0 0 0 # 5 5_OR_NTWL
 10 0 0 0 # 6 6_WA_NTWL
 10 0 0 0 # 7 7_CA_REC
 10 0 0 0 # 8 8_OR_REC
 10 0 0 0 # 9 9_WA_REC
 10 0 0 0 # 10 10_CA_ASHOP
 10 0 0 0 # 11 11_OR_ASHOP
 10 0 0 0 # 12 12_WA_ASHOP
 10 0 0 0 # 13 13_CA_FOR
 10 0 0 0 # 14 14_OR_FOR
 10 0 0 0 # 15 15_WA_FOR
 10 0 0 0 # 16 16_CA_NWFSC
 10 0 0 0 # 17 17_OR_NWFSC
 10 0 0 0 # 18 18_WA_NWFSC
 10 0 0 0 # 19 19_CA_Tri_early
 10 0 0 0 # 20 20_OR_Tri_early
 10 0 0 0 # 21 21_WA_Tri_early
 10 0 0 0 # 22 22_CA_Tri_late
 10 0 0 0 # 23 23_OR_Tri_late
 10 0 0 0 # 24 24_WA_Tri_late
 10 0 0 0 # 25 25_CA_prerec
 10 0 0 0 # 26 26_OR_prerec
 10 0 0 0 # 27 27_WA_prerec
 10 0 0 0 # 28 28_coastwide_NWFSC
 10 0 0 0 # 29 29_coastwide_Tri_early
 10 0 0 0 # 30 30_coastwide_Tri_late
 10 0 0 0 # 31 31_coastwide_prerec
#
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
# 1   1_CA_TWL LenSelex
        13.001            65       45.2431            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_1_CA_TWL(1)
             0             9       4.29477            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_1_CA_TWL(1)
             0             9       3.36951            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_1_CA_TWL(1)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_1_CA_TWL(1)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_1_CA_TWL(1)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_1_CA_TWL(1)
            -9             9       1.49932             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_1_CA_TWL(1)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_1_CA_TWL(1)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_1_CA_TWL(1)
# 2   2_OR_TWL LenSelex
        13.001            65       49.2903            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_2_OR_TWL(2)
             0             9       4.14299            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_2_OR_TWL(2)
             0             9       2.56975            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_2_OR_TWL(2)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_2_OR_TWL(2)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_2_OR_TWL(2)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_2_OR_TWL(2)
            -9             9       2.22548             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_2_OR_TWL(2)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_2_OR_TWL(2)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_2_OR_TWL(2)
# 3   3_WA_TWL LenSelex
# 4   4_CA_NTWL LenSelex
        13.001            65       36.6438            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_4_CA_NTWL(4)
             0             9        4.2818            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_4_CA_NTWL(4)
             0             9        5.1204            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_4_CA_NTWL(4)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_4_CA_NTWL(4)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_4_CA_NTWL(4)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_4_CA_NTWL(4)
            -9             9      0.144978             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_4_CA_NTWL(4)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_4_CA_NTWL(4)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_4_CA_NTWL(4)
# 5   5_OR_NTWL LenSelex
        13.001            65       29.2303            99            99             0          4          0          0          0          0          0          6          2  #  Size_DblN_peak_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_5_OR_NTWL(5)
            -9             9      -5.19605            99            99             0          5          0          0          0          0          0          6          2  #  Size_DblN_ascend_se_5_OR_NTWL(5)
            -9             9       6.43884            99            99             0          5          0          0          0          0          0          6          2  #  Size_DblN_descend_se_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_5_OR_NTWL(5)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_5_OR_NTWL(5)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_5_OR_NTWL(5)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_5_OR_NTWL(5)
            -9             9       8.26934             0            50             0          5          0          0          0          0          0          6          2  #  SzSel_Fem_Descend_5_OR_NTWL(5)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_5_OR_NTWL(5)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_5_OR_NTWL(5)
# 6   6_WA_NTWL LenSelex
        13.001            65       46.3854            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_6_WA_NTWL(6)
            -9             9       3.43562            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_6_WA_NTWL(6)
            -9             9        2.5854            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_6_WA_NTWL(6)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_6_WA_NTWL(6)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_6_WA_NTWL(6)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_6_WA_NTWL(6)
            -9             9         3.188             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_6_WA_NTWL(6)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_6_WA_NTWL(6)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_6_WA_NTWL(6)
# 7   7_CA_REC LenSelex
        13.001            65         29.03            99            99             0          4          0          0          0          0          0          3          2  #  Size_DblN_peak_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_7_CA_REC(7)
             0             9       3.50127            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_7_CA_REC(7)
             0             9       4.81676            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_descend_se_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_7_CA_REC(7)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_7_CA_REC(7)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          3          2  #  SzSel_Fem_Descend_7_CA_REC(7)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_7_CA_REC(7)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_7_CA_REC(7)
# 8   8_OR_REC LenSelex
        13.001            65       31.0723            99            99             0          4          0          0          0          0          0          4          2  #  Size_DblN_peak_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_8_OR_REC(8)
            -9             9       3.15177            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_ascend_se_8_OR_REC(8)
            -9             9       3.21989            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_descend_se_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_8_OR_REC(8)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_8_OR_REC(8)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_8_OR_REC(8)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_8_OR_REC(8)
            -9             9       2.37881             0            50             0          5          0          0          0          0          0          4          2  #  SzSel_Fem_Descend_8_OR_REC(8)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_8_OR_REC(8)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_8_OR_REC(8)
# 9   9_WA_REC LenSelex
        13.001            65        34.853            99            99             0          4          0          0          0          0          0          5          2  #  Size_DblN_peak_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_9_WA_REC(9)
            -9             9       3.26616            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_ascend_se_9_WA_REC(9)
            -9             9       5.31223            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_descend_se_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_9_WA_REC(9)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_9_WA_REC(9)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_9_WA_REC(9)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_9_WA_REC(9)
            -9             9       3.39056             0            50             0          5          0          0          0          0          0          5          2  #  SzSel_Fem_Descend_9_WA_REC(9)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_9_WA_REC(9)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_9_WA_REC(9)
# 10   10_CA_ASHOP LenSelex
        13.001            65        43.605            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_10_CA_ASHOP(10)
             0             9       2.48108            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_10_CA_ASHOP(10)
             0             9       2.89972            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_10_CA_ASHOP(10)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_10_CA_ASHOP(10)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_10_CA_ASHOP(10)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_10_CA_ASHOP(10)
            -9             9       2.48467             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_10_CA_ASHOP(10)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_10_CA_ASHOP(10)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_10_CA_ASHOP(10)
# 11   11_OR_ASHOP LenSelex
# 12   12_WA_ASHOP LenSelex
# 13   13_CA_FOR LenSelex
# 14   14_OR_FOR LenSelex
# 15   15_WA_FOR LenSelex
# 16   16_CA_NWFSC LenSelex
# 17   17_OR_NWFSC LenSelex
# 18   18_WA_NWFSC LenSelex
# 19   19_CA_Tri_early LenSelex
# 20   20_OR_Tri_early LenSelex
# 21   21_WA_Tri_early LenSelex
# 22   22_CA_Tri_late LenSelex
# 23   23_OR_Tri_late LenSelex
# 24   24_WA_Tri_late LenSelex
# 25   25_CA_prerec LenSelex
# 26   26_OR_prerec LenSelex
# 27   27_WA_prerec LenSelex
# 28   28_coastwide_NWFSC LenSelex
        13.001            65       50.1156            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_28_coastwide_NWFSC(28)
             0             9       6.97971            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_28_coastwide_NWFSC(28)
             0             9     0.0174433            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_28_coastwide_NWFSC(28)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_28_coastwide_NWFSC(28)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_28_coastwide_NWFSC(28)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_28_coastwide_NWFSC(28)
            -9             9        4.0871             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_28_coastwide_NWFSC(28)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_28_coastwide_NWFSC(28)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_28_coastwide_NWFSC(28)
# 29   29_coastwide_Tri_early LenSelex
        13.001            65       64.9721            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_29_coastwide_Tri_early(29)
             0             9       6.69609            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_29_coastwide_Tri_early(29)
             0             9       4.50063            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_29_coastwide_Tri_early(29)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_29_coastwide_Tri_early(29)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_29_coastwide_Tri_early(29)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_29_coastwide_Tri_early(29)
            -9             9    0.00246731             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_29_coastwide_Tri_early(29)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_29_coastwide_Tri_early(29)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_29_coastwide_Tri_early(29)
# 30   30_coastwide_Tri_late LenSelex
# 31   31_coastwide_prerec LenSelex
# 1   1_CA_TWL AgeSelex
# 2   2_OR_TWL AgeSelex
# 3   3_WA_TWL AgeSelex
# 4   4_CA_NTWL AgeSelex
# 5   5_OR_NTWL AgeSelex
# 6   6_WA_NTWL AgeSelex
# 7   7_CA_REC AgeSelex
# 8   8_OR_REC AgeSelex
# 9   9_WA_REC AgeSelex
# 10   10_CA_ASHOP AgeSelex
# 11   11_OR_ASHOP AgeSelex
# 12   12_WA_ASHOP AgeSelex
# 13   13_CA_FOR AgeSelex
# 14   14_OR_FOR AgeSelex
# 15   15_WA_FOR AgeSelex
# 16   16_CA_NWFSC AgeSelex
# 17   17_OR_NWFSC AgeSelex
# 18   18_WA_NWFSC AgeSelex
# 19   19_CA_Tri_early AgeSelex
# 20   20_OR_Tri_early AgeSelex
# 21   21_WA_Tri_early AgeSelex
# 22   22_CA_Tri_late AgeSelex
# 23   23_OR_Tri_late AgeSelex
# 24   24_WA_Tri_late AgeSelex
# 25   25_CA_prerec AgeSelex
# 26   26_OR_prerec AgeSelex
# 27   27_WA_prerec AgeSelex
# 28   28_coastwide_NWFSC AgeSelex
# 29   29_coastwide_Tri_early AgeSelex
# 30   30_coastwide_Tri_late AgeSelex
# 31   31_coastwide_prerec AgeSelex
#_No_Dirichlet parameters
# timevary selex parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type    PHASE  #  parm_name
        13.001            65       43.7743            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2000
        13.001            65       45.2041            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2011
             0             9       3.78717            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       4.30368            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2011
             0             9       1.68047            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9        1.8123            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2011
            -9             9       2.46135             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2000
            -9             9       1.97672             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2011
        13.001            65       43.7705            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2000
        13.001            65       45.5713            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2011
             0             9       4.27035            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       4.76301            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2011
             0             9       3.73592            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       2.82443            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2011
            -9             9       8.80073             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2000
            -9             9       2.02771             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2011
        13.001            65       33.6216            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2000
        13.001            65       34.4933            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2020
             0             9       3.04058            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       2.71648            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2020
             0             9       4.34505            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       4.20045            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2020
            -9             9       1.14547             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2000
            -9             9      0.960014             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2020
        13.001            65        32.907            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK6repl_2000
            -9             9       2.48227            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK6repl_2000
            -9             9       4.36239            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK6repl_2000
            -9             9       1.13979             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK6repl_2000
        13.001            65       30.3408            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2004
        13.001            65       32.0943            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2017
             0             9       3.33599            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       3.29501            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2017
             0             9       3.72238            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       4.23643            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2017
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2004
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2017
        13.001            65        31.741            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2004
        13.001            65       30.9615            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2015
            -9             9       2.71045            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       2.13177            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9       4.57266            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       4.13828            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2004
            -9             9       1.19634             0            50             0      5  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2015
        13.001            65       32.0858            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2006
            -9             9       2.13286            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9       4.59022            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9       1.05086             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2006
# info on dev vectors created for selex parms are reported with other devs after tag parameter section 
#
0   #  use 2D_AR1 selectivity(0/1)
#_no 2D_AR1 selex offset used
#
# Tag loss and Tag reporting parameters go next
0  # TG_custom:  0=no read and autogen if tag data exist; 1=read
#_Cond -6 6 1 1 2 0.01 -4 0 0 0 0 0 0 0  #_placeholder if no parameters
#
# deviation vectors for timevary parameters
#  base   base first block   block  env  env   dev   dev   dev   dev   dev
#  type  index  parm trend pattern link  var  vectr link _mnyr  mxyr phase  dev_vector
#      5     1     1     1     2     0     0     0     0     0     0     0
#      5     3     3     1     2     0     0     0     0     0     0     0
#      5     4     5     1     2     0     0     0     0     0     0     0
#      5     9     7     1     2     0     0     0     0     0     0     0
#      5    12     9     1     2     0     0     0     0     0     0     0
#      5    14    11     1     2     0     0     0     0     0     0     0
#      5    15    13     1     2     0     0     0     0     0     0     0
#      5    20    15     1     2     0     0     0     0     0     0     0
#      5    23    17     2     2     0     0     0     0     0     0     0
#      5    25    19     2     2     0     0     0     0     0     0     0
#      5    26    21     2     2     0     0     0     0     0     0     0
#      5    31    23     2     2     0     0     0     0     0     0     0
#      5    34    25     6     2     0     0     0     0     0     0     0
#      5    36    26     6     2     0     0     0     0     0     0     0
#      5    37    27     6     2     0     0     0     0     0     0     0
#      5    42    28     6     2     0     0     0     0     0     0     0
#      5    56    29     3     2     0     0     0     0     0     0     0
#      5    58    31     3     2     0     0     0     0     0     0     0
#      5    59    33     3     2     0     0     0     0     0     0     0
#      5    64    35     3     2     0     0     0     0     0     0     0
#      5    67    37     4     2     0     0     0     0     0     0     0
#      5    69    39     4     2     0     0     0     0     0     0     0
#      5    70    41     4     2     0     0     0     0     0     0     0
#      5    75    43     4     2     0     0     0     0     0     0     0
#      5    78    45     5     2     0     0     0     0     0     0     0
#      5    80    46     5     2     0     0     0     0     0     0     0
#      5    81    47     5     2     0     0     0     0     0     0     0
#      5    86    48     5     2     0     0     0     0     0     0     0
     #
# Input variance adjustments factors: 
 #_1=add_to_survey_CV
 #_2=add_to_discard_stddev
 #_3=add_to_bodywt_CV
 #_4=mult_by_lencomp_N
 #_5=mult_by_agecomp_N
 #_6=mult_by_size-at-age_N
 #_7=mult_by_generalized_sizecomp
#_Factor  Fleet  Value
      4      1  0.240492
      5      1   1.25386
      4      2  0.257366
      5      2   0.24574
      4      3  0.198837
      5      3  0.210923
      4      4  0.211897
      4      5    0.0833
      4      6   1.66921
      4      7  0.157959
      5      8   1.48788
      4      9   0.93728
      5      9  0.818006
      4     11  0.190467
      5     11  0.473512
      4     12  0.103997
      5     12   0.10624
      4     16     0.081
      4     17     0.081
      4     18     0.081
      4     19     0.093
      4     20     0.093
      4     21     0.093
      4     22     0.114
      4     23     0.114
      4     24     0.114
      4      8  0.258734
      4     28  0.046829
      4     29  0.103277
      4     30  0.046847
      5      4  0.515112
      5      5  0.700894
      5      6   1.09996
      5     28  0.205077
      5     29  0.118712
      5     30  0.183054
 -9999   1    0  # terminator
#
1 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 0 changes to default Lambdas (default value is 1.0)
# Like_comp codes:  1=surv; 2=disc; 3=mnwt; 4=length; 5=age; 6=SizeFreq; 7=sizeage; 8=catch; 9=init_equ_catch; 
# 10=recrdev; 11=parm_prior; 12=parm_dev; 13=CrashPen; 14=Morphcomp; 15=Tag-comp; 16=Tag-negbin; 17=F_ballpark; 18=initEQregime
#like_comp fleet  phase  value  sizefreq_method
-9999  1  1  1  1  #  terminator
#
# lambdas (for info only; columns are phases)
#  0 #_CPUE/survey:_1
#  0 #_CPUE/survey:_2
#  0 #_CPUE/survey:_3
#  0 #_CPUE/survey:_4
#  0 #_CPUE/survey:_5
#  0 #_CPUE/survey:_6
#  0 #_CPUE/survey:_7
#  0 #_CPUE/survey:_8
#  0 #_CPUE/survey:_9
#  0 #_CPUE/survey:_10
#  0 #_CPUE/survey:_11
#  0 #_CPUE/survey:_12
#  0 #_CPUE/survey:_13
#  0 #_CPUE/survey:_14
#  0 #_CPUE/survey:_15
#  0 #_CPUE/survey:_16
#  0 #_CPUE/survey:_17
#  0 #_CPUE/survey:_18
#  0 #_CPUE/survey:_19
#  0 #_CPUE/survey:_20
#  0 #_CPUE/survey:_21
#  0 #_CPUE/survey:_22
#  0 #_CPUE/survey:_23
#  0 #_CPUE/survey:_24
#  0 #_CPUE/survey:_25
#  0 #_CPUE/survey:_26
#  0 #_CPUE/survey:_27
#  1 #_CPUE/survey:_28
#  1 #_CPUE/survey:_29
#  1 #_CPUE/survey:_30
#  1 #_CPUE/survey:_31
#  1 #_lencomp:_1
#  1 #_lencomp:_2
#  1 #_lencomp:_3
#  1 #_lencomp:_4
#  1 #_lencomp:_5
#  1 #_lencomp:_6
#  1 #_lencomp:_7
#  1 #_lencomp:_8
#  1 #_lencomp:_9
#  0 #_lencomp:_10
#  1 #_lencomp:_11
#  1 #_lencomp:_12
#  0 #_lencomp:_13
#  0 #_lencomp:_14
#  0 #_lencomp:_15
#  0 #_lencomp:_16
#  0 #_lencomp:_17
#  0 #_lencomp:_18
#  0 #_lencomp:_19
#  0 #_lencomp:_20
#  0 #_lencomp:_21
#  0 #_lencomp:_22
#  0 #_lencomp:_23
#  0 #_lencomp:_24
#  0 #_lencomp:_25
#  0 #_lencomp:_26
#  0 #_lencomp:_27
#  1 #_lencomp:_28
#  1 #_lencomp:_29
#  1 #_lencomp:_30
#  0 #_lencomp:_31
#  1 #_agecomp:_1
#  1 #_agecomp:_2
#  1 #_agecomp:_3
#  1 #_agecomp:_4
#  1 #_agecomp:_5
#  1 #_agecomp:_6
#  0 #_agecomp:_7
#  1 #_agecomp:_8
#  1 #_agecomp:_9
#  0 #_agecomp:_10
#  1 #_agecomp:_11
#  1 #_agecomp:_12
#  0 #_agecomp:_13
#  0 #_agecomp:_14
#  0 #_agecomp:_15
#  1 #_agecomp:_16
#  1 #_agecomp:_17
#  1 #_agecomp:_18
#  1 #_agecomp:_19
#  1 #_agecomp:_20
#  1 #_agecomp:_21
#  1 #_agecomp:_22
#  1 #_agecomp:_23
#  1 #_agecomp:_24
#  0 #_agecomp:_25
#  0 #_agecomp:_26
#  0 #_agecomp:_27
#  1 #_agecomp:_28
#  1 #_agecomp:_29
#  1 #_agecomp:_30
#  0 #_agecomp:_31
#  1 #_init_equ_catch1
#  1 #_init_equ_catch2
#  1 #_init_equ_catch3
#  1 #_init_equ_catch4
#  1 #_init_equ_catch5
#  1 #_init_equ_catch6
#  1 #_init_equ_catch7
#  1 #_init_equ_catch8
#  1 #_init_equ_catch9
#  1 #_init_equ_catch10
#  1 #_init_equ_catch11
#  1 #_init_equ_catch12
#  1 #_init_equ_catch13
#  1 #_init_equ_catch14
#  1 #_init_equ_catch15
#  1 #_init_equ_catch16
#  1 #_init_equ_catch17
#  1 #_init_equ_catch18
#  1 #_init_equ_catch19
#  1 #_init_equ_catch20
#  1 #_init_equ_catch21
#  1 #_init_equ_catch22
#  1 #_init_equ_catch23
#  1 #_init_equ_catch24
#  1 #_init_equ_catch25
#  1 #_init_equ_catch26
#  1 #_init_equ_catch27
#  1 #_init_equ_catch28
#  1 #_init_equ_catch29
#  1 #_init_equ_catch30
#  1 #_init_equ_catch31
#  1 #_recruitments
#  1 #_parameter-priors
#  1 #_parameter-dev-vectors
#  1 #_crashPenLambda
#  0 # F_ballpark_lambda
0 # (0/1/2) read specs for more stddev reporting: 0 = skip, 1 = read specs for reporting stdev for selectivity, size, and numbers, 2 = add options for M,Dyn. Bzero, SmryBio
 # 0 2 0 0 # Selectivity: (1) fleet, (2) 1=len/2=age/3=both, (3) year, (4) N selex bins
 # 0 0 # Growth: (1) growth pattern, (2) growth ages
 # 0 0 0 # Numbers-at-age: (1) area(-1 for all), (2) year, (3) N ages
 # -1 # list of bin #'s for selex std (-1 in first bin to self-generate)
 # -1 # list of ages for growth std (-1 in first bin to self-generate)
 # -1 # list of ages for NatAge std (-1 in first bin to self-generate)
999

