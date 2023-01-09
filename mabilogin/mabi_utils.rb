module MabiUtils
  require 'csv'

  class StartMabi
    include MabiUtils

    def initialize(index = 1)
      @user = csv_finder(index)
    end

    def perform
      login = WebLogin.new(@user[0], @user[1]).perform
      open_mabi(login)
    end
  end

  def csv_finder(index)
    CSV.read('../user_info/template.csv')[index]
  end

  def open_mabi(login)
    args = [
      'C:\Nexon\Mabinogi\Mabinogi.exe',
      'code:1622',
      'ver:343',
      'logip:210.208.80.6',
      'logport:11000',
      'chatip:210.208.80.10',
      'chatport:8004',
      'setting:\"file://data/features.xml=Regular, Taiwan\"',
      "/N:#{login[:acc_id]}",
      "/V:#{login[:otp]}",
      '/T:gamania'
    ].join(' ')
    system("start #{args}")
  end
end
