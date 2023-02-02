

####################
# Movement
# M = 0.1 # Proportion moving from an area to each other area
# Retain = 1-2M
# Param = log(M/(1-2*M))
####################

#########################
# NOTES
# 1. when estimating movement and time-varying recdist-devs, the area without recdist-devs will have the highest proportion of recruitment
# 2. 
#########################

#devtools::install_github('r4ss/r4ss')#, ref='v1.23.0')  #   
library( r4ss )

RootFile = "C:/Users/James.Thorson/Desktop/UW Hideaway/2015 -- Canary assessment/Bridging/"
source( paste0(RootFile,"Extract_Laplace_Results_Fn.R") )
source( paste0(RootFile,"SS_doRetro.R") )
source( paste0(RootFile,"Laplace_Approx_Fn.R") )
#source( paste0(RootFile,"PinerPlot_v3.R") )

# 2011 base case
  RunFile = paste0(RootFile,"1_2011_base/")
  RunFile = paste0(RootFile,"2_update_ss3.24u/")
  RunFile = paste0(RootFile,"3_update_strat-shelf-slope/")
  RunFile = paste0(RootFile,"4_triennial/")
  RunFile = paste0(RootFile,"5_geostat-shelf-slope/")
  RunFile = paste0(RootFile,"6_extend_recdevs/")
  RunFile = paste0(RootFile,"7_est_steepness/")
  RunFile = paste0(RootFile,"8_fix_steepness_2013prior/")
  RunFile = paste0(RootFile,"9_combined_triennial/")
  RunFile = paste0(RootFile,"10_Francis_weighting_A/")
  RunFile = paste0(RootFile,"11_Laplace_SigmaR/")
  RunFile = paste0(RootFile,"12_New_SigmaR/")
  RunFile = paste0(RootFile,"15_Update_OR_TWL_lengths/")
  RunFile = paste0(RootFile,"16_Update_WA_TWL_lengths/")
  RunFile = paste0(RootFile,"17_Update_ORWA_NONTWL_lengths/")
  RunFile = paste0(RootFile,"18_Update_Shelf-slope-lengths/")
  RunFile = paste0(RootFile,"19_Update_Shelf-slope-CAAL/")
  RunFile = paste0(RootFile,"20_Update_Triennial_Lengths/")
  RunFile = paste0(RootFile,"21_Update_OR_TWL_MAAL/")
  RunFile = paste0(RootFile,"22_Update_WA_TWL_MAAL/")
  RunFile = paste0(RootFile,"23_Update_ORWA_NONTWL_MAAL/")
  RunFile = paste0(RootFile,"24_Turn_off_ghost_fleets/")
  RunFile = paste0(RootFile,"25_Update_CA_TWL_lengths/")
  RunFile = paste0(RootFile,"26_Update_CA_NONTWL_lengths/")
  RunFile = paste0(RootFile,"27_Update_CA_TWL_MAAL/")
  RunFile = paste0(RootFile,"28_Update_CA_NONTWL_MAAL/")
  RunFile = paste0(RootFile,"29_Update_triennial_CAAL/")
  RunFile = paste0(RootFile,"30_Update_catches/")
  RunFile = paste0(RootFile,"31_extend_years/")
  RunFile = paste0(RootFile,"32_Update_CA_fleets_2011split_lengths_plus_extend_to_allyears/")
  RunFile = paste0(RootFile,"33_Update_CA_fleets_2011split_ages_plus_extend_to_allyears/")
  RunFile = paste0(RootFile,"34_Update_pre-recruit/")
  RunFile = paste0(RootFile,"35_Change_variance_inflation/")
  RunFile = paste0(RootFile,"36_Update_fleets/")
  RunFile = paste0(RootFile,"37_Turn_on_multiarea/")
  RunFile = paste0(RootFile,"38_Update_TWL_to_new_fleetstructure/")
  RunFile = paste0(RootFile,"39a_Update_AgeingError_CAPSunbiased/")
  RunFile = paste0(RootFile,"39b_Update_AgeingError_WDFWunbiased/")
  RunFile = paste0(RootFile,"40_Update_TWL_Surface_MAAL/")
  RunFile = paste0(RootFile,"41_Add_discards_placeholders/")
  RunFile = paste0(RootFile,"42_Update_TWL_Surface_MAAL_for_truncation/")
  RunFile = paste0(RootFile,"43_Update_maturity/")
  RunFile = paste0(RootFile,"44_Add_Discard_Comps/")
  RunFile = paste0(RootFile,"45_Remove_all_discard-stuff/")
  RunFile = paste0(RootFile,"46_Update_Rec_Length/")
  RunFile = paste0(RootFile,"47_Try_multiarea/")
  RunFile = paste0(RootFile,"48_Area_specific_recdevs/")
  RunFile = paste0(RootFile,"49_Area_specific_indices/")
  RunFile = paste0(RootFile,"50_Area_specific_survey_comps/")
  RunFile = paste0(RootFile,"51_Re-add_discards/")
  RunFile = paste0(RootFile,"52_Redo_biasadj/")
  RunFile = paste0(RootFile,"53_Add_ASHOP_comps/")
  RunFile = paste0(RootFile,"54_Re-add_discard_comps/")
  RunFile = paste0(RootFile,"54_Re-add_discard_comps/")
  RunFile = paste0(RootFile,"55_Add_discard_breakpoint/")  
  RunFile = paste0(RootFile,"56_Update_steepness/")  
  RunFile = paste0(RootFile,"56b_Increase_SigmaR=0.8/")  
  RunFile = paste0(RootFile,"56c_SigmaR_profile/")  
  RunFile = paste0(RootFile,"57_Explore_movement/")    
  RunFile = paste0(RootFile,"57b_Fix_movement=0.1/")    
  RunFile = paste0(RootFile,"57c_Fix_movement=0to0.1/")    
  RunFile = paste0(RootFile,"57d_Fix_WAtoOR_movement=0to0.1/")    
  RunFile = paste0(RootFile,"57e_Fix_WAtoOR_and_ORtoCA_movement=0to0.1/")    
  RunFile = paste0(RootFile,"57f_57e_plus_change_timing/")    
  RunFile = paste0(RootFile,"57g_57e_plus_change_order_of_distdevs/")    
  RunFile = paste0(RootFile,"57h_57e_but_turnoff_distdevs/")    
  RunFile = paste0(RootFile,"57i_57e_plus_turn_on_all_recdistdevs/")    
  RunFile = paste0(RootFile,"57j_57b_plus_turnoff_distdevs/")    
  RunFile = paste0(RootFile,"57k_57j_plus_movement=0.01/")    
  RunFile = paste0(RootFile,"57l_57k_plus_turnoff_nonadjacent_movement/")    
  RunFile = paste0(RootFile,"57m_57l_plus_fix_state_dist_70-20-10/")    
  RunFile = paste0(RootFile,"57n_57m_plus_estimate_adjacent_movement/")    
  RunFile = paste0(RootFile,"57o_57n_plus_estimate_distdevs/")    
  RunFile = paste0(RootFile,"57q_57p_plus_fixed_typo_in_partition_agedata/")    
  RunFile = paste0(RootFile,"57r_57q_plus_discard_partitions_ITQ/")    
  RunFile = paste0(RootFile,"57s_57r_plus_turnoff_recdists/")    
  RunFile = paste0(RootFile,"57t_57r_plus_turnoff_areas/")    
  RunFile = paste0(RootFile,"58_57s_plus_update_fecundity_and_condition/")    
  RunFile = paste0(RootFile,"59_58_plus_update_natural_mortality_fixed/")    
  RunFile = paste0(RootFile,"60_59_plus_update_steepness/")    
  RunFile = paste0(RootFile,"60_59_plus_update_steepness/")    
  RunFile = paste0(RootFile,"63_60_plus_update_condition_and_movement_ages/")    
  RunFile = paste0(RootFile,"64_63_plus_add_WArec_MAAL/")    
  RunFile = paste0(RootFile,"64b_64_plus_change_to_hybridF/")    
  RunFile = paste0(RootFile,"65_64_plus_normal-BH_SR_curve/")    
  RunFile = paste0(RootFile,"65a_65_plus_no_movement/")    
  RunFile = paste0(RootFile,"65b_65_plus_movement=0.001to0.01/")    
  RunFile = paste0(RootFile,"65c_65_plus_Francis_weights/")    
  RunFile = paste0(RootFile,"65d_65a_plus_Francis_weights/")    
  RunFile = paste0(RootFile,"65f_65_plus_nonspatial/")    
  RunFile = paste0(RootFile,"65g_65_plus_movement=0.0001/")    
  RunFile = paste0(RootFile,"65h_65d_plus_est_distdevs/")    
  RunFile = paste0(RootFile,"65i_65h_plus_fix_params_at_bounds/")    
  RunFile = paste0(RootFile,"65j_65i_plus_fix_params_at_bounds_num2_and_start_recdev_1933/")    
  RunFile = paste0(RootFile,"65k_65_plus_movement=0.002to0.02/")    
  RunFile = paste0(RootFile,"65o_65j_plus_change_to_early-late_recdevs/")    
  RunFile = paste0(RootFile,"66_65o_plus_update_TWL_discard_fraction/")    
  RunFile = paste0(RootFile,"67_65o_plus_Eliminate_Discards/")    
  RunFile = paste0(RootFile,"68_67_plus_add triennial_1980_comps/")    
  RunFile = paste0(RootFile,"68a_68_plus_estimate_movement/")    
  RunFile = paste0(RootFile,"68b_68_plus_estimate_steepness/")    
  RunFile = paste0(RootFile,"68c_68_plus_estimate_natural_mortality/")    
  RunFile = paste0(RootFile,"68d_68_plus_estimate_steepness_and_mortality/")    
  RunFile = paste0(RootFile,"68_best_from_jitter/")    
  RunFile = paste0(RootFile,"69_Update_to_ss3-2.24V/")    
  RunFile = paste0(RootFile,"71_jitter=0.5/")    
  RunFile = paste0(RootFile,"71_70_plus_final_TWL_NONTWL_comps/")    
  RunFile = paste0(RootFile,"72_Update_CatchTable/")    
  RunFile = paste0(RootFile,"72_Laplace_SigmaR/")    
  RunFile = paste0(RootFile,"72_Laplace_SigmaDistDev/")    
  RunFile = paste0(RootFile,"72a_72_Estimate_single_movement/")    
  RunFile = paste0(RootFile,"73_Update_Francis_Weights/")    
  RunFile = paste0(RootFile,"73a_73_plus_turn_off_distdevs/")    
  RunFile = paste0(RootFile,"73b_73_plus_nonspatial/")    
  RunFile = paste0(RootFile,"73d_73_plus_selex_breakpoint_1999/")    
  RunFile = paste0(RootFile,"73f_73d_plus_selex_breakpoint_1999_unfix_selex/")    
  RunFile = paste0(RootFile,"73e_73_plus_selex_breakpoint_1999_and_2011/")    
  RunFile = paste0(RootFile,"73g_73e_plus_selex_breakpoint_1999_and_2011_unfix_selex/")    
  RunFile = paste0(RootFile,"73h_73_plus_unmirror_selex/")    
  RunFile = paste0(RootFile,"73i_73g_plus_selex_breakpoint_2002_and_2011_unfix_selex/")    
  RunFile = paste0(RootFile,"73j_73g_plus_selex_breakpoint_2000_and_2011_unfix_selex/")    
  RunFile = paste0(RootFile,"74_73j_plus_Francis_reweighting_plus_biasramp/")    
  RunFile = paste0(RootFile,"75_74_plus_fix_more_selex_params/")    
  RunFile = paste0(RootFile,"75a_75_plus_survey_MAAL/")    
  RunFile = paste0(RootFile,"75b_75a_plus_update_ASHOP_MAAL_and_unfix_selex/")    
  RunFile = paste0(RootFile,"75e_75b_plus_half_emphasis_MAAL_ML/")    
  RunFile = paste0(RootFile,"76_75b_plus_calculate_emphasis_MAAL_ML/")    
  RunFile = paste0(RootFile,"75f_75b_plus_calculate_emphasis_MAAL_ML/")    
  RunFile = paste0(RootFile,"76_75f_plus_turnoff_CA_distdevs/")    
  RunFile = paste0(RootFile,"76c_76_plus_turnoff_distdevs/")    
  RunFile = paste0(RootFile,"76d_76_plus_nonspatial/")    
  RunFile = paste0(RootFile,"77_76_plus_update_forecast/")    
  RunFile = paste0(RootFile,"78_77_plus_change_blocks_NONTWL_REC/")    
  RunFile = paste0(RootFile,"79_78_plus_turnoff_REC_blocks/")    
  RunFile = paste0(RootFile,"79a_79_plus_fleet_specific_Francis_weights/")    
  RunFile = paste0(RootFile,"80_79_plus_fix_WDFW_ageing_error_bug/")    
  RunFile = paste0(RootFile,"80_79_plus_fix_WDFW_ageing_error_bug_with_higher_maxF/")    
  RunFile = paste0(RootFile,"80_phase_plot_figure/")    
  RunFile = paste0(RootFile,"80j_80_plus_turnoff_adult_M_offset/")    
  RunFile = paste0(RootFile,"80k_80_plus_turnoff_adult_M_offset_and_estimate_male_offset/")    
  RunFile = paste0(RootFile,"80_low_M/")    
  RunFile = paste0(RootFile,"80p_80_plus_turnon_comp_aggregator/")    
  RunFile = paste0(RootFile,"80v_fix_selex+growth_and_remove_comps/")    
  RunFile = paste0(RootFile,"80w_80v+add_back_TWL_comps_and_selex/")    
  RunFile = paste0(RootFile,"80_base_fix_selex_to_avoid_squirrels/")    
  RunFile = paste0(RootFile,"80_base_fix_selex_to_avoid_squirrels_num2/")    
  RunFile = paste0(RootFile,"80ab_80_plus_state-specific_stratified_WCGBTS/")    
  RunFile = paste0(RootFile,"80ac_80_plus-state-specific_stratified_triennial/")    
  RunFile = paste0(RootFile,"80ad_80_zero_discard_rate/")    
  RunFile = paste0(RootFile,"80ae_80_twentypercent_discard_rate/")    

  #RunFile = paste0(RootFile,"81_80_plus_change_marginals_to_gender=0or3/")    
  #RunFile = paste0(RootFile,"81j_81_plus_turnoff_adult_M_offset/")    
  #RunFile = paste0(RootFile,"81k_81_plus_turnoff_adult_M_offset_and_estimate_male_offset/")    
  #RunFile = paste0(RootFile,"82_81k_plus_TWL_male_selex_offset/")    
  #RunFile = paste0(RootFile,"82m_82_plus_block_2000_2010_male_selex_offset/")    
  #RunFile = paste0(RootFile,"82n_82_plus_block_2000_male_selex_offset/")    
  #RunFile = paste0(RootFile,"82o_82_plus_mortality_ramp/")    
  #RunFile = paste0(RootFile,"83_82_plus_reweight_and_new_SigmaR_and_biasramp/")    
  #RunFile = paste0(RootFile,"83a_83_plus_simplify_male_selex_offset/")    
  #RunFile = paste0(RootFile,"83a_test_lowM/")    
  RunFile = paste0(RootFile,"82p_82o_plus_simply_male_selex_offset/")    
  RunFile = paste0(RootFile,"84_82p_plus_reweight/")    
  RunFile = paste0(RootFile,"84_jitter_winner/")    
  RunFile = paste0(RootFile,"85_84_plus_block_male_selex_offset_2000/")    
  RunFile = paste0(RootFile,"85_high_M/")    
  RunFile = paste0(RootFile,"85_low_h/")    
  RunFile = paste0(RootFile,"85_low_M/")    
  RunFile = paste0(RootFile,"85_jitter_winner/")    

  RunFile = paste0(RootFile,"87_80_plus_add_discardrate_stairstep/")    
  RunFile = paste0(RootFile,"88_87_plus_update_WA_trawl/")    
  RunFile = paste0(RootFile,"89_88_plus_update_OR_rec/")    
  RunFile = paste0(RootFile,"90_87_plus_using_catchv6preferred/")    
  RunFile = paste0(RootFile,"90_retrospectives/")    
  RunFile = paste0(RootFile,"90a_90_plus_using_catchv6alternate/")    
  RunFile = paste0(RootFile,"90b_90_plus_using_catchv6preferredforeign/")    
  RunFile = paste0(RootFile,"90c_90_plus_using_catchv6preferredbc/")    
  RunFile = paste0(RootFile,"90d_90_nodistdevs/")    
  RunFile = paste0(RootFile,"90e_90_nonspatial/")    
  RunFile = paste0(RootFile,"90h_90g+add_back_TWL_comps_and_selex/")    
  RunFile = paste0(RootFile,"90j_90g+fix_survey_lnQ_and_startfrom_90i/")    
  RunFile = paste0(RootFile,"90k_90h+remove_indices/")    
  RunFile = paste0(RootFile,"90l_90+SigmaR=1.2/")    
  RunFile = paste0(RootFile,"90m_90+SigmaR=0.9/")    
  RunFile = paste0(RootFile,"90n_90_plus_remove_indices/")    
  RunFile = paste0(RootFile,"90o_90_increase_LAA_CV/")    
  RunFile = paste0(RootFile,"90q_90_plus_downweight_CAAL_10fold/")    
  RunFile = paste0(RootFile,"90r_90q_plus_SigmaR=0.9/")    

  RunFile = paste0(RootFile,"91_90_plus_fix_WCGBTS_length_by_state/")    
  

 
# Read in stuff
#RunFile = paste0(RootFile,"81l_explore_param_inputs/")    
SsOutput = Covar = TRUE
  SsOutput = SS_output(RunFile, covar=Covar, forecast=TRUE, printstats=TRUE, ncols=210)
# Plot for inspection
# 1: bio
# 2: selex
# 3: timeseries
# 4-5: recdevs
# 7: catch
# 8: SPR
# 11: index
# 16: length comps
# 17: age comps
# 22: yield
# 23: movement
# 24 data range                    # 
  # PDF -- all 
  Plots = SS_plots(SsOutput, png=FALSE, pdf=TRUE, uncertainty=Covar, aalresids=TRUE, datplot=FALSE, areanames=c("CA","OR","WA"), multifig_colpolygon=c( rgb(1,0,0,0.5), rgb(0,0,1,0.5), rgb(0,1,0,0.5)), multifig_oma=c(5,5,1,2)+.1, linescol=c("green", "red", "blue"), andre_oma=c(3,0,0.5,0) ) #aalyear, aalbin
  # All 
  Plots = SS_plots(SsOutput, png=TRUE, printfolder="Plots_Default", uncertainty=Covar, aalresids=TRUE, datplot=TRUE, areanames=c("CA","OR","WA"), multifig_colpolygon=c( rgb(1,0,0,0.5), rgb(0,0,1,0.5), rgb(0,1,0,0.5)), multifig_oma=c(5,5,1,2)+.1, linescol=c("green", "red", "blue"), andre_oma=c(3,0,0.5,0) ) #aalyear, aalbin
  # Yield
  Plots = SS_plots(SsOutput, plot=c(22), png=TRUE, printfolder="Plots_yield", uncertainty=Covar, aalresids=TRUE, datplot=TRUE, areanames=c("CA","OR","WA"), pwidth=6.5, pheight=6.0) #aalyear, aalbin
  SSplotYield( SsOutput, plot=TRUE, print=TRUE, plotdir="Plots_yield")
  # Catch
  Plots = SS_plots(SsOutput, plot=c(7), png=TRUE, printfolder="Plots_catch", uncertainty=Covar, aalresids=TRUE, datplot=TRUE, areanames=c("CA","OR","WA"), pwidth=6.5, pheight=6.0) #aalyear, aalbin
  # Selex
  Plots = SS_plots(SsOutput, plot=c(2), png=TRUE, printfolder="Plots_selex", uncertainty=Covar, aalresids=TRUE, datplot=TRUE, areanames=c("CA","OR","WA"), pwidth=6.5, pheight=13) #aalyear, aalbin
  # Data availability illustration
  for(i in 1:2) dir.create( paste0(RunFile,c("Plots_data_part1","Plots_data_part2"))[i] )
  SSplotData(SsOutput, plot=TRUE, print=TRUE, datatypes=c("catch","cpue"), plotdir="Plots_data_part1", fleets=1:27, margins=c(5.1,2.1,0.2,8.1), pwidth=6.5, pheight=7.5, cex.main=1e-20) #aalyear, aalbin
  SSplotData(SsOutput, plot=TRUE, print=TRUE, datatypes=c("lendbase","agedbase","condbase"), plotdir="Plots_data_part2", fleets=1:27, margins=c(5.1,2.1,0.2,8.1), pwidth=6.5, pheight=7.5, cex.main=1e-20) #aalyear, aalbin
  # Comps
  #par( oma=c(0,0,0,0) )
  Plots = SS_plots(SsOutput, plot=c(16,17,18,19), png=TRUE, printfolder="Plots_Tall", uncertainty=Covar, aalresids=TRUE, datplot=FALSE, areanames=c("CA","OR","WA"), pwidth=6.5, pheight=8, maxrows=6, maxcols=4, maxrows2=2, maxcols2=4, andrerows=6, cex.main=1e-20, comp.yupper=0.4, multifig_colpolygon=c( rgb(1,0,0,0.5), rgb(0,0,1,0.5), rgb(0,1,0,0.5)), multifig_oma=c(5,5,1,2)+.1, linescol=c("green", "red", "blue"), andre_oma=c(3,0,0.5,0), showeffN=FALSE ) #aalyear, aalbin
  # Time series
  #par( mar=c(0,0,0,0) )
  Plots = SS_plots(SsOutput, plot=c(3), png=TRUE, printfolder="Plots_Narrow", uncertainty=Covar, aalresids=TRUE, datplot=FALSE, areanames=c("CA","OR","WA"), pwidth=6.5, pheight=4.5, maxrows=6, maxcols=4, maxrows2=2, maxcols2=4, andrerows=6, cex.main=1e-20) #aalyear, aalbin
  #      add=FALSE;areas="all";
  #           areacols="default";areanames="default";
  #           forecastplot=TRUE;uncertainty=TRUE;bioscale="default";
  #           minyr=NULL;maxyr=NULL;
  #           plot=TRUE;print=FALSE;plotdir="default";verbose=TRUE;
  #           btarg="default";minbthresh="default";xlab="Year";
  #           labels=NULL;
  #           pwidth=6.5;pheight=5.0;punits="in";res=300;ptsize=10;cex.main=1
  #     replist=SsOutput; subplot=10; plot=TRUE; plotdir=paste0(RunFile,"Plots_Narrow/"); print=TRUE; areanames=c("CA","OR","WA"); pwidth=6.5; pheight=4.5; forecastplot=FALSE
  SSplotTimeseries( SsOutput, subplot=10, plot=TRUE, plotdir=paste0(RunFile,"Plots_Narrow/"), print=TRUE, areanames=c("CA","OR","WA"), pwidth=6.5, pheight=4.5, forecastplot=FALSE)
  # Indices
  setwd( RunFile ) #par( mar=c(0,0,0,0) )
  SSplotIndices(SsOutput, print=TRUE, plot=FALSE, add=FALSE, addmain=FALSE, plotdir="Plots_Narrow", pwidth=6.5, pheight=3.5, maximum_ymax_ratio=3) #aalyear, aalbin

# Explore time series estimates
iarea = 2
spawnseas = 1
endyr = 2015
Dep = SsOutput$timeseries$SpawnBio[SsOutput$timeseries$Area==iarea & SsOutput$timeseries$Yr<=endyr]/(SsOutput$timeseries$SpawnBio[SsOutput$timeseries$Area==iarea & SsOutput$timeseries$Seas == spawnseas][1])
Dep

# Fit bias-ramp
SS_fitbiasramp(SsOutput, altmethod="psoptim", print=TRUE, plotdir=RunFile, pwidth=7, pheight=7, punits="in", ptsize=12, res=300, cex.main=1, twoplots=FALSE)

# Explore parameter estimates
ParTable = SsOutput[["estimated_non_rec_devparameters"]][,c('Value','Min','Max','Init','Status','Prior','Afterbound')]
ParTable[which(ParTable[,'Afterbound']=="CHECK"),]
ParTable[which(ParTable[,'Status']%in%c("LO","HI")),]

# Selectivity estimates
ParTable[grep("SizeSel_",rownames(ParTable)),]

# Explore parameter estimates
Params = SsOutput[["parameters"]][,c('Value','Active_Cnt')]

# Explore likelihood components
SsOutput[["likelihoods_used"]]
SsOutput[["likelihoods_by_fleet"]] # SsOutput[["likelihoods_raw_by_fleet"]]
sum(SsOutput[["likelihoods_by_fleet"]][1,-c(1:2)]*SsOutput[["likelihoods_by_fleet"]][2,-c(1:2)]) 

# Biological parameters
SsOutput$wtatage[c(2,4),] # Weight

# Get hessian
HESS <- getADMBHessian(File=RunFile, FileName="admodel.hes")
cov <- corpcor::pseudoinverse(HESS$hes)
scale <- HESS$scale
cov.bounded <- cov*(scale %o% scale)
#se <- sqrt(diag(cov.bounded))
#cor <- cov.bounded/(se %o% se)
H <-  corpcor::pseudoinverse(cov.bounded)

# Conventional SigmaR and SigmaDistDev formulae
Param = SsOutput$parameters
# SigmaR
RecDev = Param[grep("RecrDev",Param$Label),]
sqrt( var(RecDev[,'Value']) + mean(RecDev[,'Parm_StDev']^2) )
# DistDev
DistDev = Param[grep("RecrDist_Area",Param$Label),]
sqrt( var(DistDev[,'Value']) + mean(DistDev[,'Parm_StDev']^2,na.rm=TRUE) )

# Read ParmTrace to diagnose any crashes (for param-trace in STARTER = 4)
  # Includes 9 extra values each row
#RunFile = "C:/Users/James.Thorson/Desktop/UW Hideaway/2015 -- Canary assessment/Bridging/76_retrospectives/retrospectives/retro-2/" 
Trace = scan( paste0(RunFile,"ParmTrace.sso"), what="character" )
Ncol = sum(is.na(as.numeric(Trace)[1:1000]))
Trace = matrix( as.numeric(Trace[-c(1:Ncol)]), ncol=Ncol, byrow=TRUE, dimnames=list(NULL,Trace[1:Ncol]))
# Diagnose problem
FirstNA = (1:nrow(Trace))[which(rowSums(is.na(Trace))>0)][1]
which( is.na(Trace[FirstNA,]) )
t(Trace[FirstNA+c(-3:2),])

# Explore parameter estimates
SsOutput = SS_output(RunFile, covar=FALSE, forecast=FALSE, printstats=TRUE, ncols=400)
  ParTable = SsOutput[["parameters"]]
  ParTable = ParTable[which(!is.na(ParTable[,'Active_Cnt'])),c('Min','Max')]
  cbind( ParTable,t(Trace[FirstNA+c(-2:1),-c(1:9)]))

# Read Laplace approx
RunFile = paste0(RootFile,"78b_78_plus_turnoff_distdevs/")    
  Laplace_Approx_Fn( File=RunFile )
RunFile = paste0(RootFile,"78c_78_plus_nonspatial/")    
  Laplace_Approx_Fn( File=RunFile )
RunFile = paste0(RootFile,"73_Update_Francis_Weights/")    
  Laplace_Approx_Fn( File=RunFile, num_long=length(13:258), SD_long=0.5 )

# DEBUGGING
RunFile = paste0(RootFile,"80_base_fix_selex_to_avoid_squirrels_num3/")    
  SsOutput_0 = SS_output(RunFile, covar=FALSE, forecast=FALSE, printstats=TRUE, ncols=210)
RunFile = paste0(RootFile,"80_base_fix_selex_to_avoid_squirrels_num3_not_start_from_par/")    
  SsOutput_1 = SS_output(RunFile, covar=FALSE, forecast=FALSE, printstats=TRUE, ncols=210)

SsOutput_0[["parameters"]][,c('Value','Init','Min','Max')]
SsOutput_1[["likelihoods_used"]]
SsOutput_1[["likelihoods_by_fleet"]] # SsOutput[["likelihoods_raw_by_fleet"]]
round(SsOutput_0[["parameters"]][,c('Value','Init','Min','Max')], 5)

# Read MCMC myself
RunFile = paste0(RootFile,"90_mcmc/")
Param <- read.table(paste(RunFile,"posteriors.sso",sep=""),header=TRUE)
  Which = which.min(Param[,'Objective_function'])
  Param[Which,'Objective_function']
write.table( Param[Which,3:ncol(Param)], file=paste0(RunFile,"_New_par.txt"), row.names=FALSE, col.names=FALSE)
#for(i in 4:nrow(Param)) Param[Which,'Objective_function']
  

####################
# 
# Tables for document for base case model
#
####################

# Table b
DQ = SsOutput[["derived_quants"]]
Table1 = cbind("SPB"=DQ[match(paste0("SPB_",2006:2015),DQ[,1]),], "Bratio"=DQ[match(paste0("Bratio_",2006:2015),DQ[,1]),])
Table1 = data.frame("SPB"=round(Table1[,2],0), "SPB_CI"=paste0(round(Table1[,2]-1.96*Table1[,3],0),"-",round(Table1[,2]+1.96*Table1[,3],0)), "Depl"=paste0(round(100*Table1[,5],1),"%"), "Depl_CI"=paste0(round(100*Table1[,5]-100*1.96*Table1[,6],1),"-",round(100*Table1[,5]+100*1.96*Table1[,6],1),"%"))
write.csv( Table1, file=paste0(RunFile,"_Table_b.csv"))

# Final likelihood
write.csv( SsOutput[["likelihoods_used"]], file=paste0(RunFile,"_Likelihoods_used.csv"), row.names=TRUE)
Tmp = SsOutput[["likelihoods_by_fleet"]][c(2,4,6),]
  Tmp[,-c(1:2)] = Tmp[,-c(1:2)] * SsOutput[["likelihoods_by_fleet"]][c(1,3,5),-c(1,2)]
  Tmp = t(Tmp[,-1])
  colnames(Tmp) = SsOutput[["likelihoods_by_fleet"]][c(2,4,6),'Label']
write.csv( Tmp, file=paste0(RunFile,"_Likelihoods_by_fleet.csv"), row.names=TRUE) # SsOutput[["likelihoods_raw_by_fleet"]]

# Catchability estimates
write.csv( SsOutput$index_variance_tuning_check[,c('Fleet','Q')], file=paste0(RunFile,"_Catchability.csv"), row.names=FALSE)

# Time series estimates (by area!)
TS_table = SsOutput$timeseries[,c('Yr','Bio_all','Bio_smry','SpawnBio','Recruit_0')]
TS_table = cbind( TS_table, 'Hrate'=rowSums( SsOutput$timeseries[,paste0('Hrate:_',1:24)] ) )
write.csv( TS_table, file=paste0(RunFile,"_TS_table.csv"), row.names=FALSE)

# Derived quantities
DQ = SsOutput$derived_quants                                                                                                                                                                                                                                                   
DQ_table = cbind( "Year"=1893:2014, "Bratio"=DQ[match(paste0("Bratio_",1893:2014),DQ[,'LABEL']),c('Value','StdDev')], "SPRratio"=DQ[match(paste0("SPRratio_",1893:2014),DQ[,'LABEL']),c('Value','StdDev')], "F"=DQ[match(paste0("F_",1893:2014),DQ[,'LABEL']),c('Value','StdDev')], "Recr"=DQ[match(paste0("Recr_",1893:2014),DQ[,'LABEL']),c('Value','StdDev')], "SPB"=DQ[match(paste0("SPB_",1893:2014),DQ[,'LABEL']),c('Value','StdDev')] )
write.csv( DQ_table, file=paste0(RunFile,"_DQ_table.csv"), row.names=FALSE)

########################
# Data weighting
########################

########## Francis method by group or by fleet ############
MatrixGrouped = MatrixFleets = matrix(1, nrow=2, ncol=31)
for(i in 1:24){
  # Lengths
  RowNum = which( SsOutput$Length_comp_Eff_N_tuning_check[,'Fleet']==i )
  FrancisLengthGrouped = SSMethod.TA1.8(SsOutput,fleet=1:3+3*floor((i-1)/3), type="len", plotit=FALSE)
  if( !is.null(FrancisLengthGrouped) ) MatrixGrouped[1,i] = SsOutput$Length_comp_Eff_N_tuning_check[RowNum,'Var_Adj'] * FrancisLengthGrouped['w']
  FrancisLengthFleets = SSMethod.TA1.8(SsOutput,fleet=i, type="len", plotit=FALSE)
  if( !is.null(FrancisLengthFleets) ) MatrixFleets[1,i] = SsOutput$Length_comp_Eff_N_tuning_check[RowNum,'Var_Adj'] * FrancisLengthFleets['w']
  # Ages
  RowNum = which( SsOutput$Age_comp_Eff_N_tuning_check[,'Fleet']==i )
  FrancisCAALGrouped = SSMethod.TA1.8(SsOutput,fleet=1:3+3*floor((i-1)/3), type="con", plotit=FALSE)
  if( !is.null(FrancisCAALGrouped) & length(RowNum)>0 ){
    MatrixGrouped[2,i] = SsOutput$Age_comp_Eff_N_tuning_check[RowNum,'Var_Adj'] * FrancisCAALGrouped['w']
  }else{
    FrancisMAALGrouped = SSMethod.TA1.8(SsOutput,fleet=1:3+3*floor((i-1)/3), type="age", plotit=FALSE)
    if( !is.null(FrancisMAALGrouped) & length(RowNum)>0 ) MatrixGrouped[2,i] = SsOutput$Age_comp_Eff_N_tuning_check[RowNum,'Var_Adj'] * FrancisMAALGrouped['w']
  }
  FrancisCAALFleets = SSMethod.TA1.8(SsOutput,fleet=i, type="con", plotit=FALSE)
  if( !is.null(FrancisCAALFleets) & length(RowNum)>0 ){
    MatrixFleets[2,i] = SsOutput$Age_comp_Eff_N_tuning_check[RowNum,'Var_Adj'] * FrancisCAALFleets['w']
  }else{
    FrancisMAALFleets = SSMethod.TA1.8(SsOutput,fleet=i, type="age", plotit=FALSE)
    if( !is.null(FrancisMAALFleets) & length(RowNum)>0 ) MatrixFleets[2,i] = SsOutput$Age_comp_Eff_N_tuning_check[RowNum,'Var_Adj'] * FrancisMAALFleets['w']
  }
}
# Cap weights at 1.0
MatrixGrouped[1:2,] = ifelse( MatrixGrouped[1:2,]>1, 1, MatrixGrouped[1:2,] )
MatrixFleets[1:2,] = ifelse( MatrixFleets[1:2,]>1, 1, MatrixFleets[1:2,] )
# Downweight Rec ages
MatrixGrouped[2,7:9] = ifelse( MatrixGrouped[2,7:9]>0.1, 0.1, MatrixGrouped[2,7:9])
MatrixFleets[2,7:9] = ifelse( MatrixFleets[2,7:9]>0.1, 0.1, MatrixFleets[2,7:9])
# Supplement and format
MatrixGrouped = rbind( matrix(0,nrow=3,ncol=ncol(MatrixGrouped)), MatrixGrouped, matrix(1,nrow=1,ncol=ncol(MatrixGrouped)) )
MatrixFleets = rbind( matrix(0,nrow=3,ncol=ncol(MatrixFleets)), MatrixFleets, matrix(1,nrow=1,ncol=ncol(MatrixFleets)) )
# Write to file
write.csv( formatC(MatrixGrouped,format="f",digits=3), file=paste0(RunFile,"_NewFrancisWeights_Grouped.csv"), row.names=FALSE)
write.csv( formatC(MatrixFleets,format="f",digits=3), file=paste0(RunFile,"_NewFrancisWeights_Fleets.csv"), row.names=FALSE)

############ unweighted ##############
Matrix = rbind( matrix(0, ncol=31, nrow=3), matrix(1, ncol=31, nrow=3))
write.csv( formatC(Matrix,format="f",digits=3), file=paste0(RunFile,"_Unweighted.csv"), row.names=FALSE)

############ Harmonic mean ##############
Matrix = rbind( matrix(0, ncol=31, nrow=3), matrix(1, ncol=31, nrow=3))
# Length
Match = match( SsOutput$Length_comp_Eff_N_tuning_check[,'Fleet'], 1:31)
Matrix[4,Match] = SsOutput$Length_comp_Eff_N_tuning_check[,'HarEffN/MeanInputN'] * SsOutput$Length_comp_Eff_N_tuning_check[,'Var_Adj'] 
Matrix[4,] = ifelse( Matrix[4,]>1, 1, Matrix[4,]) 
# Age
Match = match( SsOutput$Age_comp_Eff_N_tuning_check[,'Fleet'], 1:31)
Matrix[5,Match] = SsOutput$Age_comp_Eff_N_tuning_check[,'HarEffN/MeanInputN'] * SsOutput$Age_comp_Eff_N_tuning_check[,'Var_Adj']
Matrix[5,] = ifelse( Matrix[5,]>1, 1, Matrix[5,]) 
# Write to file
write.csv( formatC(Matrix,format="f",digits=3), file=paste0(RunFile,"_HarmonicMean_Weighting.csv"), row.names=FALSE)

####################
# Do Jitter
#
# STEPS
# 1. Change starter file to have jitter value > 0
# 2. Increase crash penalty
# 3. Make sure dist-devs are turned off for CA (having them on leads to increased rate of non-convergence)
#
# POTENTIAL TRICKS
# 1. Turn on soft boundaries in STARTER file BUT this might cause problems where converged models differ slightly
#
# FAILED TRICKS
# A. Start in phase 5 so it doesn't use weird rec-devs and dist-devs for many phases
# B. Bring in bounds for rev-devs and dist-devs to -4 to 4
# C. Bring average dist. params to have bounds -2 to +2
#
# PREVIOUS OBSERVATIONS
# * Sometimes crashes when Male offset hit bounds
# * dist-devs are not jittered (and start at 0)
#
####################

RunFile = paste0(RootFile,"90_jitter=0.10/")    
Njitter = 50
  
SS_RunJitter(mydir=RunFile, model="ss3", Njitter=Njitter, Intern=FALSE, extras="-nohess -cbs 500000000 -gbs 500000000")

# Read in results
jittermodels <- SSgetoutput(dirvec=RunFile, keyvec=1:Njitter, getcovar=FALSE)
# Remove any that didn't converge
( Nonconverged = which( sapply(jittermodels, length)==1 ) )
if( length(Nonconverged)>=1 ){
  jittermodels0 = jittermodels
  jittermodels = jittermodels[-Nonconverged]
}
# summarize output
jittersummary <- SSsummarize(jittermodels)
# Parameters
  #jittersummary$pars
# Likelihoods
jittersummary$likelihoods[1,]

# Write to file
Set = as.numeric(jittersummary$likelihoods[1,1:length(jittermodels)])
Set = ifelse( is.na(Set), Inf, Set)
capture.output( table(Set), file=paste(RunFile,"_Jitter_summary.txt",sep="") )
write.csv( t(table(Set)), file=paste(RunFile,"_Jitter_summary.csv",sep=""), row.names=FALSE )

####################
#
# Compare multiple runs
#
####################

# Plot several at once
RunI = 2
for(RunI in c(10) ){
  RunSet = c("Spatial", "Decision_table--h", "Decision_table--M", "Data_weighting", "Steepness_historical", "M_historical", "Ageing_error", "M_offset", "WCGBTS_index", "Exclude_comps", "Alternative_catch", "SigmaR_sensitivity")[RunI]
  LegendLoc = switch( RunSet, "Spatial"="topright", "Decision_table--h"="topright", "Decision_table--M"="topright", "Data_weighting"="topright", "Steepness_historical"="topright", "M_historical"="topright", "Ageing_error"="topright", "M_offset"="topright", "WCGBTS_index"="topright", "Exclude_comps"="bottomleft", "Alternative_catch"="topright", "SigmaR_sensitivity"="topright")
  
  if(RunSet=="Spatial"){
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91d_91_nodistdevs", "91e_91_nonspatial", "91v_91_plus_no_selex_blocks")
    File_Names = c("Base", "No dist-devs", "Nonspatial", "No selex blocks")
    Covar = TRUE
  }
  if(RunSet=="Decision_table--h"){
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91_h=0.600", "91_h=0.946")    # , "80_low_M", "80_high_M"
    File_Names = c("Base", "Base w/ low h", "Base w/ high h")                        # , "Base w/ low M", "Base w/ high M"
    Covar = TRUE
  }
  if(RunSet=="Decision_table--M"){
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91_M=0.025", "91_M=0.060")    # , "80_low_M", "80_high_M"
    File_Names = c("Base", "Base w/ low M", "Base w/ high M")                        # , "Base w/ low M", "Base w/ high M"
    Covar = TRUE
  }
  if(RunSet=="Data_weighting"){
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91t_91_Harmonic_Mean_Weighting", "91s_91_Unweighted", "91u_91_plus_fleet_specific_Francis_weights")
    File_Names = c("Base", "Harmonic mean", "Unweighted", "Francis by fleet")
    Covar = TRUE
  }
  if(RunSet=="Steepness_historical"){
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91ad_91_plus_2011_steepness", "1_2011_base", "1b_1_plus_2015_steepness")
    File_Names = c("Base", "Base w/ 2011 h", "2011 update", "2011 update w/ 2015 h")
    Covar = TRUE
  }
  if(RunSet=="M_historical"){   
    #File_Set = c("80_79_plus_fix_WDFW_ageing_error_bug", "80_high_M", "80f_plus_2011_steepness", "1_2011_base", "1b_1_plus_2015_steepness", "1a_1_plus_high_M")
    #File_Names = c("Base", "Base w/ high M", "Base w/ 2011 h", "2011 update", "2011 update w/ 2015 h", "2011 update w/ high M")
    File_Set = c("80_79_plus_fix_WDFW_ageing_error_bug", "80_high_M", "1_2011_base", "1a_1_plus_high_M")
    File_Names = c("2015", "2015 w/ high M", "2011 update", "2011 update w/ high M")
    Covar = FALSE   # 2011 with high M does not converge!
  }
  if(RunSet=="Ageing_error"){   #7
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91ab_WDFW_unbiased", "91ac_no_surface_reads")
    File_Names = c("Base", "WDFW_unbiased", "Base + No surface-reads")
    Covar = TRUE
  }
  if(RunSet=="M_offset"){
    File_Set = c("90_87_plus_using_catchv6preferred", "90w_90_plus_no_Mramp", "90x_90_trawl_male_offset", "90y_90_no_Mramp_trawl_male_offset")
    File_Names = c("Base", "Base: no M-ramp", "Base: male TWL offset", "Base: no M-ramp + male TWL offset")
    Covar = FALSE
  }
  if(RunSet=="WCGBTS_index"){
    File_Set = c("91_90_plus_fix_WCGBTS_length_by_state", "91z_91_plus_WCGTBS_stratified", "91aa_91_plus_exclude_WCGBTS_index")
    File_Names = c("Base", "Base: stratified WCGBTS index", "Base: no WCGBTS index")
    Covar = TRUE
  }
  if(RunSet=="Exclude_comps"){   # 10
    #File_Set = c("80_79_plus_fix_WDFW_ageing_error_bug", "80v_fix_selex+growth_and_remove_comps", "80w_80v+add_back_TWL_comps_and_selex", "80z_80w+add_back_survey_comps_and_selex+growth")[1:3]
    #File_Names = c("Base", "Exclude comps", "Exclude comps except trawl", "Exclude comps except trawl+surveys")[1:3]
    File_Set = c("90_87_plus_using_catchv6preferred", "90g_fix_selex+growth_and_remove_comps", "90h_90g+add_back_TWL_comps_and_selex", "90j_90g+fix_survey_lnQ_and_startfrom_90i", "90n_90_plus_remove_indices")[1:5]
    File_Names = c("Base", "Exclude comps", "Exclude comps except trawl", "Exclude comps except trawl + fix survey Q", "Base + drop surveys")[1:5]
    Covar = TRUE
  }
  if(RunSet=="Alternative_catch"){
    File_Set = c("90_87_plus_using_catchv6preferred", "90a_90_plus_using_catchv6alternate", "90b_90_plus_using_catchv6preferredforeign", "90c_90_plus_using_catchv6preferredbc")
    File_Names = c("Base", "Alternate WA", "Base + foreign N->S", "Base + BC catches")
    Covar = TRUE
  }
  if(RunSet=="SigmaR_sensitivity"){
    File_Set = c("90_87_plus_using_catchv6preferred", "90l_90+SigmaR=1.2", "90l_90+SigmaR=0.9")
    File_Names = c("Base", "SigmaR=1.2", "SigmaR=0.9")
    Covar = TRUE
  }
  
  # Compile runs
  Results_List = NULL
  for(Index in 1:length(File_Set)){
    File = File_Set[Index]
    Results_List[[Index]] =  SS_output( paste0(RootFile,File), covar=Covar, verbose=FALSE, printstats=FALSE, forecast=FALSE, ncols=250)
    #names(Results_List)[Index] = File_Names[Index]
    print( paste0("Index=",Index," : ",File_Names[Index]) )
  }
  
  # Plot comparisons
  Summ_h <- SSsummarize(Results_List)     # After reading SsOutput for MLE run
  PlotFile = paste0(RootFile,"Summary_plots_",RunSet,"/")
  dir.create(PlotFile)           # , 
  SSplotComparisons(Summ_h, legendlabels=File_Names, png=TRUE, pdf=FALSE, res=200, plotdir=PlotFile, par=c(mar=3,3,0,0)+0.1, pwidth=6.5, pheight=4, btarg=0.4, legendloc=LegendLoc)

  # Also plot likelihood for each
  names(Summ_h$likelihoods) = File_Names
  write.csv( Summ_h$likelihoods, file=paste0(PlotFile,"Total_likelihood.csv"))
  capture.output( Summ_h$likelihoods[1,], file=paste0(PlotFile,"Total_likelihood.txt"))
}
              
########################
# Data Emphasis Factors
########################

DAT = SS_readdat( paste0(RunFile,"Canary_data.SS") )
Levels = unique( c(DAT$lencomp[,'FltSvy'],DAT$agecomp[,'FltSvy']) )
# Length comps: DAT$lencomp
InputSampSize_LenComp = tapply( DAT$lencomp[,'Nsamp'], INDEX=factor(DAT$lencomp[,'FltSvy'],levels=Levels), FUN=sum)
  InputSampSize_LenComp = ifelse( is.na(InputSampSize_LenComp), 0, InputSampSize_LenComp)
# Age comp: DAT$agecomp
InputSampSize_AgeComp = tapply( DAT$agecomp[,'Nsamp'], INDEX=factor(DAT$agecomp[,'FltSvy'],levels=Levels), FUN=sum)
  InputSampSize_AgeComp = ifelse( is.na(InputSampSize_AgeComp), 0, InputSampSize_AgeComp)
# Ratio
InputSampSize_TotalComp = InputSampSize_AgeComp + InputSampSize_LenComp
#InputSampSize_LenComp / InputSampSize_AgeComp

# Write to file
Which = which( names(InputSampSize_TotalComp)%in%(1:15) )
# Length
Value = InputSampSize_LenComp / InputSampSize_TotalComp
DF_LenComp = data.frame( 'Component'=4, 'FltSvy'=as.numeric(names(InputSampSize_TotalComp)[Which]), 'phase'=1, 'value'=Value[Which], 'wtfreq_method'=1)
# Age
Value = InputSampSize_AgeComp / InputSampSize_TotalComp
DF_AgeComp = data.frame( 'Component'=5, 'FltSvy'=as.numeric(names(InputSampSize_TotalComp)[Which]), 'phase'=1, 'value'=Value[Which], 'wtfreq_method'=1)
# Combine
DF = rbind( DF_LenComp, DF_AgeComp )
write.csv( DF, file=paste0(RunFile,"_Emphasis_factors.csv"), row.names=FALSE )

########################
# Determine SigmaR
# FIRST: remember to rename ss3safe.exe to ss3.exe
########################

# Laplace
file.remove( file=paste0(RunFile,c("Iteration.txt","Optimization_record.txt")) )
# Version=1; Intern=TRUE; CTL_linenum_Type=NULL; systemcmd=FALSE; File=RunFile; Input_SD_Group_Vec=c(0.5); CTL_linenum_List=list(106); ESTPAR_num_List=list(c(12:62)); PAR_num_Vec=34:84; Int_Group_List=list(1); StartFromPar=FALSE; BiasRamp_linenum_Vec=124:128; ReDoBiasRamp=TRUE
NegLogInt_Fn( File=RunFile, Input_SD_Group_Vec=0.5, CTL_linenum_List=list(106), ESTPAR_num_List=list(c(12:62)), PAR_num_Vec=34:84, StartFromPar=FALSE, BiasRamp_linenum_Vec=124:128, ReDoBiasRamp=FALSE)
Opt = optimize( f=NegLogInt_Fn, interval=c(0.3,1.2), File=RunFile, CTL_linenum_List=list(106), ESTPAR_num_List=list(c(12:62)), PAR_num_Vec=34:84, StartFromPar=TRUE, BiasRamp_linenum_Vec=124:128, ReDoBiasRamp=TRUE)

############
#  SigmaR
############
# CTL_linenum_List -- line number in CTL
# ESTPAR_num_List -- Check Report file for estimated_par_number for recdevs
# PAR_num_Vec -- Check Report file (1+row number in PARAMETER section)
# BiasRamp_linenum_Vec -- line numbers in CTL (5 lines)
file.remove( file=paste0(RunFile,c("Iteration.txt","Optimization_record.txt")) )
Input_SD_Group_Set = c( 0.5, seq(0.3,0.45, by=0.05), seq(0.6,0.7, by=0.1))
Integral_Vec = rep(NA, length(Input_SD_Group_Set) )
# Run
Iteration = 0
for(IterI in 1:length(Input_SD_Group_Set)){
  # File=RunFile; Input_SD_Group_Vec=Input_SD_Group_Set[IterI]; CTL_linenum_List=list(154); ESTPAR_num_List=list( c(124:178) ); PAR_num_Vec=30:84; StartFromPar=FALSE; BiasRamp_linenum_Vec=140:144; ReDoBiasRamp=FALSE
  # Int_Group_List = list(1); Version = 1; Intern = TRUE; systemcmd = FALSE; CTL_linenum_Type=NULL
  Integral_Vec[IterI] = NegLogInt_Fn( File=RunFile, Input_SD_Group_Vec=Input_SD_Group_Set[IterI], CTL_linenum_List=list(154), ESTPAR_num_List=list( c(260:341) ), PAR_num_Vec=281:362+1, StartFromPar=TRUE, BiasRamp_linenum_Vec=172:176, ReDoBiasRamp=FALSE)
}

############
#  SigmaDistDev
############
# CTL_linenum_List -- line number in CTL
# ESTPAR_num_List -- Check Report file (4th column in PARAMETER section)
# PAR_num_Vec -- Check Report file (1+row number in PARAMETER section)
# BiasRamp_linenum_Vec -- line numbers in CTL (5 lines)
file.remove( file=paste0(RunFile,c("Iteration.txt","Optimization_record.txt")) )
Input_SD_Group_Set = seq(0.5,0.3, by=-0.05)
Integral_Vec = rep(NA, length(Input_SD_Group_Set) )
# Run
Iteration = 0
for(IterI in 1:length(Input_SD_Group_Set)){
  # File=RunFile; Input_SD_Group_Vec=Input_SD_Group_Set[IterI]; CTL_linenum_List=list( c(106,107) ); ESTPAR_num_List=list( c(13:67) ); PAR_num_Vec=NULL; StartFromPar=FALSE; BiasRamp_linenum_Vec=140:144; ReDoBiasRamp=FALSE
  # Int_Group_List = list(1); Version = 1; Intern = TRUE; systemcmd = FALSE; CTL_linenum_Type=NULL
  Integral_Vec[IterI] = NegLogInt_Fn( File=RunFile, Input_SD_Group_Vec=Input_SD_Group_Set[IterI], CTL_linenum_List=list( c(126:128) ), ESTPAR_num_List=list( c(13:258) ), PAR_num_Vec=29:274+1, StartFromPar=TRUE, BiasRamp_linenum_Vec=140:144, ReDoBiasRamp=FALSE)
}

Res = Extract_Laplace_Results_Fn( RunFile ) 
plot( x=Res[,'SD_Group_Vec'], y=Res[,'Ln_Integral'] )

########################
# Likelihood profiles
#
# Steps:
# 1. make sure "ss3.par" exists!!
# 2. add crash penalty increase to lambda section (adding line "13 1 1 1000 1")
# 3. Run the MLE to load SsOutput first!
# 4. Make sure parameter is labeled with string below
# 5. Make sure soft boundaries are turned on in STARTER file
#
# If doing h or R0:
# 6. h --  Increase starting R0 to 10 and upper bound to 15
# 7. Change ss3.par for converged model to "parfile_original_backup.sso" and also keep ss3.par
# 8. R0 -- Check what is the MLE estimate of R0!
#
# If doing M:
# 6. Increase Moffset upper bound to 3.0 and lower bound to -2.0
# 7. Include ss3.par from converged model
#
########################

Param = 3 # 1=Steepness; 2=R0; 3=M; 4=SigmaR

if(Param==1) RunFile = paste0(RootFile,"91_profile_h")
if(Param==2) RunFile = paste0(RootFile,"91_profile_R0")
if(Param==3) RunFile = paste0(RootFile,"91_profile_M")
#if(Param==3) RunFile = paste0(RootFile,"91_profile_M_fixed_offset")
if(Param==4) RunFile = paste0(RootFile,"90_profile_SigmaR")

# Run MLE first
MLE_File = paste0(RootFile,"91_90_plus_fix_WCGBTS_length_by_state/")    
  SsOutput = SS_output(MLE_File, covar=FALSE, forecast=FALSE, printstats=TRUE, ncols=400)

  ## Not run: 
# note: don't run this in your main directory
# make a copy in case something goes wrong
mydir <- RunFile
# vector of values to profile over
  # Steepness -- IMPORTANT TO INCLUDE CRASH PENALTY INCREASE
  if(Param==1) vec <- seq(0.25,0.95,0.05)
  # R0 -- CHECK WHAT IS THE MLE
  if(Param==2) vec <- 7.95 + seq(-0.2,0.8,by=0.1)  # MLE: 8.05, or v_83: 7.8
  # M
  if(Param==3) vec <- seq(0.025,0.08,by=0.0025)
  # SigmaR
  if(Param==4) vec <- seq(0.3,0.9,by=0.1)

# the following commands related to starter.ss could be done by hand
# read starter file
starter <- SS_readstarter(file.path(mydir, 'starter.ss'))
# change control file name in the starter file
starter$ctlfile <- "control_modified.ss"
# make sure the prior likelihood is calculated
# for non-estimated quantities
starter$prior_like <- 1
  # CHANGE THIS FOR GLOBAL_PAR or SEQUENTIAL START
  if(Param %in% c(1,2,4)) starter$init_values_src = 1
  if(Param %in% 3) starter$init_values_src = 1
  # END CHANGE
# write modified starter file
SS_writestarter(starter, dir=mydir, overwrite=TRUE)
# run SS_profile command
if(Param%in%c(1:2,4)) profile <- SS_profile(dir=mydir, masterctlfile="Canary_control.ss", newctlfile="control_modified.ss", string=c("Steep","R0","M1_natM_young","Sigma R")[Param], profilevec=vec, usepar=TRUE, globalpar=TRUE, parstring=c("SR_parm[2]","SR_parm[1]","MGparm[1]","SR_parm[3]")[Param], model = "ss3", extras="-nohess -cbs 500000000 -gbs 500000000")        #    
  # dir=mydir; model="ss3"; masterctlfile="Canary_control.ss"; newctlfile="control_modified.ss"; string = c("steep","R0","NatM")[Param]; profilevec=vec; usepar=TRUE; globalpar=TRUE; parstring=c("SR_parm[2]","SR_parm[1]")[Param]; model = "ss3safe"; extras="-nohess -cbs 500000000 -gbs 500000000"
  # linenum=NULL; parfile=NULL; parlinenum=NULL; dircopy=TRUE; exe.delete=FALSE; systemcmd=FALSE; saveoutput=TRUE; overwrite=TRUE; whichruns=NULL; verbove=TRUE
  
# NEED TO CHANGE LINE 84 of SS_profile.R (SS_changepars() newvals input should have changed length)
if(Param%in%3) profile <- SS_profile(dir=mydir, masterctlfile="Canary_control.ss", newctlfile="control_modified.ss", string=c("Steep","R0","M1_natM_young")[Param], profilevec=vec, usepar=TRUE, parlinenum=5, globalpar=FALSE, extras="-nohess -cbs 500000000 -gbs 500000000", model = "ss3")        #    

# read the output files (with names like Report1.sso, Report2.sso, etc.)
profilemodels <- SSgetoutput(dirvec=mydir, keyvec=1:length(vec), getcovar=FALSE)
# Remove any that didn't converge
( Nonconverged = which(sapply(profilemodels, length)==1) )
if( length(Nonconverged)>=1 ){
  profilemodels0 = profilemodels
  profilemodels = profilemodels[-Nonconverged]
  vec = vec[-Nonconverged]
}
# OPTIONAL COMMANDS TO ADD MODEL WITH PROFILE PARAMETER ESTIMATED
  #MLEmodel <- SS_output("C:/Users/James.Thorson/Dropbox/Darkblotched/Model files (local copy)/2011_assessment_62_FINAL_DATA_v20/", covar=FALSE)
  #profilemodels$MLE <- MLEmodel
# summarize output
  # biglist=profilemodels; keyvec=NULL; numvec=NULL; sizeselfactor="Lsel"; ageselfactor="Asel"; selfleet=NULL; selyr="startyr"; selgender=1; SpawnOutputUnits=NULL; lowerCI=0.025; upperCI=0.975
profilesummary <- SSsummarize(profilemodels)
# Likelihoods
delta_loglike = profilesummary$likelihoods[1,1:length(vec)] - profilesummary$likelihoods[1,which.min(profilesummary$likelihoods[1,1:length(vec)])] 
# Remove any that didn't converge
( Nonconverged = which(delta_loglike>=1000 | is.na(delta_loglike)) )
if( length(Nonconverged)>=1 ){
  profilemodels = profilemodels[-Nonconverged]
  vec = vec[-Nonconverged]
  profilesummary <- SSsummarize(profilemodels)
}
# Parameters
profilesummary$pars
  if(Param==1) profilesummary$pars[grep("Steep",profilesummary$pars$Label),1:(length(vec)+1)]
  if(Param==2) profilesummary$pars[grep("R0",profilesummary$pars$Label),1:(length(vec)+1)]
  if(Param==3) profilesummary$pars[grep("natM",profilesummary$pars$Label),1:(length(vec)+1)]

### Comparison plots
  List = NULL
  for(i in 1:(length(vec)+1)) List[[i]] = SsOutput
  Summ <- SSsummarize(List)     # After reading SsOutput for MLE run
  for(i in 2:(length(vec)+1)) Summ$mcmc[[i]] <- SSgetoutput(RunFile, keyvec=vec[i], getcovar=FALSE)
  # Save to file
  SSplotComparisons(profilesummary, legendlabels=paste(c("h","ln(R0)","M")[Param],"=",vec), png=TRUE, plotdir=RunFile, uncertainty=TRUE)
  # Save specific to screen
  SSplotComparisons(list(profilesummary), legendlabels=paste(c("h","ln(R0)","M")[Param],"=",vec), subplots=1, plot=TRUE, uncertainty=FALSE)
  # Save specific to screen
  SSplotComparisons(profilesummary, legendlabels=paste(c("h","ln(R0)","M")[Param],"=",vec), subplots=1, plot=TRUE, uncertainty=FALSE)
    SSplotComparisons(SSsummarize(list(SsOutput)), add=TRUE, subplots=1, uncertainty=TRUE, plot=FALSE) #aalyear, aalbin
                        # 
#### Profile plots
# make timeseries plots comparing models in profile
SSplotComparisons(profilesummary, legendlabels=paste(c("h","ln(R0)","M")[Param],"=",vec), png=TRUE, plotdir=RunFile, legendloc="bottomleft", pwidth=6.5, pheight=4.0)

# plot profile using summary created above
png(file=paste(RunFile,"/Profile_",c("Steep","R0","natM")[Param],".png",sep=""), width=6.5, height=6.5, res=200, units="in")
  SSplotProfile(profilesummary, profile.string=c("steep","R0","NatM_p_1_Fem_GP_1")[Param], profile.label="", legendloc="topright") # axis label
dev.off()

FleetGroups = c(rep(c("TWL","NONTWL","REC","ASHOP","FOR","WCGBTS","Tri_early","Tri_late","Pre_rec"),each=3),rep("Coastwide",4))
#FleetGroups = c(rep(1:9,each=3),rep(10,4))
for(PlotI in 1:3){
  png(file=paste(RunFile,"/Profile_",c("Steep","R0","NatM")[Param],"_by_",c("Length_like","Age_like","Surv_like")[PlotI],".png",sep=""), width=6.5, height=4.0, res=200, units="in")
    PinerPlot(profilesummary, fleetgroups=FleetGroups, plot=TRUE, component=c("Length_like","Age_like","Surv_like")[PlotI], main="",  profile.string=c("steep","R0","NatM_p_1_Fem_GP_1")[Param], pch=1, likelihood_type="raw_times_lambda", minfraction=0.01, profile.label=c("Steepness","Unfished recruits","Natural mortality")[Param])
    #Table = PinerPlot(profilesummary, fleetgroups=FleetGroups, plot=FALSE, print=FALSE, component=c("Length_like","Age_like","Surv_like")[PlotI], main="",  profile.string=c("steep","R0","NatM_p_1_Fem_GP_1")[Param], pch=1, likelihood_type="raw", minfraction=0.01, profile.label=c("Steepness","Unfished recruits","Natural mortality")[Param])
    # summaryoutput=profilesummary; fleetgroups=FleetGroups; plot=TRUE; print=FALSE; component=c("Length_like","Age_like","Surv_like")[PlotI]; main="Changes in length-composition likelihoods by fleet"; models="all"; fleets="all"; fleetnames="default"; profile.string=c("steep","R0","NatM_p_1_Fem_GP_1")[Param]; profile.label=expression(log(italic(R)[0])); ylab="Change in -log-likelihood"; col="default"; pch=1; lty=1; lty.total=1; lwd=2; lwd.total=3; cex=1; cex.total=1.5; xlim="default"; ymax="default"; xaxs="r"; yaxs="r"; type="o"; legend=TRUE; legendloc="topright"; pwidth=6.5; pheight=5; punits="in"; res=300; ptsize=10; cex.main=1; plotdir=NULL; verbose=TRUE; fleetgroups=FleetGroups; likelihood_type="raw_times_lambda"; minfraction=0.01
  dev.off()
}

# Explore likelihoods by fleet
lbf <- profilesummary$likelihoods_by_fleet
lbf[,c(1,2,31:34)]

# plot=TRUE; print=FALSE; component="Length_like"; main="Changes in length-composition likelihoods by fleet"; models="all"; fleets="all"; fleetnames="default"; profile.string="R0"; profile.label=expression(log(italic(R)[0])); ylab="Change in -log-likelihood"; col="default"; pch="default"; lty=1; lty.total=1; lwd=2; lwd.total=3; cex=1; cex.total=1.5; xlim="default"; ymax="default"; xaxs="r"; yaxs="r"; type="o"; legend=TRUE; legendloc="topright"; pwidth=6.5; pheight=5.0; punits="in"; res=300; ptsize=10; cex.main=1; plotdir=NULL; verbose=TRUE
#summaryoutput=profilesummary; fleetgroups=FleetGroups; plot=TRUE; component=c("Length_like","Age_like","Surv_like")[PlotI]; main="";  profile.string=c("steep","R0","NatM_p_1_Fem_GP_1")[Param]; pch=1


################
# Do retrospective
# Steps:
# 1. Do not include hessian (otherwise, when hessian isn't PD, it doesn't generate DERIVED_VALUES in REPORT file)
###############

RetroYears = c(0,-1:-8)
Uncertainty = TRUE

MLE_File = paste0(RootFile,"91_90_plus_fix_WCGBTS_length_by_state/")    
  SsOutput = SS_output(MLE_File, covar=Uncertainty, forecast=FALSE, printstats=TRUE, ncols=400)

RunFile = paste(RootFile,"91_retrospectives",sep="")
  # masterdir=RunFile; oldsubdir=""; newsubdir="retrospectives"; years=0:-3
  # subdirstart='retro'; overwrite=TRUE; extras="-nox"; intern=FALSE; CallType="system"
#SS_doRetro(masterdir=RunFile, oldsubdir="", newsubdir="retrospectives", years=RetroYears, CallType="system", extras="-nohess")
    
# Get runs
retroModels <- SSgetoutput(dirvec=file.path(RunFile,"retrospectives",paste0("retro",RetroYears)), getcovar=Uncertainty)

# Remove any that didn't converge
( Nonconverged = which( sapply(retroModels, length)==1 ) )
if( length(Nonconverged)>=1 ){
  retroModels0 = retroModels
  retroModels = retroModels[-Nonconverged]
  RetroYears = RetroYears[-Nonconverged]
}
# Eliminate 
#retroModels = lapply( retroModels, FUN=function(List){retroModels[1:140]})
# Summarize
retroSummary <- SSsummarize(retroModels)
endyrvec <- retroSummary$endyrs #+ RetroYears

for(PlotI in 1:20){
  #PlotName = c("biomass_ratio", "depletion_ratio", "SPR_ratio", "recruit_devs", "phase_plot")[PlotI]
  PlotName = PlotI
  par( mar=c(3,3,2,0), mgp=c(2,0.5,0), tck=-0.02 )    # c(2,4,6,10,13)[PlotI]
  SSplotComparisons(retroSummary, subplot=PlotI, uncertainty=Uncertainty, endyrvec=endyrvec, legendlabels=paste("Data",RetroYears,"years"), png=TRUE, pdf=FALSE, pwidth=6.5, pheight=4, res=200, plotdir=RunFile)
  dev.off()
}

# make a table of values for each model
Temp = SStableComparisons(retroSummary, likenames=c("TOTAL","Survey","Length_comp","Age_comp","Discard","Mean_body_wt"), names=c("SR_LN","SR_BH_steep","NatM","L_at_","VonBert_K","SPB_Virg","Bratio_2013"), csvdir=RunFile)
write.csv(Temp, file=paste(RunFile,"/Comparison_table_unformatted.csv",sep=""))
Temp[17,-1] = Temp[17,-1] / 1000
Temp[,-1] = t(apply(Temp[,-1], MARGIN=1, FUN=format, digits=3, nsmall=3, scientific=FALSE))
write.csv(Temp, file=paste(RunFile,"/Comparison_table_formatted.csv",sep=""))

################
# Explore movement rates
#
# STEPS
#  1.  Turn on movement
#  2.  Label movement "# Movement_1" through "# Movement_8"
#  3.  Increase crash penalty "13 1 1 1000 1"
#  4.  Make sure lower bound on movement is -10, and that phase is negative for all movement parameters
###############

MLE_File = paste0(RootFile,"90_87_plus_using_catchv6preferred/")    
  SsOutput = SS_output(MLE_File, covar=FALSE, forecast=FALSE, printstats=TRUE, ncols=400)

RunFile = paste0(RootFile,"90_profile_movement/")    

vec = log( c(0.0001,seq(0.01,0.05,by=0.01)) )

# the following commands related to starter.ss could be done by hand
# read starter file
starter <- SS_readstarter(file.path(RunFile, 'starter.ss'))
# change control file name in the starter file
starter$ctlfile <- "control_modified.ss"
# make sure the prior likelihood is calculated
# for non-estimated quantities
starter$prior_like <- 1
  # CHANGE THIS FOR GLOBAL_PAR START
  starter$init_values_src = 0
  # END CHANGE
# write modified starter file
SS_writestarter(starter, dir=RunFile, overwrite=TRUE)
# run SS_profile command
profile <- SS_profile(dir=RunFile, masterctlfile="Canary_control.ss", newctlfile="control_modified.ss", string=c("Movement_all",paste0("Movement_",1:8)), profilevec=vec, usepar=FALSE, globalpar=FALSE, extras="-nohess -cbs 500000000 -gbs 500000000", model = "ss3")        #    
  # dir=RunFile; model="ss3safe"; masterctlfile="Canary_control.ss"; newctlfile="control_modified.ss"; string="Adult_movement"; profilevec=vec; usepar=FALSE; globalpar=FALSE; parstring=NULL; extras="-nohess -cbs 500000000 -gbs 500000000"
  # linenum=NULL; parfile=NULL; parlinenum=NULL; dircopy=TRUE; exe.delete=FALSE; systemcmd=FALSE; saveoutput=TRUE; overwrite=TRUE; whichruns=NULL; verbove=TRUE

# read the output files (with names like Report1.sso, Report2.sso, etc.)
profilemodels <- SSgetoutput(dirvec=RunFile, keyvec=1:length(vec), getcovar=FALSE)
# Remove any that didn't converge
( Nonconverged = which(sapply(profilemodels, length)==1) )
if( length(Nonconverged)>=1 ){
  profilemodels0 = profilemodels
  profilemodels = profilemodels[-Nonconverged]
  vec = vec[-Nonconverged]
}
# OPTIONAL COMMANDS TO ADD MODEL WITH PROFILE PARAMETER ESTIMATED
  #MLEmodel <- SS_output("C:/Users/James.Thorson/Dropbox/Darkblotched/Model files (local copy)/2011_assessment_62_FINAL_DATA_v20/", covar=FALSE)
  #profilemodels$MLE <- MLEmodel
# summarize output
  # biglist=profilemodels; keyvec=NULL; numvec=NULL; sizeselfactor="Lsel"; ageselfactor="Asel"; selfleet=NULL; selyr="startyr"; selgender=1; SpawnOutputUnits=NULL; lowerCI=0.025; upperCI=0.975
profilesummary <- SSsummarize(profilemodels)
# Likelihoods
delta_loglike = profilesummary$likelihoods[1,1:length(vec)] - profilesummary$likelihoods[1,which.min(profilesummary$likelihoods[1,1:length(vec)])] 
# Remove any that didn't converge
( Nonconverged = which(delta_loglike>=500 | is.na(delta_loglike) ))
if( length(Nonconverged)>=1 ){
  profilemodels = profilemodels[-Nonconverged]
  vec = vec[-Nonconverged]
  profilesummary <- SSsummarize(profilemodels)
}

### Comparison plots
# Save to file
SSplotComparisons(profilesummary, legendlabels=paste0("Movement_rate=",formatC(exp(vec),format="f",digits=4)), png=TRUE, plotdir=RunFile, uncertainty=TRUE)
# Save specific to screen
SSplotComparisons(list(profilesummary), legendlabels=paste0("Movement_rate=",formatC(exp(vec),format="f",digits=4)), subplots=1, plot=TRUE, uncertainty=FALSE)
# Save specific to screen
SSplotComparisons(profilesummary, legendlabels=paste0("Movement_rate=",formatC(exp(vec),format="f",digits=4)), subplots=1, plot=TRUE, uncertainty=FALSE)
  SSplotComparisons(SSsummarize(list(SsOutput)), add=TRUE, subplots=1, uncertainty=TRUE, plot=FALSE) #aalyear, aalbin
                        # 
#### Profile plots
# plot profile using summary created above
png(file=paste0(RunFile,"/Profile_Movement.png"), width=8, height=8, res=200, units="in")
  Table = SSplotProfile(profilesummary, profile.string="MoveParm_B_seas_1_GP_1from_1to_2", profile.label="") # axis label
  write.csv( Table, file=paste0(RunFile,"/Profile_Movement.csv")) 
dev.off()

FleetGroups = c(rep(c("TWL","NONTWL","REC","ASHOP","FOR","WCGBTS","Tri_early","Tri_late","Pre_rec"),each=3),rep("Coastwide",4))
for(PlotI in 1:3){
  png(file=paste0(RunFile,"/Profile_Movement_by_",c("Length_like","Age_like","Surv_like")[PlotI],".png"), width=12, height=12, res=200, units="in")
    Table = PinerPlot(profilesummary, fleetgroups=FleetGroups, plot=TRUE, component=c("Length_like","Age_like","Surv_like")[PlotI], main="", profile.string="MoveParm_B_seas_1_GP_1from_1to_2", pch=1)
    # summaryoutput=profilesummary; plot=TRUE; print=FALSE; component=c("Length_like","Age_like","Surv_like")[PlotI]; main="Changes in length-composition likelihoods by fleet"; models="all"; fleets="all"; fleetnames="default"; profile.string=c("Steep","R0","NatM_p_1_Fem_GP_1")[Param]; profile.label=expression(log(italic(R)[0])); ylab="Change in -log-likelihood"; col="default"; pch=1; lty=1; lty.total=1; lwd=2; lwd.total=3; cex=1; cex.total=1.5; xlim="default"; ymax="default"; xaxs="r"; yaxs="r"; type="o"; legend=TRUE; legendloc="topright"; pwidth=6.5; pheight=5; punits="in"; res=300; ptsize=10; cex.main=1; plotdir=NULL; verbose=TRUE
    #PinerPlot(profilesummary, plotdir=RunFile, plot=TRUE, component=c("Length_like","Age_like","Surv_like")[PlotI], profile.string=c("Steep","R0","NatM_p_1_Fem_GP_1")[Param], pch=1, main=paste0("Profile_",c("steep","R0","NatM")[Param],"_by_",c("Length_like","Age_like","Surv_like")[PlotI]))
    write.csv( Table, file=paste0(RunFile,"/Profile_Movement_by_",c("Length_like","Age_like","Surv_like")[PlotI],".csv")) 
  dev.off()
}
