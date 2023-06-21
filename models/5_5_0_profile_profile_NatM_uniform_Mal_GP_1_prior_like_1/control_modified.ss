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
5 #_Nblock_Patterns
 2 2 2 2 2 #_blocks_per_pattern 
# begin and end years of blocks
 2000 2010 2011 2022
 2000 2019 2020 2022
 2004 2016 2017 2022
 2004 2014 2015 2022
 2006 2020 2021 2022
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
 0.02 0.2 0.0810807 -2.74 0.31 3 1 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 2 15 8.36082 4 50 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 50 70 59.4819 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.02 0.21 0.136882 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.02 0.21 0.0818184 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.21 0.0417322 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 0 0.1 1.19e-05 1.19e-05 50 6 -50 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 2 4 3.09 3.09 50 6 -50 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 9 12 10.87 10.87 0.055 6 -50 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 3 -0.688 -0.688 50 6 -50 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 1e-10 0.1 7.218e-08 -16.4441 0.135 3 -50 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 2 6 4.043 4.043 0.3 6 -50 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.02 0.2 0.0725 -2.74 0.31 6 -50 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 0 15 0 0 50 6 -50 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 50 70 54.6182 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.02 0.21 0.155833 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.02 0.21 0.0897767 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.21 0.0478876 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 0 0.1 1.08e-05 1.08e-05 50 6 -50 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 2 4 3.118 3.118 50 6 -50 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
# Hermaphroditism
#  Recruitment Distribution 
#  Cohort growth dev base
 -1 1 1 1 50 6 -50 0 0 0 0 0 0 0 # CohortGrowDev
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
             7            11       8.27338           8.5            50             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
          0.21          0.99          0.72          0.72          0.16             2         -6          0          0          0          0          0          0          0 # SR_BH_steep
             0             2           0.5           0.4            50             6        -50          0          0          0          0          0          0          0 # SR_sigmaR
            -5             5             0             0            50             6        -50          0          0          0          0          0          0          0 # SR_regime
             0             2             0             1            50             6        -50          0          0          0          0          0          0          0 # SR_autocorr
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
#  -0.0035132 -0.00376613 -0.00403434 -0.00432231 -0.00463153 -0.00496304 -0.00531826 -0.00569877 -0.00610605 -0.00654168 -0.00700769 -0.00750659 -0.00804096 -0.00861284 -0.00922378 -0.00987515 -0.0105695 -0.0113114 -0.0121062 -0.0129592 -0.0138756 -0.0148608 -0.0159197 -0.0170556 -0.0182711 -0.0195722 -0.0209675 -0.0224681 -0.0240913 -0.0258445 -0.0277367 -0.029777 -0.0319598 -0.0342896 -0.0367692 -0.03938 -0.0421048 -0.0449067 -0.0477544 -0.0506394 -0.0535286 -0.0565157 -0.0597302 -0.0633842 -0.0677573 -0.073016 -0.079111 -0.0857253 -0.0927151 -0.0990691 -0.104375 -0.108571 -0.111829 -0.111673 -0.108979 -0.10454 -0.0978106 -0.0883334 -0.0757239 -0.0603746 -0.0421815 -0.0209748 0.00429249 0.0362464 0.0792921 0.139936 0.227349 0.352185 0.444018 0.521409 0.368179 0.138823 -0.0214153 -0.0618644 0.0444886 0.330083 0.739465 0.118697 -0.277701 -0.266502 0.20984 0.424845 0.00211284 0.136088 0.403114 -0.134868 0.256216 0.132997 -0.469207 0.207809 -0.00523948 -0.239754 0.108069 0.0520261 -0.0763127 0.0507843 0.0827754 0.3587 0.277711 0.108816 0.31748 -0.015008 0.225676 0.379011 0.259726 -0.00400538 -0.0854993 -0.233926 -0.105265 0.088243 0.0117384 0.334903 0.0248529 -0.575151 -0.287923 0.165858 -0.742293 -0.404313 -0.0136285 -0.0213598 -0.0503408 0.115816 -0.607983 -0.292894 -0.0379206 -0.748227 -0.929998 -0.575204 -0.286717 0.164405 -0.0342566 0 0 0 0 0 0 0 0 0 0 0 0
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
# 1_CA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000257023 0.00039384 0.000420735 0.000326371 0.000327362 0.000254765 0.000225113 0.000265288 0.000144936 9.96048e-05 0.000326366 0.000421321 0.000520202 0.00095509 0.000828389 0.0011507 0.000787754 0.00107412 0.000923822 0.000946575 0.000569037 0.000868378 0.000887225 0.00117774 0.00096363 0.00076743 0.000186938 0.000935248 0.00401022 0.00956746 0.00914178 0.0037707 0.00435545 0.00388576 0.00354366 0.00721333 0.00520232 0.00500846 0.00361468 0.00389168 0.00384666 0.0044221 0.00594192 0.00447186 0.00345455 0.002706 0.00270022 0.00379499 0.00236675 0.00312212 0.0022564 0.00306706 0.00288495 0.00699144 0.00747168 0.0112773 0.0141538 0.0112546 0.0144658 0.015845 0.0173293 0.0169623 0.025333 0.0130109 0.0195892 0.0260435 0.042184 0.0304119 0.0256884 0.0219966 0.0118299 0.0155288 0.018327 0.0165484 0.0332186 0.0170629 0.0307992 0.0139808 0.0192585 0.0193769 0.0302744 0.0233048 0.0203467 0.0122071 0.0021006 0.00141105 0.00206091 0.000153543 0.000291491 0.000381398 0.00116498 0.00254119 0.00124904 0.000201556 5.69411e-05 3.67361e-05 5.69262e-05 0.000152247 0.000195634 0.000692316 0.000277986 0.00737778 0.0136439 0.0170834 0.00708061 0.00754495 0.00879122 0 0 0.0133611 0.013272 0.0131802 0.0130731 0.0129436 0.012835 0.0127478 0.0126758 0.0126451 0.0126328
# 2_OR_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1.82961e-05 1.12267e-05 4.59068e-07 8.96923e-06 3.27237e-05 6.3969e-05 0 9.16432e-05 0.0021129 0.00326742 0.00617587 0.0219157 0.039544 0.06422 0.0418313 0.0269351 0.0195783 0.0172478 0.0183486 0.0171275 0.0179753 0.0190251 0.0243864 0.0248417 0.0373588 0.039661 0.0275157 0.0304646 0.0367272 0.0336717 0.0397457 0.022943 0.0350867 0.0286603 0.0326234 0.00533467 0.030199 0.00955002 0.0193931 0.0249789 0.0241339 0.030192 0.0194735 0.013974 0.00901021 0.020975 0.0658718 0.0526165 0.119728 0.0890823 0.189033 0.200648 0.0838638 0.0737022 0.0749587 0.115772 0.138939 0.147925 0.111759 0.250322 0.244567 0.293572 0.137889 0.102566 0.133673 0.0975705 0.110458 0.0579575 0.00402912 0.00185869 0.0024724 0.00132075 0.000569221 0.00110655 0.00114165 0.000228702 0.000295383 0.000463791 0.000232183 0.000221738 0.000460921 0.00040776 0.000677997 0.00265317 0.00108235 0.00931831 0.0109028 0.0121758 0.0116551 0.0139612 0.0198875 0 0 0.0190331 0.0189064 0.0187759 0.0186238 0.01844 0.0182856 0.0181615 0.018059 0.0180152 0.0179976
# 3_WA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9.14803e-07 0 6.88602e-06 5.33554e-05 6.89042e-05 6.16597e-05 9.11931e-05 9.58193e-05 0.000212756 7.99669e-05 0.00156397 0.00513117 0.00219258 0.0241859 0.0128984 0.00695972 0.0115287 0.0142659 0.0139258 0.0118209 0.0114223 0.00500139 0.00724218 0.00691193 0.00670293 0.00565163 0.00726303 0.00821061 0.00751217 0.00900887 0.0126793 0.010245 0.00753264 0.0167084 0.0231831 0.0113794 0.0193508 0.0184349 0.0165041 0.0185927 0.00516947 0.0117515 0.0183791 0.0255692 0.0195207 0.0163837 0.0495848 0.0265752 0.0306363 0.0232833 0.0218886 0.0378954 0.0393389 0.0700287 0.0635447 0.0764088 0.0808322 0.112232 0.115956 0.120354 0.123707 0.0514081 0.028353 0.0285548 0.0322682 0.0332201 0.0316934 0.0204697 0.00129075 0.000859396 0.00198834 0.000848995 0.000581937 0.0017141 0.000635872 0.000271079 0.000209418 0.000333658 0.000396181 0.000255141 0.00034793 0.000307161 0.000141769 0.000255175 0.000320249 0.00234688 0.00979806 0.00409469 0.00492724 0.00459772 0.00646011 0 0 0.0066259 0.00658182 0.00653639 0.00648341 0.00641942 0.00636567 0.0063225 0.00628681 0.00627155 0.00626544
# 4_CA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000954113 0.00154273 0.00159743 0.000929297 0.00100541 0.000901146 0.00083971 0.0010153 0.00123084 0.00151651 0.00178302 0.00143875 0.00124866 0.000849393 0.00120951 0.00118054 0.000979963 0.000391866 0.000546174 0.000830325 0.000750932 0.000477931 0.000490441 0.000469664 0.000348499 0.000452252 0.00033814 0.000284655 0.00108997 0.00276486 0.00297004 0.000693886 0.00137279 0.000536444 0.000439794 0.000717873 0.000545887 0.000319954 0.00078681 0.000186023 0.000291116 0.000322947 0.000421862 0.000292041 0.000372306 0.000300664 0.000425782 0.000387665 0.00035245 0.000377887 0.000295037 0.000307268 0.000191626 0.00075274 0.000477932 0.000856966 0.00166786 0.000801323 0.00207346 0.001522 0.00217093 0.00263754 0.0067543 0.00624682 0.00487951 0.00923073 0.00260972 0.00443579 0.00422855 0.00818462 0.00425739 0.00406097 0.00467808 0.0202643 0.0212367 0.0181272 0.0158502 0.0144116 0.0124733 0.0139333 0.0147759 0.0121577 0.00955078 0.0035934 0.00210205 0.00164734 1.64521e-05 0.000325599 0.000362029 0.000238746 0.000385814 0.000484707 0.000165265 0.0002084 0.000659114 0.00161442 0.000518007 0.000776454 0.000537183 0.000626426 0.00035935 0.00080923 0.000828053 0.00118937 0.00196172 0.00273461 0.00246914 0 0 0.0027562 0.00273782 0.00271883 0.00269669 0.00266999 0.00264761 0.00262966 0.00261482 0.00260847 0.00260592
# 5_OR_NTWL 9.73007e-05 9.73089e-05 9.73169e-05 2.50447e-05 6.05111e-06 6.2192e-06 3.52984e-06 5.8832e-06 8.23686e-06 1.07591e-05 1.31141e-05 1.54699e-05 1.7995e-05 2.03532e-05 2.27128e-05 2.50738e-05 2.76046e-05 2.99687e-05 3.23346e-05 3.48707e-05 3.72404e-05 3.96121e-05 4.21546e-05 4.45309e-05 4.69203e-05 4.93326e-05 5.193e-05 5.43611e-05 5.67926e-05 5.93995e-05 6.18399e-05 6.42875e-05 6.69147e-05 6.93815e-05 7.18659e-05 7.38523e-05 0.000123442 0.000211788 0.000193437 0.000155593 4.96602e-05 8.1871e-05 8.84127e-05 7.95598e-05 0.000190507 0.000227423 0.000224932 0.00012844 0.000285179 0.000383179 0.000535417 0.00134423 0.000354993 0.000237537 0.000308022 0.000161197 0.000270915 0.00018434 0.000174673 0.000136917 0.000132495 7.01095e-05 8.29956e-05 0.00010437 6.77106e-05 0.000150265 3.06013e-05 6.36654e-05 4.29255e-05 0.000121226 0.000112365 0.000101547 2.34404e-05 0.000171608 0.000118729 0.000340286 0.000309558 0.000681164 0.000260587 0.000526709 0.000684048 0.000734507 0.00094347 0.000501075 0.00066811 0.000825483 0.00133696 0.00398928 0.00244619 0.00287334 0.00585244 0.0138489 0.0103434 0.0109351 0.00923783 0.0156997 0.0144527 0.0160358 0.0240352 0.0312499 0.0239009 0.0712294 0.0203888 0.0193073 0.0267258 0.0402412 0.0385231 0.0177014 0.00244142 0.00222398 9.58442e-05 9.60005e-05 0.00118985 0.000382874 0.000564004 0.000379557 0.000160859 0.00053221 0.000171826 0.000717332 0.000310051 0.000456298 0.000305951 0.000530613 0.00106237 0.000864875 0.000651247 0.000939946 0.00053983 0.000475249 0.000809918 0 0 0.000912263 0.000906185 0.000899918 0.00089261 0.000883787 0.00087638 0.000870431 0.000865515 0.000863415 0.000862573
# 6_WA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000682761 0.000632299 0.000951535 0.00100179 0.000967966 0.000507098 0.000661199 0.000462662 0.00070835 0.00020626 0.00019166 9.25929e-05 6.39492e-05 0.000438826 0.000272116 0.000370295 0.000721187 0.000435151 0.000225447 0.000397523 0.000624978 0.000327679 0.000207237 0.000137184 0.000109321 0.000185085 8.52456e-05 5.53773e-05 0 0 0.00014357 0.000142616 0.000141635 0.000140492 0.000139109 0.000137947 0.000137012 0.00013624 0.000135909 0.000135777
# 7_CA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000171747 0.000344212 0.000395995 0.000529724 0.000664154 0.000799176 0.000934924 0.00107061 0.00120837 0.00143772 0.00141791 0.00124451 0.00179582 0.00166716 0.000890486 0.000858666 0.000714919 0.000976969 0.00171895 0.00138306 0.00277781 0.00361493 0.00443095 0.00527597 0.0046331 0.00397009 0.00499693 0.00604745 0.006744 0.00629979 0.0106326 0.00846881 0.00647688 0.00442268 0.00519955 0.00524856 0.00449877 0.00645531 0.00681331 0.00721376 0.0079596 0.00918094 0.0119958 0.0104426 0.0132444 0.0153336 0.0168822 0.0174572 0.0200363 0.0193626 0.0190945 0.0215408 0.020268 0.0192596 0.036177 0.0147694 0.0158417 0.0249735 0.0360453 0.0378326 0.0325672 0.0214378 0.0340902 0.0339679 0.0330873 0.034146 0.0273992 0.0348344 0.012833 0.0218131 0.00595441 0.014912 0.0178323 0.00782368 0.00149685 0.00452809 0.00495848 0.00264888 0.00580927 0.00504797 0.00246365 0.00589024 0.00546106 0.00689619 0.00640202 0.00540046 0.00806741 0.00900699 0.00729067 0.01529 0.0111765 0.0132461 0.0146217 0.0144005 0.013292 0 0 0.0183298 0.0182075 0.0180808 0.0179334 0.0177561 0.0176076 0.0174884 0.0173899 0.0173478 0.0173308
# 8_OR_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000450493 0.00093296 0.00150565 0.00211447 0.00264967 0.00322834 0.00389322 0.004203 0.00551798 0.00626753 0.00384099 0.00507913 0.00284963 0.00587688 0.00402693 0.00335461 0.00414403 0.00272235 0.00396292 0.00573884 0.00783255 0.00598512 0.00723087 0.00453439 0.00598574 0.0094327 0.0057604 0.00470183 0.00248148 0.00204818 0.00207588 0.000503778 0.000749551 0.000398905 0.000416266 0.000501033 0.000653535 0.000857048 0.000577979 0.000551567 0.000756261 0.000576318 0.00228939 0.00149641 0.00415851 0.0063205 0.00575576 0.00917209 0.00594251 0.00908993 0 0 0.00988424 0.0098183 0.00975007 0.00967068 0.00957505 0.00949492 0.00943062 0.00937743 0.0093547 0.00934554
# 9_WA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5.62428e-05 7.92444e-05 0.000104517 0.000133737 0.000165165 0.000192928 0.000212807 0.000234212 0.000267758 0.000126848 0.000341448 0.000516436 0.000382197 0.000254557 0.000225425 0.000258871 0.000485067 0.000887246 0.000448751 0.00076447 0.000826017 0.000854845 0.00141417 0.00141903 0.0016677 0.00350183 0.00348666 0.00193856 0.0015471 0.00144696 0.00137203 0.00238387 0.00143866 0.00112172 0.000948913 0.000408455 0.000377811 0.000171244 0.000259147 0.000123138 0.00010198 8.30647e-05 7.77691e-05 0.000143419 0.00014968 0.000127741 0.000128392 0.000184162 0.000280162 0.000234233 0.000558332 0.000454922 0.00144051 0.000888125 0.00163431 0.00175 0 0 0.00188534 0.00187281 0.00185989 0.00184483 0.00182665 0.00181138 0.00179911 0.00178897 0.00178464 0.00178291
# 10_CA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.14248e-05 1.62339e-06 2.34242e-05 0.000177208 4.15403e-06 3.92548e-06 3.36535e-06 0 2.66736e-06 0 1.64025e-05 3.19992e-05 7.68904e-06 2.96917e-06 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.33168e-08 7.28252e-08 7.23196e-08 7.17321e-08 7.10244e-08 7.04311e-08 6.99554e-08 6.95627e-08 6.93962e-08 6.93305e-08
# 11_OR_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000385773 7.21353e-05 0.000594415 0.000604442 0.000494251 9.33335e-05 1.52315e-05 0.00016173 9.84364e-05 0.000397113 7.64642e-05 0.000231208 0.000378282 0.000179424 0.000276805 0.000308794 1.5707e-05 3.176e-05 0.000135211 2.89303e-05 3.62844e-06 7.84914e-05 4.04284e-05 1.06751e-05 3.3375e-05 0.000131868 0.000284353 2.66318e-05 0.000474398 5.43232e-05 4.5557e-05 0.000176736 5.32158e-05 2.95089e-06 2.83298e-06 8.94138e-07 8.53241e-06 6.63355e-06 3.00237e-05 6.37551e-06 1.81855e-05 0.000142373 0.000239498 5.60685e-05 1.6362e-05 0.00025051 0.000328854 0 0 0.000215076 0.000213647 0.000212176 0.000210459 0.000208381 0.000206635 0.000205232 0.000204073 0.000203578 0.000203379
# 12_WA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.79021e-05 1.6775e-05 0.000100138 2.08108e-05 0.00187139 0.00205931 0.000178363 0.000243113 0.000340533 0.000590658 0.000228609 0.000119997 0.000234516 0.000259802 0.000378714 0.000136965 0.000809218 5.01458e-05 0.000177793 0.000455592 0.000766523 0.00102939 0.00031011 0.000368978 0.000333908 7.65663e-05 7.71293e-05 9.32719e-05 6.47921e-05 2.42381e-05 0.000326323 0.000247875 0.000107653 9.56727e-05 2.64505e-05 4.56057e-05 2.10977e-05 1.03602e-05 2.29296e-05 0.000377289 0.000200639 0.00034036 5.60983e-05 0.000205803 0.000119442 0 0 0.000238145 0.000236562 0.000234933 0.000233032 0.000230732 0.000228798 0.000227244 0.000225961 0.000225413 0.000225193
# 13_CA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00154755 0.00383708 0.0150409 0.000176329 0 0 0.000449403 0.0131579 0.00542347 0.00229385 0.00178833 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.32762e-08 7.27813e-08 7.22744e-08 7.16873e-08 7.0981e-08 7.03899e-08 6.99164e-08 6.95251e-08 6.93594e-08 6.9294e-08
# 14_OR_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0504412 0.023095 0.00989088 0.00169003 0.00238763 0.00379496 0.010196 0.0170788 0.00269606 0.00474732 0.00384245 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.3331e-08 7.28409e-08 7.23366e-08 7.17497e-08 7.10419e-08 7.04481e-08 6.99716e-08 6.95781e-08 6.94109e-08 6.93447e-08
# 15_WA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00394454 0.00315889 0.0037696 0.000405607 0.000915803 0.00225125 0.00218027 0.00221211 0.00958599 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.3331e-08 7.28409e-08 7.23366e-08 7.17497e-08 7.10419e-08 7.04481e-08 6.99716e-08 6.95781e-08 6.94109e-08 6.93447e-08
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
           -25            25     -0.816477             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_28_coastwide_NWFSC(28)
           -25            25      -1.45852             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_29_coastwide_Tri_early(29)
           -25            25      -1.45852             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_30_coastwide_Tri_late(30)
           -25            25      -2.91641             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_31_coastwide_prerec(31)
             0             3      0.464402           0.1            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_31_coastwide_prerec(31)
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
        13.001            65       45.6528            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_1_CA_TWL(1)
             0             9       4.26341            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_1_CA_TWL(1)
             0             9       3.33615            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_1_CA_TWL(1)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_1_CA_TWL(1)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_1_CA_TWL(1)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_1_CA_TWL(1)
            -9             9       1.24853             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_1_CA_TWL(1)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_1_CA_TWL(1)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_1_CA_TWL(1)
# 2   2_OR_TWL LenSelex
        13.001            65       49.2953            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_2_OR_TWL(2)
             0             9       4.13878            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_2_OR_TWL(2)
             0             9        2.3781            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_2_OR_TWL(2)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_2_OR_TWL(2)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_2_OR_TWL(2)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_2_OR_TWL(2)
            -9             9       2.29844             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_2_OR_TWL(2)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_2_OR_TWL(2)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_2_OR_TWL(2)
# 3   3_WA_TWL LenSelex
# 4   4_CA_NTWL LenSelex
        13.001            65       36.4954            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_4_CA_NTWL(4)
             0             9       4.28446            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_4_CA_NTWL(4)
             0             9       5.00028            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_4_CA_NTWL(4)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_4_CA_NTWL(4)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_4_CA_NTWL(4)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_4_CA_NTWL(4)
            -9             9      0.370792             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_4_CA_NTWL(4)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_4_CA_NTWL(4)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_4_CA_NTWL(4)
# 5   5_OR_NTWL LenSelex
        13.001            65       55.4968            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_5_OR_NTWL(5)
            -9             9       5.24285            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_5_OR_NTWL(5)
            -9             9       8.31436            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_5_OR_NTWL(5)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_5_OR_NTWL(5)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_5_OR_NTWL(5)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_5_OR_NTWL(5)
            -9             9       4.23189             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_5_OR_NTWL(5)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_5_OR_NTWL(5)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_5_OR_NTWL(5)
# 6   6_WA_NTWL LenSelex
        13.001            65       47.1813            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_6_WA_NTWL(6)
            -9             9       3.58751            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_6_WA_NTWL(6)
            -9             9       2.14156            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_6_WA_NTWL(6)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_6_WA_NTWL(6)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_6_WA_NTWL(6)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_6_WA_NTWL(6)
            -9             9       2.76337             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_6_WA_NTWL(6)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_6_WA_NTWL(6)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_6_WA_NTWL(6)
# 7   7_CA_REC LenSelex
        13.001            65       28.8522            99            99             0          4          0          0          0          0          0          3          2  #  Size_DblN_peak_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_7_CA_REC(7)
             0             9       3.47908            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_7_CA_REC(7)
             0             9       4.82802            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_descend_se_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_7_CA_REC(7)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_7_CA_REC(7)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          3          2  #  SzSel_Fem_Descend_7_CA_REC(7)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_7_CA_REC(7)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_7_CA_REC(7)
# 8   8_OR_REC LenSelex
        13.001            65       30.9436            99            99             0          4          0          0          0          0          0          4          2  #  Size_DblN_peak_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_8_OR_REC(8)
            -9             9       3.12642            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_ascend_se_8_OR_REC(8)
            -9             9       3.17632            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_descend_se_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_8_OR_REC(8)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_8_OR_REC(8)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_8_OR_REC(8)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_8_OR_REC(8)
            -9             9       2.29312             0            50             0          5          0          0          0          0          0          4          2  #  SzSel_Fem_Descend_8_OR_REC(8)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_8_OR_REC(8)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_8_OR_REC(8)
# 9   9_WA_REC LenSelex
        13.001            65       34.1851            99            99             0          4          0          0          0          0          0          5          2  #  Size_DblN_peak_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_9_WA_REC(9)
            -9             9       2.72615            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_ascend_se_9_WA_REC(9)
            -9             9       3.83857            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_descend_se_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_9_WA_REC(9)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_9_WA_REC(9)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_9_WA_REC(9)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_9_WA_REC(9)
            -9             9       1.31007             0            50             0          5          0          0          0          0          0          5          2  #  SzSel_Fem_Descend_9_WA_REC(9)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_9_WA_REC(9)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_9_WA_REC(9)
# 10   10_CA_ASHOP LenSelex
        13.001            65       43.7001            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_10_CA_ASHOP(10)
             0             9       2.53729            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_10_CA_ASHOP(10)
             0             9       2.87591            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_10_CA_ASHOP(10)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_10_CA_ASHOP(10)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_10_CA_ASHOP(10)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_10_CA_ASHOP(10)
            -9             9        2.1245             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_10_CA_ASHOP(10)
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
        13.001            65       49.0892            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_28_coastwide_NWFSC(28)
             0             9        6.8246            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_28_coastwide_NWFSC(28)
             0             9       1.71786            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_28_coastwide_NWFSC(28)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_28_coastwide_NWFSC(28)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_28_coastwide_NWFSC(28)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_28_coastwide_NWFSC(28)
            -9             9       2.66878             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_28_coastwide_NWFSC(28)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_28_coastwide_NWFSC(28)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_28_coastwide_NWFSC(28)
# 29   29_coastwide_Tri_early LenSelex
        13.001            65       57.0191            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_29_coastwide_Tri_early(29)
             0             9       6.49019            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_29_coastwide_Tri_early(29)
             0             9       7.20631            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_29_coastwide_Tri_early(29)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_29_coastwide_Tri_early(29)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_29_coastwide_Tri_early(29)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_29_coastwide_Tri_early(29)
            -9             9       3.11578             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_29_coastwide_Tri_early(29)
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
        13.001            65       43.9564            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2000
        13.001            65       43.3881            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2011
             0             9       3.79452            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       3.86818            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2011
             0             9       1.61656            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       2.48142            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2011
            -9             9       2.30987             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2000
            -9             9       1.47969             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2011
        13.001            65       43.2848            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2000
        13.001            65       45.8082            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2011
             0             9       4.27393            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       4.75725            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2011
             0             9        3.8867            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       2.66499            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2011
            -9             9       7.87382             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2000
            -9             9       1.80031             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2011
        13.001            65       33.4491            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2000
        13.001            65       38.5373            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2020
             0             9       3.00893            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       3.71539            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2020
             0             9        4.4587            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       3.66146            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2020
            -9             9      0.908152             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2000
            -9             9       1.01405             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2020
        13.001            65       33.3548            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK2repl_2000
        13.001            65       45.5068            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK2repl_2020
            -9             9       2.48602            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       5.19569            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK2repl_2020
            -9             9       4.09964            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       1.78894            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK2repl_2020
            -9             9      0.805182             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       2.25661             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK2repl_2020
        13.001            65       30.3851            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2004
        13.001            65       32.3517            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2017
             0             9       3.33719            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       3.36399            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2017
             0             9       3.71943            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       4.27955            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2017
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2004
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2017
        13.001            65       31.7422            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2004
        13.001            65       31.3552            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2015
            -9             9       2.70859            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       2.30055            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9       4.55662            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       4.22772            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2004
            -9             9       1.11094             0            50             0      5  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2015
        13.001            65       29.0667            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2006
        13.001            65       47.7562            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2021
            -9             9      -7.48743            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9       5.43542            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2021
            -9             9       5.03701            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9       1.97165            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2021
            -9             9      0.797146             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2006
            -9             9       3.01686             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2021
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
#      5    34    25     2     2     0     0     0     0     0     0     0
#      5    36    27     2     2     0     0     0     0     0     0     0
#      5    37    29     2     2     0     0     0     0     0     0     0
#      5    42    31     2     2     0     0     0     0     0     0     0
#      5    56    33     3     2     0     0     0     0     0     0     0
#      5    58    35     3     2     0     0     0     0     0     0     0
#      5    59    37     3     2     0     0     0     0     0     0     0
#      5    64    39     3     2     0     0     0     0     0     0     0
#      5    67    41     4     2     0     0     0     0     0     0     0
#      5    69    43     4     2     0     0     0     0     0     0     0
#      5    70    45     4     2     0     0     0     0     0     0     0
#      5    75    47     4     2     0     0     0     0     0     0     0
#      5    78    49     5     2     0     0     0     0     0     0     0
#      5    80    51     5     2     0     0     0     0     0     0     0
#      5    81    53     5     2     0     0     0     0     0     0     0
#      5    86    55     5     2     0     0     0     0     0     0     0
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
      4      1  0.210446
      5      1   2.00626
      4      2  0.269326
      5      2  0.250746
      4      3  0.203297
      5      3  0.226089
      4      4  0.211531
      4      5   1.67622
      4      6   1.77302
      4      7  0.177314
      5      8     1.096
      4      9  0.842248
      5      9  0.976416
      4     11  0.218366
      5     11   0.51864
      4     12  0.113429
      5     12  0.112265
      4     16     0.081
      4     17     0.081
      4     18     0.081
      4     19     0.093
      4     20     0.093
      4     21     0.093
      4     22     0.114
      4     23     0.114
      4     24     0.114
      4      8  0.229704
      4     28  0.049981
      4     29  0.096778
      4     30  0.044651
      5      4  0.620306
      5      5  0.302913
      5      6   1.10963
      5     28  0.194961
      5     29   0.12857
      5     30  0.186059
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

