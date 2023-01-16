#!/bin/bash
cd /c/projects/mabilogin/main

# 顯示登入清單
ruby acc_list.rb

# 選擇要登入哪一組
read -p "請選擇欲登入帳號(輸入數字): " index

# 開啟登入瑪奇程式
ruby main.rb $index
read enter to close
