#C file created using an r4ss function
#C file write time: 2025-07-14  08:57:00
#
1 #_benchmarks
2 #_MSY
0.5 #_SPRtarget
0.4 #_Btarget
#_Bmark_years: beg_bio, end_bio, beg_selex, end_selex, beg_relF, end_relF,  beg_recr_dist, end_recr_dist, beg_SRparm, end_SRparm (enter actual year, or values of 0 or -integer to be rel. endyr)
-999 0 0 0 0 0 -999 0 -999 0
1 #_Bmark_relF_Basis
1 #_Forecast
14 #_Nforecastyrs
1 #_F_scalar
#_Fcast_years:  beg_selex, end_selex, beg_relF, end_relF, beg_recruits, end_recruits (enter actual year, or values of 0 or -integer to be rel. endyr)
0 0 -3 0 -999 0
0 #_Fcast_selex
3 #_ControlRuleMethod
0.4 #_BforconstantF
0.1 #_BfornoF
-1 #_Flimitfraction
 #_year buffer
   2023  1.000
   2024  1.000
   2025  1.000
   2026  1.000
   2027  0.926
   2028  0.922
   2029  0.917
   2030  0.913
   2031  0.909
   2032  0.904
   2033  0.900
   2034  0.896
   2035  0.892
   2036  0.887
-9999 0
3 #_N_forecast_loops
3 #_First_forecast_loop_with_stochastic_recruitment
0 #_fcast_rec_option
1 #_fcast_rec_val
0 #_Fcast_loop_control_5
2037 #_FirstYear_for_caps_and_allocations
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
 #_year seas fleet catch_or_F
   2023    1     1      150.6
   2023    1     2      295.2
   2023    1     3       74.4
   2023    1     4       19.2
   2023    1     5       12.0
   2023    1     6        0.8
   2023    1     7       73.2
   2023    1     8       57.0
   2023    1     9       21.9
   2023    1    11        7.0
   2023    1    12       13.2
   2024    1     1      114.4
   2024    1     2      259.0
   2024    1     3       51.2
   2024    1     4       19.3
   2024    1     5       12.0
   2024    1     6        0.4
   2024    1     7       40.2
   2024    1     8       50.3
   2024    1     9       26.8
   2024    1    11        1.0
   2024    1    12        0.0
   2025    1     1       74.2
   2025    1     2      179.2
   2025    1     3       87.9
   2025    1     4       34.3
   2025    1     5       16.6
   2025    1     6        1.5
   2025    1     7       46.7
   2025    1     8       26.1
   2025    1     9       17.3
   2025    1    11       11.2
   2025    1    12        8.8
   2026    1     1       76.8
   2026    1     2      185.5
   2026    1     3       91.0
   2026    1     4       35.6
   2026    1     5       17.2
   2026    1     6        1.6
   2026    1     7       48.6
   2026    1     8       26.9
   2026    1     9       18.0
   2026    1    11       11.6
   2026    1    12        9.1
-9999 0 0 0
#
999 # verify end of input 
