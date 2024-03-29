#' Performs inference over a fitted GBN
#'
#' Performs inference over a Gaussian BN. It's thought to be used in a map for
#' a data.table, to use as evidence each separate row. If not specifically
#' needed, it's recommended to use the function \code{\link{predict_dt}} instead.
#' This function is deprecated and will be removed in a future version.
#' @param fit the fitted bn
#' @param evidence values of the variables used as evidence for the net
#' @return a data.table with the predictions
#' @examples
#' size = 3
#' data(motor)
#' dt_train <- motor[200:2500]
#' dt_val <- motor[2501:3000]
#' net <- learn_dbn_struc(dt_train, size)
#' f_dt_train <- fold_dt(dt_train, size)
#' f_dt_val <- fold_dt(dt_val, size)
#' fit <- fit_dbn_params(net, f_dt_train, method = "mle-g")
#' res <- f_dt_val[, predict_bn(fit, .SD), .SDcols = c("pm_t_0", "coolant_t_0"), by = 1:nrow(f_dt_val)]
#' @export
predict_bn <- function(fit, evidence){
  n <- names(fit)
  obj_nodes <- n[which(!(n %in% names(evidence)))]
  
  pred <- mvn_inference(attr(fit,"mu"), attr(fit,"sigma"), evidence)
  pred <- as.data.table(t(pred$mu_p[,1]))
  if(length(obj_nodes) == 1)
    setnames(pred, names(pred), obj_nodes)
  
  return(pred)
}

#' Performs inference over a test dataset with a GBN
#'
#' This function performs inference over each row of a folded data.table, 
#' plots the results and gives metrics of the accuracy of the predictions. Given
#' that only a single row is predicted, the horizon of the prediction is at most 1.
#' This function is also called by the generic predict method for "dbn.fit" 
#' objects. For long term forecasting, please refer to the 
#' \code{\link{forecast_ts}} function.
#' @param fit the fitted bn
#' @param dt the test dataset
#' @param obj_nodes the nodes that are going to be predicted. They are all predicted at the same time
#' @param verbose if TRUE, displays the metrics and plots the real values against the predictions
#' @param look_ahead boolean that defines whether or not the values of the variables in t_0 should be used when predicting, even if they are not present in obj_nodes. This decides if look-ahead bias is introduced or not.
#' @return a data.table with the prediction results for each row
#' @examples
#' size = 3
#' data(motor)
#' dt_train <- motor[200:900]
#' dt_val <- motor[901:1000]
#' 
#' # With a DBN
#' obj <- c("pm_t_0")
#' net <- learn_dbn_struc(dt_train, size)
#' f_dt_train <- fold_dt(dt_train, size)
#' f_dt_val <- fold_dt(dt_val, size)
#' fit <- fit_dbn_params(net, f_dt_train, method = "mle-g")
#' res <- suppressWarnings(predict_dt(fit, f_dt_val, obj_nodes = obj, verbose = FALSE))
#' 
#' # With a Gaussian BN directly from bnlearn
#' obj <- c("pm")
#' net <- bnlearn::mmhc(dt_train)
#' fit <- bnlearn::bn.fit(net, dt_train, method = "mle-g")
#' res <- suppressWarnings(predict_dt(fit, dt_val, obj_nodes = obj, verbose = FALSE))
#' @importFrom graphics "plot" "lines" 
#' @importFrom stats "ts"
#' @export
predict_dt <- function(fit, dt, obj_nodes, verbose = T, look_ahead = F){
  initial_fit_check(fit)
  initial_df_check(dt)
  fit <- initial_attr_check(fit)
  
  if(!look_ahead){
    vars_t_0 <- names(fit)[grepl("t_0", names(fit))]
    obj_nodes_full <- c(obj_nodes, vars_t_0[!(vars_t_0 %in% obj_nodes)])
  }
  
  else
    obj_nodes_full <- obj_nodes
  
  dt <- as.data.table(dt)
  obj_dt <- dt[, .SD, .SDcols = obj_nodes_full]
  ev_dt <- copy(dt)
  ev_dt[, (obj_nodes_full) := NULL]
  
  res <- ev_dt[, predict_bn(fit, .SD), by = 1:nrow(ev_dt)]
  res[, nrow := NULL]
  
  mae <- sapply(obj_nodes, function(x){mae(obj_dt[, get(x)],
                                           res[, get(x)])})
  sd_e <- sapply(obj_nodes, function(x){sd_error(obj_dt[, get(x)], 
                                                 res[, get(x)])})

  if(verbose){
    sapply(obj_nodes,
           function(x){plot(ts(obj_dt[, get(x)]), ylab = x) +
                       lines(ts(res[, get(x)]), col="red")})
    cat("MAE:", fill = T)
    cat(mae, fill = T)
    cat("SD:", fill = T)
    cat(sd_e, fill = T)
  }

  return(res)
}

#' Performs inference in every row of a dataset with a DBN
#'
#' Generic method for predicting a dataset with a "dbn.fit" S3 objects. Calls 
#' \code{\link{predict_dt}} underneath.
#' @param object a "dbn.fit" object
#' @param ... additional parameters for the inference process
#' @return a data.table with the prediction results
#' @export
predict.dbn.fit <- function(object, ...){
   predict_dt(object, ...)
}

#' Performs approximate inference in a time slice of the dbn
#'
#' Given a bn.fit object and some variables, performs
#' particle inference over such variables in the net for a given time slice.
#' @param fit bn.fit object
#' @param variables variables to be predicted
#' @param particles a list with the provided evidence
#' @param n the number of particles to be used by bnlearn
#' @return the inferred particles
#' @keywords internal
approx_prediction_step <- function(fit, variables, particles, n = 50){
  if(length(particles) == 0)
    particles <- TRUE

  particles <- bnlearn::cpdist(fit, nodes = variables, evidence = particles, 
                                 method = "lw", n = n)
  particles <- as.list(apply(particles, 2, mean))

  return(particles)
}

#' Performs exact inference in a time slice of the dbn
#'
#' Given a bn.fit object and some variables, performs
#' exact MVN inference over such variables in the net for a given time slice.
#' @param fit list with the mu and sigma of the MVN model
#' @param variables variables to be predicted
#' @param evidence a list with the provided evidence
#' @return a list with the predicted mu and sigma
#' @keywords internal
exact_prediction_step <- function(fit, variables, evidence){
  if(length(evidence) == 0)
    evidence <- attr(fit,"mu")[bnlearn::root.nodes(fit)]
  
  res <- mvn_inference(attr(fit,"mu"), attr(fit,"sigma"), evidence)
  res$mu_p <- as.list(res$mu_p[,1])
  
  return(res)
}

#' Performs approximate inference forecasting with the GDBN over a dataset
#'
#' Given a bn.fit object, the size of the net and a dataset,
#' performs approximate forecasting with bnlearns cpdist function over the 
#' initial evidence taken from the dataset.
#' @param dt data.table object with the TS data
#' @param fit bn.fit object
#' @param obj_vars variables to be predicted
#' @param ini starting point in the dataset to forecast.
#' @param rep number of repetitions to be performed of the approximate inference
#' @param len length of the forecast
#' @param num_p number of particles to be used by bnlearn
#' @return a list with the mu results of the forecast
#' @keywords internal
approximate_inference <- function(dt, fit, obj_vars, ini, rep, len, num_p){
  var_names <- names(dt)
  vars_pred_idx <- grep("t_0", var_names)
  vars_subs_idx <- grep("t_1", var_names)
  vars_last_idx <- grep(paste0("t_", attr(fit, "size")-1), var_names)
  vars_pred <- var_names[vars_pred_idx]
  vars_subs <- var_names[vars_subs_idx]
  vars_prev <- var_names[-c(vars_pred_idx, vars_subs_idx)]
  vars_post <- var_names[-c(vars_pred_idx, vars_last_idx)]
  vars_ev <- var_names[-vars_pred_idx]
  
  test <- NULL
  
  for(i in 1:rep){
    evidence <- dt[ini, .SD, .SDcols = vars_ev]
    
    # Subsequent queries
    for(j in 1:len){
      particles <- approx_prediction_step(fit, vars_pred, as.list(evidence), num_p)
      if(length(vars_post) > 0)
        evidence[, (vars_prev) := .SD, .SDcols = vars_post]
      evidence[, (vars_subs) := particles[vars_pred]]
      
      temp <- particles[obj_vars]
      temp["exec"] <- i
      test <- rbindlist(list(test, temp))
    }
  }
  
  return(test)
}

#' Performs exact inference forecasting with the GDBN over a dataset
#'
#' Given a bn.fit object, the size of the net and a data.set,
#' performs exact forecasting over the initial evidence taken from the dataset.
#' @param dt data.table object with the TS data
#' @param fit bn.fit object
#' @param obj_vars variables to be predicted
#' @param ini starting point in the dataset to forecast.
#' @param len length of the forecast
#' @param prov_ev variables to be provided as evidence in each forecasting step
#' @return a list with the mu results of the forecast
#' @keywords internal
exact_inference <- function(dt, fit, obj_vars, ini, len, prov_ev){
  fit <- initial_attr_check(fit)

  var_names <- names(dt)
  vars_pred_idx <- grep("t_0", var_names)
  vars_subs_idx <- grep("t_1", var_names)
  vars_last_idx <- grep(paste0("t_", attr(fit, "size")-1), var_names)
  vars_pred <- var_names[vars_pred_idx]
  vars_prev <- var_names[-c(vars_pred_idx, vars_subs_idx)]
  vars_post <- var_names[-c(vars_pred_idx, vars_last_idx)]
  vars_ev <- var_names[-vars_pred_idx]
  vars_pred_crop <- vars_pred[!(vars_pred %in% prov_ev)]
  vars_subs_crop <- sub("t_0","t_1", vars_pred_crop)
  prov_ev_subs <- sub("t_0","t_1", prov_ev)

  test <- NULL
  evidence <- dt[ini, .SD, .SDcols = c(vars_ev, prov_ev)]

  for(j in 1:len){
    particles <- exact_prediction_step(fit, vars_pred, evidence)
    
    if(is.null(names(particles$mu_p)))
      names(particles$mu_p) <- obj_vars # If only 1 variable is obtained from the inference, no name is returned
        
    if(length(vars_post) > 0)
      evidence[, (vars_prev) := .SD, .SDcols = vars_post]
    evidence[, (vars_subs_crop) := particles$mu_p[vars_pred_crop]]
    if(!is.null(prov_ev)){
      evidence[, (prov_ev_subs) := .SD, .SDcols = prov_ev]
      evidence[, (prov_ev) := dt[ini + j, .SD, .SDcols = prov_ev]]
    }
    temp <- particles$mu_p[obj_vars]
    temp["exec"] <- 1
    test <- rbindlist(list(test, temp))
  }

  return(test)
}

#' Performs forecasting with the GDBN over a dataset
#'
#' Given a dbn.fit object, the size of the net and a folded dataset,
#' performs a forecast over the initial evidence taken from the dataset.
#' @param dt data.table object with the TS data
#' @param fit dbn.fit object
#' @param size number of time slices of the net. Deprecated, will be removed in the future
#' @param obj_vars variables to be predicted
#' @param ini starting point in the dataset to forecast.
#' @param len length of the forecast
#' @param rep number of times to repeat the approximate forecasting
#' @param num_p number of particles in the approximate forecasting
#' @param print_res if TRUE prints the mae and sd metrics of the forecast
#' @param plot_res if TRUE plots the results of the forecast
#' @param mode "exact" for exact inference, "approx" for approximate
#' @param prov_ev variables to be provided as evidence in each forecasting step
#' @return a list with the original time series values and the results of the forecast
#' @examples
#' size = 3
#' data(motor)
#' dt_train <- motor[200:900]
#' dt_val <- motor[901:1000]
#' obj <- c("pm_t_0")
#' net <- learn_dbn_struc(dt_train, size)
#' f_dt_train <- fold_dt(dt_train, size)
#' f_dt_val <- fold_dt(dt_val, size)
#' fit <- fit_dbn_params(net, f_dt_train, method = "mle-g")
#' res <- suppressWarnings(forecast_ts(f_dt_val, fit, 
#'         obj_vars = obj, len = 10, print_res = FALSE, plot_res = FALSE))
#' @export
forecast_ts <- function(dt, fit, size = NULL, obj_vars, ini = 1, len = dim(dt)[1]-ini,
                        rep = 1, num_p = 50, print_res = TRUE, plot_res = TRUE,
                        mode = "exact", prov_ev = NULL){
  initial_folded_dt_check(dt)
  initial_dbnfit_check(fit)
  numeric_arg_check(ini, len, rep, num_p)
  character_arg_check(obj_vars)
  null_or_character_arg_check(prov_ev)
  obj_prov_check(obj_vars, prov_ev)
  logical_arg_check(print_res, plot_res)
  initial_mode_check(mode)
  
  if(!is.null(size)) # Retain deprecation warning until version 0.8.0
    warning("The size argument is deprecated and  will be removed in the future. It is already stored inside the 'dbn.fit' object after learning the parameters of the network.")
  
  dt <- as.data.table(dt)

  exec_time <- Sys.time()
  
  if(mode == "exact")
    test <- exact_inference(dt, fit, obj_vars, ini, len, prov_ev)
  else if (mode == "approx")
    test <- approximate_inference(dt, fit, obj_vars, ini, rep, len, num_p)

  exec_time <- exec_time - Sys.time()

  metrics <- lapply(obj_vars, function(x){
    test[, mae_by_col(dt[ini:(ini+len-1)], .SD), .SDcols = x, by = "exec"]})
  metrics <- sapply(metrics, function(x){mean(x$V1)})
  names(metrics) <- obj_vars

  if(print_res){
    cat(paste0("Time difference of ", round(exec_time, 6), " secs"), fill = T)
    print_metrics(metrics, obj_vars)
  }
  
  if(plot_res)
    plot_results(dt[ini:(ini+len-1)], test, obj_vars)

  return(list(orig = dt[ini:(ini+len-1)], pred = test))
}

#' Performs exact inference smoothing with the GDBN over a dataset
#'
#' Given a bn.fit object, the size of the net and a dataset,
#' performs exact smoothing over the initial evidence taken from the dataset.
#' Take notice that the smoothing is done backwards in time, as opposed to
#' forecasting.
#' @param dt data.table object with the TS data
#' @param fit bn.fit object
#' @param obj_vars variables to be predicted. Should be in the oldest time step
#' @param ini starting point in the dataset to smooth
#' @param len length of the smoothing
#' @param prov_ev variables to be provided as evidence in each forecasting step. Should be in the oldest time step
#' @return a list with the results of the inference backwards
#' @keywords internal
exact_inference_backwards <- function(dt, fit, obj_vars, ini, len, prov_ev){
  fit <- initial_attr_check(fit)
  
  var_names <- names(dt)
  vars_pred_idx <- grep(paste0("t_", attr(fit, "size")-1), var_names)
  vars_subs_idx <- grep(paste0("t_", attr(fit, "size")-2), var_names)
  vars_last_idx <- grep("t_0", var_names)
  vars_pred <- var_names[vars_pred_idx] # In this case, we predict the oldest time slice, because we are going backwards 
  vars_prev <- var_names[-c(vars_pred_idx, vars_subs_idx)]
  vars_post <- var_names[-c(vars_pred_idx, vars_last_idx)]
  vars_ev <- var_names[-vars_pred_idx]
  vars_pred_crop <- vars_pred[!(vars_pred %in% prov_ev)]
  vars_subs_crop <- sub(paste0("t_", attr(fit, "size")-1), paste0("t_", attr(fit, "size")-2), vars_pred_crop)
  prov_ev_subs <- sub(paste0("t_", attr(fit, "size")-1), paste0("t_", attr(fit, "size")-1), prov_ev)
  
  test <- NULL
  evidence <- dt[ini, .SD, .SDcols = c(vars_ev, prov_ev)]
  
  for(j in 1:len){
    particles <- exact_prediction_step(fit, vars_pred, evidence)
    
    if(is.null(names(particles$mu_p)))
      names(particles$mu_p) <- obj_vars
    
    if(length(vars_post) > 0)
      evidence[, (vars_prev) := .SD, .SDcols = vars_post]
    evidence[, (vars_subs_crop) := particles$mu_p[vars_pred_crop]]
    if(!is.null(prov_ev)){
      evidence[, (prov_ev_subs) := .SD, .SDcols = prov_ev]
      evidence[, (prov_ev) := dt[ini + j, .SD, .SDcols = prov_ev]]
    }
    temp <- particles$mu_p[obj_vars]
    temp["exec"] <- 1
    test <- rbindlist(list(temp, test))
  }
  
  return(test)
}

#' Performs smoothing with the GDBN over a dataset
#'
#' Given a dbn.fit object, the size of the net and a folded dataset,
#' performs a smoothing of a trajectory. Smoothing is the opposite of 
#' forecasting: given a starting point, predict backwards in time to obtain
#' the time series that generated that point. 
#' @param dt data.table object with the TS data
#' @param fit dbn.fit object
#' @param size number of time slices of the net. Deprecated, will be removed in the future
#' @param obj_vars variables to be predicted. Should be in the oldest time step
#' @param ini starting point in the dataset to smooth
#' @param len length of the smoothing
#' @param print_res if TRUE prints the mae and sd metrics of the smoothing
#' @param plot_res if TRUE plots the results of the smoothing
#' @param prov_ev variables to be provided as evidence in each smoothing step. Should be in the oldest time step
#' @return a list with the original values and the results of the smoothing
#' @examples
#' size = 3
#' data(motor)
#' dt_train <- motor[200:900]
#' dt_val <- motor[901:1000]
#' obj <- c("pm_t_2")
#' net <- learn_dbn_struc(dt_train, size)
#' f_dt_train <- fold_dt(dt_train, size)
#' f_dt_val <- fold_dt(dt_val, size)
#' fit <- fit_dbn_params(net, f_dt_train, method = "mle-g")
#' res <- suppressWarnings(smooth_ts(f_dt_val, fit, 
#'         obj_vars = obj, len = 10, print_res = FALSE, plot_res = FALSE))
#' @export
smooth_ts <- function(dt, fit, size = NULL, obj_vars, ini = dim(dt)[1], len = ini-1,
                      print_res = TRUE, plot_res = TRUE, prov_ev = NULL){
  initial_folded_dt_check(dt)
  initial_dbnfit_check(fit)
  numeric_arg_check(ini, len)
  character_arg_check(obj_vars)
  null_or_character_arg_check(prov_ev)
  obj_prov_check(obj_vars, prov_ev)
  logical_arg_check(print_res, plot_res)
  
  if(!is.null(size)) # Retain deprecation warning until version 0.8.0
    warning("The size argument is deprecated and  will be removed in the future. It is already stored inside the 'dbn.fit' object after learning the parameters of the network.")
  
  dt <- as.data.table(dt)
  
  exec_time <- Sys.time()
  
  test <- exact_inference_backwards(dt, fit, obj_vars, ini, len, prov_ev)
  
  exec_time <- exec_time - Sys.time()
  
  metrics <- lapply(obj_vars, function(x){
    test[, mae_by_col(dt[(ini-len+1):ini], .SD), .SDcols = x, by = "exec"]})
  metrics <- sapply(metrics, function(x){mean(x$V1)})
  names(metrics) <- obj_vars
  
  if(print_res){
    cat(exec_time, fill = T)
    print_metrics(metrics, obj_vars)
  }
  
  if(plot_res)
    plot_results(dt[(ini-len+1):ini], test, obj_vars)
  
  return(list(orig = dt[(ini-len+1):ini], pred = test))
}
