# frozen_string_literal: true

require 'mechanize'
require_relative 'otp_handler'

# login bf and get otp
class WebLogin
  include OtpHandler

  def initialize(account, password)
    @agent = Mechanize.new do |a|
      a.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/50.0.2661.102 Safari/537.36'
    end
    @account = account
    @password = password
    @service_code = '600309'
    @skey, @akey, @bfwebtoken = ''
  end

  # return acc_id and otp
  def perform
    login_handler
    otp_handler(@agent, @service_code, @bfwebtoken)
  end

  private

  def login_handler
    puts '-' * 70
    puts '| [1/3] 登入Beanfun中...'
    @skey = skey_getter
    @akey = akey_getter
    puts "| [2/3] 驗證成功, Akey: '#{@akey}'"
    @bfwebtoken = bfwebtoken_getter
    puts "| [3/3] 登入成功, bfwebtoken: '#{@bfwebtoken}'"
    puts '-' * 70
    nil
  end

  def get(url)
    @agent.get(url)
  end

  # 取得session key, 並合成login_page網址
  def skey_getter
    url = 'https://tw.beanfun.com/beanfun_block/bflogin/default.aspx?service_code=999999&service_region=T0'
    get(url).body.match(/strSessionKey = "(.*?)"/)[1]
  end

  # 登入bf帳號
  def akey_getter
    url = "https://tw.newlogin.beanfun.com/login/id-pass_form.aspx?skey=#{@skey}"
    login_page = get(url)
    login_page.form.field_with('t_AccountID').value = @account
    login_page.form.field_with('t_Password').value = @password
    login_result = login_page.form.click_button
    login_result.inspect.match(/akey=(\w+)/)[1]
  end

  # 跑完登入程序, 取得bfWebToken
  def bfwebtoken_getter
    get("https://tw.newlogin.beanfun.com/login/final_step.aspx?akey=#{@akey}")

    # 最後將skey + akey 一起 POST 出去, 完成登入
    url = 'https://tw.beanfun.com/beanfun_block/bflogin/return.aspx'
    payload = {
      SessionKey: @skey,
      AuthKey: @akey
    }
    @agent.post(url, payload)

    # 完成登入後, 回到BF首頁, 取得 bfWebToken
    get('https://tw.beanfun.com')
    @agent.cookies.to_s.match(/"bfWebToken", value="(.*?)"/)[1]
  end
end
