#C forecast file written by R function SS_writeforecast
#C rerun model to get more complete formatting in forecast.ss_new
#C should work with SS version: 3.3
#C file write time: 2023-05-25 11:56:10
#
1 #_benchmarks
2 #_MSY
0.5 #_SPRtarget
0.4 #_Btarget
#_Bmark_years: beg_bio, end_bio, beg_selex, end_selex, beg_relF, end_relF,  beg_recr_dist, end_recr_dist, beg_SRparm, end_SRparm (enter actual year, or values of 0 or -integer to be rel. endyr)
-999 0 0 0 0 0 -999 0 -999 0
1 #_Bmark_relF_Basis
1 #_Forecast
12 #_Nforecastyrs
1 #_F_scalar
#_Fcast_years:  beg_selex, end_selex, beg_relF, end_relF, beg_recruits, end_recruits (enter actual year, or values of 0 or -integer to be rel. endyr)
0 0 -3 0 -999 0
0 #_Fcast_selex
3 #_ControlRuleMethod
0.4 #_BforconstantF
0.1 #_BfornoF
-1 #_Flimitfraction
 #_Year Fraction
   2023    1.000
   2024    1.000
   2025    0.935
   2026    0.930
   2027    0.926
   2028    0.922
   2029    0.917
   2030    0.913
   2031    0.909
   2032    0.904
   2033    0.900
   2034    0.896
-9999 0
3 #_N_forecast_loops
3 #_First_forecast_loop_with_stochastic_recruitment
0 #_fcast_rec_option
1 #_fcast_rec_val
0 #_Fcast_MGparm_averaging
2025 #_FirstYear_for_caps_and_allocations
0 #_stddev_of_log_catch_ratio
0 #_Do_West_Coast_gfish_rebuilder_output
0 #_Ydecl
0 #_Yinit
1 #_fleet_relative_F
# Note that fleet allocation is used directly as average F if Do_Forecast=4 
2 #_basis_for_fcast_catch_tuning
# enter list of fleet number and max for fleets with max annual catch; terminate with fleet=-9999
-9999 -1
# enter list of area ID and max annual catch; terminate with area=-9999
-9999 -1
# enter list of fleet number and allocation group assignment, if any; terminate with fleet=-9999
-9999 -1
2 #_InputBasis
 #_Year Seas Fleet Catch or F
   2023    1     1          0
   2023    1     2          0
   2023    1     3          0
   2023    1     4          0
   2023    1     5          0
   2023    1     6          0
   2023    1     7          0
   2023    1     8          0
   2023    1     9          0
   2023    1    10          0
   2023    1    11          0
   2023    1    12          0
   2023    1    13          0
   2023    1    14          0
   2023    1    15          0
   2024    1     1          0
   2024    1     2          0
   2024    1     3          0
   2024    1     4          0
   2024    1     5          0
   2024    1     6          0
   2024    1     7          0
   2024    1     8          0
   2024    1     9          0
   2024    1    10          0
   2024    1    11          0
   2024    1    12          0
   2024    1    13          0
   2024    1    14          0
   2024    1    15          0
-9999 0 0 0
#
999 # verify end of input 
