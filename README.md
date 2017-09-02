# predictive-text-jhu-capstone

This project contains the code and data necessary to create and run the shiny app located [here](https://chris-harris.shinyapps.io/predictive_text_R_capstone/).

This app performs predictive. It has been trained on various corpora, including news, blogs, and Twitter, so that once you input some text it will offer top 5 predictions of what the next word should be.

The app implements a [Katz's backoff model](https://en.wikipedia.org/wiki/Katz%27s_back-off_model) with stupid backoff. For example, given 2 words, we look at a list of top 3-grams and top 2-grams that could complete those 2 words. We compute the probabilities in each case of the 3-gram occuring and also "back off" and compute the probability of the 2-gram occuring with the discount.

The files in this project include:
* ui.R - This is the user-interface definition for the Shiny web application.
* server.R - This is the server logic for the Shiny web application.
* stop_words.txt - List of stop words
* nGram_med.rData - Contains 6 environments. Each contains key-values where the key is a 1-gram or a 2-gram and the value is a table of the 1-gram that follows that n-gram and the count for how many times that it followed it. There is one of each of these environments for each of the three data sets.
* fourGram_light.rData - Contains an environment with key-values where the key is a 3-gram and the value is a table of 1-grams that complete the 3-gram and the number of times it occurred.

