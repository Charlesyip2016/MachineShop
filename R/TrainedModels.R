#' Selected Model
#'
#' Model selection from a candidate set.
#'
#' @param ... \link[=models]{model} functions, function names, calls, or vectors
#'   of these to serve as the candidate set from which to select, such as that
#'   returned by \code{\link{expand_model}}.
#' @param control \link[=controls]{control} function, function name, or call
#'   defining the resampling method to be employed.
#' @param metrics \link[=metrics]{metric} function, function name, or vector of
#'   these with which to calculate performance.  If not specified, default
#'   metrics defined in the \link{performance} functions are used.  Model
#'   selection is based on the first calculated metric.
#' @param stat function or character string naming a function to compute a
#'   summary statistic on resampled metric values for model selection.
#' @param cutoff argument passed to the \code{metrics} functions.
#'
#' @details
#' \describe{
#'   \item{Response Types:}{\code{factor}, \code{numeric}, \code{ordered},
#'     \code{Surv}}
#' }
#'
#' @return \code{SelectedModel} class object that inherits from \code{MLModel}.
#'
#' @seealso \code{\link{fit}}, \code{\link{resample}}
#'
#' @examples
#' \donttest{
#' ## Requires prior installation of suggested package gbm and glmnet to run
#'
#' model_fit <- fit(sale_amount ~ ., data = ICHomes,
#'                  model = SelectedModel(GBMModel, GLMNetModel, SVMRadialModel))
#' (selected_model <- as.MLModel(model_fit))
#' summary(selected_model)
#' }
#'
SelectedModel <- function(..., control = MachineShop::settings("control"),
                          metrics = NULL,
                          stat = MachineShop::settings("stat.train"),
                          cutoff = MachineShop::settings("cutoff")) {

  models <- as.list(unlist(list(...)))
  model_names <- character()
  for (i in seq(models)) {
    models[[i]] <- getMLObject(models[[i]], class = "MLModel")
    name <- names(models)[i]
    model_names[i] <-
      if (!is.null(name) && nzchar(name)) name else models[[i]]@name
  }
  names(models) <- make.unique(model_names)

  new("SelectedModel",
      name = "SelectedModel",
      label = "Selected Model",
      response_types = Reduce(intersect,
                              map(slot, models, "response_types"),
                              init = .response_types),
      predictor_encoding = NA_character_,
      params = list(models = ListOf(models),
                    control = getMLObject(control, "MLControl"),
                    metrics = metrics, stat = stat, cutoff = cutoff)
  )

}

MLModelFunction(SelectedModel) <- NULL


.fit.SelectedModel <- function(x, inputs, ...) {
  models <- x@params$models
  trainbit <- resample_selection(models, identity, x@params, inputs,
                                 class = "SelectedModel")
  trainbit$grid <- tibble(Model = factor(seq(models)))
  model <- models[[trainbit$selected]]
  push(do.call(TrainBit, trainbit), fit(inputs, model = model))
}


#' Tuned Model
#'
#' Model tuning over a grid of parameter values.
#'
#' @param model \link[=models]{model} function, function name, or call defining
#'   the model to be tuned.
#' @param grid \link[=data.frame]{data frame} containing parameter values at
#'   which to evaluate a single model supplied to \code{models}, such as that
#'   returned by \code{\link{expand_params}}; the number of parameter-specific
#'   values to generate automatically if the model has a pre-defined grid; or a
#'   call to \code{\link{Grid}} or \code{\link{ParameterGrid}}.
#' @param fixed list of fixed parameter values to combine with those in
#'   \code{grid}.
#' @param control \link[=controls]{control} function, function name, or call
#'   defining the resampling method to be employed.
#' @param metrics \link[=metrics]{metric} function, function name, or vector of
#'   these with which to calculate performance.  If not specified, default
#'   metrics defined in the \link{performance} functions are used.  Model
#'   selection is based on the first calculated metric.
#' @param stat function or character string naming a function to compute a
#'   summary statistic on resampled metric values for model tuning.
#' @param cutoff argument passed to the \code{metrics} functions.
#'
#' @details
#' \describe{
#'   \item{Response Types:}{\code{factor}, \code{numeric}, \code{ordered},
#'     \code{Surv}}
#' }
#'
#' @return \code{TunedModel} class object that inherits from \code{MLModel}.
#'
#' @seealso \code{\link{fit}}, \code{\link{resample}}
#'
#' @examples
#' \donttest{
#' ## Requires prior installation of suggested package gbm to run
#' ## May require a long runtime
#'
#' # Automatically generated grid
#' model_fit <- fit(sale_amount ~ ., data = ICHomes,
#'                  model = TunedModel(GBMModel))
#' varimp(model_fit)
#' (tuned_model <- as.MLModel(model_fit))
#' summary(tuned_model)
#' plot(tuned_model, type = "l")
#'
#' # Randomly sampled grid points
#' fit(sale_amount ~ ., data = ICHomes,
#'     model = TunedModel(GBMModel, grid = Grid(length = 1000, random = 5)))
#'
#' # User-specified grid
#' fit(sale_amount ~ ., data = ICHomes,
#'     model = TunedModel(GBMModel,
#'                        grid = expand_params(n.trees = c(50, 100),
#'                                             interaction.depth = 1:2,
#'                                             n.minobsinnode = c(5, 10))))
#' }
#'
TunedModel <- function(model, grid = MachineShop::settings("grid"),
                       fixed = NULL, control = MachineShop::settings("control"),
                       metrics = NULL,
                       stat = MachineShop::settings("stat.train"),
                       cutoff = MachineShop::settings("cutoff")) {

  if (missing(model)) {
    model <- NULL
  } else {
    model <- if (is(model, "MLModel")) fget(model@name) else fget(model)
    stopifnot(is(model, "MLModelFunction"))
  }

  grid <- if (is(grid, "numeric")) {
    Grid(grid)
  } else if (identical(grid, "Grid") || identical(grid, Grid)) {
    Grid()
  } else if (is(grid, "Grid")) {
    grid
  } else if (is(grid, "parameters")) {
    ParameterGrid(grid)
  } else if (is(grid, "data.frame")) {
    as_tibble(grid)
  } else {
    stop("'grid' must be a grid length, Grid or ParameterGrid object, ",
         "or data frame")
  }

  fixed <- as_tibble(fixed)
  if (nrow(fixed) > 1) stop("only single values allowed for fixed parameters")

  new("TunedModel",
      name = "TunedModel",
      label = "Grid Tuned Model",
      response_types =
        if (is.null(model)) .response_types else model()@response_types,
      predictor_encoding = NA_character_,
      params = list(model = model, grid = grid, fixed = fixed,
                    control = getMLObject(control, "MLControl"),
                    metrics = metrics, stat = stat, cutoff = cutoff)
  )

}

MLModelFunction(TunedModel) <- NULL


.fit.TunedModel <- function(x, inputs, ...) {
  params <- x@params
  grid <- as.grid(params$grid, fixed = params$fixed,
                  inputs, model = getMLObject(params$model, "MLModel"))
  models <- expand_model(list(params$model, grid))
  trainbit <- resample_selection(models, identity, params, inputs,
                                 class = "TunedModel")
  trainbit$grid <- tibble(Model = grid)
  model <- models[[trainbit$selected]]
  push(do.call(TrainBit, trainbit), fit(inputs, model = model))
}
