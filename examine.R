library("readxl")
library("tidyverse")

PDP_AR <- read.csv(
    "00306800leap_AR_IDENTIFIED_20240412.csv",
    stringsAsFactors = TRUE,
    na.strings = c("NA","UK","unknown")
    )

problems(PDP_AR)

PDP_AR_course <- read.csv("00306800leap_COURSE_LEVEL_AR_ID_20240412.csv")

summary(PDP_AR)
