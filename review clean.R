# SESSION ----------------------------------------------

library(tidyverse)
library(stringr)
library(tidytext)
library(rtweet)

setwd("~/Documents/Github/hardwax_bot")

reviews <- read_csv("./Data/reviews.csv")


# TEXT MINING ---------------------------------------------------

# get unique words
word_counts <- reviews %>%
  unnest_tokens(word, value, token = "ngrams", to_lower = TRUE, n = 1) %>%
  count(word, sort = TRUE) %>% filter(word != "")

# get sentence openers
opener_counts <- str_extract(reviews$value, '\\w*') %>% 
  str_to_lower() %>% 
  as_data_frame() %>%
  count(value, sort = TRUE) %>% 
  rename(word=value) %>% 
  filter(word != "")

# get words preceding commas
comma_precede <- str_split_fixed(reviews$value, ',', 5)  %>% 
  as_data_frame() %>% 
  filter(`V1` != "")

a <- comma_precede %>% filter(V2 != "") 
b <- a %>% filter(`V3` != "") %>% select(`V2`) %>% as.vector()
c <- a %>% filter(`V4` != "") %>% select(`V3`)
d <- a %>% filter(`V5` != "") %>% select(`V4`)
comma_precede <- c(a$V1, b$V2, c$V3, d$V4) %>% as_data_frame()

# get last words preceding commas
comma_precede$value <- word(comma_precede$value, -1)

# make lower case
comma_precede$value <- tolower(comma_precede$value)

# get word proceeding comma counts
comma_precede_counts <- count(comma_precede, value, sort = TRUE) %>% rename(comma_n=n)

# join to abs word counts
word_counts <- left_join(word_counts, comma_precede_counts, by=c("word"="value"))
opener_counts <- left_join(opener_counts, comma_precede_counts, by=c("word"="value"))

# probability of comma after word
word_counts$comma_prob <- round((word_counts$comma_n / word_counts$n) * 100)
opener_counts$comma_prob <- round((opener_counts$comma_n / opener_counts$n) * 100)
word_counts$comma_prob[is.na(word_counts$comma_prob)] <- 0
opener_counts$comma_prob[is.na(opener_counts$comma_prob)] <- 0

# create bigrams
bigrams <- reviews %>%
  unnest_tokens(bigram, value, token = "ngrams", to_lower = TRUE, n = 2) %>% 
  # separate bigram col
  separate(bigram, c("word1", "word2"), sep = " ")

# new bigram counts:
bigram_counts <- bigrams %>% 
  count(word1, word2, sort = TRUE)

# create bigrams
trigrams <- reviews %>%
  unnest_tokens(trigram, value, token = "ngrams", to_lower = TRUE, n = 3) %>% 
  # separate bigram col
  separate(trigram, c("word1", "word2", "word3"), sep = " ")

# new bigram counts:
trigram_counts <- trigrams %>% 
  count(word1, word2, word3, sort = TRUE)


## EXPORT ----------------------------------------

write_csv(word_counts, "./Data/words.csv")
write_csv(opener_counts, "./Data/openers.csv")
write_csv(bigram_counts, "./Data/bigrams.csv")
write_csv(trigram_counts, "./Data/trigrams.csv")


# BOT INIT --------------------------------------------------------

# ## name assigned to created app
# appname <- "dumb_hardwax"
# ## api key (example below is not a real key)
# key <- "l0V6xuUUntFGN4eEblPYTSw5U"
# ## api secret (example below is not a real key)
# secret <- "VmYihhRJuj88Lq4AZgOmmU2R3KqLsRME66dsTrwUr7ZKi7c4Z6"
# twitter_token <- create_token(
#   app = appname,
#   consumer_key = key,
#   consumer_secret = secret)
# 
# # combine with name for token
# file_name <- file.path(getwd(), "twitter_token.rds")
# 
# # save token
# saveRDS(twitter_token, file = "twitter_token.rds")
# 
# # create environment file
# cat(paste0("TWITTER_PAT=", file_name),
#     file = file.path(getwd(), ".Renviron"),
#     append = TRUE)
