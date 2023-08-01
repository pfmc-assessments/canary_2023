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
 0.02 0.2 0.0775183 -2.74 0.31 3 2 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 2 15 8.15904 4 50 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 50 70 59.2183 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.02 0.21 0.139093 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.02 0.21 0.0905157 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.21 0.0378799 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
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
 50 70 53.7011 60 50 0 3 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.02 0.21 0.162653 0.14 50 0 3 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.02 0.21 0.0975484 0.15 50 0 4 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.21 0.0463415 0.028 50 0 4 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
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
             7            11       8.11854           8.5            50             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
 0.21 0.99 0.95 0.72 0.16 2 -6 0 0 0 0 0 0 0 # SR_BH_steep
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
#  -0.00325577 -0.00352086 -0.0038071 -0.00411615 -0.00444978 -0.00480989 -0.00519852 -0.00561785 -0.00607019 -0.006558 -0.00708389 -0.0076506 -0.00826096 -0.00891803 -0.009625 -0.0103854 -0.011203 -0.0120822 -0.0130284 -0.0140488 -0.0151527 -0.0163477 -0.0176373 -0.0190244 -0.0205146 -0.0221163 -0.0238391 -0.0256941 -0.0276944 -0.029852 -0.0321756 -0.0346692 -0.0373347 -0.0401755 -0.0431914 -0.0463708 -0.049692 -0.0531225 -0.0566451 -0.060258 -0.0639511 -0.0678179 -0.071986 -0.0766479 -0.0820476 -0.0883216 -0.0954168 -0.103055 -0.110995 -0.118223 -0.124534 -0.129851 -0.134194 -0.135916 -0.135626 -0.133552 -0.129231 -0.122357 -0.112546 -0.100259 -0.0852519 -0.0673422 -0.0452014 -0.016323 0.0235289 0.0798419 0.158919 0.264157 0.315751 0.376969 0.298497 0.143813 0.0284636 0.010827 0.117926 0.363423 0.618824 0.171465 -0.171089 -0.164856 0.226775 0.459292 0.121419 0.172796 0.433912 -0.0311629 0.326846 0.259668 -0.420597 0.278366 0.0693903 -0.170295 0.148011 0.0971718 -0.0524204 0.0949755 0.0810741 0.301557 0.191538 -0.002968 0.176415 -0.245993 0.0182333 0.159175 0.145341 -0.218404 -0.227828 -0.37918 -0.237328 0.0861688 -0.0254323 0.39051 0.014177 -0.572791 -0.22551 0.357525 -0.673049 -0.233213 0.0802277 -0.0936431 0.00989648 0.225088 -0.402748 -0.431343 -0.166007 -0.868761 -0.931006 -0.331829 -0.166631 0.115826 -0.0432468 0 0 0 0 0 0 0 0 0 0 0 0
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
# 1_CA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000238117 0.000364869 0.000389782 0.000302359 0.00030328 0.000236031 0.00020857 0.000245812 0.000134308 9.23112e-05 0.000302503 0.000390561 0.000482287 0.000885615 0.000768269 0.00106739 0.000730869 0.000996759 0.000857476 0.000878799 0.000528426 0.000806627 0.000824378 0.00109465 0.000895928 0.000713783 0.000173949 0.000870787 0.00373669 0.00892337 0.00853958 0.00352999 0.00408822 0.0036581 0.00334632 0.0068324 0.00494179 0.00477015 0.00345089 0.00372361 0.00368871 0.00425064 0.00572597 0.00432108 0.00334842 0.00263196 0.00263673 0.00372169 0.00233221 0.00309568 0.00225888 0.00310756 0.00295947 0.00724508 0.00777947 0.0117359 0.0146409 0.011536 0.0146997 0.0160019 0.0174222 0.0169616 0.0251908 0.012854 0.0192326 0.0254396 0.0411158 0.0297199 0.0251447 0.0215059 0.0115428 0.0151118 0.0177932 0.0160241 0.0320416 0.0164004 0.0295033 0.0133078 0.0182152 0.0181631 0.0281554 0.0215454 0.0187293 0.0111907 0.00195842 0.00129796 0.0018574 0.000135091 0.000250315 0.000320003 0.000955619 0.00203825 0.00098082 0.000155587 4.35177e-05 2.62277e-05 4.04163e-05 0.000107247 0.000136681 0.000479141 0.000191243 0.00508316 0.00947388 0.0120096 0.00503717 0.00541508 0.00636791 0.00751645 0.00800036 0.0112675 0.0112064 0.0111572 0.0111078 0.011046 0.0109965 0.0109471 0.0108856 0.0108364 0.0107874
# 2_OR_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1.65433e-05 1.01527e-05 4.15218e-07 8.1139e-06 2.96085e-05 5.7891e-05 0 8.29719e-05 0.00191346 0.0029599 0.00559679 0.0198739 0.0358973 0.0583999 0.038123 0.0245987 0.0179221 0.0158323 0.0168946 0.0158214 0.0166587 0.017687 0.0227407 0.0232354 0.035052 0.0373349 0.0259851 0.028863 0.034923 0.0321459 0.0381187 0.0221099 0.0339873 0.027937 0.0321101 0.00531195 0.0304471 0.00974885 0.0199841 0.0259071 0.0250779 0.0313147 0.0201126 0.0143542 0.00920689 0.0213202 0.0667513 0.0531493 0.120565 0.089519 0.190067 0.202965 0.0851365 0.0748065 0.0760311 0.117328 0.14086 0.150147 0.113433 0.254332 0.249309 0.298271 0.138964 0.102161 0.13147 0.0947393 0.106026 0.0551472 0.00388067 0.0017647 0.00230833 0.00121144 0.000513181 0.000981443 0.000996856 0.00019669 0.000250387 0.000388039 0.000192137 0.000172455 0.000355958 0.00031297 0.000517385 0.00201407 0.000818968 0.00704108 0.00823071 0.00919513 0.00882691 0.0106349 0.0152679 0.0149012 0.0155475 0.01717 0.0170771 0.0170025 0.0169277 0.0168339 0.0167588 0.0166836 0.01659 0.0165151 0.0164404
# 3_WA_TWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 8.27163e-07 0 6.22826e-06 4.82673e-05 6.23447e-05 5.5801e-05 8.25459e-05 8.67529e-05 0.000192674 7.24406e-05 0.00141732 0.00465312 0.00199038 0.021994 0.0117549 0.00635604 0.0105535 0.0130951 0.0128222 0.0109194 0.0105857 0.00464963 0.00675345 0.00646499 0.00628903 0.00532017 0.00685902 0.00777897 0.00714315 0.00860064 0.0121602 0.00987294 0.00729661 0.0162867 0.0228183 0.0113309 0.0195098 0.0188187 0.017007 0.0192837 0.00537166 0.0121885 0.0189823 0.0262649 0.0199468 0.0166533 0.0502469 0.0268443 0.0308504 0.0233974 0.0220083 0.038333 0.0399359 0.0710779 0.0644538 0.0774357 0.0819493 0.113917 0.117693 0.122282 0.126106 0.0522311 0.028574 0.0284419 0.0317365 0.0322561 0.0304217 0.0194771 0.00124319 0.000815935 0.0018564 0.000778734 0.000524645 0.00152031 0.000555226 0.000233135 0.000177517 0.000279161 0.000327848 0.000198433 0.000268698 0.000235757 0.000108185 0.000193708 0.000242318 0.00177335 0.00739671 0.00309231 0.00373161 0.00350231 0.0049595 0.00530427 0.00553431 0.00597512 0.00594279 0.00591683 0.00589077 0.00585816 0.005832 0.00580586 0.00577327 0.00574722 0.00572122
# 4_CA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000943427 0.0015255 0.00157965 0.000919008 0.000994359 0.000891329 0.000830659 0.00100449 0.00121789 0.00150078 0.00176478 0.00142426 0.00123631 0.000841168 0.00119809 0.00116967 0.000971181 0.000388448 0.000541552 0.000823522 0.000745003 0.000474318 0.000486913 0.000466462 0.000346269 0.000449583 0.000336343 0.000283377 0.00108629 0.00275962 0.00297103 0.000695781 0.00137976 0.000540391 0.000443967 0.000726066 0.000553054 0.000324644 0.000799497 0.00018932 0.000296825 0.000330037 0.000432241 0.000300078 0.000383801 0.000311096 0.000442515 0.000405135 0.000371066 0.000401791 0.000317367 0.00033333 0.0002083 0.000814763 0.000512172 0.000907512 0.00174966 0.000837088 0.00216014 0.00157715 0.0022321 0.00268846 0.00683658 0.00628681 0.00489073 0.00922842 0.0026056 0.00443287 0.00422121 0.00813752 0.00421113 0.00399675 0.00458485 0.019767 0.0206198 0.0175456 0.0152875 0.0138826 0.0120214 0.0133598 0.014088 0.0115294 0.00899582 0.00334453 0.00198068 0.00151364 1.47884e-05 0.000287058 0.000313696 0.000203357 0.000322697 0.000399048 0.000134521 0.000168952 0.000534099 0.00130558 0.000416384 0.00062034 0.000427622 0.000501333 0.000292095 0.000666872 0.000686167 0.000987139 0.00194996 0.00278704 0.00260581 0.0105251 0.0111707 0.00325512 0.00323733 0.003223 0.00320868 0.00319083 0.00317656 0.00316233 0.00314456 0.00313036 0.00311618
# 5_OR_NTWL 0.000115519 0.00011553 0.000115541 2.9735e-05 7.18436e-06 7.38426e-06 4.19145e-06 6.98659e-06 9.78262e-06 1.27794e-05 1.55778e-05 1.83775e-05 2.13785e-05 2.41814e-05 2.69861e-05 2.97927e-05 3.28014e-05 3.56125e-05 3.8426e-05 4.14425e-05 4.42617e-05 4.70842e-05 5.01105e-05 5.29404e-05 5.57903e-05 5.86741e-05 6.17809e-05 6.46871e-05 6.7591e-05 7.0703e-05 7.36165e-05 7.65405e-05 7.96818e-05 8.26366e-05 8.56186e-05 8.80102e-05 0.000147148 0.000252537 0.000230733 0.000185665 5.9282e-05 9.77715e-05 0.000105627 9.50956e-05 0.000227827 0.000272127 0.000269307 0.000153874 0.000341877 0.000459679 0.000642742 0.00161488 0.00042673 0.000285693 0.000370099 0.000193209 0.000323814 0.000219795 0.000207807 0.000162597 0.000157089 8.29643e-05 9.80174e-05 0.000122987 7.95936e-05 0.000176091 3.57304e-05 7.40398e-05 4.96695e-05 0.000139358 0.000128117 0.000114562 2.60983e-05 0.00018825 0.000128318 0.000363236 0.000330065 0.000731867 0.000283606 0.000579885 0.000754248 0.000799989 0.00101781 0.000543388 0.000734326 0.00091443 0.00147512 0.00436703 0.00265717 0.00306526 0.00615774 0.014263 0.0103205 0.0107805 0.00898264 0.0149837 0.0135931 0.0147101 0.0212357 0.0264371 0.0189633 0.0522047 0.0138058 0.0124799 0.0169756 0.0253811 0.0246963 0.0116604 0.00196058 0.0017195 7.1601e-05 6.92591e-05 0.000828464 0.000257938 0.000370905 0.000246636 0.000104725 0.000349963 0.000112834 0.000464427 0.000198428 0.000288683 0.000190574 0.000330903 0.000677713 0.000563933 0.000430549 0.000621089 0.000268597 0.000235837 0.000400737 0.00115721 0.00117186 0.000596678 0.000593449 0.000590857 0.000588262 0.000585017 0.000582417 0.000579818 0.000576574 0.000573978 0.000571385
# 6_WA_NTWL 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000650693 0.000593921 0.000882223 0.000921358 0.00088745 0.000465189 0.0006062 0.000421416 0.000637013 0.000182521 0.000166796 7.92671e-05 5.38259e-05 0.000362539 0.000220315 0.000293876 0.000562968 0.000336149 0.000173145 0.000303658 0.000474223 0.000247003 0.000155187 0.000102059 8.1024e-05 0.000137098 6.32146e-05 4.11581e-05 0.000322477 0.000326849 0.000126076 0.000125396 0.000124852 0.000124306 0.000123621 0.000123071 0.00012252 0.000121834 0.000121284 0.000120736
# 7_CA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000188219 0.000377364 0.00043431 0.00058121 0.000728983 0.000877523 0.00102701 0.0011766 0.00132868 0.00158181 0.00156102 0.00137099 0.0019797 0.00183931 0.000983244 0.000949019 0.000790826 0.00108133 0.00190471 0.00153465 0.00308602 0.00401973 0.00492951 0.00587076 0.00515584 0.00441846 0.0055628 0.00673662 0.00752033 0.00703538 0.0118976 0.00949795 0.00728138 0.00498565 0.00588541 0.00598559 0.00519092 0.00753318 0.00797693 0.0083801 0.00908843 0.0102395 0.0130519 0.0112087 0.01425 0.0165036 0.0180631 0.0184757 0.0209928 0.0201067 0.0196497 0.0220669 0.0207191 0.0196017 0.0366133 0.0148618 0.015867 0.0248863 0.0356984 0.0372357 0.0318588 0.0208204 0.0329025 0.0326248 0.0316717 0.0328882 0.02654 0.0336337 0.0123378 0.0208818 0.00564471 0.0138523 0.0160993 0.00688323 0.00128791 0.00382366 0.0041035 0.00215104 0.00466126 0.00403685 0.00199241 0.00484967 0.00453664 0.0056555 0.00518464 0.00435405 0.00660231 0.00769209 0.00647477 0.0138986 0.0102199 0.0122395 0.0139361 0.0143329 0.0137014 0.0233612 0.0241999 0.0211828 0.0210665 0.0209732 0.0208801 0.0207642 0.0206715 0.020579 0.0204635 0.0203711 0.0202787
# 8_OR_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000471622 0.000970869 0.00154128 0.0021349 0.00266002 0.00322512 0.00386849 0.00417107 0.00546774 0.00618797 0.00377991 0.00497652 0.00277732 0.00569909 0.00388487 0.00321834 0.00395187 0.00258447 0.00374792 0.0054038 0.00741871 0.0057064 0.00686627 0.00427561 0.00561058 0.00875372 0.0052442 0.00415931 0.00213584 0.00172361 0.00171205 0.000426483 0.00062253 0.000325363 0.000334939 0.000401323 0.000526248 0.000693987 0.000466654 0.000442286 0.000603046 0.00045887 0.00203187 0.00135817 0.0038236 0.00583774 0.00535387 0.00875001 0.00587635 0.00925247 0.0113306 0.0116569 0.0114232 0.0113606 0.0113104 0.0112601 0.0111976 0.0111476 0.0110976 0.0110353 0.0109855 0.0109357
# 9_WA_REC 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.86654e-05 4.03761e-05 5.18432e-05 6.3367e-05 7.50454e-05 8.63737e-05 9.79956e-05 0.000110341 0.000123973 5.61393e-05 0.000145717 0.000220652 0.000165754 0.000112347 0.000102655 0.000121002 0.000236492 0.000447205 0.000225834 0.000384115 0.000417187 0.000435439 0.000734422 0.000757998 0.000923095 0.00202754 0.00211148 0.00121872 0.000978206 0.0009033 0.000838892 0.00140547 0.000807475 0.000594175 0.000472459 0.000190754 0.000164633 6.93507e-05 9.83578e-05 9.81563e-05 8.02032e-05 6.48172e-05 6.04202e-05 0.000110837 0.000115328 9.8391e-05 9.81553e-05 0.000140365 0.000215826 0.000183897 0.000443749 0.000363663 0.00114709 0.000717846 0.00135975 0.00147276 0.00183509 0.00188262 0.00183631 0.00182636 0.00181837 0.00181036 0.00180036 0.00179234 0.00178433 0.00177434 0.00176634 0.00175836
# 10_CA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.23492e-05 1.68088e-06 2.40864e-05 0.000181273 4.23689e-06 4.0127e-06 3.44871e-06 0 2.71847e-06 0 1.65644e-05 3.22039e-05 7.71213e-06 2.96963e-06 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# 11_OR_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000405299 7.56064e-05 0.000620061 0.000625848 0.000508223 9.54747e-05 1.55353e-05 0.000165323 0.000100875 0.000406386 7.79293e-05 0.000234458 0.000382017 0.000180572 0.000277637 0.000308842 1.56658e-05 3.15061e-05 0.000133319 2.81995e-05 3.49511e-06 7.49481e-05 3.83932e-05 1.00923e-05 3.14084e-05 0.00012306 0.000261422 2.39837e-05 0.000417575 4.67791e-05 3.84271e-05 0.000146132 4.31331e-05 2.34673e-06 2.21691e-06 6.92069e-07 6.56758e-06 5.08724e-06 2.28978e-05 4.82577e-06 1.36589e-05 0.000106196 0.000178089 4.18204e-05 1.22735e-05 0.000188639 0.000248245 0.000909025 0.000947073 0.000191922 0.000190886 0.000190056 0.000189221 0.000188174 0.000187332 0.000186492 0.000185445 0.000184608 0.000183773
# 12_WA_ASHOP 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.9106e-05 1.73691e-05 0.000102969 2.12883e-05 0.00190872 0.00210506 0.000182781 0.00024879 0.000347057 0.00059896 0.000230867 0.000120765 0.00023522 0.000259843 0.000377721 0.00013587 0.000797896 4.88792e-05 0.00017126 0.000435025 0.000727935 0.000973187 0.000291836 0.000344333 0.000306981 6.8953e-05 6.78908e-05 8.03189e-05 5.46518e-05 2.00409e-05 0.000264496 0.000197125 8.42425e-05 7.40513e-05 2.03595e-05 3.49748e-05 1.60904e-05 7.84188e-06 1.72222e-05 0.000281421 0.000149194 0.000253868 4.20806e-05 0.000154974 9.01646e-05 0.00125532 0.00130786 0.000211509 0.000210368 0.000209453 0.000208533 0.000207378 0.000206451 0.000205525 0.000204371 0.000203449 0.000202529
# 13_CA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00154925 0.00388775 0.0154294 0.000182726 0 0 0.000464869 0.0134869 0.00551113 0.00231656 0.00179792 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# 14_OR_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0496475 0.0229967 0.00997215 0.00172522 0.00246039 0.00393599 0.0105947 0.0177139 0.00278454 0.00487649 0.00392633 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# 15_WA_FOR 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.00388247 0.00314544 0.00380057 0.000414052 0.000943711 0.00233491 0.00226554 0.00229437 0.00990058 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
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
           -25            25      -1.03604             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_28_coastwide_NWFSC(28)
           -25            25      -1.18136             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_29_coastwide_Tri_early(29)
           -25            25      -1.18136             0             1             0          2          0          0          0          0          0          0          0  #  LnQ_base_30_coastwide_Tri_late(30)
           -25            25      -3.05223             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_31_coastwide_prerec(31)
             0             3      0.524756           0.1            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_31_coastwide_prerec(31)
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
        13.001            65       45.2107            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_1_CA_TWL(1)
             0             9       4.29588            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_1_CA_TWL(1)
             0             9       3.55468            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_1_CA_TWL(1)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_1_CA_TWL(1)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_1_CA_TWL(1)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_1_CA_TWL(1)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_1_CA_TWL(1)
            -9             9        1.5796             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_1_CA_TWL(1)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_1_CA_TWL(1)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_1_CA_TWL(1)
# 2   2_OR_TWL LenSelex
        13.001            65       49.4867            99            99             0          4          0          0          0          0          0          1          2  #  Size_DblN_peak_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_2_OR_TWL(2)
             0             9       4.16481            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_ascend_se_2_OR_TWL(2)
             0             9        2.6181            99            99             0          5          0          0          0          0          0          1          2  #  Size_DblN_descend_se_2_OR_TWL(2)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_2_OR_TWL(2)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_2_OR_TWL(2)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_2_OR_TWL(2)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_2_OR_TWL(2)
            -9             9        3.1443             0            50             0          5          0          0          0          0          0          1          2  #  SzSel_Fem_Descend_2_OR_TWL(2)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_2_OR_TWL(2)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_2_OR_TWL(2)
# 3   3_WA_TWL LenSelex
# 4   4_CA_NTWL LenSelex
        13.001            65         36.35            99            99             0          4          0          0          0          0          0          2          2  #  Size_DblN_peak_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_4_CA_NTWL(4)
             0             9       4.26375            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_ascend_se_4_CA_NTWL(4)
             0             9       5.16229            99            99             0          5          0          0          0          0          0          2          2  #  Size_DblN_descend_se_4_CA_NTWL(4)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_4_CA_NTWL(4)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_4_CA_NTWL(4)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_4_CA_NTWL(4)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_4_CA_NTWL(4)
            -9             9      0.268616             0            50             0          5          0          0          0          0          0          2          2  #  SzSel_Fem_Descend_4_CA_NTWL(4)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_4_CA_NTWL(4)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_4_CA_NTWL(4)
# 5   5_OR_NTWL LenSelex
        13.001            65       31.0532            99            99             0          4          0          0          0          0          0          6          2  #  Size_DblN_peak_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_5_OR_NTWL(5)
            -9             9      -7.42709            99            99             0          5          0          0          0          0          0          6          2  #  Size_DblN_ascend_se_5_OR_NTWL(5)
            -9             9       6.09542            99            99             0          5          0          0          0          0          0          6          2  #  Size_DblN_descend_se_5_OR_NTWL(5)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_5_OR_NTWL(5)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_5_OR_NTWL(5)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_5_OR_NTWL(5)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_5_OR_NTWL(5)
            -9             9       7.54605             0            50             0          5          0          0          0          0          0          6          2  #  SzSel_Fem_Descend_5_OR_NTWL(5)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_5_OR_NTWL(5)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_5_OR_NTWL(5)
# 6   6_WA_NTWL LenSelex
        13.001            65       46.1789            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_6_WA_NTWL(6)
            -9             9       3.41474            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_6_WA_NTWL(6)
            -9             9       2.60825            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_6_WA_NTWL(6)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_6_WA_NTWL(6)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_6_WA_NTWL(6)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_6_WA_NTWL(6)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_6_WA_NTWL(6)
            -9             9       2.78717             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_6_WA_NTWL(6)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_6_WA_NTWL(6)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_6_WA_NTWL(6)
# 7   7_CA_REC LenSelex
        13.001            65       28.9104            99            99             0          4          0          0          0          0          0          3          2  #  Size_DblN_peak_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_7_CA_REC(7)
             0             9       3.48962            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_ascend_se_7_CA_REC(7)
             0             9       4.82373            99            99             0          5          0          0          0          0          0          3          2  #  Size_DblN_descend_se_7_CA_REC(7)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_7_CA_REC(7)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_7_CA_REC(7)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_7_CA_REC(7)
            -9             9             0             0            50             0        -99          0          0          0          0          0          3          2  #  SzSel_Fem_Descend_7_CA_REC(7)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_7_CA_REC(7)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_7_CA_REC(7)
# 8   8_OR_REC LenSelex
        13.001            65       30.9841            99            99             0          4          0          0          0          0          0          4          2  #  Size_DblN_peak_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_8_OR_REC(8)
            -9             9       3.13845            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_ascend_se_8_OR_REC(8)
            -9             9       3.23577            99            99             0          5          0          0          0          0          0          4          2  #  Size_DblN_descend_se_8_OR_REC(8)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_8_OR_REC(8)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_8_OR_REC(8)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_8_OR_REC(8)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_8_OR_REC(8)
            -9             9        2.3357             0            50             0          5          0          0          0          0          0          4          2  #  SzSel_Fem_Descend_8_OR_REC(8)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_8_OR_REC(8)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_8_OR_REC(8)
# 9   9_WA_REC LenSelex
        13.001            65       34.8654            99            99             0          4          0          0          0          0          0          5          2  #  Size_DblN_peak_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_9_WA_REC(9)
            -9             9       3.28445            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_ascend_se_9_WA_REC(9)
            -9             9       5.23293            99            99             0          5          0          0          0          0          0          5          2  #  Size_DblN_descend_se_9_WA_REC(9)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_9_WA_REC(9)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_9_WA_REC(9)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_9_WA_REC(9)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_9_WA_REC(9)
            -9             9       2.21315             0            50             0          5          0          0          0          0          0          5          2  #  SzSel_Fem_Descend_9_WA_REC(9)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_9_WA_REC(9)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_9_WA_REC(9)
# 10   10_CA_ASHOP LenSelex
        13.001            65       43.5358            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_10_CA_ASHOP(10)
             0             9       2.46752            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_10_CA_ASHOP(10)
             0             9       2.89722            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_10_CA_ASHOP(10)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_10_CA_ASHOP(10)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_10_CA_ASHOP(10)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_10_CA_ASHOP(10)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_10_CA_ASHOP(10)
            -9             9       2.31342             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_10_CA_ASHOP(10)
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
        13.001            65       48.3007            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_28_coastwide_NWFSC(28)
             0             9       7.08559            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_28_coastwide_NWFSC(28)
             0             9       2.29106            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_28_coastwide_NWFSC(28)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_28_coastwide_NWFSC(28)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_28_coastwide_NWFSC(28)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_28_coastwide_NWFSC(28)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_28_coastwide_NWFSC(28)
            -9             9       2.38703             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_28_coastwide_NWFSC(28)
           -99            99             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Final_28_coastwide_NWFSC(28)
             0             2             1             1            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Scale_28_coastwide_NWFSC(28)
# 29   29_coastwide_Tri_early LenSelex
        13.001            65       64.9506            99            99             0          4          0          0          0          0          0          0          0  #  Size_DblN_peak_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_top_logit_29_coastwide_Tri_early(29)
             0             9       6.75515            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_ascend_se_29_coastwide_Tri_early(29)
             0             9       4.50084            99            99             0          5          0          0          0          0          0          0          0  #  Size_DblN_descend_se_29_coastwide_Tri_early(29)
           -99            99           -15            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_start_logit_29_coastwide_Tri_early(29)
           -99            99          -999            99            99             0        -99          0          0          0          0          0          0          0  #  Size_DblN_end_logit_29_coastwide_Tri_early(29)
           -25            25             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Peak_29_coastwide_Tri_early(29)
            -9             9             0             0            50             0        -99          0          0          0          0          0          0          0  #  SzSel_Fem_Ascend_29_coastwide_Tri_early(29)
            -9             9    0.00334634             0            50             0          5          0          0          0          0          0          0          0  #  SzSel_Fem_Descend_29_coastwide_Tri_early(29)
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
        13.001            65       43.7447            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2000
        13.001            65       45.0593            99            99             0      4  # Size_DblN_peak_1_CA_TWL(1)_BLK1repl_2011
             0             9       3.79721            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       4.30057            99            99             0      5  # Size_DblN_ascend_se_1_CA_TWL(1)_BLK1repl_2011
             0             9       1.71386            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2000
             0             9       1.85243            99            99             0      5  # Size_DblN_descend_se_1_CA_TWL(1)_BLK1repl_2011
            -9             9         2.382             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2000
            -9             9       1.87605             0            50             0      5  # SzSel_Fem_Descend_1_CA_TWL(1)_BLK1repl_2011
        13.001            65       43.5996            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2000
        13.001            65       45.3073            99            99             0      4  # Size_DblN_peak_2_OR_TWL(2)_BLK1repl_2011
             0             9        4.2678            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       4.76026            99            99             0      5  # Size_DblN_ascend_se_2_OR_TWL(2)_BLK1repl_2011
             0             9       3.81017            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2000
             0             9       2.86994            99            99             0      5  # Size_DblN_descend_se_2_OR_TWL(2)_BLK1repl_2011
            -9             9       8.78309             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2000
            -9             9       1.84882             0            50             0      5  # SzSel_Fem_Descend_2_OR_TWL(2)_BLK1repl_2011
        13.001            65        33.616            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2000
        13.001            65       34.5754            99            99             0      4  # Size_DblN_peak_4_CA_NTWL(4)_BLK2repl_2020
             0             9       3.04686            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       2.75589            99            99             0      5  # Size_DblN_ascend_se_4_CA_NTWL(4)_BLK2repl_2020
             0             9       4.30963            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2000
             0             9       4.16134            99            99             0      5  # Size_DblN_descend_se_4_CA_NTWL(4)_BLK2repl_2020
            -9             9       1.09846             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2000
            -9             9       0.90593             0            50             0      5  # SzSel_Fem_Descend_4_CA_NTWL(4)_BLK2repl_2020
        13.001            65       32.8887            99            99             0      4  # Size_DblN_peak_5_OR_NTWL(5)_BLK6repl_2000
            -9             9       2.47633            99            99             0      5  # Size_DblN_ascend_se_5_OR_NTWL(5)_BLK6repl_2000
            -9             9       4.34344            99            99             0      5  # Size_DblN_descend_se_5_OR_NTWL(5)_BLK6repl_2000
            -9             9       1.07152             0            50             0      5  # SzSel_Fem_Descend_5_OR_NTWL(5)_BLK6repl_2000
        13.001            65       30.2957            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2004
        13.001            65       32.0647            99            99             0      4  # Size_DblN_peak_7_CA_REC(7)_BLK3repl_2017
             0             9       3.33455            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       3.30397            99            99             0      5  # Size_DblN_ascend_se_7_CA_REC(7)_BLK3repl_2017
             0             9       3.71653            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2004
             0             9       4.21524            99            99             0      5  # Size_DblN_descend_se_7_CA_REC(7)_BLK3repl_2017
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2004
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_7_CA_REC(7)_BLK3repl_2017
        13.001            65       31.6768            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2004
        13.001            65       30.8941            99            99             0      4  # Size_DblN_peak_8_OR_REC(8)_BLK4repl_2015
            -9             9       2.69585            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       2.10916            99            99             0      5  # Size_DblN_ascend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9       4.54794            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2004
            -9             9       4.16313            99            99             0      5  # Size_DblN_descend_se_8_OR_REC(8)_BLK4repl_2015
            -9             9             0             0            50             0      -99  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2004
            -9             9       1.11228             0            50             0      5  # SzSel_Fem_Descend_8_OR_REC(8)_BLK4repl_2015
        13.001            65       32.0282            99            99             0      4  # Size_DblN_peak_9_WA_REC(9)_BLK5repl_2006
            -9             9       2.11294            99            99             0      5  # Size_DblN_ascend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9        4.5742            99            99             0      5  # Size_DblN_descend_se_9_WA_REC(9)_BLK5repl_2006
            -9             9      0.978072             0            50             0      5  # SzSel_Fem_Descend_9_WA_REC(9)_BLK5repl_2006
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

