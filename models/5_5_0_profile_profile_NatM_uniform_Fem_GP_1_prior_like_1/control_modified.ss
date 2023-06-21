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
 0.02 0.2 0.095 -2.74 0.31 3 -1 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 2 15 8.25495 4 50 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 50 70 59.0476 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.02 0.21 0.140222 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.02 0.21 0.082568 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.21 0.0411602 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
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
 50 70 54.8276 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.02 0.21 0.154886 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.02 0.21 0.0935696 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.21 0.0472291 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
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
             7            11        8.2959           8.5            50             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
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
#  -0.00858689 -0.00911355 -0.009672 -0.0102641 -0.010892 -0.0115576 -0.0122632 -0.0130109 -0.0138033 -0.0146427 -0.0155316 -0.0164725 -0.0174678 -0.0185201 -0.0196319 -0.0208055 -0.0220438 -0.0233499 -0.0247288 -0.0261877 -0.0277369 -0.0293844 -0.0311311 -0.0329751 -0.0349185 -0.0369664 -0.0391262 -0.0414083 -0.0438252 -0.0463863 -0.049097 -0.0519531 -0.054948 -0.0580786 -0.0613428 -0.0647224 -0.0682003 -0.0717398 -0.0753283 -0.078963 -0.0826269 -0.0863935 -0.090345 -0.094626 -0.0994457 -0.104961 -0.111199 -0.117952 -0.125108 -0.131488 -0.136841 -0.140958 -0.143723 -0.142986 -0.139328 -0.133734 -0.125687 -0.1145 -0.0997673 -0.0818211 -0.060422 -0.0355395 -0.00641619 0.0294292 0.0762955 0.141353 0.235225 0.372676 0.42746 0.526729 0.381837 0.150052 -0.0113976 -0.052327 0.0551473 0.339856 0.776453 0.117792 -0.276585 -0.266805 0.212397 0.440684 0.000564855 0.13503 0.414124 -0.143218 0.254164 0.147627 -0.485304 0.214834 0.0101175 -0.225748 0.137666 0.10421 -0.0333564 0.119339 0.141412 0.433141 0.358298 0.181172 0.398502 0.0370832 0.260005 0.393138 0.25534 -0.0208619 -0.126678 -0.278816 -0.163961 0.0537234 -0.027117 0.317873 0.0213911 -0.583408 -0.298763 0.167631 -0.763458 -0.430425 -0.0431447 -0.0503642 -0.0883996 0.0774892 -0.640481 -0.359312 -0.0885293 -0.800207 -0.983425 -0.608176 -0.301548 0.153549 -0.0640147 0 0 0 0 0 0 0 0 0 0 0 0
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
# 1_CA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000250696 0.000384309 0.000410731 0.000318757 0.00031988 0.000249068 0.000220195 0.000259635 0.000141927 9.7594e-05 0.000319968 0.000413316 0.000510649 0.00093818 0.000814283 0.0011319 0.000775438 0.00105811 0.00091073 0.000933861 0.000561817 0.000858012 0.000877308 0.00116548 0.000954353 0.00076067 0.000185453 0.000928845 0.00398858 0.00953602 0.00913288 0.00377337 0.00436443 0.00389874 0.00355984 0.00725453 0.00523744 0.0050466 0.00364499 0.00392717 0.00388462 0.004469 0.00600723 0.00452104 0.00349175 0.00273357 0.00272526 0.00382447 0.00238002 0.00313182 0.00225886 0.00306464 0.00287737 0.00696285 0.00743157 0.0112061 0.0140487 0.0111514 0.0142937 0.0156057 0.0170237 0.0166369 0.0248214 0.0127335 0.0191464 0.0254245 0.0411348 0.0296228 0.0250042 0.0213994 0.0115027 0.0150843 0.0177631 0.0159753 0.0318746 0.0162053 0.0288035 0.0128221 0.017382 0.0173096 0.0267263 0.0203182 0.0175301 0.0104379 0.00185465 0.0012558 0.00184795 0.000138615 0.000264762 0.000348314 0.0010688 0.00233889 0.00115148 0.000185865 5.24945e-05 3.37053e-05 5.23403e-05 0.000140304 0.000180836 0.000642466 0.000259181 0.00691476 0.0128582 0.0161992 0.00676149 0.00725867 0.0085201 0 0 0.0130562 0.0129854 0.0129285 0.0128711 0.0127993 0.0127417 0.0126347 0.0125454 0.0125009 0.0124779
# 2_OR_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1.82916e-05 1.12317e-05 4.596e-07 8.98608e-06 3.2809e-05 6.41829e-05 0 9.20878e-05 0.0021248 0.00328845 0.0062208 0.0220973 0.0399228 0.0649521 0.0423887 0.0273306 0.0198865 0.0175365 0.0186735 0.0174467 0.0183259 0.0194104 0.0248975 0.0253801 0.0381972 0.0405826 0.0281698 0.0311962 0.0376112 0.0344737 0.0406704 0.0234519 0.0358057 0.0291864 0.0331527 0.00540749 0.0305238 0.00962752 0.0195067 0.0250877 0.0242134 0.0302617 0.0194883 0.0139495 0.00896855 0.0208284 0.0653063 0.0520948 0.118348 0.0878742 0.186012 0.196801 0.082004 0.0718931 0.0729555 0.112399 0.134415 0.142354 0.106773 0.236391 0.226882 0.266147 0.122672 0.0902631 0.116158 0.0835999 0.0933874 0.0485892 0.00361964 0.00168431 0.00226121 0.00121963 0.000530871 0.00104213 0.00108515 0.000219164 0.000284932 0.000449509 0.000225865 0.000202825 0.000422502 0.00037471 0.000624985 0.00245476 0.00100558 0.00869395 0.010214 0.0114585 0.0110273 0.0132878 0.0190446 0 0 0.0184794 0.0183794 0.0182992 0.0182185 0.0181174 0.0180363 0.0178848 0.0177584 0.0176955 0.0176629
# 3_WA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 9.14578e-07 0 6.89401e-06 5.34557e-05 6.90837e-05 6.18658e-05 9.15663e-05 9.62842e-05 0.000213955 8.04815e-05 0.00157535 0.00517371 0.00221358 0.0244616 0.0130702 0.00706192 0.0117102 0.0145047 0.0141723 0.0120411 0.0116451 0.00510269 0.00739397 0.00706173 0.00685334 0.00578295 0.00743569 0.00840779 0.00769298 0.00922344 0.0129743 0.0104722 0.00768701 0.0170151 0.0235592 0.0115347 0.019559 0.0185844 0.0166008 0.0186737 0.0051865 0.0117786 0.018393 0.0255245 0.0194304 0.0162691 0.0491592 0.0263117 0.0302831 0.0229675 0.0215389 0.0371689 0.0384665 0.0683097 0.0618465 0.0741826 0.0782003 0.108005 0.110783 0.113655 0.114761 0.0466057 0.025224 0.0251295 0.0280402 0.0284635 0.0267953 0.0171609 0.00115957 0.000778766 0.0018185 0.000783998 0.00054273 0.00161432 0.000604402 0.000259774 0.000202008 0.000323383 0.000385401 0.000233378 0.000318929 0.000282265 0.000130684 0.000236092 0.000297533 0.00218964 0.00917906 0.00385348 0.00466181 0.00437593 0.00618632 0 0 0.00643109 0.00639629 0.00636838 0.00634031 0.00630513 0.00627689 0.00622418 0.0061802 0.00615828 0.00614694
# 4_CA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000977885 0.00158195 0.00163887 0.000953901 0.00103258 0.000926007 0.000863369 0.00104453 0.00126705 0.00156214 0.00183788 0.00148403 0.00128885 0.000877332 0.00125017 0.00122108 0.00101435 0.000405909 0.000566155 0.000861332 0.000779555 0.000496519 0.000509895 0.000488656 0.000362851 0.000471198 0.000352524 0.000296877 0.0011368 0.00288204 0.00309371 0.000722663 0.00142995 0.000558943 0.000458408 0.000748573 0.000569482 0.000333925 0.000821436 0.000194236 0.000303926 0.00033699 0.000439863 0.000304177 0.000387203 0.000312092 0.000440871 0.000400185 0.000362725 0.000387905 0.000302144 0.000314101 0.000195769 0.000769315 0.000489011 0.000877248 0.00170488 0.000816436 0.00210602 0.00154373 0.00220212 0.00267655 0.00684676 0.00631846 0.0049217 0.00928218 0.00261569 0.00442704 0.0042105 0.00814432 0.00423335 0.00403156 0.00462726 0.0199215 0.0207039 0.0174575 0.0150194 0.0134197 0.0114685 0.0127144 0.0133745 0.0109194 0.00852102 0.00319744 0.00188784 0.0014888 1.49611e-05 0.000297865 0.000332946 0.000220486 0.000357337 0.000449718 0.000153466 0.000193816 0.000614452 0.00150856 0.000485514 0.000731053 0.000508476 0.000596664 0.000344605 0.000781184 0.000804531 0.00116305 0.00193533 0.00271907 0.00247409 0 0 0.00279434 0.00277915 0.00276692 0.00275461 0.00273925 0.00272696 0.00270407 0.00268497 0.00267545 0.00267051
# 5_OR_NTWL 9.24591e-05 9.24666e-05 9.2474e-05 2.37984e-05 5.74999e-06 5.90977e-06 3.3543e-06 5.59091e-06 7.82832e-06 1.02268e-05 1.24672e-05 1.47098e-05 1.71148e-05 1.93625e-05 2.16131e-05 2.38666e-05 2.62834e-05 2.85432e-05 3.08064e-05 3.32335e-05 3.55039e-05 3.7778e-05 4.02171e-05 4.24997e-05 4.47968e-05 4.71181e-05 4.96185e-05 5.19625e-05 5.43096e-05 5.6827e-05 5.9188e-05 6.15588e-05 6.41047e-05 6.65004e-05 6.89165e-05 7.08585e-05 0.000118502 0.000203426 0.000185906 0.000149623 4.77838e-05 7.88265e-05 8.5179e-05 7.66996e-05 0.00018378 0.000219539 0.000217283 0.000124158 0.000275866 0.000370927 0.000518662 0.00130308 0.000344365 0.000230595 0.000299207 0.000156655 0.000263378 0.000179276 0.000169936 0.000133256 0.000129006 6.82906e-05 8.0876e-05 0.000101747 6.60375e-05 0.000146609 2.98642e-05 6.2137e-05 4.18908e-05 0.000118262 0.000109547 9.88946e-05 2.27935e-05 0.000166541 0.000114948 0.000328511 0.000297992 0.000654044 0.000249745 0.000504208 0.00065435 0.000702072 0.000900608 0.000477451 0.000635458 0.000783981 0.00126771 0.00377533 0.00230943 0.00270398 0.00548385 0.0128929 0.00957042 0.0100704 0.00846998 0.0143268 0.013108 0.014428 0.0214116 0.0274282 0.0205259 0.0595564 0.0166876 0.015626 0.0213655 0.0317403 0.0300115 0.0136939 0.00222358 0.00203836 8.84128e-05 8.91156e-05 0.00111034 0.000358471 0.000528469 0.000355563 0.000150503 0.000498414 0.000161463 0.000676106 0.000292942 0.000433421 0.000292422 0.000510522 0.00102936 0.000843876 0.000639899 0.000930774 0.000517966 0.000459013 0.000787648 0 0 0.000908513 0.000903585 0.000899628 0.000895649 0.000890665 0.000886668 0.000879219 0.000873005 0.00086991 0.000868307
# 6_WA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000604451 0.000551423 0.000816295 0.000847475 0.000813062 0.000428149 0.000564816 0.000399615 0.000617629 0.000181369 0.00016988 8.26808e-05 5.74636e-05 0.000396022 0.000246069 0.000334854 0.000651581 0.000393358 0.000204362 0.000361499 0.000569961 0.000299943 0.00019046 0.00012646 0.000101043 0.000171629 7.94057e-05 5.1893e-05 0 0 0.000136196 0.000135461 0.000134873 0.000134283 0.000133542 0.000132946 0.00013183 0.000130899 0.000130435 0.000130195
# 7_CA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000172469 0.000345938 0.000398304 0.000533247 0.000669112 0.000805784 0.000943402 0.00108118 0.00122128 0.00145426 0.00143539 0.00126084 0.00182076 0.00169152 0.000904085 0.000872348 0.000726799 0.000994008 0.00175021 0.00140882 0.00283034 0.00368422 0.00451695 0.00537933 0.00472405 0.00404719 0.0050916 0.00615726 0.00685874 0.00639709 0.0107747 0.00856051 0.00652823 0.00444285 0.00520177 0.00523156 0.00447838 0.00642059 0.0067714 0.00716357 0.00789767 0.00910065 0.0118738 0.010303 0.0130079 0.0150302 0.0165524 0.0171388 0.0196823 0.0190091 0.018745 0.0211528 0.0199073 0.0189313 0.0355744 0.0145224 0.0155832 0.024554 0.0353862 0.0370492 0.0317438 0.0207477 0.0327057 0.0322261 0.0310013 0.0315758 0.025082 0.0316467 0.0115735 0.019559 0.00531581 0.0133001 0.015945 0.00702203 0.00134879 0.00409467 0.00455851 0.00243518 0.00534203 0.0046408 0.00226553 0.00542724 0.00504438 0.00638407 0.00595799 0.00507096 0.00765565 0.00863266 0.00705169 0.0148884 0.010964 0.0130936 0.0145691 0.0144595 0.0134358 0 0 0.0187245 0.0186226 0.0185402 0.0184577 0.0183551 0.0182731 0.0181199 0.017992 0.0179283 0.0178952
# 8_OR_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000455618 0.000943598 0.00152893 0.00215426 0.00269654 0.00327725 0.00394757 0.0042583 0.00558923 0.00635029 0.00388921 0.0051424 0.00288529 0.00594174 0.00406015 0.00336635 0.00412401 0.00268088 0.00385158 0.00549396 0.00737803 0.0055665 0.00666982 0.00415175 0.0054498 0.00855258 0.00521863 0.00427375 0.00226637 0.00188043 0.00191591 0.00046106 0.000687669 0.000366541 0.000382774 0.000460973 0.000602129 0.000791345 0.000534757 0.000512008 0.000705411 0.000541156 0.00222692 0.00146495 0.0040972 0.0062675 0.00574916 0.00924147 0.00603456 0.00929617 0 0 0.010219 0.0101634 0.0101186 0.0100736 0.0100175 0.00997273 0.00988909 0.00981927 0.00978445 0.00976635
# 9_WA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 5.75456e-05 8.10336e-05 0.000106946 0.000137013 0.000169309 0.00019728 0.000216166 0.000236942 0.000270987 0.000128767 0.00034741 0.000525048 0.000387983 0.000258109 0.000228222 0.000261959 0.000490452 0.000896137 0.000453309 0.000771797 0.000832364 0.000858538 0.00141131 0.00140238 0.0016273 0.00336239 0.00329068 0.00180428 0.00142598 0.0013218 0.00124346 0.00214769 0.00129383 0.00101317 0.000862964 0.000373886 0.000348051 0.000158691 0.000241348 0.000115437 9.57655e-05 7.80495e-05 7.31811e-05 0.00013537 0.000141699 0.000121299 0.000122498 0.000176717 0.000270511 0.000227581 0.000545854 0.000447571 0.00142595 0.000885685 0.00153498 0.00165278 0 0 0.00185403 0.001844 0.00183596 0.00182788 0.00181777 0.00180965 0.00179447 0.0017818 0.00177549 0.00177222
# 10_CA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.17793e-05 1.65255e-06 2.38324e-05 0.000179998 4.21496e-06 3.97713e-06 3.40276e-06 0 2.68826e-06 0 1.64826e-05 3.20143e-05 7.64399e-06 2.92066e-06 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.2979e-08 7.258e-08 7.22604e-08 7.19408e-08 7.15421e-08 7.12234e-08 7.06272e-08 7.01303e-08 6.98837e-08 6.97567e-08
# 11_OR_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000392568 7.32488e-05 0.000604249 0.0006153 0.000502864 9.48032e-05 1.54548e-05 0.000163858 9.95308e-05 0.000400908 7.70635e-05 0.00023275 0.000380131 0.000179509 0.000275184 0.000303749 1.51839e-05 3.00143e-05 0.000125342 2.64786e-05 3.27365e-06 6.97738e-05 3.54819e-05 9.29954e-06 2.9161e-05 0.000116182 0.000252499 2.38198e-05 0.000427231 4.9232e-05 4.15183e-05 0.000161808 4.88762e-05 2.7156e-06 2.60966e-06 8.24222e-07 7.87898e-06 6.14209e-06 2.78684e-05 5.93439e-06 1.69938e-05 0.000133599 0.000225643 5.3067e-05 1.55695e-05 0.00023986 0.000316989 0 0 0.000210848 0.000209709 0.000208797 0.00020788 0.000206726 0.000205798 0.000204068 0.000202626 0.000201907 0.000201535
# 12_WA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.83638e-05 1.70764e-05 0.000101884 2.11386e-05 0.00189884 0.0020864 0.000180346 0.000245436 0.000343202 0.000594597 0.000229727 0.000120054 0.000233142 0.000255558 0.000366102 0.000129437 0.000750155 4.58962e-05 0.000160409 0.000404992 0.000672736 0.000896742 0.000270954 0.000325086 0.000296503 6.84819e-05 6.94607e-05 8.45304e-05 5.90482e-05 2.21908e-05 0.000299713 0.00022811 9.9167e-05 8.81918e-05 2.44248e-05 4.22269e-05 1.95832e-05 9.64338e-06 2.1427e-05 0.000354037 0.000189032 0.000322139 5.33812e-05 0.000197054 0.000115133 0 0 0.000231823 0.00023057 0.000229568 0.000228559 0.00022729 0.00022627 0.000224369 0.000222783 0.000221993 0.000221583
# 13_CA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00154923 0.00383405 0.0150014 0.000175608 0 0 0.000446066 0.0130372 0.00535892 0.0022592 0.0017568 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.29394e-08 7.25373e-08 7.22165e-08 7.18975e-08 7.15003e-08 7.11839e-08 7.05901e-08 7.00948e-08 6.98493e-08 6.97226e-08
# 14_OR_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0512595 0.0234103 0.00999727 0.00170374 0.00240162 0.00381149 0.0102295 0.0171182 0.0026981 0.00473902 0.00382468 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.29944e-08 7.25971e-08 7.22788e-08 7.19599e-08 7.15612e-08 7.1242e-08 7.0645e-08 7.01472e-08 6.98999e-08 6.97724e-08
# 15_WA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00400853 0.00320201 0.00381015 0.000408899 0.000921168 0.00226105 0.00218745 0.00221721 0.00959324 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.29944e-08 7.25971e-08 7.22788e-08 7.19599e-08 7.15612e-08 7.1242e-08 7.0645e-08 7.01472e-08 6.98999e-08 6.97724e-08
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
           -25            25     -0.903857             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_28_coastwide_NWFSC(28)
           -25            25      -1.41966             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_29_coastwide_Tri_early(29)
           -25            25      -1.41966             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_30_coastwide_Tri_late(30)
           -25            25      -2.85596             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_31_coastwide_prerec(31)
             0             3      0.466445           0.1            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_31_coastwide_prerec(31)
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
        13.001            65       45.4598            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_1_CA_TWL(1)
             0             9       4.22784            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_1_CA_TWL(1)
             0             9       3.24244            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_1_CA_TWL(1)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_1_CA_TWL(1)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_1_CA_TWL(1)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_1_CA_TWL(1)
            -9             9       1.79658             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_1_CA_TWL(1)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_1_CA_TWL(1)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_1_CA_TWL(1)
# 2   2_OR_TWL LenSelex
        13.001            65       49.0323            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_2_OR_TWL(2)
             0             9       4.10202            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_2_OR_TWL(2)
             0             9       2.44902            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_2_OR_TWL(2)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_2_OR_TWL(2)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_2_OR_TWL(2)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_2_OR_TWL(2)
            -9             9       2.67315             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_2_OR_TWL(2)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_2_OR_TWL(2)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_2_OR_TWL(2)
# 3   3_WA_TWL LenSelex
# 4   4_CA_NTWL LenSelex
        13.001            65       36.5217            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_4_CA_NTWL(4)
             0             9       4.28451            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_4_CA_NTWL(4)
             0             9        5.1566            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_4_CA_NTWL(4)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_4_CA_NTWL(4)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_4_CA_NTWL(4)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_4_CA_NTWL(4)
            -9             9     -0.214731             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_4_CA_NTWL(4)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_4_CA_NTWL(4)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_4_CA_NTWL(4)
# 5   5_OR_NTWL LenSelex
        13.001            65       54.0415            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_5_OR_NTWL(5)
            -9             9       5.15814            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_5_OR_NTWL(5)
            -9             9       8.51963            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_5_OR_NTWL(5)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_5_OR_NTWL(5)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_5_OR_NTWL(5)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_5_OR_NTWL(5)
            -9             9       4.28645             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_5_OR_NTWL(5)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_5_OR_NTWL(5)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_5_OR_NTWL(5)
# 6   6_WA_NTWL LenSelex
        13.001            65       46.1946            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_6_WA_NTWL(6)
            -9             9       3.34676            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_6_WA_NTWL(6)
            -9             9        2.4979            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_6_WA_NTWL(6)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_6_WA_NTWL(6)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_6_WA_NTWL(6)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_6_WA_NTWL(6)
            -9             9       3.23662             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_6_WA_NTWL(6)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_6_WA_NTWL(6)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_6_WA_NTWL(6)
# 7   7_CA_REC LenSelex
        13.001            65       28.8665            99            99             0          4          0          0          0          0          0          3          2  #  Size_DblN_peak_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_7_CA_REC(7)
             0             9       3.47948            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_7_CA_REC(7)
             0             9       4.82046            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_descend_se_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_7_CA_REC(7)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_7_CA_REC(7)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          3          2  #  SzSel_Fem_Descend_7_CA_REC(7)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_7_CA_REC(7)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_7_CA_REC(7)
# 8   8_OR_REC LenSelex
        13.001            65        31.005            99            99             0          4          0          0          0          0          0          4          2  #  Size_DblN_peak_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_8_OR_REC(8)
            -9             9       3.14375            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_ascend_se_8_OR_REC(8)
            -9             9        3.1673            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_descend_se_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_8_OR_REC(8)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_8_OR_REC(8)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_8_OR_REC(8)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_8_OR_REC(8)
            -9             9       2.33851             0            50             0          5          0          0          0          0          0          4          2  #  SzSel_Fem_Descend_8_OR_REC(8)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_8_OR_REC(8)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_8_OR_REC(8)
# 9   9_WA_REC LenSelex
        13.001            65       34.2134            99            99             0          4          0          0          0          0          0          5          2  #  Size_DblN_peak_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_9_WA_REC(9)
            -9             9       2.72828            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_ascend_se_9_WA_REC(9)
            -9             9       3.81219            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_descend_se_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_9_WA_REC(9)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_9_WA_REC(9)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_9_WA_REC(9)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_9_WA_REC(9)
            -9             9       1.34859             0            50             0          5          0          0          0          0          0          5          2  #  SzSel_Fem_Descend_9_WA_REC(9)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_9_WA_REC(9)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_9_WA_REC(9)
# 10   10_CA_ASHOP LenSelex
        13.001            65       43.4627            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_10_CA_ASHOP(10)
             0             9       2.41924            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_10_CA_ASHOP(10)
             0             9       2.84172            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_10_CA_ASHOP(10)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_10_CA_ASHOP(10)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_10_CA_ASHOP(10)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_10_CA_ASHOP(10)
            -9             9       2.44135             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_10_CA_ASHOP(10)
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
        13.001            65       47.5704            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_28_coastwide_NWFSC(28)
             0             9        6.7923            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_28_coastwide_NWFSC(28)
             0             9       2.43521            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_28_coastwide_NWFSC(28)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_28_coastwide_NWFSC(28)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_28_coastwide_NWFSC(28)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_28_coastwide_NWFSC(28)
            -9             9       3.04031             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_28_coastwide_NWFSC(28)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_28_coastwide_NWFSC(28)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_28_coastwide_NWFSC(28)
# 29   29_coastwide_Tri_early LenSelex
        13.001            65       63.8225            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_29_coastwide_Tri_early(29)
             0             9       6.90888            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_29_coastwide_Tri_early(29)
             0             9        4.5962            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_29_coastwide_Tri_early(29)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_29_coastwide_Tri_early(29)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_29_coastwide_Tri_early(29)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_29_coastwide_Tri_early(29)
            -9             9      0.374435             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_29_coastwide_Tri_early(29)
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
        13.001            65       43.8349            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2000
        13.001            65       43.2554            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2011
             0             9       3.75962            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       3.85972            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2011
             0             9       1.49365            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9         2.478            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2011
            -9             9       2.60461             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2000
            -9             9       1.58611             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2011
        13.001            65       42.9556            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2000
        13.001            65       45.4292            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2011
             0             9       4.19177            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       4.72338            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2011
             0             9       3.72407            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       2.68197            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2011
            -9             9       8.80734             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2000
            -9             9       2.08397             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2011
        13.001            65        33.373            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2000
        13.001            65       38.1723            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2020
             0             9       2.99433            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       3.62873            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2020
             0             9       4.43468            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       3.65751            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2020
            -9             9      0.968424             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2000
            -9             9       1.11887             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2020
        13.001            65       33.2016            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK2repl_2000
        13.001            65       45.0986            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK2repl_2020
            -9             9       2.42547            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       5.17125            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK2repl_2020
            -9             9       4.05518            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       1.90913            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK2repl_2020
            -9             9      0.898502             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK2repl_2000
            -9             9       2.35579             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK2repl_2020
        13.001            65       30.3528            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2004
        13.001            65       32.2824            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2017
             0             9       3.33335            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       3.35374            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2017
             0             9       3.71751            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       4.25715            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2017
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2004
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2017
        13.001            65       31.7146            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2004
        13.001            65        31.403            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2015
            -9             9       2.70483            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       2.31875            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9       4.53999            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9        4.1126            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2004
            -9             9       1.26008             0            50             0      5  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2015
        13.001            65       29.0665            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2006
        13.001            65       45.9071            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2021
            -9             9      -7.51618            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9       5.26939            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2021
            -9             9       4.94902            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9       2.75306            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2021
            -9             9      0.935814             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2006
            -9             9       3.67452             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2021
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

