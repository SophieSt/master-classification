# Classify using multiclass gradient boosting method.
library(xgboost)
library(caret)
source("utils/load-data.r")
source("utils/accuracy-statistics.r")

OutputDir = "../data/"

AllData = LoadClassificationData()
PureLabels = AllData@data[AllData@data$pure,]$dominant
ValidationData = LoadValidationData()
ImpureValidation = ValidationData@data[!AllData@data$pure,]
TrainData = LoadTrainingData()

# Create an evaluation function so we can see RMSEs in progress
MGB = function(filename = paste0(OutputDir, "stat-gradientboost.csv"), exclude=c(), ...)
{
    PureData = TrainData@data[AllData@data$pure,GetTrainingNames(exclude=exclude)]
    ImpureData = TrainData@data[!AllData@data$pure,GetTrainingNames(exclude=exclude)]

    TrainMatrix = xgb.DMatrix(as.matrix(PureData), label=as.numeric(PureLabels)-1)
    set.seed(0xfadedad)
    Model = xgboost(TrainMatrix, objective="multi:softprob", num_class = 9, ...)
    
    PredRaw = predict(Model, newdata=as.matrix(ImpureData))
    Prediction = matrix(PredRaw, byrow=TRUE, ncol=9, dimnames=list(list(), levels(PureLabels)))
    Prediction = data.frame(Prediction)[names(ImpureValidation)]*100
    # 21.78, amazing, but at a cost of range compression
    plot(unlist(Prediction), unlist(ImpureValidation))
    AST = AccuracyStatTable(Prediction, ImpureValidation)
    print(AST)
    write.csv(AST, filename)
}

# Unoptimised
MGB(nrounds=14, filename = paste0(OutputDir, "stat-gradientboost-unoptimised.csv"))
# 21.21
MGB(nrounds=5, exclude=c("is.water", "osavi", "aspect", "lswi", "swir", "height"))
# Optimised
MGB(nrounds=14, params=list(eta=0.05, max_depth=7))
# Note: pure fuzz here gets 25.43! Less than 27 when using all samples.
