#C forecast file written by R function SS_writeforecast
#C rerun model to get more complete formatting in forecast.ss_new
#C should work with SS version: 3.3
#C file write time: 2023-07-27 17:58:48
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
1 #_Flimitfraction
3 #_N_forecast_loops
3 #_First_forecast_loop_with_stochastic_recruitment
0 #_fcast_rec_option
1 #_fcast_rec_val
0 #_Fcast_MGparm_averaging
2035 #_FirstYear_for_caps_and_allocations
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
 #_#Year Seas Fleet dead(B)               comment
    2023    1     1  101.72 #sum_for_2023: 863.16
    2023    1     2  298.05                      
    2023    1     3  106.09                      
    2023    1     4   83.45                      
    2023    1     5   30.89                      
    2023    1     6    6.86                      
    2023    1     7   96.50                      
    2023    1     8   62.40                      
    2023    1     9   41.20                      
    2023    1    11   15.12                      
    2023    1    12   20.88                      
    2024    1     1  101.72 #sum_for_2024: 860.19
    2024    1     2  298.05                      
    2024    1     3  106.09                      
    2024    1     4   82.21                      
    2024    1     5   30.43                      
    2024    1     6    6.76                      
    2024    1     7   96.50                      
    2024    1     8   61.50                      
    2024    1     9   40.93                      
    2024    1    11   15.12                      
    2024    1    12   20.88                      
    2025    1     1   88.13 #sum_for_2025: 533.39
    2025    1     2  208.45                      
    2025    1     3   72.52                      
    2025    1     4   15.81                      
    2025    1     5   10.06                      
    2025    1     6    1.65                      
    2025    1     7   63.83                      
    2025    1     8   43.05                      
    2025    1     9   25.89                      
    2025    1    11    1.91                      
    2025    1    12    2.09                      
    2026    1     1   83.50 #sum_for_2026: 533.26
    2026    1     2  201.18                      
    2026    1     3   69.99                      
    2026    1     4   16.67                      
    2026    1     5   10.01                      
    2026    1     6    1.57                      
    2026    1     7   73.34                      
    2026    1     8   47.41                      
    2026    1     9   25.83                      
    2026    1    11    1.79                      
    2026    1    12    1.97                      
    2027    1     1   81.78 #sum_for_2027: 542.25
    2027    1     2  197.90                      
    2027    1     3   68.85                      
    2027    1     4   18.03                      
    2027    1     5   10.04                      
    2027    1     6    1.50                      
    2027    1     7   82.72                      
    2027    1     8   51.77                      
    2027    1     9   26.06                      
    2027    1    11    1.72                      
    2027    1    12    1.88                      
    2028    1     1   83.08 #sum_for_2028: 557.65
    2028    1     2  198.41                      
    2028    1     3   69.03                      
    2028    1     4   19.46                      
    2028    1     5   10.11                      
    2028    1     6    1.46                      
    2028    1     7   90.37                      
    2028    1     8   55.72                      
    2028    1     9   26.45                      
    2028    1    11    1.70                      
    2028    1    12    1.86                      
    2029    1     1   86.87 #sum_for_2029: 576.92
    2029    1     2  202.16                      
    2029    1     3   70.33                      
    2029    1     4   20.77                      
    2029    1     5   10.22                      
    2029    1     6    1.46                      
    2029    1     7   95.73                      
    2029    1     8   58.81                      
    2029    1     9   26.94                      
    2029    1    11    1.73                      
    2029    1    12    1.90                      
    2030    1     1   92.31 #sum_for_2030: 598.43
    2030    1     2  208.39                      
    2030    1     3   72.50                      
    2030    1     4   21.87                      
    2030    1     5   10.37                      
    2030    1     6    1.48                      
    2030    1     7   99.14                      
    2030    1     8   61.10                      
    2030    1     9   27.49                      
    2030    1    11    1.80                      
    2030    1    12    1.98                      
    2031    1     1   98.54 #sum_for_2031: 621.13
    2031    1     2  216.37                      
    2031    1     3   75.28                      
    2031    1     4   22.76                      
    2031    1     5   10.55                      
    2031    1     6    1.53                      
    2031    1     7  101.22                      
    2031    1     8   62.81                      
    2031    1     9   28.11                      
    2031    1    11    1.89                      
    2031    1    12    2.07                      
    2032    1     1  104.95 #sum_for_2032: 644.73
    2032    1     2  225.60                      
    2032    1     3   78.49                      
    2032    1     4   23.50                      
    2032    1     5   10.78                      
    2032    1     6    1.59                      
    2032    1     7  102.63                      
    2032    1     8   64.20                      
    2032    1     9   28.82                      
    2032    1    11    1.99                      
    2032    1    12    2.18                      
    2033    1     1  110.73 #sum_for_2033: 666.52
    2033    1     2  234.77                      
    2033    1     3   81.68                      
    2033    1     4   24.08                      
    2033    1     5   11.02                      
    2033    1     6    1.65                      
    2033    1     7  103.46                      
    2033    1     8   65.24                      
    2033    1     9   29.51                      
    2033    1    11    2.09                      
    2033    1    12    2.29                      
    2034    1     1  115.69 #sum_for_2034: 686.28
    2034    1     2  243.52                      
    2034    1     3   84.72                      
    2034    1     4   24.54                      
    2034    1     5   11.27                      
    2034    1     6    1.72                      
    2034    1     7  104.00                      
    2034    1     8   66.06                      
    2034    1     9   30.21                      
    2034    1    11    2.17                      
    2034    1    12    2.38                      
-9999 0 0 0
#
999 # verify end of input 
