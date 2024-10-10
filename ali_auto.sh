#!/bin/sh
# auto_sign_aliyun
# author:kratos

#你自己的refresh_token

refresh_token="${REFRESH_TOKEN}"

function get_json_value()
{
  local json=$1
  local key=$2

  if [[ -z "$3" ]]; then
    local num=1
  else
    local num=$3
  fi

  local value=$(echo "${json}" | awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'${key}'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p)

  echo ${value}
}


token=$(curl -s  -X POST -H "Content-Type: application/json" -d '{"grant_type": "refresh_token", "refresh_token": "'"$refresh_token"'"}' https://auth.aliyundrive.com/v2/account/token)

#access_token=$(get_json_value $token "access_token")
access_token=$(echo $token | grep -ioP '(?<="access_token":").*?(?=")')
#echo "access_token 登录令牌：$access_token"

# show token
#echo $access_toekn
sign=$(curl -s -X POST -H "Content-Type: application/json" -H 'Authorization:Bearer '$access_token'' -d '{"grant_type": "refresh_token", "refresh_token": "'"$refresh_token"'"}' https://member.aliyundrive.com/v1/activity/sign_in_list)

#show sign result
#echo $sign

#不做验证
#result=$(get_json_value $sign "success")
#echo $result

# 使用 grep 和 sed 提取 blessing 值
success=$(echo $sign | grep -ioP '"success":.*?[,}]')
title=$(echo $sign | grep -ioP '"title":.*?[,}]')
subject=$(echo $sign | grep -ioP '"subject":.*?[,}]')

signInCount=$(echo $sign | grep -ioP '(?<="signInCount":).*?(?=[,"}])')
signInCover=$(echo "$sign" | grep -ioP '"signInCover":.*?[,}]')
# 输出 $title $subject $signInCover 值
echo "$title $subject $signInCover"

if [[ -z "$title" || "$success" != '"success":true,' ]]; then
  code=$(echo "$sign" | grep -o '"code": *"[^"]*"' | sed 's/"code": *"\([^"]*\)"/\1/')
  message=$(echo "$sign" | grep -o '"message": *"[^"]*"' )
  echo "错误！！！：code: $code, $message"
else
  echo "签到执行状态： $success 你已经签到： $signInCount "
fi

# 领取奖励（{"code":"Forbidden","message":"请升级最新客户端访问","requestId":"0a00700817285276256135451e3db4"}）
url="https://member.aliyundrive.com/v1/activity/sign_in_reward?_rx-s=mobile"

# 构造 JSON 数据
reward_body='{"signInDay": "'"$signInCount"'"}'
# 使用 curl 发送 POST 请求
#response=$(curl -s -X POST "$url"  -H "Content-Type: application/json"  -H "Authorization: $access_token" -d "$reward_body" )
#echo $response
# 使用原生工具解析 JSON
#reward=$(echo "$response" | grep -o '"notice":"[^"]*"' | sed 's/"notice":"\([^"]*\)"/\1/')