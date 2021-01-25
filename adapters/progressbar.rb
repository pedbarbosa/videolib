# frozen_string_literal: true

require 'ruby-progressbar'

def progressbar_create(operation, total)
  ProgressBar.create(format: "#{operation} %t |%b>%i| %c/%C",
                     title: '...                      ', starting_at: 0, total: total)
end

def progressbar_title(title)
  if title.length > 19
    format("'%-19.19s ...'", title)
  else
    format('%-25.25s', "'#{title}'")
  end
end

def progressbar_update(progressbar, title)
  progressbar.title = progressbar_title(title)
  progressbar.increment
end
