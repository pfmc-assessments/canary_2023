# Canary rockfish 2023
# Pre-recruit index (coastwide and for each state)
# Tanya Rogers

library(RREAS) #devtools::install_github("tanyalrogers/RREAS")
library(dplyr)
library(ggplot2)
library(tidyr)
library(sdmTMB)

#load data from local database (to reproduce output, start at line 25)
load_mdb(mdb_path = "C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/juv_cruise_backup24JAN23.mdb",
         atsea_path = "C:/Users/trogers/Documents/Rockfish/RREAS/Survey data/at_sea.mdb",
         datasets = c("RREAS","NWFSC","PWCC"),
         activestationsonly = F)

rfspecies <- subset(sptable_rockfish100, SPECIES %in% c(618))
rfspecies$NAME <- c("Canary")

c_100 <- get_totals(rfspecies, datasets = c("RREAS","NWFSC","PWCC"), 
                     what = "100day", startyear = 2001)

# export raw data ####
# write.csv(c_100, "data/canary_prerecruit_raw_c100.csv", row.names = F)
# c_100 <- read.csv("data/canary_prerecruit_raw_c100.csv", stringsAsFactors = F, 
#                   colClasses = c(CRUISE="character", HAUL_DATE="POSIXct"))

#state map
states <- map_data("state", region = c("california","oregon","washington"))

#exclude offshore stations
c_100 <- subset(c_100, !(STATION %in% c(176:181,214:216)))

#check occurence
# occur <- c_100 %>%
#   group_by(STATION, LONDD, LATDD, NAME) %>%
#   summarize(proppos=length(which(TOTAL_NO>0))/n())
# ggplot(occur, aes(LONDD, LATDD)) +
#   geom_point(data=filter(occur, proppos==0), color="tomato") +
#   geom_point(data=filter(occur, proppos!=0), aes(color=proppos)) +
#   facet_grid(.~NAME) + scale_color_distiller(palette = "Blues", direction = 1) +
#   geom_polygon( data=states, aes(x=long, y=lat, group=group),
#                 color="gray30", fill="transparent")

#spatial subset
#N of Conception, include Point Sal line
c_100 <- subset(c_100, LATDD>=35)

#plot occurrence
occur <- c_100 %>%
  group_by(STATION, LONDD, LATDD, NAME) %>%
  summarize(proppos=length(which(TOTAL_NO>0))/n())
ggplot(occur, aes(LONDD, LATDD)) +
  geom_point(data=filter(occur, proppos==0), color="tomato") +
  geom_point(data=filter(occur, proppos!=0), aes(fill=proppos),pch=21,color="black") +
  facet_grid(.~NAME) + scale_fill_distiller(palette = "Blues", direction = 1) +
  geom_polygon( data=states, aes(x=long, y=lat, group=group),
                color="gray30", fill="transparent") +
  coord_cartesian(xlim = range(occur$LONDD), ylim = range(occur$LATDD)) +
  labs(fill="Prop. Pos.\nCatches") +
  scale_y_continuous(breaks = 20:50)
#ggsave("Indices/RREAS/canary rf figures/canary_poscatch.png", width = 4, height = 4)

#plot of spatial sampling effort
ggplot(c_100, aes(LONDD, LATDD, col = SURVEY)) + 
  geom_polygon( data=states, aes(x=long, y=lat, group=group),
                color="gray30", fill="transparent") +
  geom_point(size=0.5) + facet_wrap(~YEAR, nrow = 3) + 
  coord_cartesian(xlim = range(c_100$LONDD), ylim = range(c_100$LATDD))
#ggsave("Indices/RREAS/canary rf figures/sampling_effort_st.png", width = 10, height = 6)

#fill in missing stations (only needed for raw cpue)
c_100$STATION=ifelse(is.na(c_100$STATION),paste0(c_100$CRUISE,c_100$HAUL_NO),c_100$STATION)
#center covariates
c_100$JDAYC <- c_100$JDAY - mean(c_100$JDAY)

#select focal species
focal <- c_100

# raw CPUE ####

#years with no catch
(totals=aggregate(TOTAL_NO~YEAR*NAME, data=c_100, FUN=sum))
totals[totals$TOTAL_NO==0,]

logind=get_logcpueindex(droplevels(focal),var = "N100")
ggplot(logind, aes(x=YEAR, y=N100_INDEX, color=NAME, group=NAME)) +
  geom_point() + geom_line() + labs(y="mean log(CPUE+1)")
#ggsave("Indices/RREAS/canary rf figures/raw_cpue.png", width = 6, height = 4)

# sdmtmb ####

focalcoast <- focal
excludeyears=2020
focalcoast=filter(focalcoast, !(YEAR %in% excludeyears)) %>% droplevels()
focalcoast$FYEAR <- as.factor(focalcoast$YEAR)
yearscoast=unique(focalcoast$YEAR)

#plot log mean vs log variance by year for positive data
# mvaryr <- focalcoast %>% filter(TOTAL_NO>0) %>% group_by(YEAR) %>% 
#   summarise(n=n(),logmean=log(mean(TOTAL_NO)), logvar=log(var(TOTAL_NO)),
#             logmean100=log(mean(N100)), logvar100=log(var(N100))) %>% 
#   filter(n>=10)
# png("Indices/RREAS/canary rf figures/mean_var.png", width = 7, height = 4, res = 300, units = "in")
# par(mfrow=c(1,2), mar=c(4,4,1,1))
# plot(logvar~logmean, data=mvaryr); abline(a=0, b=1); abline(a=0, b=2, lty=2); abline(a=0, b=3, lty=3)
# plot(logvar100~logmean100, data=mvaryr); abline(a=0, b=1); abline(a=0, b=2, lty=2); abline(a=0, b=3, lty=3)
# dev.off()

#create mesh
focalcoast <- add_utm_columns(focalcoast, c("LONDD","LATDD"))
meshcoast = make_mesh(focalcoast, xy_cols = c("X","Y"), cutoff = 25)
par(mfrow=c(1,1)); plot(meshcoast)

# * fit models ####

#tweedie with spatial-temporal field
fit_spde_tw_coast <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
                            spatiotemporal = "iid",
                            time="FYEAR",
                            spatial="on",
                            family = tweedie(),
                            mesh=meshcoast,
                            data=focalcoast)
sanity(fit_spde_tw_coast)
fit_spde_tw_coast

#delta lognormal with spatial-temporal field
fit_spde_dln3_coast <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
                              spatiotemporal = "iid",
                              time="FYEAR",
                              spatial="on",
                              family = delta_lognormal(),
                              mesh=meshcoast,
                              data=focalcoast)
sanity(fit_spde_dln3_coast)
fit_spde_dln3_coast

#delta gamma with spatial-temporal field
fit_spde_dgam_coast <- sdmTMB(N100 ~ -1 + FYEAR + s(JDAYC, k=4),
                              spatiotemporal = "iid",
                              time="FYEAR",
                              spatial="on",
                              family = delta_gamma(),
                              mesh=meshcoast,
                              data=focalcoast)
sanity(fit_spde_dgam_coast)
fit_spde_dgam_coast

# * residual plots (dharma) ####

s_tw <- simulate(fit_spde_tw_coast, nsim = 500)
s_dln <- simulate(fit_spde_dln3_coast, nsim = 500) 
s_dgam <- simulate(fit_spde_dgam_coast, nsim = 500) 

#check number of zeros
sum(focalcoast$N100 == 0) / length(focalcoast$N100)
sum(s_tw == 0)/length(s_tw)
sum(s_dln == 0)/length(s_dln)
sum(s_dgam == 0)/length(s_dgam)

#png("Indices/RREAS/canary rf figures/qqplots.png", width = 8, height = 4, res = 300, units = "in")
par(mfrow=c(1,3))
sdmTMBextra::dharma_residuals(s_tw, fit_spde_tw_coast)
title("tweedie", line=-1)
sdmTMBextra::dharma_residuals(s_dln, fit_spde_dln3_coast)
title("delta-lognormal", line=-1)
sdmTMBextra::dharma_residuals(s_dgam, fit_spde_dgam_coast)
title("delta-gamma", line=-1)
#dev.off()

# * predictions ####

activestations=filter(focalcoast, ACTIVE=="Y")
new_grid <- unique.data.frame(select(activestations, STATION, STRATA, LATDD, X, Y))
new_grid_coast=expand_grid(new_grid, YEAR=yearscoast)
new_grid_coast$JDAYC=0
new_grid_coast$FYEAR <- factor(new_grid_coast$YEAR)

pred_tw_coast=predict(fit_spde_tw_coast, newdata = new_grid_coast, return_tmb_object = T)
ind_tw_coast=get_index(pred_tw_coast, bias_correct = T)
ind_tw_coast$model="tweedie spatial-temporal canary"
ind_tw_coast$region="coastwide"

pred_dln3_coast=predict(fit_spde_dln3_coast, newdata = new_grid_coast, return_tmb_object = T)
ind_dln3_coast=get_index(pred_dln3_coast, bias_correct = T)
ind_dln3_coast$model="delta-logn spatial-temporal canary"
ind_dln3_coast$region="coastwide"

pred_dgam_coast=predict(fit_spde_dgam_coast, newdata = new_grid_coast, return_tmb_object = T)
ind_dgam_coast=get_index(pred_dgam_coast, bias_correct = T)
ind_dgam_coast$model="delta-gamma spatial-temporal canary"
ind_dgam_coast$region="coastwide"

# * plot predictions over space ####

plot_map <- function(dat, column, pointsize=2) {
  ggplot(dat, aes(X, Y, color = {{ column }})) +
    geom_point(size=pointsize) + scale_colour_gradient2()
}

#observed
plot_map(focalcoast, log(N100)) + facet_wrap(~YEAR) + ggtitle("Observed canary")  +
  geom_point(data=filter(focalcoast, N100>0), pch=1, color="tomato")
#ggsave("Indices/RREAS/canary rf figures/observed.png", width = 10, height = 8)

#tweedie with spatial-temporal field

#predicted
predictions_tw=predict(fit_spde_tw_coast)
plot_map(predictions_tw, est) + facet_wrap(~YEAR) + ggtitle("Predicted canary") 
#ggsave("Indices/RREAS/canary rf figures/predicted.png", width = 10, height = 8)

#predicted to active station grid
plot_map(pred_tw_coast$data, est) + facet_wrap(.~YEAR) + ggtitle("Predicted to grid canary")
#ggsave("Indices/RREAS/canary rf figures/predictedgrid.png", width = 10, height = 8)

#random fields
plot_map(pred_tw_coast$data, omega_s, pointsize = 5) + ggtitle("Spatial random effects")
plot_map(pred_tw_coast$data, epsilon_st) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal offsets")
plot_map(pred_tw_coast$data, est_rf) + facet_wrap(.~YEAR) + ggtitle("Spatial-temporal random effects")

# * plot indices ####

#compare different error structures
ind_comp=rbind(ind_tw_coast, ind_dln3_coast, ind_dgam_coast)
ind_comp=ind_comp %>% mutate(YEAR=as.numeric(as.character(FYEAR)))
ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
                                             YEAR=min(yearscoast):max(yearscoast))) %>% 
  arrange(model, YEAR)
ggplot(ind_comp, aes(x=YEAR, y=log_est,color=model, fill=model, group=model)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), alpha=0.1) +  
  labs(color="model", fill="model", y="log index") +
  theme(legend.position = "top", legend.direction = "vertical")
#ggsave("Indices/RREAS/canary rf figures/comparison_error_dist.png", width = 6, height = 4)
ggplot(ind_comp, aes(x=YEAR, y=est,color=model, fill=model, group=model)) +
  geom_line(size=1) +
  geom_ribbon(aes(ymin=lwr, ymax=upr), alpha=0.1) +  
  labs(color="model", fill="model", y="index") 

#plot final coastwide index
ind_comp=rbind(ind_tw_coast)
ind_comp=ind_comp %>% mutate(YEAR=as.numeric(as.character(FYEAR)))
ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
                                             YEAR=min(yearscoast):max(yearscoast))) %>% 
  arrange(model, YEAR)

ggplot(ind_comp, aes(x=YEAR, y=log_est, color=model, fill=model, group=model)) +
  geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), outline.type = "full", alpha=0.1) +  
  geom_ribbon(aes(ymin=log_est-se, ymax=log_est+se), color=NA, alpha=0.1) +  
  geom_line(size=1) + geom_point(size=1) +
  labs(color="model", fill="model", y="log index")  +
  theme(legend.position = "top")
#ggsave("Indices/RREAS/canary rf figures/indexcomparison_log.png", width = 6, height = 4)

ggplot(ind_comp, aes(x=YEAR, y=log_est)) +
  # facet_wrap(.~model, scales = "free_y") +
  geom_line(size=1) + geom_point(size=0.5) +
  geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), outline.type = "full", alpha=0.25) +  
  geom_ribbon(aes(ymin=log_est-se, ymax=log_est+se), color=NA, alpha=0.1) +  
  labs(y="log index") + theme_bw()
#ggsave("Indices/RREAS/canary rf figures/indexcomparison_log2.png", width = 8, height = 4)

ggplot(ind_comp, aes(x=YEAR, y=est)) +
  # facet_wrap(.~model, scales = "free_y") +
  geom_line(size=1) + geom_point(size=0.5) +
  geom_ribbon(aes(ymin=lwr, ymax=upr),outline.type = "full", alpha=0.25) +  
  labs(y="index") + theme_bw()
#ggsave("Indices/RREAS/canary rf figures/indexcomparison.png", width = 8, height = 4)

# * JDAY effect ####
#png("Indices/RREAS/canary rf figures/jday_effect.png", width = 4, height = 4, res = 300, units = "in")
visreg::visreg(fit_spde_tw_coast, xvar = "JDAYC")
#dev.off()

# * predictions for each state ####

#table of sampling and catches by region
reg_sampling=c_100 %>% mutate(region=ifelse(STRATA %in% c("OR","WA"), STRATA, "CA")) %>% 
  group_by(region, YEAR) %>% 
  summarise(ntrawls=n(), nfish=sum(TOTAL_NO))
coast_sampling=c_100 %>% mutate(region="coastwide") %>% group_by(region, YEAR) %>% 
  summarise(ntrawls=n(), nfish=sum(TOTAL_NO))
sampling=rbind(reg_sampling,coast_sampling)

#OR: no sampling in 2010
#WA: no sampling in 2001, 2002, 2003, 2010, 2012, 2014, 2017, 2021

#state-specific prediction grid
new_grid_CA = subset(new_grid_coast, LATDD<=42)
new_grid_OR = subset(new_grid_coast, LATDD>=42 & LATDD<46.5)
new_grid_WA = subset(new_grid_coast, LATDD>=46.5)

pred_tw_CA=predict(fit_spde_tw_coast, newdata = new_grid_CA, return_tmb_object = T)
ind_tw_CA=get_index(pred_tw_CA, bias_correct = T)
ind_tw_CA$model="tweedie spatial-temporal canary CA"
ind_tw_CA$region="CA"

pred_tw_OR=predict(fit_spde_tw_coast, newdata = new_grid_OR, return_tmb_object = T)
ind_tw_OR=get_index(pred_tw_OR, bias_correct = T)
ind_tw_OR$model="tweedie spatial-temporal canary OR"
ind_tw_OR$region="OR"

pred_tw_WA=predict(fit_spde_tw_coast, newdata = new_grid_WA, return_tmb_object = T)
ind_tw_WA=get_index(pred_tw_WA, bias_correct = T)
ind_tw_WA$model="tweedie spatial-temporal canary WA"
ind_tw_WA$region="WA"

#plot indices
ind_comp=rbind(ind_tw_coast, ind_tw_CA, ind_tw_OR, ind_tw_WA)
ind_comp=ind_comp %>% 
  mutate(YEAR=as.numeric(as.character(FYEAR)))
ind_comp=ind_comp %>% right_join(expand.grid(model=unique(ind_comp$model),
                                             YEAR=min(yearscoast):max(yearscoast))) %>% 
  arrange(model, YEAR) %>% 
  left_join(sampling)
ind_comp[is.na(ind_comp$ntrawls),1:6]=NA #remove years with no sampling

ggplot(ind_comp, aes(x=YEAR, y=log_est, color=model, fill=model, group=model)) +
  facet_wrap(.~model, nrow = 2) +
  geom_ribbon(aes(ymin=log(lwr), ymax=log(upr)), outline.type = "full", alpha=0.1) +  
  geom_ribbon(aes(ymin=log_est-se, ymax=log_est+se), color=NA, alpha=0.1) +  
  geom_line(size=1) + geom_point(size=1) +
  labs(color="model", fill="model", y="log index")  +
  theme(legend.position = "off")
#ggsave("Indices/RREAS/canary rf figures/state_comparison.png", width = 6, height = 6)

ggplot(ind_comp, aes(x=YEAR, y=est,color=model, fill=model, group=model)) +
  facet_wrap(.~model, nrow = 2, scales = "free_y") +
  geom_ribbon(aes(ymin=lwr, ymax=upr),outline.type = "full", alpha=0.1) +  
  geom_line(size=1) + geom_point(size=1) +
  labs(color="model", fill="model", y="index") +
  theme(legend.position = "off")

# * export final indices ####
ind_export <- ind_comp %>% select(YEAR, est:se, region, ntrawls, nfish) %>% 
  filter(!is.na(ntrawls)) #remove years with no sampling
write.csv(ind_export, "data/canary_prerecruit_indices.csv", row.names = F)
