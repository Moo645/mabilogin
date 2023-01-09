require_relative 'web_login'
require_relative 'mabi_utils'

def main(argv)
  MabiUtils::StartMabi.new.perform
end

if __FILE__ == $0
  main(ARGV)
end
