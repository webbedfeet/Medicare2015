library(tidyverse)
library(broom)
set.seed(2085)
N <- 1000000
Age <- rnorm(N, 75, 5)
Sex <- sample(c("M","F"), N, replace=T, prob = c(0.45, 0.55))
Race <- sample(c("White", "Black", "Hispanic", "Asian", "Other"), N, replace = T,
               prob = c(0.55, 0.12, 0.13,0.10, 0.10))
Region <- sample(1:10, N, replace=T)

linpred <- log(0.005) + 0.1*(Age - 75) + log(0.8)*(Sex=='M') + log(2)*(Region >= 7) +
  log(0.8)*(Race=='Black') + log(0.6)*(Race=='Asian')
p <- plogis(linpred)
outcome <- rbernoulli(N, p)

dat <- tibble(Age, Sex, Race, Region, outcome) %>% mutate_if(is.character, as.factor) %>%
  mutate(Race = fct_relevel(Race, 'White', 'Black','Hispanic','Asian','Other'))

m <- glm(outcome~Age + Race + Sex, data=dat, family = 'binomial')

dat %>% group_by(Region) %>% count(outcome) %>% spread(outcome, n)

pred <- predict(m, type='response')

dat1 <- augment(m, data = dat, type.predict='response')

checks <- dat1 %>% group_by(Region) %>% summarize(observed = sum(outcome)/n(),
                                                  expected = sum(.fitted)/n())

m2 <- glm(outcome ~ Age + Race + Sex + as.factor(Region), data = dat, family = 'binomial')
dat2 <- augment(m2, data = dat, type.predict = 'response')
checks2 <- dat2 %>% group_by(Region) %>% summarize(observed = sum(outcome)/n(),
                                                   expected = sum(.fitted)/n())
