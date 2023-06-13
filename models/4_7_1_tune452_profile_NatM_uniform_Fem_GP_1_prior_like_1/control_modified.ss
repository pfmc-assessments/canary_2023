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
 0.02 0.2 0.079 -2.74 0.31 3 -2 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 2 15 8.41745 4 50 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 50 70 59.5283 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.02 0.21 0.136872 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.02 0.21 0.0837219 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.21 0.0410754 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 0 0.1 1.19e-05 1.19e-05 50 6 -50 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 2 4 3.09 3.09 50 6 -50 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 9 12 10.87 10.87 0.055 6 -50 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 3 -0.688 -0.688 50 6 -50 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 1e-10 0.1 7.218e-08 -16.4441 0.135 3 -50 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 2 6 4.043 4.043 0.3 6 -50 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.02 0.2 0.0643 -2.74 0.31 6 -50 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 0 15 0 0 50 6 -50 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 50 70 55.0054 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.02 0.21 0.153209 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.02 0.21 0.0894438 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.21 0.0492301 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
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
             7            11       8.16239           8.5            50             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
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
#  -0.00713226 -0.00758194 -0.00806013 -0.00856847 -0.00910879 -0.00968299 -0.0102931 -0.0109414 -0.01163 -0.0123613 -0.0131377 -0.0139615 -0.0148355 -0.0157621 -0.0167443 -0.0177844 -0.018885 -0.02005 -0.0212842 -0.0225955 -0.0239947 -0.0254903 -0.0270841 -0.0287754 -0.0305681 -0.0324693 -0.0344888 -0.0366399 -0.0389398 -0.0414013 -0.0440324 -0.0468333 -0.0498008 -0.0529348 -0.0562334 -0.0596747 -0.0632318 -0.0668551 -0.0705134 -0.0741878 -0.077863 -0.0816316 -0.0856251 -0.0900651 -0.0952581 -0.101381 -0.108388 -0.11594 -0.123896 -0.131218 -0.137489 -0.142518 -0.145969 -0.145639 -0.14228 -0.136857 -0.128701 -0.117052 -0.101381 -0.0819676 -0.0585555 -0.0310505 0.00114599 0.0405212 0.0915255 0.160908 0.258463 0.398576 0.482942 0.586216 0.424682 0.185132 0.0224492 -0.016403 0.0930245 0.378295 0.819478 0.140493 -0.249038 -0.239186 0.239064 0.486323 0.0350192 0.15006 0.474307 -0.103254 0.310607 0.197296 -0.448051 0.253407 0.0503671 -0.195641 0.140072 0.0874034 -0.0605454 0.0473541 0.0765836 0.347996 0.26054 0.0690988 0.269444 -0.0628898 0.18414 0.339963 0.232349 -0.0556179 -0.131182 -0.30328 -0.188038 0.0473886 -0.0246504 0.305679 0.00676078 -0.607656 -0.320187 0.139189 -0.757197 -0.429978 -0.0328038 -0.0768893 -0.0596206 0.0961109 -0.566666 -0.297076 -0.0607633 -0.765914 -0.971372 -0.67598 -0.37909 0.147302 -0.0475679 0 0 0 0 0 0 0 0 0 0 0 0
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
# 1_CA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000270781 0.00041507 0.000443585 0.000344232 0.000345417 0.000268929 0.00023773 0.00028028 0.000153196 0.000105332 0.000345303 0.000445998 0.000550967 0.00101214 0.000878373 0.00122086 0.000836299 0.00114102 0.000981978 0.00100682 0.000605652 0.000924877 0.000945601 0.00125612 0.00102851 0.000819711 0.000199833 0.00100083 0.00429734 0.0102763 0.00984682 0.00406954 0.00470827 0.00420795 0.00384444 0.00783963 0.00566367 0.00546014 0.00394526 0.00425236 0.0042078 0.00484216 0.00651004 0.00489998 0.00378417 0.00296158 0.00295126 0.00413841 0.0025723 0.00337958 0.00243374 0.00329253 0.00307964 0.0074216 0.00788873 0.0118574 0.0148333 0.0117649 0.0150911 0.0164967 0.0180062 0.0175958 0.0262764 0.0135074 0.0203548 0.027081 0.0438934 0.0316544 0.0267086 0.0228364 0.0122688 0.0160973 0.0190104 0.0171989 0.0346519 0.0179146 0.0326511 0.0150094 0.0209022 0.021217 0.0335254 0.0261441 0.0231472 0.0140488 0.00243881 0.00164148 0.0024025 0.000179365 0.000341304 0.000448084 0.00137542 0.00301785 0.00149052 0.000240959 6.79636e-05 4.3551e-05 6.71987e-05 0.000178943 0.000229012 0.000807591 0.000323287 0.00856794 0.0158546 0.0198575 0.00821758 0.00873237 0.0101584 0 0 0.0132922 0.01322 0.013142 0.0130455 0.0129243 0.0128238 0.012748 0.0126929 0.0126846 0.0126985
# 2_OR_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1.86671e-05 1.14606e-05 4.68893e-07 9.16639e-06 3.34624e-05 6.54516e-05 0 9.38814e-05 0.00216592 0.00335176 0.00634018 0.0225233 0.0407072 0.0662776 0.0433053 0.0279558 0.0203658 0.0179821 0.0191744 0.0179411 0.0188737 0.0200209 0.0257188 0.0262568 0.0395802 0.0421264 0.0292897 0.0324859 0.0392299 0.0360164 0.0425631 0.0245819 0.0375857 0.0306861 0.0349486 0.00571389 0.0322668 0.010162 0.0205138 0.0262667 0.025246 0.0314629 0.0202442 0.0144955 0.00931902 0.0216103 0.0676665 0.053994 0.122955 0.0916492 0.195026 0.207883 0.0870987 0.0765429 0.0778033 0.120113 0.144289 0.153987 0.116766 0.263525 0.260871 0.318902 0.152313 0.114611 0.151412 0.112176 0.128807 0.0682825 0.00478321 0.00220871 0.00293956 0.00157133 0.000678308 0.00132303 0.00137177 0.000276267 0.000358296 0.000563373 0.000281693 0.000260683 0.000540961 0.000477319 0.000791255 0.00308734 0.00125619 0.0108009 0.0126455 0.0141335 0.0135233 0.0161808 0.0230447 0 0 0.018933 0.0188303 0.0187195 0.0185824 0.0184103 0.0182675 0.0181597 0.0180812 0.0180694 0.0180892
# 3_WA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1.01288e-06 0 7.63363e-06 5.91864e-05 7.64854e-05 6.84905e-05 0.000101367 0.000106586 0.00023684 8.9086e-05 0.00174364 0.00572571 0.0024491 0.0270576 0.0144533 0.00780483 0.0129339 0.0160132 0.0156409 0.0132865 0.0128489 0.00562957 0.00815637 0.00778892 0.00755794 0.00637567 0.00819434 0.00926079 0.0084668 0.0101395 0.0142422 0.0114731 0.0084001 0.0185333 0.0255709 0.0124591 0.0210181 0.0198784 0.0176963 0.0198705 0.00551443 0.0125165 0.0195299 0.0270871 0.0206331 0.0173093 0.052452 0.0281414 0.0324398 0.0246259 0.0231186 0.0399013 0.0411988 0.072958 0.0659259 0.0790248 0.0833875 0.115539 0.119231 0.123776 0.127354 0.053102 0.0293826 0.0297177 0.0338609 0.0352846 0.0342059 0.0224491 0.00147021 0.000974244 0.00224566 0.000955508 0.000652494 0.00191561 0.000709242 0.000302313 0.000233917 0.00037371 0.000444625 0.000306492 0.000414755 0.000363186 0.000166183 0.00029688 0.000371262 0.00272315 0.0114073 0.00477262 0.00572218 0.00530663 0.00731626 0 0 0.00654467 0.00650922 0.006471 0.00642372 0.00636435 0.00631506 0.0062778 0.00625068 0.0062466 0.00625344
# 4_CA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00103793 0.00167894 0.00173922 0.00101222 0.0010956 0.000982422 0.00091586 0.0011079 0.00134375 0.00165649 0.00194866 0.00157331 0.00136624 0.00092993 0.00132501 0.0012941 0.00107494 0.000430129 0.000599906 0.000912644 0.000825966 0.000526063 0.000540224 0.00051772 0.000384443 0.000499264 0.000373575 0.000314764 0.00120635 0.00306489 0.00329881 0.000771745 0.00152875 0.000598295 0.000491257 0.000803058 0.000611471 0.000358711 0.000882601 0.000208744 0.000326688 0.000362268 0.000472805 0.000326848 0.000415795 0.000334795 0.000472364 0.000428029 0.000386873 0.000412178 0.000319923 0.000331371 0.000205861 0.000806671 0.00051129 0.000915524 0.0017779 0.000851886 0.00220105 0.00161537 0.00230508 0.00280172 0.00718045 0.00664525 0.00518757 0.00979682 0.00276325 0.00468107 0.0044505 0.00860963 0.00447999 0.00427625 0.00493226 0.0214222 0.0225628 0.0193958 0.0171173 0.0157347 0.0137493 0.0155019 0.0166271 0.0138561 0.011038 0.00420152 0.00245704 0.00193009 1.93235e-05 0.000383652 0.000428731 0.000284553 0.000462055 0.00058142 0.000197873 0.000248531 0.000782961 0.00191112 0.000611151 0.000912883 0.000629569 0.000732672 0.000419935 0.00094446 0.000964754 0.00138124 0.00224302 0.00311577 0.00281137 0 0 0.00270319 0.00268849 0.00267259 0.00265292 0.00262828 0.00260788 0.00259248 0.00258129 0.00257961 0.00258243
# 5_OR_NTWL 9.27386e-05 9.27462e-05 9.27537e-05 2.38704e-05 5.76738e-06 5.92763e-06 3.3644e-06 5.60764e-06 7.85148e-06 1.02565e-05 1.25028e-05 1.47507e-05 1.71609e-05 1.9413e-05 2.16673e-05 2.39241e-05 2.63441e-05 2.86062e-05 3.0871e-05 3.32997e-05 3.55706e-05 3.78448e-05 4.02836e-05 4.25649e-05 4.48604e-05 4.71797e-05 4.96778e-05 5.20188e-05 5.43622e-05 5.68754e-05 5.92314e-05 6.15965e-05 6.41361e-05 6.65246e-05 6.8933e-05 7.08664e-05 0.0001185 0.000203397 0.000185856 0.000149564 4.7759e-05 7.87758e-05 8.51138e-05 7.66317e-05 0.000183596 0.000219295 0.000217017 0.000123993 0.000275474 0.000370373 0.000517859 0.00130112 0.000343934 0.000230427 0.000299227 0.000156788 0.000263806 0.000179722 0.000170527 0.000133871 0.000129759 6.87759e-05 8.15564e-05 0.000102741 6.678e-05 0.000148492 3.02926e-05 6.31151e-05 4.261e-05 0.000120454 0.000111727 0.000100979 2.32962e-05 0.000170359 0.00011775 0.000336858 0.000305531 0.000670025 0.000255431 0.00051485 0.000667198 0.000715126 0.000916677 0.000485608 0.000645824 0.000796167 0.00128746 0.00383746 0.00235141 0.00275979 0.00561832 0.0132844 0.00989951 0.0104349 0.0087918 0.0149114 0.013708 0.0151949 0.0227691 0.0296651 0.0228036 0.0686121 0.019852 0.0189805 0.026593 0.0406229 0.0395255 0.0184333 0.00284513 0.002597 0.000112139 0.000112649 0.00140376 0.000455386 0.00067492 0.00045476 0.000192082 0.000631366 0.000202579 0.000842014 0.000362603 0.000531148 0.000354771 0.000614047 0.00122966 0.00100037 0.000751744 0.00107939 0.000607715 0.000534558 0.000909948 0 0 0.000886409 0.000881594 0.000876397 0.00086997 0.000861905 0.000855215 0.000850161 0.000846484 0.00084593 0.000846856
# 6_WA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000665922 0.000628135 0.000966985 0.00104308 0.00102786 0.000428624 0.00057466 0.000409077 0.000634642 0.000187026 0.000175169 8.45814e-05 5.7762e-05 0.000388418 0.000235555 0.000315987 0.000829833 0.000502634 0.000260891 0.00046008 0.000723785 0.000379381 0.000239527 0.000158404 0.000126229 0.000213974 9.87918e-05 6.43553e-05 0 0 0.000142499 0.000141728 0.000140895 0.000139866 0.000138573 0.0001375 0.000136689 0.000136098 0.000136009 0.000136158
# 7_CA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000181742 0.000364482 0.0004196 0.000561691 0.000704725 0.000848582 0.000993412 0.00113838 0.00128575 0.00153084 0.0015108 0.00132694 0.00191613 0.00178022 0.000951694 0.000918863 0.000766443 0.00105112 0.00185871 0.00150152 0.00302592 0.00395023 0.00485507 0.00579384 0.0050967 0.00437164 0.00550497 0.00666459 0.00743264 0.00694136 0.0117084 0.00931501 0.00711089 0.00484378 0.00567843 0.00571355 0.00488037 0.00697861 0.00735183 0.00779931 0.00863317 0.00995352 0.0129195 0.0111434 0.013972 0.0160498 0.0178271 0.0187232 0.021571 0.0205881 0.020094 0.0228066 0.0215763 0.0205019 0.0386461 0.0157825 0.0169697 0.0269786 0.0389239 0.0408622 0.0354629 0.0234933 0.0377071 0.0381741 0.0378403 0.0396026 0.0320695 0.0413462 0.0154923 0.0266683 0.00736569 0.0185229 0.0220525 0.00963559 0.00184294 0.00557808 0.00619818 0.00331849 0.00725525 0.00630867 0.003058 0.00731774 0.00680813 0.00844227 0.00766268 0.00652302 0.00974292 0.0107812 0.00877973 0.0191448 0.0139712 0.0165419 0.0153503 0.0213897 0.0164464 0 0 0.0197356 0.0196283 0.0195117 0.019368 0.0191882 0.0190394 0.0189273 0.0188457 0.0188335 0.0188542
# 8_OR_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000478401 0.000991635 0.00160492 0.00225848 0.00282699 0.00344128 0.00415287 0.0044763 0.00586158 0.00663488 0.00405061 0.00535082 0.00300489 0.00619834 0.00424567 0.00354227 0.004396 0.00290824 0.00427266 0.00625728 0.00863356 0.0066553 0.00811225 0.00514671 0.00688324 0.0109943 0.00678811 0.00556951 0.00294963 0.00244591 0.00249491 0.000675679 0.00100365 0.000528351 0.000546634 0.000653724 0.000849207 0.00112688 0.000767514 0.0007193 0.000971453 0.000743572 0.00264563 0.00172884 0.00479645 0.00726908 0.00658697 0.0104573 0.00676704 0.0103626 0 0 0.00967246 0.00961986 0.00956281 0.00949245 0.00940439 0.00933151 0.00927653 0.00923655 0.00923058 0.00924067
# 9_WA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6.03228e-05 8.47028e-05 0.000111617 0.000142839 0.00017644 0.000205712 0.000225744 0.000247906 0.000283783 0.000134821 0.000363789 0.000550475 0.000407322 0.000271245 0.000239603 0.000274277 0.000511875 0.000933358 0.000472198 0.00080535 0.000870698 0.000901972 0.00149743 0.00151196 0.00179109 0.00380069 0.00382774 0.00214795 0.00172915 0.001635 0.00157031 0.002767 0.00168942 0.00132551 0.00112466 0.000485671 0.000451119 0.000205742 0.000313815 0.000132257 0.000110091 9.00206e-05 8.36987e-05 0.000152533 0.00015859 0.000135719 0.000135242 0.000193376 0.000295237 0.000247416 0.000589263 0.000479842 0.0015046 0.000924384 0.001914 0.00205016 0 0 0.00180996 0.00180015 0.00178956 0.00177647 0.00176004 0.00174642 0.00173613 0.00172864 0.00172752 0.00172941
# 10_CA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.24677e-05 1.70607e-06 2.46596e-05 0.000186654 4.37879e-06 4.14094e-06 3.54384e-06 0 2.7951e-06 0 1.71701e-05 3.3558e-05 8.08731e-06 3.1406e-06 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.40919e-08 7.36857e-08 7.32484e-08 7.27103e-08 7.20377e-08 7.14813e-08 7.10624e-08 7.07586e-08 7.07156e-08 7.07958e-08
# 11_OR_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000405192 7.55972e-05 0.000623349 0.000635226 0.000520317 9.8309e-05 1.60556e-05 0.000170607 0.000103657 0.000417084 8.01262e-05 0.000241931 0.000395986 0.000188165 0.000291143 0.000326623 1.67615e-05 3.42822e-05 0.000147325 3.17706e-05 4.02917e-06 8.83004e-05 4.61261e-05 1.23284e-05 3.87217e-05 0.000153092 0.000330479 3.09891e-05 0.00055264 6.33916e-05 5.3312e-05 0.000207686 6.28317e-05 3.49632e-06 3.35995e-06 1.05903e-06 1.00798e-05 7.81367e-06 3.52612e-05 7.46799e-06 2.12481e-05 0.000166069 0.000279509 6.55191e-05 1.91192e-05 0.000292334 0.00038326 0 0 0.000215204 0.000214038 0.000212781 0.000211225 0.00020927 0.000207645 0.000206418 0.000205525 0.000205391 0.000205616
# 12_WA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.92603e-05 1.76294e-05 0.00010542 2.19202e-05 0.00197265 0.00217234 0.000187824 0.000255339 0.000356841 0.00061805 0.000239309 0.000125843 0.000246663 0.000274803 0.000404138 0.000147842 0.000881715 5.50691e-05 0.000197429 0.000512526 0.000874551 0.00118881 0.000359789 0.000428362 0.000388073 8.90936e-05 8.98502e-05 0.000108842 7.58215e-05 2.84827e-05 0.000385289 0.000293691 0.000127678 0.000113316 3.12475e-05 5.3719e-05 2.47781e-05 1.21355e-05 2.67911e-05 0.000440082 0.000234158 0.000397729 6.55515e-05 0.000240163 0.000139203 0 0 0.000238533 0.000237241 0.000235848 0.000234124 0.000231956 0.000230155 0.000228795 0.000227806 0.000227657 0.000227906
# 13_CA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00166918 0.00411916 0.0160559 0.000187178 0 0 0.000470979 0.0137544 0.00565789 0.00238819 0.00185819 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.40496e-08 7.36398e-08 7.32014e-08 7.26647e-08 7.19944e-08 7.14409e-08 7.10245e-08 7.07224e-08 7.06804e-08 7.07608e-08
# 14_OR_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0540364 0.0247367 0.0105681 0.00179832 0.00252561 0.00399061 0.0106658 0.0177977 0.00280276 0.00492452 0.00397415 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.41083e-08 7.3704e-08 7.32686e-08 7.27315e-08 7.20586e-08 7.15013e-08 7.10812e-08 7.07763e-08 7.07323e-08 7.08118e-08
# 15_WA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00435083 0.00345862 0.00409438 0.000437368 0.000981961 0.00240597 0.00232575 0.00235611 0.0101862 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.41166e-08 7.37126e-08 7.32773e-08 7.27403e-08 7.20675e-08 7.15101e-08 7.10898e-08 7.07849e-08 7.07409e-08 7.08206e-08
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
           -25            25     -0.644323             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_28_coastwide_NWFSC(28)
           -25            25      -1.44145             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_29_coastwide_Tri_early(29)
           -25            25      -1.44145             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_30_coastwide_Tri_late(30)
           -25            25      -2.75319             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_31_coastwide_prerec(31)
             0             3      0.461043           0.1            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_31_coastwide_prerec(31)
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
 24 0 4 0 # 3 3_WA_TWL
 24 0 4 0 # 4 4_CA_NTWL
 24 0 4 0 # 5 5_OR_NTWL
 15 0 0 3 # 6 6_WA_NTWL
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
        13.001            65       45.7498            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_1_CA_TWL(1)
             0             9       4.27916            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_1_CA_TWL(1)
             0             9       3.28032            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_1_CA_TWL(1)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_1_CA_TWL(1)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_1_CA_TWL(1)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_1_CA_TWL(1)
            -9             9        1.2885             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_1_CA_TWL(1)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_1_CA_TWL(1)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_1_CA_TWL(1)
# 2   2_OR_TWL LenSelex
        13.001            65       49.4214            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_2_OR_TWL(2)
             0             9       4.03344            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_2_OR_TWL(2)
             0             9        2.1502            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_2_OR_TWL(2)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_2_OR_TWL(2)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_2_OR_TWL(2)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_2_OR_TWL(2)
            -9             9       2.93905             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_2_OR_TWL(2)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_2_OR_TWL(2)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_2_OR_TWL(2)
# 3   3_WA_TWL LenSelex
        13.001            65       48.9415            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_3_WA_TWL(3)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_3_WA_TWL(3)
             0             9       4.24817            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_3_WA_TWL(3)
             0             9       2.70492            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_3_WA_TWL(3)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_3_WA_TWL(3)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_3_WA_TWL(3)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_3_WA_TWL(3)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_3_WA_TWL(3)
            -9             9       1.40753             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_3_WA_TWL(3)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_3_WA_TWL(3)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_3_WA_TWL(3)
# 4   4_CA_NTWL LenSelex
        13.001            65       36.3807            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_4_CA_NTWL(4)
             0             9       4.27884            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_4_CA_NTWL(4)
             0             9       5.01337            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_4_CA_NTWL(4)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_4_CA_NTWL(4)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_4_CA_NTWL(4)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_4_CA_NTWL(4)
            -9             9       0.27384             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_4_CA_NTWL(4)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_4_CA_NTWL(4)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_4_CA_NTWL(4)
# 5   5_OR_NTWL LenSelex
        13.001            65       54.0602            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_5_OR_NTWL(5)
             0             9       5.15113            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_5_OR_NTWL(5)
             0             9       8.47009            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_5_OR_NTWL(5)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_5_OR_NTWL(5)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_5_OR_NTWL(5)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_5_OR_NTWL(5)
            -9             9       4.41211             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_5_OR_NTWL(5)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_5_OR_NTWL(5)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_5_OR_NTWL(5)
# 6   6_WA_NTWL LenSelex
# 7   7_CA_REC LenSelex
        13.001            65       30.0349            99            99             0          4          0          0          0          0          0          3          2  #  Size_DblN_peak_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_7_CA_REC(7)
             0             9       3.75975            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_7_CA_REC(7)
             0             9       5.02239            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_descend_se_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_7_CA_REC(7)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_7_CA_REC(7)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_7_CA_REC(7)
            -9             9      -1.51542             0            50             0          5          0          0          0          0          0          3          2  #  SzSel_Fem_Descend_7_CA_REC(7)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_7_CA_REC(7)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_7_CA_REC(7)
# 8   8_OR_REC LenSelex
        13.001            65       30.8767            99            99             0          4          0          0          0          0          0          4          2  #  Size_DblN_peak_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_8_OR_REC(8)
             0             9       3.11936            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_ascend_se_8_OR_REC(8)
             0             9       3.18669            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_descend_se_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_8_OR_REC(8)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_8_OR_REC(8)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_8_OR_REC(8)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_8_OR_REC(8)
            -9             9       2.25521             0            50             0          5          0          0          0          0          0          4          2  #  SzSel_Fem_Descend_8_OR_REC(8)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_8_OR_REC(8)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_8_OR_REC(8)
# 9   9_WA_REC LenSelex
        13.001            65       34.1325            99            99             0          4          0          0          0          0          0          5          2  #  Size_DblN_peak_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_9_WA_REC(9)
             0             9       2.71511            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_ascend_se_9_WA_REC(9)
             0             9       3.83364            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_descend_se_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_9_WA_REC(9)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_9_WA_REC(9)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_9_WA_REC(9)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_9_WA_REC(9)
            -9             9       1.28333             0            50             0          5          0          0          0          0          0          5          2  #  SzSel_Fem_Descend_9_WA_REC(9)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_9_WA_REC(9)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_9_WA_REC(9)
# 10   10_CA_ASHOP LenSelex
        13.001            65       43.7037            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_10_CA_ASHOP(10)
             0             9       2.53913            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_10_CA_ASHOP(10)
             0             9        2.8667            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_10_CA_ASHOP(10)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_10_CA_ASHOP(10)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_10_CA_ASHOP(10)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_10_CA_ASHOP(10)
            -9             9       2.08905             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_10_CA_ASHOP(10)
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
        13.001            65         50.04            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_28_coastwide_NWFSC(28)
             0             9       6.90985            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_28_coastwide_NWFSC(28)
             0             9     0.0187181            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_28_coastwide_NWFSC(28)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_28_coastwide_NWFSC(28)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_28_coastwide_NWFSC(28)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_28_coastwide_NWFSC(28)
            -9             9       3.94507             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_28_coastwide_NWFSC(28)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_28_coastwide_NWFSC(28)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_28_coastwide_NWFSC(28)
# 29   29_coastwide_Tri_early LenSelex
        13.001            65       50.9081            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_29_coastwide_Tri_early(29)
             0             9       6.05013            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_29_coastwide_Tri_early(29)
             0             9       2.76504            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_29_coastwide_Tri_early(29)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_29_coastwide_Tri_early(29)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_29_coastwide_Tri_early(29)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_29_coastwide_Tri_early(29)
            -9             9        7.3639             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_29_coastwide_Tri_early(29)
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
        13.001            65       43.9257            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2000
        13.001            65       43.4008            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2011
             0             9       3.79737            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       3.86992            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2011
             0             9        1.6536            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       2.50012            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2011
            -9             9       2.24586             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2000
            -9             9       1.43054             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2011
        13.001            65       42.8399            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2000
        13.001            65       46.1178            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2011
             0             9       4.02045            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       4.83808            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2011
             0             9       3.97787            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       2.48209            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2011
            -9             9       3.28861             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2000
            -9             9       1.86733             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2011
        13.001            65       44.8627            99            99             0      4  # Size_DblN_peak_3_WA_TWL(3)_BLK1repl_2000
        13.001            65       47.3396            99            99             0      4  # Size_DblN_peak_3_WA_TWL(3)_BLK1repl_2011
             0             9        4.6084            99            99             0      5  # Size_DblN_ascend_se_3_WA_TWL(3)_BLK1repl_2000
             0             9       4.13511            99            99             0      5  # Size_DblN_ascend_se_3_WA_TWL(3)_BLK1repl_2011
             0             9       3.68935            99            99             0      5  # Size_DblN_descend_se_3_WA_TWL(3)_BLK1repl_2000
             0             9       1.86629            99            99             0      5  # Size_DblN_descend_se_3_WA_TWL(3)_BLK1repl_2011
            -9             9       8.81273             0            50             0      5  # SzSel_Fem_Descend_3_WA_TWL(3)_BLK1repl_2000
            -9             9       2.70323             0            50             0      5  # SzSel_Fem_Descend_3_WA_TWL(3)_BLK1repl_2011
        13.001            65       33.4645            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2000
        13.001            65       38.7553            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2020
             0             9       3.01231            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       3.77351            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2020
             0             9       4.49337            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       3.63504            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2020
            -9             9      0.819423             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2000
            -9             9       1.00067             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2020
        13.001            65       33.4362            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK2repl_2000
        13.001            65       47.6456            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK2repl_2020
             0             9       2.50753            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK2repl_2000
             0             9       5.48779            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK2repl_2020
             0             9       4.08936            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK2repl_2000
             0             9   0.000687807            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK2repl_2020
            -9             9      0.805069             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       3.36578             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK2repl_2020
        13.001            65       31.1407            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2004
        13.001            65       33.8652            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2017
             0             9       3.49901            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       3.70401            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2017
             0             9       3.91913            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2004
             0             9        4.2949            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2017
            -9             9      -1.77529             0            50             0      5  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2004
            -9             9      -2.18932             0            50             0      5  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2017
        13.001            65       33.0457            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2004
        13.001            65       31.3691            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2015
             0             9       3.08586            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2004
             0             9       2.30571            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2015
             0             9       4.64874            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2004
             0             9       4.23109            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9      -2.17495             0            50             0      5  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2004
            -9             9        1.1104             0            50             0      5  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2015
        13.001            65       32.2651            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2006
        13.001            65       49.7712            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2021
             0             9       2.15366            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2006
             0             9       5.64231            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2021
             0             9       4.66493            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2006
             0             9    0.00191171            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2021
            -9             9      0.924367             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2006
            -9             9       4.19085             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2021
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
#      5    23    17     1     2     0     0     0     0     0     0     0
#      5    25    19     1     2     0     0     0     0     0     0     0
#      5    26    21     1     2     0     0     0     0     0     0     0
#      5    31    23     1     2     0     0     0     0     0     0     0
#      5    34    25     2     2     0     0     0     0     0     0     0
#      5    36    27     2     2     0     0     0     0     0     0     0
#      5    37    29     2     2     0     0     0     0     0     0     0
#      5    42    31     2     2     0     0     0     0     0     0     0
#      5    45    33     2     2     0     0     0     0     0     0     0
#      5    47    35     2     2     0     0     0     0     0     0     0
#      5    48    37     2     2     0     0     0     0     0     0     0
#      5    53    39     2     2     0     0     0     0     0     0     0
#      5    56    41     3     2     0     0     0     0     0     0     0
#      5    58    43     3     2     0     0     0     0     0     0     0
#      5    59    45     3     2     0     0     0     0     0     0     0
#      5    64    47     3     2     0     0     0     0     0     0     0
#      5    67    49     4     2     0     0     0     0     0     0     0
#      5    69    51     4     2     0     0     0     0     0     0     0
#      5    70    53     4     2     0     0     0     0     0     0     0
#      5    75    55     4     2     0     0     0     0     0     0     0
#      5    78    57     5     2     0     0     0     0     0     0     0
#      5    80    59     5     2     0     0     0     0     0     0     0
#      5    81    61     5     2     0     0     0     0     0     0     0
#      5    86    63     5     2     0     0     0     0     0     0     0
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
      4      1  0.208697
      5      1   2.01234
      4      2   0.27671
      5      2  0.249245
      4      3  0.175032
      5      3  0.208749
      4      4  0.210227
      4      5   1.72709
      4      6   3.11959
      4      7  0.169774
      5      8   1.15536
      4      9  0.821009
      5      9   0.93209
      4     11  0.218925
      5     11  0.529423
      4     12   0.11364
      5     12  0.114201
      4     16     0.081
      4     17     0.081
      4     18     0.081
      4     19     0.093
      4     20     0.093
      4     21     0.093
      4     22     0.114
      4     23     0.114
      4     24     0.114
      4      8   0.24038
      4     28  0.050354
      4     29  0.101164
      4     30  0.045147
      5      4  0.625305
      5      5  0.303213
      5      6   1.29585
      5     28  0.199556
      5     29  0.130685
      5     30  0.184125
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

