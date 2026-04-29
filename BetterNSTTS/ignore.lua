-- contains words that DISQUALIFY the sentence entirely from processing
BetterNSTTS.BNSTTS_IGNORE_GLOBAL =  {
    ["set"] = true
}

-- contains words to omit while speaking
BetterNSTTS.BNSTTS_IGNORE_WORDS = {
    [""] = true,
    [" "] = true,
    ["-"] = true,
    ["--"] = true,
    ["---"] = true
}