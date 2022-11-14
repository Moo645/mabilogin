# frozen_string_literal: true

require 'mechanize'

# login bf
class BeanfunClient
  def initialize(username, account, password)
    @skey_url = 'https://tw.beanfun.com/beanfun_block/bflogin/default.aspx?service_code=999999&service_region=T0'
    @agent = Mechanize.new do |a|
      a.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
      a.user_agent_alias = 'Windows Chrome'
    end
    @username = username
    @account = account
    @password = password
    @bfwebtoken = ''
  end

  def login_processor
    puts '-----------------------------------'
    puts '| [1/3][執行] 正在合成登入網址...'
    login_url = login_url_getter
    puts "| [2/3][執行] 使用者'#{@username}'登入Beanfun中..."
    akey = login_beanfun(login_url)
    puts "| [2/3][成功] 使用者'#{@username}'驗證成功, Akey: '#{akey}'"
    @bfwebtoken = bfwebtoken_getter(akey)
    puts "| [3/3][成功] 使用者'#{@username}'登入成功..."
    puts '-----------------------------------'
    nil
  end

  def start_game_processor
    # 取得遊戲帳號
    # 取得otp
    # 用DES解密otp
  end

  private

  # 取得session key, 並合成login_page網址
  def login_url_getter
    skey = @agent.get(@skey_url).body.match(/strSessionKey = "(.*?)"/)[1]
    "https://tw.newlogin.beanfun.com/login/id-pass_form.aspx?skey=#{skey}"
  end

  # 登入bf帳號
  def login_beanfun(login_url)
    login_page = @agent.get(login_url)
    login_page.form.field_with('t_AccountID').value = @account
    login_page.form.field_with('t_Password').value = @password

    # POST 出資訊後, 並返回auth key
    login_result = login_page.form.click_button
    login_result.inspect.match(/akey=(\w+)/)[1]
  end

  # 跑完登入程序, 取得bfWebToken
  def bfwebtoken_getter(akey)
    # 使用akey合成final_step網址, 並GET 該網址
    final_step_url = "https://tw.newlogin.beanfun.com/login/final_step.aspx?akey=#{akey}"
    @agent.get(final_step_url)

    # 最後將skey + akey 一起 POST 出去, 完成登入
    @agent.post('https://tw.beanfun.com/beanfun_block/bflogin/return.aspx')

    # 完成登入後, 回到BF首頁, 取得 bfWebToken
    @agent.get('https://tw.beanfun.com')
    @agent.cookies.to_s.match(/"bfWebToken", value="(.*?)"/)[1]
  end
end
