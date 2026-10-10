# SurveyNCD: submission guide

Prepared 10 October 2026. This guide covers two free (no-fee) venues: **The R Journal**, where you can submit once the
steps below are done, and the **Journal of Open Source Software (JOSS)**, which you can submit to after about
21 December 2026, and only once the package has been used in research.

---

## 0. Status at a glance

| Item | Status |
|---|---|
| Package 0.2.0: design helpers, `survey_prevalence()`, multimorbidity patterns, age standardisation, missing-answer bounds, corrected concentration indices, curves, SII/RII, `ncd_table()`, `autoplot()`, NHANES vignette, tie fix, simulated datasets | Done. 154 tests pass; `R CMD check` 0 errors, 0 warnings (offline sandbox) |
| Simulated data with a known population (`ncd_survey`, `child_anthro`, `data-raw/`) | Done |
| Full analysis using all 10 functions, with 8 tables and 6 figures (`analysis/`) | Done. Reproduces in about 6 minutes |
| Validation against `rineq`, design bootstrap, tie check, 1,000-sample simulation | Done |
| R Journal article (`rjournal/`, 13 pages, official template) | Done except the `[TODO]` items in section 3 |
| JOSS paper (`paper/`, about 1,120 words, 2 figures) | Done except the `[TODO]` items; **blocked** by JOSS screening rules (section 6) |
| **Submit 0.2.0 to CRAN** | **You** (section 2). The R Journal requires the described version to be on CRAN |
| AI disclosure, funding statement, affiliation | **You** (section 3) |

---

## 1. Which journal, and in what order

**Submit to The R Journal first.** It publishes articles about R packages (the package must be on CRAN or
Bioconductor), allows up to 20 pages with tables and figures, and has no six-month-history or research-use gate.
It is open access, and its submission page lists no author fee.

**Do not submit the same article to two journals at once.** The R Journal requires that the article is "not published
or submitted elsewhere". A JOSS paper describes the same software, so treat the two as sequential:

- If the R Journal accepts, a later JOSS submission adds little; if you still make one, declare the R Journal article
  to JOSS as a related publication.
- If you decide on JOSS instead, wait for its gates (section 6) and do not submit the R Journal article in the meantime.

Another no-fee option for a longer methods-and-software paper is the *Journal of Statistical Software*. Its bar is
higher and reviews are long, so check its current scope and policies before choosing it.

---

## 2. Release SurveyNCD 0.2.0 (needed before the R Journal submission)

1. **Put the work on GitHub.** The easiest route is the git bundle, which contains the whole branch with its history.
   From your local clone of the repository:
   ```sh
   git fetch /path/to/SurveyNCD-v0.2.0.bundle feature/v0.2.0-toolkit:feature/v0.2.0-toolkit
   git push origin feature/v0.2.0-toolkit
   ```
   Then open a pull request on GitHub from `feature/v0.2.0-toolkit` into `master`, review it, and merge it.
   Alternatives: `git am patches/*.patch` on a new branch, or unzip `SurveyNCD-0.2.0-submission-ready.zip` over your
   working copy. (If you install the Claude GitHub App for the StatAid-Research-Lab organisation, Claude can push the
   branch and open the pull request for you next time.)
2. **Check locally** (Windows R 4.6, as you used for CRAN):
   ```r
   install.packages(c("sf", "xgboost", "rineq", "srvyr", "knitr", "rmarkdown"))
   devtools::document()      # regenerates Rd files with your roxygen2 version (they were built with 7.3.1 here)
   devtools::check(args = "--as-cran")
   devtools::check_win_devel()   # results arrive by e-mail
   ```
   Aim for 0 errors and 0 warnings. A "New maintainer" or spelling note is acceptable if explained.
3. **Fill in `cran-comments.md`** (the two `[TODO]` lines: test environments and check results).
4. **Submit**: `devtools::submit_cran()`. Confirm the e-mail link CRAN sends. Wait for acceptance, usually a few
   days to two weeks.
5. **Tag the release** on GitHub: Releases, then "Draft a new release", tag `v0.2.0`, with the NEWS entry as the notes.
6. **Archive with a DOI (optional but recommended)**: log in to zenodo.org with GitHub, enable the
   `SurveyNCD` repository, then publish the `v0.2.0` release. Zenodo mints a DOI you can cite and add to
   `CITATION.cff`.

---

## 3. Items only you can complete

These are marked `[TODO]` in `rjournal/mia.tex` and `paper/paper.md`:

1. **AI disclosure.** You told me Claude Sonnet 5.5 was used for the package code. Add what kind of help it gave
   (writing functions, refactoring, debugging) and whether tests or documentation were AI-assisted. The October 2026
   work (simulation, analysis scripts, papers, fix, datasets) was done with Claude and is already described.
   Add the sentence "the author reviewed, ran and verified all code and results and takes responsibility for them"
   **only if it is true**. Be ready to explain every design decision in your own words, because reviewers will ask.
2. **Funding.** Name the funder or write "No specific funding was received."
3. **Affiliation.** Confirm that listing "Department of Statistics, Jagannath University" is appropriate now that you
   have graduated. If not, use "StatAid Research Lab, Dhaka, Bangladesh" alone.
4. **Acknowledgement.** Confirm that Professor Md. Atiqul Islam agrees to be acknowledged.
5. **Read the whole article and paper once** as their author: you must stand behind every sentence.

---

## 4. Rebuild and verify the R Journal article

From the package source root, after installing SurveyNCD 0.2.0 from CRAN:

```sh
Rscript analysis/run_all.R          # regenerates analysis/output/ and copies figures/tables into rjournal/
cd rjournal
pdflatex RJwrapper && bibtex RJwrapper && pdflatex RJwrapper && pdflatex RJwrapper
```

Note: `run_all.R` refreshes `rjournal/tables/` and `rjournal/figures/` automatically. With the fixed seeds the numbers
reproduce exactly; if you ever change the analysis, also update any number quoted in the article text.

Then check that:

- [ ] `RJwrapper.pdf` builds without errors and is no more than 20 pages (currently 13).
- [ ] The abstract is plain text and under 250 words (currently about 150).
- [ ] `mia.R` runs in a fresh R session from the submission folder in under 10 minutes.
- [ ] No `[TODO]` text remains anywhere: `grep -rn TODO rjournal/ paper/`.

---

## 5. Submit to The R Journal

1. **Build the submission zip** (must be under 10 MB). `rjournal_submission.zip` is already prepared with this layout;
   rebuild it after you finish section 3:
   ```
   RJwrapper.tex  RJournal.sty  RJwrapper.pdf
   mia.tex  mia.bib  mia.R  _Rpackages.txt
   figures/  tables/
   motivation-letter/motivation-letter.md   (or a PDF of it)
   analysis/  data-raw/      (needed by mia.R; includes the cached simulation)
   ```
2. **Motivating letter.** Review `motivation-letter/motivation-letter.md`, add your signature line, and optionally
   knit it to PDF.
3. **Submit** through the form linked from <https://journal.r-project.org/submissions.html>. Choose
   "Contributed research article". Upload the zip and give the GitHub URL.
4. **What happens next.** First a technical check (does it build and reproduce?), then a scope check, then peer review,
   which "might take several months". The verdict is accept, minor revision, major revision (each to be completed
   within three months) or reject. Answer reviewers point by point, change the package and article as needed, and
   release a new CRAN version if the code changes.

---

## 6. JOSS (later, if you choose it instead)

JOSS desk-rejects any submission that fails one of its screening gates. Status today:

| Gate | Status | What would satisfy it |
|---|---|---|
| More than 6 months of public history, with activity spread across it | Not before about **21 Dec 2026** | Keep committing real work regularly; tag releases |
| **Evidence of research use** | **Not met** | Use SurveyNCD in a real analysis (for example your MICS or STEPS studies) that becomes a preprint, thesis chapter or paper, or get documented use by another group |
| Open-source practice (single author: several indicators) | Largely met | CI, tests, NEWS, CONTRIBUTING, CITATION.cff, releases; add a few real issues and pull requests |
| Iterative development | Weak (bursts) | Ongoing commits through to submission |

When the gates are met: fill in the Research impact statement with the specific citations, complete the AI disclosure,
check that the `draft-pdf` GitHub Action builds `paper/paper.pdf`, then submit at <https://joss.theoj.org/papers/new>.

---

## 7. For graduate applications

- **Now:** "SurveyNCD (R package, CRAN, 2026), doi:10.32614/CRAN.package.SurveyNCD". Add the Zenodo DOI after
  section 2.6.
- **After you submit:** "Mia, S. SurveyNCD: Design-based multimorbidity, health-inequality and child-growth indicators
  from complex population surveys. *Submitted to The R Journal*, 2026."
- Write "under review" only once the journal confirms the article has passed its initial checks and gone to reviewers.
- Do not describe the simulated results as findings about any real population; they validate the software.

---

## 8. What was verified, and what was not

- Every number in both papers comes from code that ran in this preparation, with fixed seeds.
- References were checked against Crossref or OpenAlex. Page numbers are omitted for three references whose
  Crossref pages could not be retrieved (Barnett 2012, Lerman and Yitzhaki 1989, Lumley and Scott 2017); titles,
  years and DOIs were confirmed.
- The `rineq` comparison used rineq 0.0.2 from GitHub (CRAN has 0.3.0); the concentration-index formula is the
  same, but re-run `analysis/02_validation.R` with the CRAN version before you submit.
- `R CMD check` here ran on Linux with R 4.3.3 and no internet. Your own `--as-cran` check and win-builder run are
  required.
- The R Journal's site lists no author fee, but I could not find an explicit statement either way.
