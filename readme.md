# 瑪奇 - Beanfun 登入器
## 簡介
1. 這不是官方發行的登入器, 我無法為您承擔任何使用後造成的任何結果
2. 簡化瑪奇登入流程, 避免OTP過期導致登入失敗
3. 支援複數帳號選擇登入, 記錄到CSV檔後, 你就可以不用一直問兄弟姊妹帳號密碼了XD
4. 如果有甚麼想要的需求可以許願, 但不一定會成真XD (畢竟對我目前已經夠用了)
## 需求 / 系統需求
- Ruby: [ruby 3.1.2p20](https://www.ruby-lang.org/en/news/2022/04/12/ruby-3-1-2-released/)
- RubyGems: ['mechanize'](https://rubygems.org/search?query=mechanize) 和 ['openssl'](https://rubygems.org/gems/openssl)
- 能玩瑪奇的系統需求
- 最後, 可能還要會一點Ruby的你.. XD
## 如何使用
1. 安裝對應版本的Ruby, 下載本專案
2. 安裝RubyGems
```ruby
gem install mechanize
gem install openssl
```
3. 打開user_info/template.csv 依照格式輸入你的帳號密碼與名稱
4. 修改mabi_utils.rb 內```open_mabi(login)``` 的瑪奇路徑
```ruby
def open_mabi(login)
  args = [
    # 修改成你的瑪奇路徑
    'C:\Nexon\Mabinogi\Client.exe',
    # ...
  ].join(' ')
    
  # 修改成你的瑪奇路徑
  Dir.chdir('../../../Nexon/Mabinogi')
  # ...
end
```
5. 打開 main.sh 選擇你要登入帳號的序號, 就可以到角色選單了
## 特別感謝
[@LiYu87](https://github.com/mickey9910326) 的耐心教導和鼓勵, 不直接跟我說答案, 引導我慢慢找出答案的教學方式, 真的超級感謝的啦QQ 
## 參考資料
- https://github.com/mickey9910326/mabilogin
- https://github.com/BeanfunLogin/BeanfunLogin