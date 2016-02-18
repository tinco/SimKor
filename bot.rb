$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bwapi_ruby\bwapi_ruby'

require 'zerg_ai'

Bwapi.start_bot(ZergAI)