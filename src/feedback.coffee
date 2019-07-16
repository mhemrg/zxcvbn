scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "از چند کلمه استفاده و از عبارات رایج جلوگیری کنید."
      "نیازی به استفاده از حروف بزرگ، اعداد و علائم نیست."
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'یک یا دو کلمه‌ی دیگر اضافه کنید. رایج نباشند.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Straight rows of keys are easy to guess'
        else
          'Short keyboard patterns are easy to guess'
        warning: warning
        suggestions: [
          'Use a longer keyboard pattern with more turns'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'تکرارهایی مثل aaa به سادگی قابل حدس‌زدن هستند.'
        else
          'تکرارهایی مثل abcabcabc فقط کمی سخت‌تر از حدس‌زدن abc هستند.'
        warning: warning
        suggestions: [
          'از تکرار کلمات و حروف خودداری کنید.'
        ]

      when 'sequence'
        warning: "تکرارهایی مانند abc و 6543 به راحتی قابل حدس‌زدن هستند."
        suggestions: [
          'از تکرار کلمات و حروف خودداری کنید.'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Recent years are easy to guess"
          suggestions: [
            'Avoid recent years'
            'Avoid years that are associated with you'
          ]

      when 'date'
        warning: "تاریخ‌ها معمولا به راحتی قابل حدس‌زدن هستند."
        suggestions: [
          'از تاریخ‌ها و سال‌هایی که به نوعی با شما مرتبط هستند، استفاده نکنید.'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'این رمز بین ۱۰ رمز عبور رایج دنیا است.'
        else if match.rank <= 100
          'این رمز بین ۱۰۰ رمز عبور رایج دنیا است.'
        else
          'این یک رمز عبور رایج است'
      else if match.guesses_log10 <= 4
        'این رمز، مشابه رمزهای رایج است.'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'یک کلمه به تنهایی، به سادگی قابل حدس‌زدن است.'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'اسامی به راحتی قابل حدس‌زدن هستند.'
      else
        'اسامی رایج به راحتی قابل حدس‌زدن هستند.'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "استفاده از حروف بزرگ کمک چندانی نمی‌کند."
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "حدس رمزهایی که کاملا با حروف بزرگ هستند تقریبا معادل رمزهایی کاملا با حروف کوچک است."

    if match.reversed and match.token.length >= 4
      suggestions.push "کلمات رزرو شده به‌راحتی قابل حدس‌زدن هستند."
    if match.l33t
      suggestions.push "حالت‌های قابل پیش‌بینی مثل استفاده از @ به جای a کمک چندانی نمی‌کند."

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
