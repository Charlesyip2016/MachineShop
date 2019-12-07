#' Combine MachineShop Objects
#'
#' Combine one or more \pkg{MachineShop} objects of the same class.
#'
#' @name combine
#' @rdname combine-methods
#'
#' @param ... named or unnamed \link{calibration}, \link{confusion},
#'   \link[=curves]{performance curve}, \link{lift}, \link{summary}, or
#'   \link{resample} results.  Curves must have been generated with the same
#'   performance \link{metrics} and resamples with the same resampling
#'   \link[=controls]{control}.
#' @param e1,e2 objects.
#'
#' @return Object of the same class as the arguments.
#'
NULL


c.BinomialVariate <- function(...) {
  args <- list(...)
  if (all(mapply(is, args, "BinomialVariate"))) {
    structure(do.call(rbind, args), class = "BinomialVariate")
  } else {
    NextMethod()
  }
}


#' @rdname combine-methods
#'
c.Calibration <- function(...) {
  args <- list(...)
  if (all(mapply(is, args, "Calibration"))) {

    smoothed <- args[[1]]@smoothed
    if (!all(sapply(args, function(x) identical(x@smoothed, smoothed)))) {
      stop("Calibration arguments are a mix of smoothed and binned curves")
    }

    df <- do.call(append, set_model_names(args))
    rownames(df) <- NULL
    Calibration(df, smoothed = smoothed)

  } else {
    NextMethod()
  }
}


#' @rdname combine-methods
#'
c.ConfusionList <- function(...) {
  args <- list(...)
  is_valid <- function(x) is(x, "ConfusionList") || is(x, "ConfusionMatrix")
  if (all(sapply(args, is_valid))) {

    conf_list <- list()
    for (i in seq(args)) {
      x <- args[[i]]
      if (is(x, "ConfusionMatrix")) x <- list("Model" = x)
      arg_name <- names(args)[i]
      if (!is.null(arg_name) && nzchar(arg_name)) {
        names(x) <- rep(arg_name, length(x))
      }
      conf_list <- c(conf_list, x)
    }
    names(conf_list) <- make.unique(names(conf_list))

    ConfusionList(conf_list)

  } else {
    NextMethod()
  }
}


#' @rdname combine-methods
#'
c.ConfusionMatrix <- function(...) {
  args <- list(...)
  args[[1]] <- ConfusionList(ListOf(args[1]))
  if (is.null(names(args)[1])) names(args)[1] <- "Model"
  do.call(c, args)
}


#' @rdname combine-methods
#'
c.Curves <- function(...) {
  args <- list(...)
  class <- class(args[[1]])
  if (all(mapply(is, args, class))) {

    metrics <- args[[1]]@metrics
    if (!all(sapply(args, function(x) identical(x@metrics, metrics)))) {
      stop(class, " arguments have different metrics")
    }

    df <- do.call(append, set_model_names(args))
    rownames(df) <- NULL
    do.call(class, list(df, metrics = metrics))

  } else {
    NextMethod()
  }
}


c.DiscreteVariate <- function(...) {
  args <- list(...)
  x <- NextMethod()
  class <- class(args[[1]])
  if (all(mapply(is, args, class))) {
    new(class, x,
        min = min(sapply(args, slot, name = "min")),
        max = max(sapply(args, slot, name = "max")))
  } else {
    x
  }
}


#' @rdname combine-methods
#'
c.Lift <- function(...) {
  NextMethod()
}


#' @rdname combine-methods
#'
c.ListOf <- function(...) {
  args <- list(...)
  class <- class(args[[1]][[1]])[1]
  is_valid <- function(x) {
    is(x, "ListOf") && is(x[[1]], class) && is(x[[1]], "vector")
  }
  if (all(sapply(args, is_valid))) {
    x <- list()
    for (i in seq(args)) {
      name <- names(args)[i]
      if (!is.null(name) && nzchar(name)) {
        names(args[[i]]) <- rep(name, length(args[[i]]))
      }
      x <- c(x, args[[i]])
    }
    if (!is.null(names(x))) names(x) <- make.unique(names(x))
    ListOf(x)
  } else {
    NextMethod()
  }
}


c.Performance <- function(...) {
  args <- list(...)
  if (all(mapply(is, args, "Performance"))) {
    if (length(args) > 1) {

      names <- dimnames(args[[1]])[1:2]
      if (!all(sapply(args, function(x) identical(dimnames(x)[1:2], names)))) {
        stop("Performance objects have different row or column names")
      }

      Performance(abind(args, along = 3))

    } else {
      args[[1]]
    }
  } else {
    NextMethod()
  }
}


#' @rdname combine-methods
#'
c.Resamples <- function(...) {
  args <- list(...)
  if (all(mapply(is, args, "Resamples"))) {

    control <- args[[1]]@control
    if (!all(sapply(args, function(x) identical(x@control, control)))) {
      stop("Resamples arguments have different control structures")
    }

    strata <- args[[1]]@strata
    if (!all(sapply(args, function(x) identical(x@strata, strata)))) {
      stop("Resamples arguments have different strata variables")
    }

    df <- do.call(append, set_model_names(args))
    rownames(df) <- NULL
    Resamples(df, control = control, strata = strata)

  } else {
    NextMethod()
  }
}


c.SurvMatrix <- function(...) {
  args <- list(...)
  class <- class(args[[1]])
  if (all(mapply(is, args, class))) {
    times <- args[[1]]@times
    if (!all(sapply(args, function(x) identical(x@times, times)))) {
      stop(class, " arguments have different times")
    }
    new(class, do.call(rbind, args), times = times)
  } else {
    NextMethod()
  }
}


c.TrainBits <- function(...) {
  args <- list(...)
  if (all(mapply(is, args, "TrainBits"))) {
    if (length(args) > 1) {

      grid <- do.call(append, lapply(args, slot, name = "grid"))

      values_list <- lapply(args, slot, name = "values")
      values <- unlist(values_list)
      names(values) <- paste0(names(values), ".",
                              rep(seq(args), lengths(values_list)))

      performance <- do.call(c, lapply(args, slot, name = "performance"))
      dimnames(performance)[[3]] <- names(values)

      metric <- args[[1]]@metric
      if (!all(sapply(args, function(x) identical(x@metric, metric)))) {
        stop("TrainBits objects have different metric functions")
      }

      selected <- ifelse(metric@maximize, which.max, which.min)(values)
      selected_names <- names(sapply(args, slot, name = "selected"))
      if (!all(selected_names == selected_names[1])) {
        stop("TrainBits objects have difference selected metric names")
      }
      names(selected) <- selected_names[1]

      TrainBits(grid = grid, performance = performance, selected = selected,
                values = values, metric = metric)

    } else {
      args[[1]]
    }
  } else {
    NextMethod()
  }
}


#' @rdname combine-methods
#'
setMethod("+", c("SurvMatrix", "SurvMatrix"),
  function(e1, e2) {
    x <- callNextMethod()
    class <- class(e1)
    if (class(e2) == class && all(e1@times == e2@times)) {
      new(class, x, times = e1@times)
    } else x
  }
)