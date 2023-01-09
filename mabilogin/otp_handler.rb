module OtpHandler
  require 'openssl'

  def otp_handler(agent, service_code, bfwebtoken)
    uptime = Time.now.to_i

    puts '取得遊戲帳號OTP中:'
    get('https://tw.beanfun.com/game_zone/')

    # [1/7] 取得 acc_id, sopt, name
    game_info = game_info_getter(service_code, bfwebtoken)
    acc_id, sopt, name = game_info[1..3]

    # [2/7] 取得 long_polling_key, secreate_time
    game_info = polling_secreate_getter(service_code, sopt)
    long_polling_key, secreate_time = game_info

    # [3/7] 取得 m_str_secret_code
    m_str_secret_code = secret_code_getter

    # [4/7] 送出opt_data
    otp_data = {
      'service_code': service_code,
      'service_region': 'A2',
      'service_account_id': acc_id,
      'service_sotp': sopt,
      'service_display_name': name,
      'service_create_time': secreate_time
    }
    agent.post('https://tw.beanfun.com/beanfun_block/generic_handlers/record_service_start.ashx', otp_data)

    # [5/7] 參考的流程有做, 但作用不明, 試著跳過也可以登入
    # get("https://tw.beanfun.com/generic_handlers/get_result.ashx?meth=GetResultByLongPolling&key=#{long_polling_key}")

    # [6/7] 取得OTP加密資料
    otp_data = opt_getter(long_polling_key, bfwebtoken, m_str_secret_code, service_code, acc_id, secreate_time, uptime)
    return puts "取得 OTP 時出現異常: #{otp_data}" if otp_data[0] != '1'

    # [7/7] 解密OTP, 並回傳
    puts "取得加密資料成功: #{otp_data[2..]}", "帳號: #{acc_id}"
    return { acc_id: acc_id, otp: otp_decrypt(otp_data) }
  end

  private

  def game_info_getter(service_code, bfwebtoken)
    url = "https://tw.beanfun.com/beanfun_block/auth.aspx?channel=game_zone&page_and_query=game_start.aspx%3Fservice_code_and_region%3D#{service_code}_A2&web_token=#{bfwebtoken}"
    get(url).body.match(/id="(.*?)" sn="(.*?)" name="(.*?)"/).to_a
  end

  def polling_secreate_getter(service_code, sopt)
    current_time = DateTime.now.strftime("%Y%m%d%H%M%S")
    url = "https://tw.beanfun.com/beanfun_block/game_zone/game_start_step2.aspx?service_code=#{service_code}&service_region=A2&sotp=#{sopt}&dt=#{current_time}"
    game_start = get(url)
    long_polling_key = game_start.body.match(/GetResultByLongPolling&key=(.*?)"/)[1]
    secreate_time = game_start.body.match(/ServiceAccountCreateTime: "(.*?)"/)[1]
    [long_polling_key, secreate_time]
  end

  def secret_code_getter
    url = 'https://tw.newlogin.beanfun.com/generic_handlers/get_cookies.ashx'
    get(url).body.match(/var m_strSecretCode = '(.*)';/)[1]
  end

  def opt_getter(long_polling_key, bfwebtoken, m_str_secret_code, service_code, acc_id, secreate_time, uptime)
    # uptime 隨便填都可以, 感覺只是橘子驗證紀錄用的
    uptime = Time.now.to_i - uptime
    url = "http://tw.beanfun.com/beanfun_block/generic_handlers/get_webstart_otp.ashx?SN=#{long_polling_key}&WebToken=#{bfwebtoken}&SecretCode=#{m_str_secret_code}&ppppp=1F552AEAFF976018F942B13690C990F60ED01510DDF89165F1658CCE7BC21DBA&ServiceCode=#{service_code}&ServiceRegion=A2&ServiceAccount=#{acc_id}&CreateTime=#{secreate_time.gsub(' ', '%20')}&d=#{uptime*1000}"
    get(url).body
  end

  def otp_decrypt(otp_result)
    key = otp_result[2..9]
    data = [otp_result[10..]].pack('H*')

    cipher = OpenSSL::Cipher.new('des-ecb').decrypt
    cipher.key = key
    cipher.padding = 0

    result = cipher.update(data)
    result << cipher.final
    puts "解密成功, OTP: #{result}"
    result.gsub("\x00", '')
  end
end
