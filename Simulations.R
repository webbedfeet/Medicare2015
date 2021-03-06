#' ---
#' title: The case for funnel plots
#' author: Abhijit
#' date: February 26, 2019
#' output:
#'     html_document:
#'         toc: true
#'         toc_float: true
#'         theme: journal
#'         highlight: zenburn
#'         keep_md: true
#' ---
#'
#' # Background
#'
#' The statistical idea behind identifying certain HRR's as
#' having excess or deficit numbers of knee transplants after accounting
#' for demographic and clinical factors is to try and model the rate of
#' knee replacements in each region using Poisson regression (accounting
#' for repeated measures, if needed), and use this as indirectly
#' standardized rates accounting for these factors. We can then identify
#' regions which are outliers with respect to these standardized rates.
#'
#' One point of confusion is in how to utilize these standardized rates.
#' The standardization can create a "normalized" distribution of rates,
#' and perhaps merely ranking the rates and seeing which regions change
#' rank the most suffices, or which regions move from "outliers" to
#' "normal" rates after adjustment works. However, this approach, in my
#' opinion, ignores natural variability in the estimates.
#'
#' # A demonstrative simulation
#'
#' We start by creating a population of 500,000 individuals split across
#' 10 regions, , and
#' simulating realistic age, sex and race distributions for each region. The
#' regions differ in size and in local demographic distributions, and so the
#' rates have a natural variability solely dependent on the actual distribution
#' of race, age and sex within each region. Additionally, we added a protective
#' effect for regions 1 and 2 and an excess risk for regions 8, 9 and 10, which
#' represent non-demographic factors in each region that might drive the rate
#' of knee transplants. Ages were distributed as a normal distribution roughly
#' centered at 75 years and with a standard deviation of 5 years, the male: female
#' ratio was set roughly at 50:50 with some regional variability, and race, classified
#' as white, black and other, were simulated to have proportions in 45-60%,
#' 10-30% for whites and blacks, with the rest being classified as other. The
#' following age, sex and race odds ratios were modeled:
#+ ors, echo = F, message = F, warning = F
library(tidyverse)
tribble(~ Variable, ~ `Odds ratio`,
        'Age', '1.1 per year',
        'Male', '0.8',
        'Race: Black', '0,8',
        'Race: Other', '0.6',
        'Region: 1,2', '0.7',
        'Region: 8,9,10', '1.4') %>%
  knitr::kable()
#+ simulation_setup, echo = F, message = F, warning = F
library(tidyverse)
library(broom)
set.seed(2095)
N <- 500000
reg_prob <- c(10,20, 5,15, 25, 10, 15, 5, 15,7)
reg_prob <- reg_prob/sum(reg_prob)
Region <- sample(1:10, N, replace = T,
                 prob = reg_prob)
dat <- tibble(Region)
dat <- dat %>% group_by(Region) %>%
  mutate(Age = rnorm(n(), rnorm(1, 75,3), rnorm(1, 5, 1))) %>%
  mutate(p = rbeta(1, 20, 20)) %>%
  mutate(Sex = sample(c('M','F'), n(), replace = T,
                      prob = c(1 - unique(p), unique(p)))) %>%
  ungroup()
dat$Race <- ""
for(i in 1:10){
  p_white <- runif(1, .45,.60)
  p_black <- runif(1, .10,.30)
  p_other <- 1 - p_white - p_black
  dat$Race[dat$Region == i] = sample(c('White','Black','Other'),
                                sum(dat$Region == i),
                                replace = TRUE,
                                prob = c(p_white, p_black, p_other))
}

linpred <- with(dat, log(0.005) + 0.1*(Age - 75) + log(0.8)*(Sex=='M') +
  log(1.4)*(Region >= 8) + log(0.7)*(Region <= 2) +
  log(0.8)*(Race=='Black') + log(0.6)*(Race == 'Other'))
p <- plogis(linpred)
outcome <- rbernoulli(N, p)
dat$outcome <- outcome
dat <- dat %>% mutate_if(is.character, as.factor) %>%
  mutate(Race = fct_relevel(Race, 'White','Black','Other'))

#' We then simulated the knee replacement statuses of 500,000 individuals,
#' with a baseline rate of 5 replacements per 1000 individuals. We summarize
#' the observed knee replacement rates by region in the bar graph below
#+ obs_rates, echo = F, message = F, warning = F
dat %>% group_by(Region) %>% summarize(p_hat = mean(outcome)) %>%
  ggplot(aes(as.factor(Region), p_hat))+geom_bar(stat = 'identity') +
    labs(x = 'Region', y = 'Observed rates') +
  scale_y_continuous('Events per 10,000', labels = scales::unit_format(unit = '', scale = 1e4))

#' We note that, just by natural variability, region 6 has a higher rate of
#' replacements than regions 8, 9 or 10, which have an extraneous increased
#' rate of transplants in the simulation.
#'
#' We then model the rates using GLMs (in this case logistic regression, but
#' Poission could have been used just as easily given the low baseline rate),
#' adjusting for age, race and sex. We also did nested models with just age, and with
#' age and sex as well. We'll concentrate on the full model, since it makes the point
#+ models, include = F, cache = TRUE
m1 <- glm(outcome~Age,  data=dat, family = 'binomial')
m2 <- update(m1, . ~ . + Sex)
m3 <- update(m2, . ~ . + Race)

mods <- list('Model1' = m1, 'Model2' = m2, 'Model3' = m3)
checks <- map(mods, ~augment(., data = dat, type.predict = 'response') %>%
                group_by(Region) %>%
               summarize(obs = sum(outcome), expect = sum(.fitted),
                       SMR = obs/expect, N = n() ) %>%
                mutate(obs_rate = obs/N*10000, exp_rate = expect/N*10000))

#' We can then look at the predicted regional rate estimates from the model,
#' which can be considered as indirectly adjusted rates, compared to the observed
#' rates, in the boxplot below. The labels refer to the regions.
#+ boxplot, echo = F, warning = F, message = F

bl <- checks[[3]] %>% select(Region, obs_rate, exp_rate) %>%
  rename(Observed = obs_rate, Expected = exp_rate) %>%
  gather(variable, value , -Region) %>%
  mutate(variable = forcats::fct_relevel(variable, 'Observed'))

ggplot(bl, aes(x = variable, y = value)) +
  geom_boxplot() +
  geom_label(aes(label = Region),
             position = position_jitter(width = 0.1)) +
  labs(x = '', y = 'Rate per 10,000') +
  theme_bw()

#' We see that regions 1, 8, 9, 10 fall in the box after adjustment,
#' which might be interpreted as being "normal" regions once you account
#' for demographics. Moreover, regions 4,5, 6, 7, which are "normal"
#' regions in the simulation, appear as outliers. This shows that
#' looking at the predicted (adjusted) rates, in not at all the right
#' approach.
#'
#' # The case for statistical variability assessment and funnel plots
#'
#' If we think a bit more about this quesiton, the null hypothesis we
#' are assuming is that there is no extraneous factors other than
#' demographics that explain the regional variabilty. If this is true,
#' then if we model the rates on the demographics, all that should be
#' left is statistical variability. Under this assumption of
#' residual statistical variability, we should look for outliers in
#' the "residuals" to see suggestions of the falsehood of our implied
#' null hypothesis. In Poisson regression, we are modeling the log-rates,
#' so the residuals can be considered as
#' $\log$(Observed) - $\log$(Expected), which is the logarithm of the
#' SMR. The standard funnel plot in this scenario plots the SMR against
#' the expected number of events, and puts control bounds based on
#' natural Poisson variabiity (or a normal approximation to it). We use
#' the normal approximation in the following plot, resulting from
#' modeling all the demographics,
#+ funnel, echo = F, warning = F, message = F
funnel_SMR <- function(d){
  ggplot(d) + geom_label(aes(x = expect, y = SMR, label = Region)) +
    geom_line(aes(x = expect, y = 1 - 1.96 * sqrt(1/expect))) +
    geom_line(aes(x = expect, y = 1 + 1.96 * sqrt(1/expect))) +
    geom_line(aes(x = expect, y = 1 - 2.58 * sqrt(1/expect)), linetype = 2) +
    geom_line(aes(x = expect, y = 1 + 2.58 * sqrt(1/expect)), linetype = 2) +
    geom_hline(yintercept = 1, linetype = 2, color = 'darkgrey',
               size = 2) +
    theme_bw() +
    labs(x = 'Expected number of events', y = 'SMR')
}
plts <- map(checks, funnel_SMR)
plts[[3]]

#' We see in this plot that the correct regions are identified as being
#' at excess (8, 9, 10) and diminished (1,2) risk of replacements.
#'
#' Let's expound on this a bit more. If the only factors driving the
#' replacement rate was demographics, we would expect the observed
#' rate to be close to the predicted rate when adjusting for age, race
#' and sex, while if there was some extraneous factor affecting the rate,
#'  we would see  poor agreement with the predicted rate, since the
#'  adjustment isn't accounting for an unmeasured factor.
#'
#' # The fuller model
#'
#' The underlying conceptual model that Mike proposes is
#'
#' ```
#' rate = [patient characteristics] + [physician characteristics] + [behavioral characteristics] + error
#' ```
#'
