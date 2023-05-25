####
#
#This function compares growth from entered in SSoutput from a run model
#to the growth estimated from the NWFSC.Combo survey for males and females
#aggregated across the coast. 
#
#Mal Amin is entered with INIT = zero (which means its fixed at the female value)
#Put it in as an offset incase our model formulation changes
#
#Note that this only works with the constant M set up. With M as breakpoints it wont work
#
####


growComp <- function(out){
  grow <- data.frame("Age" = 1:84, "F surv" = 0, "M surv" = 0, "F est" = 0, "M est" = 0)
  
  #Survey direct estimates
  grow$F.surv <- 11.38 + (57.90 - 11.38)*(1-exp(-0.1427*(grow$Age - 1)))
  grow$M.surv <- 11.365 + (51.32 - 11.365)*(1-exp(-0.1755*(grow$Age - 1)))
  
  #Model estimated estimates
  grow$F.est <- out$parameters['L_at_Amin_Fem_GP_1',"Value"] + 
    (out$parameters['L_at_Amax_Fem_GP_1',"Value"] - out$parameters['L_at_Amin_Fem_GP_1',"Value"])*
    (1-exp(-out$parameters['VonBert_K_Fem_GP_1',"Value"]*(grow$Age - 1)))
  grow$M.est <- out$parameters['L_at_Amin_Fem_GP_1',"Value"]*exp(out$parameters['L_at_Amin_Mal_GP_1',"Value"]) + 
    (out$parameters['L_at_Amax_Mal_GP_1',"Value"] - out$parameters['L_at_Amin_Fem_GP_1',"Value"]*exp(out$parameters['L_at_Amin_Mal_GP_1',"Value"]))*
    (1-exp(-out$parameters['VonBert_K_Mal_GP_1',"Value"]*(grow$Age - 1)))
  
  #Plot
  plot(grow$Age, grow$F.surv, type = "l", lty = 1, lwd=3, col = 2, 
       xlab = "Age", ylab = "Length cm", ylim = c(0,70))
  lines(grow$Age, grow$F.est, type = "l", lty = 2, lwd=3, col = 2)
  lines(grow$Age, grow$M.surv, type = "l", lty = 1, lwd=3, col = 4)
  lines(grow$Age, grow$M.est, type = "l", lty = 2, lwd=3, col = 4)
  legend("bottomright", c("F surv", "F model", "M surv", "M model"), 
         ncol = 2, lty = c(1,2,1,2), lwd = 3, col = c(2,2,4,4), bty = "n")
  
  text(20,20,paste("F Surv Lmax", 57.90, "K", 0.143))
  text(20,15,paste("M Surv Lmax", 51.32, "K", 0.176))
  text(20,10,paste("F Lmax", round(out$parameters['L_at_Amax_Fem_GP_1',"Value"],2), "K", round(out$parameters['VonBert_K_Fem_GP_1',"Value"],3)))
  text(20,5,paste("M Lmax", round(out$parameters['L_at_Amax_Mal_GP_1',"Value"],2), "K", round(out$parameters['VonBert_K_Mal_GP_1',"Value"],3)))
  
}
growComp(pp)