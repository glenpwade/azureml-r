# Source Required Helper-Files, Create Command-Line-Parser Object

# Source the azureml_utils.R script which is needed to use the MLflow backend with R
source("azureml_utils.R")
# Add the carrier pkg so we can serialise it as a 'crate' for MLflow
library(carrier)

# load your required packages here. Make sure that they are installed in the container.
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
  "--train_percent",
  type = "numeric",
  action = "store",
  default = "67"
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
#  YOUR R-Code here!
#
# do all the data prep:

myData <- read.csv(args$data_file)
Obs <- NROW(myData)  # Get the total number of rows 
trainingRows <- Obs * args$train_percent/100
testRows <- obs - trainingRows
data_train <- myData[,1:trainingRows]
data_test <- myData[,(1+trainingRows):Obs]

# Train/Estimate model using Training subset:

# 1.  Convert data to time series:
Y <- ts(data_train["Returns"],start = c(1,2022),frequency = 12)
Y_L1 <- lag(Y, k=1)  # Lag 1 observation 

# 2. Construct a DataFrame for the model:
modData <- data.frame(Y,Y_L1,)
# 3. Estimate the model & forecast 1-step ahead
mod1 <- lm(Y~Y_L1,data = modData)
predict.lm(mod1)

# 4. Crate the estimate model to be used for forecasting:
crated_model <- crate(function(x)
{
  mod1 <- lm(Y~Y_L1,data = modData)
})


# 5. If estimation is not onerous, we can have the deployed model re-estimate every time it is called:
crated_model <- crate(function(x)
{
  Y <- ts(x,start = c(1,2022),frequency = 12)
  Y_L1 <- lag(Y, k=1)  # Lag 1 observation 
  
  # 2. Construct a DataFrame for the model:
  modData <- data.frame(Y,Y_L1,)
  # 3. Estimate the model & forecast 1-step ahead
  predict.lm(lm(Y~Y_L1,data = modData))
  
})
##

mlflow_log_model(
  model = crated_model, # the crated model object
  artifact_path = "models" # a path to save the model object to
  )

mlflow_log_param('data file', args$data_file)

# mlflow_end_run() - causes an error, do not include mlflow_end_run()


## -------------------------------------------------------------------------- ##

