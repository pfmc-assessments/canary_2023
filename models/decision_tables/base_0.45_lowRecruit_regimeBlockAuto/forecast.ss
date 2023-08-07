#C forecast file written by R function SS_writeforecast
#C rerun model to get more complete formatting in forecast.ss_new
#C should work with SS version: 3.3
#C file write time: 2023-08-04 17:12:06
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
    2025    1     1   94.39 #sum_for_2025: 571.28
    2025    1     2  223.25                      
    2025    1     3   77.67                      
    2025    1     4   16.94                      
    2025    1     5   10.78                      
    2025    1     6    1.76                      
    2025    1     7   68.36                      
    2025    1     8   46.11                      
    2025    1     9   27.73                      
    2025    1    11    2.05                      
    2025    1    12    2.24                      
    2026    1     1   89.62 #sum_for_2026: 572.52
    2026    1     2  216.01                      
    2026    1     3   75.15                      
    2026    1     4   17.90                      
    2026    1     5   10.75                      
    2026    1     6    1.68                      
    2026    1     7   78.74                      
    2026    1     8   50.89                      
    2026    1     9   27.74                      
    2026    1    11    1.93                      
    2026    1    12    2.11                      
    2027    1     1   87.95 #sum_for_2027: 583.53
    2027    1     2  212.97                      
    2027    1     3   74.09                      
    2027    1     4   19.39                      
    2027    1     5   10.81                      
    2027    1     6    1.62                      
    2027    1     7   89.05                      
    2027    1     8   55.72                      
    2027    1     9   28.06                      
    2027    1    11    1.85                      
    2027    1    12    2.02                      
    2028    1     1   89.51 #sum_for_2028: 601.48
    2028    1     2  213.99                      
    2028    1     3   74.45                      
    2028    1     4   20.98                      
    2028    1     5   10.91                      
    2028    1     6    1.58                      
    2028    1     7   97.57                      
    2028    1     8   60.12                      
    2028    1     9   28.54                      
    2028    1    11    1.83                      
    2028    1    12    2.00                      
    2029    1     1   93.66 #sum_for_2029: 623.09
    2029    1     2  218.25                      
    2029    1     3   75.93                      
    2029    1     4   22.43                      
    2029    1     5   11.05                      
    2029    1     6    1.58                      
    2029    1     7  103.57                      
    2029    1     8   63.59                      
    2029    1     9   29.11                      
    2029    1    11    1.87                      
    2029    1    12    2.05                      
    2030    1     1   99.73 #sum_for_2030: 647.91
    2030    1     2  225.46                      
    2030    1     3   78.44                      
    2030    1     4   23.68                      
    2030    1     5   11.24                      
    2030    1     6    1.60                      
    2030    1     7  107.62                      
    2030    1     8   66.26                      
    2030    1     9   29.79                      
    2030    1    11    1.95                      
    2030    1    12    2.14                      
    2031    1     1  106.69 #sum_for_2031: 674.18
    2031    1     2  234.61                      
    2031    1     3   81.62                      
    2031    1     4   24.72                      
    2031    1     5   11.47                      
    2031    1     6    1.66                      
    2031    1     7  110.26                      
    2031    1     8   68.32                      
    2031    1     9   30.53                      
    2031    1    11    2.05                      
    2031    1    12    2.25                      
    2032    1     1  113.62 #sum_for_2032: 699.95
    2032    1     2  244.60                      
    2032    1     3   85.10                      
    2032    1     4   25.54                      
    2032    1     5   11.72                      
    2032    1     6    1.72                      
    2032    1     7  111.93                      
    2032    1     8   69.90                      
    2032    1     9   31.30                      
    2032    1    11    2.16                      
    2032    1    12    2.36                      
    2033    1     1  120.20 #sum_for_2033: 725.65
    2033    1     2  255.18                      
    2033    1     3   88.78                      
    2033    1     4   26.26                      
    2033    1     5   12.01                      
    2033    1     6    1.80                      
    2033    1     7  113.25                      
    2033    1     8   71.27                      
    2033    1     9   32.15                      
    2033    1    11    2.27                      
    2033    1    12    2.48                      
    2034    1     1  125.95 #sum_for_2034: 749.33
    2034    1     2  265.39                      
    2034    1     3   92.33                      
    2034    1     4   26.84                      
    2034    1     5   12.31                      
    2034    1     6    1.87                      
    2034    1     7  114.27                      
    2034    1     8   72.42                      
    2034    1     9   32.99                      
    2034    1    11    2.37                      
    2034    1    12    2.59                      
-9999 0 0 0
#
999 # verify end of input 
