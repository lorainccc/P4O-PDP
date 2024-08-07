library("tidyverse")

PDP_AR <- read.csv(
    "00306800leap_AR_IDENTIFIED_20240412.csv",
    stringsAsFactors = TRUE,
    na.strings = c("NA","UK","unknown")
    )

summary(PDP_AR)

PDP_AR <- read.csv(
    params$file,
    stringsAsFactors = TRUE,
    na.strings = c("NA","UK","unknown")
    )

summary(PDP_AR)

PDP_AR_parsed <- PDP_AR |>
    filter(Cohort.Term != "SUMMER") |>
    mutate(
        cohort_year_num = as.numeric(str_sub(Cohort, 1, 4)) + 1,
        five_years_after = cohort_year_num + 5,
        five_year_mark = as.factor(str_c(five_years_after - 1, "-", str_sub(five_years_after, 3, 5))),
        five_years_after_match = case_when(
            five_years_after > 2024 ~ 0,
            .default = 1
        ),
        five_years_status = case_when(
            five_years_after_match == 0 ~ "tracking period open",
            Years.of.Last.Enrollment.at.cohort.institution >= 5 ~ "still enrolled",
            Years.of.Last.Enrollment.at.other.institution >= 5 ~ "still enrolled",
            Years.to.Bachelors.at.cohort.inst. <= 4 & Years.to.Bachelors.at.cohort.inst. > 0 & Years.to.Associates.or.Certificate.at.cohort.inst. <= 4 & Years.to.Associates.or.Certificate.at.cohort.inst. > 0 ~ "Assoc/Cert then Bach",
            Years.to.Bachelor.at.other.inst. <= 4 & Years.to.Bachelor.at.other.inst. > 0 & Years.to.Associates.or.Certificate.at.cohort.inst. <= 4 & Years.to.Associates.or.Certificate.at.cohort.inst. > 0 ~ "Assoc/Cert then Bach",
            Years.to.Bachelors.at.cohort.inst. <= 4 & Years.to.Bachelors.at.cohort.inst. > 0 ~ "Bach only",
            Years.to.Bachelor.at.other.inst. <= 4 & Years.to.Bachelor.at.other.inst. > 0 ~ "Bach only",
            Years.to.Associates.or.Certificate.at.cohort.inst. <= 4 & Years.to.Associates.or.Certificate.at.cohort.inst. > 0 ~ "Assoc/Cert",
            .default = "noncompleter"
        ),
        assoc_cert_compl = case_when(
            Years.to.Associates.or.Certificate.at.cohort.inst. > 0 ~ Years.to.Associates.or.Certificate.at.cohort.inst.
        ),
        bach_compl = case_when(
            Years.to.Bachelors.at.cohort.inst. > 0 ~ Years.to.Bachelors.at.cohort.inst.,
            Years.to.Bachelor.at.other.inst. > 0 ~ Years.to.Bachelor.at.other.inst.
        ),
        completion_status_raw = case_when(
            bach_compl > 0 & assoc_cert_compl > 0 ~ "Assoc/Cert then Bach",
            bach_compl > 0 ~ "Bach only",
            assoc_cert_compl > 0 ~ "Assoc/Cert"
        ),
        completion_timeframe_raw = case_when(
            bach_compl > 0 ~ bach_compl,
            assoc_cert_compl > 0 ~ assoc_cert_compl
        ),
        latest_enrollment = case_when(
            Years.of.Last.Enrollment.at.cohort.institution > Years.of.Last.Enrollment.at.other.institution ~ Years.of.Last.Enrollment.at.cohort.institution,
            .default = Years.of.Last.Enrollment.at.other.institution
        ),
        completion_status = case_when(
            latest_enrollment > completion_timeframe_raw ~ "continued enrollment",
            .default = completion_status_raw
        ),
        completion_timeframe = case_when(
            completion_status != "continued enrollment" ~ completion_timeframe_raw
        ),
        one_year_after_compl_num = cohort_year_num + completion_timeframe,
        one_year_after_compl_match = case_when(
            one_year_after_compl_num < 2025 ~ 1,
            .default = 0
        ),
        one_year_after_compl = as.factor(str_c(one_year_after_compl_num - 1, "-", str_sub(one_year_after_compl_num, 3, 5))),
        access_minority = case_when(
            Race == "Black or African American" ~ "Y",
            Race == "Hispanic" ~ "Y",
            .default = "N"
        ),
        access_Pell = Pell.Status.First.Year,
        access_age = case_when(
            Student.Age == "Older than 24" ~ "Y",
            .default = "N"
        )
    )

summary(PDP_AR_parsed)

PDP_AR_parsed |>
    group_by(Cohort, five_year_mark, five_years_status) |>
    summarize(
        cohort_records = n(),
        match_expected = round(0.7 * sum(five_years_after_match), 0)
    )

PDP_AR_parsed |>
    group_by(completion_cohort, completion_status) |>
    summarize(
        cohort_records = n(),
        match_expected = round(0.7 * sum(one_year_after_compl_match), 0)
    )
