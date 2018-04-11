require_relative 'micropub'
require_relative 'auth'

require_relative 'media'

# require_relative 'card'
# require_relative 'cite'
# require_relative 'location'

require_relative 'post'
Dir[File.join(__dir__, 'posts', '*.rb')].each { |file| require file }

# require_relative 'items/article'
# require_relative 'items/bookmark'
# require_relative 'items/note'
# require_relative 'items/photo'
