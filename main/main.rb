require_relative '../mabilogin/mabi_utils'
include MabiUtils

def main(argv)
  MabiUtils::StartMabi.new(argv).perform
end

if __FILE__ == $0
  main(ARGV[0].to_i)
end
