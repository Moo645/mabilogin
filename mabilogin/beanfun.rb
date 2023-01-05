# frozen_string_literal: true

require 'mechanize'

# login bf
class BeanfunClient
  def initialize(username, account, password)
    @agent = Mechanize.new do |a|
      a.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
    end
    @username = username
    @account = account
    @password = password
    @bfwebtoken = ''
    @service_code = '600309'
    @region = 'A2'
    @acc, @sopt, @name = '', '', ''
    @skey, @akey = '', ''
    @uptime = Time.now.to_i
  end

  def login_processor
    puts '------------------------------------------------------------------'
    puts '| [1/3][執行] 正在合成登入網址...'
    login_url = login_url_getter
    puts "| [2/3][執行] 使用者'#{@username}'登入Beanfun中..."
    @akey = login_beanfun(login_url)
    puts "| [2/3][成功] 使用者'#{@username}'驗證成功, Akey: '#{@akey}'"
    @bfwebtoken = bfwebtoken_getter
    puts "| [3/3][成功] 使用者'#{@username}'登入成功, bfwebtoken: '#{@bfwebtoken}'"
    puts '------------------------------------------------------------------'
    nil
  end

  def start_game_processor
    # 取得遊戲帳號資訊
    @agent.get('https://tw.beanfun.com/game_zone/')
    puts '取得遊戲帳號資訊'
    game_zone_url = "https://tw.beanfun.com/beanfun_block/auth.aspx?channel=game_zone&page_and_query=game_start.aspx%3Fservice_code_and_region%3D#{@service_code}_#{@region}&web_token=#{@bfwebtoken}"
    game_info = @agent.get(game_zone_url).body.match(/id="(.*?)" sn="(.*?)" name="(.*?)"/).to_a
    @acc, @sopt, @name = game_info[1..3]
    # puts "acc: #{@acc}"
    # puts "sopt: #{@sopt}"
    # puts "name: #{@name}"
    # puts '--------------------------------------------------------------'

    # 取得 acc 的 otp
    # puts '取得 acc 的 otp - 步驟1'
    current_time = DateTime.now.strftime("%Y%m%d%H%M%S")
    game_start_url = "https://tw.beanfun.com/beanfun_block/game_zone/game_start_step2.aspx?service_code=#{@service_code}&service_region=#{@region}&sotp=#{@sopt}&dt=#{current_time}"
    game_start = @agent.get(game_start_url)
    long_polling_key = game_start.body.match(/GetResultByLongPolling&key=(.*?)"/)[1]
    secreate_time = game_start.body.match(/ServiceAccountCreateTime: "(.*?)"/)[1]
    # puts "long_polling_key: #{long_polling_key}"
    # puts "secreate_time: #{secreate_time}"
    # puts '--------------------------------------------------------------'
    # puts '取得 acc 的 otp - 步驟2'
    secret_code_url = 'https://tw.newlogin.beanfun.com/generic_handlers/get_cookies.ashx'
    secret_code = @agent.get(secret_code_url)
    m_str_secret_code = secret_code.body.match(/var m_strSecretCode = '(.*)';/)[1]
    # puts "m_str_secret_code: #{m_str_secret_code}"
    # puts '--------------------------------------------------------------'
    # puts '取得 acc 的 otp - 步驟3'
    otp_data = {
      'service_code': @service_code,
      'service_region': @region,
      'service_account_id': @acc,
      'service_sotp': @sopt,
      'service_display_name': @name,
      'service_create_time': secreate_time
    }
    # puts otp_data
    otp_url = 'https://tw.beanfun.com/beanfun_block/generic_handlers/record_service_start.ashx'
    @agent.post(otp_url, otp_data)
    # puts '--------------------------------------------------------------'
    # puts '取得 acc 的 otp - 步驟4'
    otp_url2 = "https://tw.beanfun.com/generic_handlers/get_result.ashx?meth=GetResultByLongPolling&key=#{long_polling_key}"
    @agent.get(otp_url2)
    # puts '--------------------------------------------------------------'
    # puts '取得 acc 的 otp - 步驟5'
    @uptime = Time.now.to_i - @uptime
    otp_url3 = "http://tw.beanfun.com/beanfun_block/generic_handlers/get_webstart_otp.ashx?SN=#{long_polling_key}&WebToken=#{@bfwebtoken}&SecretCode=#{m_str_secret_code}&ppppp=1F552AEAFF976018F942B13690C990F60ED01510DDF89165F1658CCE7BC21DBA&ServiceCode=#{@service_code}&ServiceRegion=#{@region}&ServiceAccount=#{@acc}&CreateTime=#{secreate_time.gsub(' ', '%20')}&d=#{@uptime*1000}"
    opt_result = @agent.get(otp_url3).body
    
    return false if opt_result[0] != '1'
    
    key = opt_result[2..10]
    data = opt_result[10..]
    puts "#{key}, #{data}"
    puts '--------------------------------------------------------------'
    # 用DES解密otp

    return true
  end

  private

  # 取得session key, 並合成login_page網址
  def login_url_getter
    skey_url = 'https://tw.beanfun.com/beanfun_block/bflogin/default.aspx?service_code=999999&service_region=T0'
    @skey = @agent.get(skey_url).body.match(/strSessionKey = "(.*?)"/)[1]
    "https://tw.newlogin.beanfun.com/login/id-pass_form.aspx?skey=#{@skey}"
  end

  # 登入bf帳號
  def login_beanfun(login_url)
    login_page = @agent.get(login_url)
    login_page.form.field_with('t_AccountID').value = @account
    login_page.form.field_with('t_Password').value = @password
    login_result = login_page.form.click_button
    login_result.inspect.match(/akey=(\w+)/)[1]
  end

  # 跑完登入程序, 取得bfWebToken
  def bfwebtoken_getter
    # 使用akey合成final_step網址, 並GET 該網址
    final_step_url = "https://tw.newlogin.beanfun.com/login/final_step.aspx?akey=#{@akey}"
    @agent.get(final_step_url)

    # 最後將skey + akey 一起 POST 出去, 完成登入
    payload = {
      SessionKey: @skey,
      AuthKey: @akey
    }
    @agent.post('https://tw.beanfun.com/beanfun_block/bflogin/return.aspx', payload)

    # 完成登入後, 回到BF首頁, 取得 bfWebToken
    @agent.get('https://tw.beanfun.com')
    # puts @agent.cookie_jar.jar
    @agent.cookies.to_s.match(/"bfWebToken", value="(.*?)"/)[1]
  end

  def decrypt_des(data, key); end
end

def test
  puts "Test"
  usr = 'Willy'
  acc = ''
  pwd = ''

  bf_c = BeanfunClient.new(usr,acc,pwd)
  bf_c.login_processor()
  bf_c.start_game_processor()
end

if __FILE__ == $0
  test()
end
