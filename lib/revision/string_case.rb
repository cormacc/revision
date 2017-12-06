class String
  # ruby mutation methods have the expectation to return self if a mutation occurred, nil otherwise. (see http://www.ruby-doc.org/core-1.9.3/String.html#method-i-gsub-21)
  def to_underscore!
    gsub!(/::/, '/')
    gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    tr!("-", "_")
  end

  ##
  # Converts _SnakeCase_ to _snake_case_
  def to_snake_case!
    to_underscore!
    downcase!
  end

  ##
  # Converts _ScreamingSnakeCase to _SCREAMING_SNAKE_CASE_
  def to_screaming_snake_case!
    to_underscore!
    upcase!
  end

  def to_underscore
    dup.tap { |s| s.to_underscore! }
  end

  def to_snake_case
    dup.tap { |s| s.to_snake_case! }
  end

  def to_screaming_snake_case
    dup.tap { |s| s.to_screaming_snake_case! }
  end

end