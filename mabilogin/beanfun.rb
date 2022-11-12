# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

# Get Skey
class BeanfunClient
  def initialize(username, password)
    @username = username
    @password = password
    @headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    }
    # @headers_tmp = {
    #   "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
    #   "Accept-Encoding": "gzip, deflate, br",
    #   "Accept-Language": "zh-TW,zh;q=0.9",
    #   "Connection": "keep-alive",
    #   "Host": "tw.newlogin.beanfun.com",
    #   "sec-ch-ua": %{"Google Chrome";v="107", "Chromium";v="107", "Not=A?Brand";v="24"},
    #   "sec-ch-ua-mobile": "?0",
    #   "sec-ch-ua-platform": "Windows",
    #   "Sec-Fetch-Dest": "document",
    #   "Sec-Fetch-Mode": "navigate",
    #   "Sec-Fetch-Site": "none",
    #   "Sec-Fetch-User": "?1",
    #   "Upgrade-Insecure-Requests": "1",
    #   "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
    # }
  end

  def beanfun_login
    # skey = login_page_uri
    login_data = {
      '__EVENTTARGET': '',
      '__EVENTARGUMENT': '',
      '__VIEWSTATE': viewstate,
      '__VIEWSTATEGENERATOR': viewstateGenerator,
      '__EVENTVALIDATION': eventvalidation,
      't_AccountID': @username,
      't_Password': @password,
      'btn_login': '登入'
    }
    http = Net::HTTP.new(login_page_uri.host, login_page_uri.port)
    http.use_ssl = true
    res = http.get_response(login_page_uri.path)
    # login_page_res = Net::HTTP.get_response(login_page_uri)
    # puts login_page_res.body if login_page_res.is_a?(Net::HTTPSuccess)
  end

  private
  
  def login_page_uri
    # 先取得 skey
    uri = URI('https://tw.beanfun.com/beanfun_block/bflogin/default.aspx?service_code=999999&service_region=T0')
    res = Net::HTTP.get_response(uri)
    skey = res.body.match(/\d\w+;*/).to_s
    
    uri = URI(res['location'])
    redirect = Net::HTTP::Get.new(uri.path)
    re_0 = Net::HTTP.start(uri.path, uri.port, use_ssl: true, headers: %{"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"}) { |http| http.request(redirect) }
    
    redirect = Net::HTTP::GET.new(re_0.path)
    re_2 = Net::HTTP.start(uri.path, uri.port, use_ssl: true, **@headers) { |http| http.request(redirect) }
    
    redirect = Net::HTTP::GET.new("/id-pass_form.aspx?skey=#{skey}")
    re_target = Net::HTTP.start(uri.path, uri.port, use_ssl: true, **@headers) { |http| http.request(redirect) }
    
    # 把取得的 skey 放入登入頁的 uri
    uri = [
      URI("https://tw.newlogin.beanfun.com/checkin.aspx?skey=#{skey}&display_mode=0"),
      URI("https://tw.newlogin.beanfun.com/checkin_step2.aspx?skey=#{skey}&display_mode=2"),
      URI("https://tw.newlogin.beanfun.com/login/id-pass_form.aspx?skey=#{skey}&clientID=undefined"),
      URI("https://tw.newlogin.beanfun.com/login/id-pass_form.aspx?skey=#{skey}")
    ]
    res = Net::HTTP.get_response(uri[0])
    res = Net::HTTP.get_response(uri[1])
  end
end

# utility
def uri_get(some_uri, headers)
  uri = some_uri
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  req = Net::HTTP::Get.new(uri, headers)
  res = http.request(req)   # 發送請求
  # if res.kind_of? Net::HTTPSuccess
  #   res_body = JSON.parse(res.body) # 取得回應，並解析 JSON
  # end
end

def fetch_uri(uri_str, limit = 10)
  # You should choose better exception.
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0

  url = URI uri_str
  req = Net::HTTP::Get.new(url.path)
  response = Net::HTTP.start(url.host, url.port, use_ssl: true) { |http| http.request(req) }
  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch_uri(response['location'], limit - 1)
  else
    response.error!
  end
end