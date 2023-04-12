# Source Required Helper-Files, Create Command-Line-Parser Object

# source the azureml_utils.R script which is needed to use the MLflow back end with R
source("azureml_utils.R")
library(carrier)

# load your packages here. Make sure that they are installed in the container.
#library(vars)


# parse the command line arguments.
library(optparse)
parser <- OptionParser()

parser <- add_option(
  parser,
  "--data_file",
  type = "character",
  action = "store",
  default = "data/mydata.csv"
)
parser <- add_option(
  parser,
  "--output_dir",
  type = "character",
  action = "store",
  default = "./outputs"
)

# Fetch the actual arguments passed from the Job Command
args <- parse_args(parser)

if (!dir.exists(args$output_dir)) {
  dir.create(args$output_dir)
}

# log models and parameters to MLflow
mlflow_start_run()

##
YOUR R-Code here
##


mlflow_log_model(
  model = crated_cust_load_fcst_model, # the crate model object
  artifact_path = "models" # a path to save the model object to
  )

mlflow_log_param('data file', args$data_file)

# mlflow_end_run() - causes an error, do not include mlflow_end_run()


## -------------------------------------------------------------------------- ##

