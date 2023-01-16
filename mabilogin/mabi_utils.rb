module MabiUtils
  require 'csv'
  require_relative 'web_login'

  class StartMabi
    include MabiUtils

    def initialize(index)
      @user = csv_picker(index)
    end

    def perform
      puts "=> #{@user[0]}"
      login = WebLogin.new(@user[1], @user[2]).perform
      open_mabi(login)
    end

    private

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

  # 顯示預登入的帳號清單
  def csv_list
    csv = CSV.read('../user_info/template.csv')
    i = 1
    puts '-' * 20
    puts "目前有#{csv.size - 1}組可登入帳號:"
    csv[1..csv.size - 1].each do |row|
      puts "#{i}. #{row[0]}"
      i += 1
    end
    puts '-' * 20
  end

  # 使用輸入的ARGV 取得csv 裡的資訊
  def csv_picker(argv)
    csv = CSV.read('../user_info/template.csv')
    csv[argv]
  end
end
