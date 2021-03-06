setClass(
  "aws",
  representation(
    .Data = "list",
    y = "array",
    dy = "numeric",
    nvec = "integer",
    x = "matrix",
    ni = "array",
    mask = "logical",
    theta = "array",
    mae = "numeric",
    psnr = "numeric",
    var = "numeric",
    xmin = "numeric",
    xmax = "numeric",
    wghts = "numeric",
    degree = "integer",
    hmax  = "numeric",
    #
    hseq = "numeric",
    sigma2  = "numeric",
    # error variance
    scorr = "numeric",
    # spatial correlation
    family = "character",
    shape = "numeric",
    lkern  = "integer",
    lambda = "numeric",
    ladjust = "numeric",
    aws = "logical",
    memory = "logical",
    homogen = "logical",
    earlystop = "logical",
    varmodel = "character",
    vcoef = "numeric",
    call = "call"
  )
)
setClass(
  "awssegment",
  representation(
    .Data = "list",
    y = "array",
    dy = "numeric",
    x = "numeric",
    ni = "array",
    mask = "logical",
    segment = "array",
    level = "numeric",
    delta = "numeric",
    theta = "array",
    mae = "numeric",
    var = "numeric",
    xmin = "numeric",
    xmax = "numeric",
    wghts = "numeric",
    degree = "integer",
    hmax  = "numeric",
    #
    sigma2  = "numeric",
    # error variance
    scorr = "numeric",
    # spatial correlation
    family = "character",
    shape = "numeric",
    lkern  = "integer",
    lambda = "numeric",
    ladjust = "numeric",
    aws = "logical",
    memory = "logical",
    homogen = "logical",
    earlystop = "logical",
    varmodel = "character",
    vcoef = "numeric",
    call = "call"
  )
)
setClass(
  "kernsm",
  representation(
    .Data = "list",
    y = "array",
    dy = "numeric",
    x = "numeric",
    h = "numeric",
    kern = "character",
    m = "integer",
    nsector = "integer",
    sector = "integer",
    symmetric = "logical",
    yhat = "array",
    vred = "numeric",
    call = "call"
  )
)
setClass(
  "ICIsmooth",
  representation(
    .Data = "list",
    y = "array",
    dy = "numeric",
    x = "numeric",
    hmax = "numeric",
    hinc = "numeric",
    thresh = "numeric",
    kern = "character",
    m = "integer",
    nsector = "integer",
    sector = "integer",
    symmetric = "logical",
    yhat = "array",
    vhat = "array",
    hbest = "array",
    sigma = "numeric",
    call = "call"
  )
)
kernsmobj <-  function(y,
           x = numeric(0),
           h,
           kern,
           m,
           nsector,
           sector,
           symmetric,
           yhat,
           vred,
           call,
           data = list(NULL)) {
    dy <- if (is.null(dim(y)))
      length(y)
    else
      dim(y)
    invisible(
      new(
        "kernsm",
        .Data = data,
        y = array(y, dy),
        dy = dy,
        x = as.numeric(x),
        h = as.numeric(h),
        kern = as.character(kern),
        m = as.integer(m),
        nsector = as.integer(nsector),
        sector = as.integer(sector),
        symmetric = as.logical(symmetric),
        yhat = array(yhat, dy),
        vred = vred,
        call = call
      )
    )
  }
ICIsmoothobj <-  function(y,
           x = numeric(0),
           h,
           hinc,
           thresh,
           kern,
           m,
           nsector,
           sector,
           symmetric,
           yhat,
           vhat,
           hbest,
           sigma,
           call,
           data = list(NULL)) {
    dy <- if (is.null(dim(y)))
      length(y)
    else
      dim(y)
    invisible(
      new(
        "ICIsmooth",
        .Data = data,
        y = array(y, dy),
        dy = dy,
        x = as.numeric(x),
        hmax = as.numeric(h),
        hinc = as.numeric(hinc),
        thresh = as.numeric(thresh),
        kern = as.character(kern),
        m = as.integer(m),
        nsector = as.integer(nsector),
        sector = if (is.null(sector))
          as.integer(0)
        else
          as.integer(sector),
        symmetric = as.logical(symmetric),
        yhat = array(yhat, dy),
        vhat = array(vhat, dy),
        hbest = array(hbest, dy),
        sigma = as.numeric(sigma),
        call = call
      )
    )
  }

awsobj <-  function(y,
           theta,
           var,
           hmax,
           sigma2,
           lkern,
           lambda,
           ladjust,
           aws,
           memory,
           call,
           hseq = NULL,
           homogen = FALSE,
           earlystop = FALSE,
           family = "Gaussian",
           nvec = 1L,
           degree = 0,
           x = matrix(0,1,1),
           ni = as.numeric(1),
           xmin = numeric(0),
           xmax = numeric(0),
           wghts = numeric(0),
           scorr = 0,
           mae = numeric(0),
           psnr = numeric(0),
           shape = numeric(0),
           varmodel = "Constant",
           vcoef = NULL,
           mask = logical(0),
           data = list(NULL)) {
    dy <- if (is.null(dim(y)))
      length(y)
    else
      dim(y)
    dy0 <- if(nvec==1) dy else dy[-1]
    invisible(
      new(
        "aws",
        .Data = data,
        y = array(y, dy),
        dy = dy,
        x = x,
        ni = array(ni, dy0),
        mask = as.logical(mask),
        nvec = as.integer(nvec),
        theta = array(theta, if (degree == 0)
          dy
          else
            c(dy, degree + 1)),
        mae = as.numeric(mae),
        psnr = as.numeric(psnr),
        var = as.numeric(var),
        xmin = as.numeric(xmin),
        xmax = as.numeric(xmax),
        wghts = as.numeric(wghts),
        degree = as.integer(degree),
        hmax  = as.numeric(hmax),
        #
        hseq = as.numeric(hseq),
        sigma2  = as.numeric(sigma2),
        # error variance
        scorr = as.numeric(scorr),
        # spatial correlation
        family = family,
        shape = as.numeric(shape),
        lkern  = as.integer(lkern),
        lambda = as.numeric(lambda),
        ladjust = as.numeric(ladjust),
        aws = aws,
        memory = memory,
        homogen = homogen,
        earlystop = earlystop,
        varmodel = varmodel,
        vcoef = if (is.null(vcoef))
          mean(sigma2)
        else
          vcoef,
        call = call
      )
    )
  }
  awssegmentobj <- function(y,
           theta,
           segment,
           var,
           level,
           delta,
           hmax,
           sigma2,
           lkern,
           lambda,
           ladjust,
           aws,
           memory,
           call,
           hseq = NULL,
           homogen = FALSE,
           earlystop = FALSE,
           family = "Gaussian",
           degree = 0,
           x = numeric(0),
           ni = as.integer(1),
           xmin = numeric(0),
           xmax = numeric(0),
           wghts = numeric(0),
           scorr = 0,
           mae = numeric(0),
           shape = numeric(0),
           varmodel = "Constant",
           vcoef = NULL,
           mask = logical(0),
           data = list(NULL)) {
    dy <- if (is.null(dim(y)))
      length(y)
    else
      dim(y)
    invisible(
      new(
        "awssegment",
        .Data = data,
        y = array(y, dy),
        dy = dy,
        x = as.numeric(x),
        ni = array(ni, dy),
        mask = as.logical(mask),
        segment = array(segment, dy),
        level = level,
        delta = delta,
        theta = array(theta, dy),
        mae = as.numeric(mae),
        var = as.numeric(var),
        xmin = as.numeric(xmin),
        xmax = as.numeric(xmax),
        wghts = as.numeric(wghts),
        degree = as.integer(degree),
        hmax  = as.numeric(hmax),
        sigma2  = as.numeric(sigma2),
        # error variance
        scorr = as.numeric(scorr),
        # spatial correlation
        family = family,
        shape = as.numeric(shape),
        lkern  = as.integer(lkern),
        lambda = as.numeric(lambda),
        ladjust = as.numeric(ladjust),
        aws = aws,
        memory = memory,
        homogen = homogen,
        earlystop = earlystop,
        varmodel = varmodel,
        vcoef = mean(sigma2),
        call = call
      )
    )
  }

awsdata <- function(awsobj, what) {
  what <- tolower(what)
  switch(
    what,
    "y" = array(awsobj@y, awsobj@dy),
    "data" = array(awsobj@y, awsobj@dy),
    "theta" = array(awsobj@theta, c(awsobj@dy, awsobj@degree +
                                      1)),
    "segment" = array(awsobj@segment, awsobj@dy),
    "est" = array(awsobj@theta, c(awsobj@dy)),
    "var" = array(awsobj@var, awsobj@dy),
    "sd" = array(sqrt(awsobj@var), awsobj@dy),
    "sigma2" = array(awsobj@sigma2, awsobj@dy),
    "mae" = awsobj@mae,
    "ni" = array(awsobj@ni, awsobj@dy),
    "mask" = array(awsobj@mask, awsobj@dy),
    "bi" = awsobj$bi,
    "bi2" = awsobj$bi2
  )
}
