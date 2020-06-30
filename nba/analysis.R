library(tidyverse)
library(survival)
library(ggfortify)
library(broom)

games = read_csv('nba/processed/study-data-by-game.csv')

games

summary = read_csv('nba/processed/study-data-summary.csv')

summary

summary.predictors = summary %>% 
  mutate(
    largest.gain = peak - starting.elo,
    largest.loss = starting.elo - bottom,
    starting.team.type = case_when(
      starting.elo < 1400 ~ '01.bad',
      starting.elo >= 1400 & starting.elo < 1500 ~ '02.below.avg',
      starting.elo >= 1500 & starting.elo < 1600 ~ '03.above.avg',
      starting.elo >= 1600 ~ '04.good',
    )
  )

summary.predictors

surv.all = survfit(Surv(total.games, end.event) ~ 1, data = summary.predictors)
surv.all
autoplot(surv.all)

surv.black = survfit(Surv(total.games, end.event) ~ black, data = summary.predictors)
surv.black
autoplot(surv.black)

surv.start = survfit(Surv(total.games, end.event) ~ starting.team.type, data = summary.predictors)
surv.start
autoplot(surv.start)

survfit(Surv(total.games, end.event) ~ starting.team.type + black, data = summary.predictors)

# model.summ = coxph(
#   Surv(total.games, end.event) ~
#     black + first.hc.job + win.pct + starting.team.type + tenure.progress + last.year.progress + 
#     recent.progress + largest.gain + largest.loss + middle,
#   data = summary.predictors
# )
# 
# summary(model.summ)
# 
# tidy(model.summ) %>% 
#   mutate(significant = p.value < .05) %>% 
#   arrange(p.value)

games.predictors = games %>% 
  # filter(total.games <= 82 * 5) %>% 
  mutate(
    t1 = total.games,
    t2 = t1 + 1,
    largest.gain = peak - starting.elo,
    largest.loss = starting.elo - bottom,
    starting.team.type = case_when(
      starting.elo < 1400 ~ '01.bad',
      starting.elo >= 1400 & starting.elo < 1500 ~ '02.below.avg',
      starting.elo >= 1500 & starting.elo < 1600 ~ '03.above.avg',
      starting.elo >= 1600 ~ '04.good',
    )
  )

games.predictors

model.games = coxph(
  Surv(time = t1, time2 = t2, event = end.event) ~
    black + first.hc.job + win.pct + starting.team.type + tenure.progress + last.year.progress + 
    recent.progress + largest.gain + largest.loss + middle,
  data = games.predictors,
  cluster = tenure.slug
)

summary(model.games)

tidy(model.games) %>% 
  mutate(significant = p.value < 0.05) %>% 
  arrange(statistic)

# model.games2 = coxph(
#   Surv(time = t1, time2 = t2, event = end.event) ~
#     black + tenure.progress + last.year.progress,
#   data = games.predictors,
#   cluster = tenure.slug
# )
# 
# summary(model.games2)
# 
# tidy(model.games2) %>% 
#   mutate(significant = p.value < 0.05) %>% 
#   arrange(statistic)

games.predictions = games.predictors %>% 
  rename(fired = end.event) %>% 
  mutate(
    pred.prob.firing = predict(model.games, newdata = ., type = 'lp'),
    # pred.prob.firing = 1 - exp(-pred.prob.firing)
  )

games.predictions %>% 
  filter(tenure.slug == 'watsoea01c_PHO_2016_2018') %>% 
  arrange(total.games) %>% 
  ggplot(aes(total.games, pred.prob.firing)) +
  geom_line()

games.predictions %>% 
  filter(tenure.slug == 'popovgr99c_SAS_1997_2020') %>% 
  arrange(total.games) %>% 
  ggplot(aes(total.games, pred.prob.firing)) +
  geom_line()

current.hot.seat = games.predictions %>%
  semi_join(
    summary %>% 
      filter(tenure.ending == 'active'),
    by = 'tenure.slug'
  ) %>% 
  group_by(tenure.slug) %>% 
  filter(total.games == max(total.games)) %>% 
  arrange(-pred.prob.firing)

firings = games.predictions %>% 
  filter(fired == 1)

games.predictions %>% 
  filter(total.games <= 82 * 5) %>% 
  ggplot(aes(total.games, pred.prob.firing, group = tenure.slug)) +
  geom_line(alpha = 0.1) +
  geom_point(
    data = . %>% 
      filter(fired == 1)
  ) +
  geom_hline(yintercept = 0) +
  facet_wrap(. ~ black)

# autoplot(survfit(model.games))

# model.games.aa = aareg(
#   Surv(time = t1, time2 = t2, event = end.event) ~
#     black + first.hc.job + win.pct + starting.team.type + tenure.progress + last.year.progress + 
#     recent.progress + largest.gain + largest.loss + middle + cluster(tenure.slug),
#   data = games.predictors,
#   nmin = 20
# )
# 
# beepr::beep()

model.games.aft = survreg(
  Surv(time = t1, time2 = t2, event = end.event) ~
    black + first.hc.job + win.pct + starting.team.type + tenure.progress + last.year.progress +
    recent.progress + largest.gain + largest.loss + middle,
  cluster = tenure.slug,
  data = games.predictors,
)
