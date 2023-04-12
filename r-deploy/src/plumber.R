# plumber.R
# This script will be deployed to a managed endpoint to do the model scoring

# REQUIRED
# When you deploy a model as an online endpoint, Azure Machine Learning mounts your model
# to your endpoint. Model mounting enables you to deploy new versions of the model without
# having to create a new Docker image.

model_dir <- Sys.getenv("AZUREML_MODEL_DIR")

# REQUIRED
# This reads the serialized model with its respecive predict/score method you 
# registered. The loaded load_model object is a raw binary object.
load_model <- readRDS(paste0(model_dir, "/models/crate.bin"))

# REQUIRED
# You have to unserialize the load_model object to make it its function
scoring_function <- unserialize(load_model)

# REQUIRED
# << Readiness route vs. liveness route >>
# An HTTP server defines paths for both liveness and readiness. A liveness route is used to
# check whether the server is running. A readiness route is used to check whether the 
# server's ready to do work. In machine learning inference, a server could respond 200 OK 
# to a liveness request before loading a model. The server could respond 200 OK to a
# readiness request only after the model has been loaded into memory.

#* Liveness check
#* @get /live
function() {
  "alive"
}

#* Readiness check
#* @get /ready
function() {
  "ready"
}

# << The scoring function >>
# This is the function that is deployed as a web API that will score the model
# Make sure that whatever you are producing as a score can be converted 
# to JSON to be sent back as the API response
# in the example here, forecast_horizon (the number of time units to forecast) is the input to scoring_function.  
# the output is a tibble
# we are converting some of the output types so they work in JSON


#* @param forecast_horizon 
#* @post /score
function(forecast_horizon) {
  scoring_function(as.numeric(forecast_horizon)) |> 
    tibble::as_tibble() |> 
    dplyr::transmute(period = as.character(yr_wk),
                     dist = as.character(logmove),
                     forecast = .mean) |> 
    jsonlite::toJSON()
}