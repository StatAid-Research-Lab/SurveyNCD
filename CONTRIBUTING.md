# Contributing to SurveyNCD

Thank you for your interest in SurveyNCD. Bug reports, questions,
documentation fixes and code contributions are all welcome.

## Reporting a problem or asking a question

Open an issue at
<https://github.com/StatAid-Research-Lab/SurveyNCD/issues>. For a bug,
please include:

1.  a **minimal reproducible example** (simulated data is fine; please
    do not post restricted survey microdata),
2.  the output of
    [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) and
    `packageVersion("SurveyNCD")`,
3.  what you expected and what happened.

## Proposing a change

1.  Open an issue first for anything larger than a typo, so the approach
    can be agreed.
2.  Fork the repository and create a branch.
3.  Make your change with roxygen2 documentation
    (`devtools::document()`), and add or update tests in
    `tests/testthat/`. A change to an estimator should come with an
    independent check (for example a hand calculation or a comparison
    with another package).
4.  Run `devtools::test()` and `devtools::check()`; both should pass
    without new warnings or notes.
5.  Add a line to `NEWS.md` and open a pull request.

## Scope

SurveyNCD builds on the `survey` package for design-based inference and
aims to stay small and well tested. New features that need design-based
variance estimation should use `survey` rather than reimplement it.
Contributions for other self-reported-indicator workflows (for example
risk-factor co-occurrence or care-cascade calculations) are welcome as
issues for discussion first.

## Support and maintenance

SurveyNCD is maintained by Sujon Mia (StatAid Research Lab). Support is
on a best-effort basis; the aim is to acknowledge issues and pull
requests within about two weeks. Releases are tagged on GitHub and
published on CRAN, and changes are recorded in `NEWS.md`.

## Conduct

Please be respectful and constructive. This project follows the spirit
of the [Contributor
Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/);
unacceptable behaviour can be reported to the maintainer at the address
in `DESCRIPTION`.
