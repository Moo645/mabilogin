require_relative '../mabilogin/mabi_utils'
include MabiUtils

def acc_list
  MabiUtils.csv_list
end

if __FILE__ == $0
  acc_list
end
