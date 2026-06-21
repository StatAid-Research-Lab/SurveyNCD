## dev_setup.R -- developer workflow script (not part of the built package,
## see .Rbuildignore). Run this after editing anything in R/.

devtools::document()                 # regenerate NAMESPACE and man/*.Rd from roxygen comments
devtools::test()                     # run the testthat suite in tests/testthat/
devtools::check(args = "--as-cran")  # full CRAN-style check
devtools::install()                  # install the package locally
