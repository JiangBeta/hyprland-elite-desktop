#!/usr/bin/env python3
"""
TOTP导入工具 - 解析Google Authenticator导出数据
"""

import base64
import urllib.parse
import os

def parse_google_auth_migration(uri):
    """解析Google Authenticator migration URI"""
    # 解析URI并获取data
    parsed = urllib.parse.urlparse(uri)
    query = urllib.parse.parse_qs(parsed.query)
    data = query['data'][0]
    
    # URL安全的base64解码
    data = data.replace('-', '+').replace('_', '/')
    padding = 4 - len(data) % 4
    if padding != 4:
        data += '=' * padding
    
    decoded = base64.b64decode(data)
    
    # 手动解析protobuf数据（简化版）
    accounts = []
    i = 0
    
    while i < len(decoded):
        if decoded[i] == 0x0a:  # account字段开始
            i += 1
            length = decoded[i]
            i += 1
            
            # 解析账户数据
            account_data = decoded[i:i+length]
            account = {}
            
            j = 0
            while j < len(account_data):
                if account_data[j] == 0x0a:  # secret字段
                    j += 1
                    secret_len = account_data[j]
                    j += 1
                    secret_bytes = account_data[j:j+secret_len]
                    account['secret'] = base64.b32encode(secret_bytes).decode().rstrip('=')
                    j += secret_len
                elif account_data[j] == 0x12:  # name字段
                    j += 1
                    name_len = account_data[j]
                    j += 1
                    account['name'] = account_data[j:j+name_len].decode('utf-8', errors='ignore')
                    j += name_len
                elif account_data[j] == 0x1a:  # issuer字段
                    j += 1
                    issuer_len = account_data[j]
                    j += 1
                    account['issuer'] = account_data[j:j+issuer_len].decode('utf-8', errors='ignore')
                    j += issuer_len
                else:
                    j += 1
            
            if 'secret' in account:
                accounts.append(account)
            
            i += length
        else:
            i += 1
    
    return accounts

# 您的migration URI
# 从命令行参数获取migration_uri，移除硬编码的敏感数据
if len(sys.argv) > 1:
    migration_uri = sys.argv[1]
else:
    print("错误: 请提供 otpauth-migration URI 作为参数")
    print("用法: python3 import-totp.py 'otpauth-migration://...'")
    sys.exit(1)

try:
    # 解析账户
    accounts = parse_google_auth_migration(migration_uri)
    
    # 创建配置目录
    config_dir = os.path.expanduser("~/.config/totp")
    os.makedirs(config_dir, exist_ok=True)
    
    # 写入配置文件
    config_file = os.path.join(config_dir, "secrets.conf")
    with open(config_file, 'w', encoding='utf-8') as f:
        f.write("# TOTP密钥配置文件\n")
        f.write("# 从Google Authenticator导入\n")
        f.write("# 格式: 服务名称:密钥\n\n")
        
        for account in accounts:
            issuer = account.get('issuer', '')
            name = account.get('name', '')
            secret = account.get('secret', '')
            
            # 生成显示名称
            if issuer and name:
                if '@' in name:
                    display_name = issuer
                else:
                    display_name = f"{issuer}_{name}"
            elif issuer:
                display_name = issuer
            elif name:
                display_name = name.replace('@', '_at_').replace(':', '_')
            else:
                display_name = "Unknown"
            
            f.write(f"{display_name}:{secret}\n")
            print(f"✅ 导入: {display_name}")
    
    print(f"\n🎉 成功导入 {len(accounts)} 个TOTP账户到: {config_file}")
    print("现在可以在waybar中看到TOTP验证码了！")
    
except Exception as e:
    print(f"❌ 导入失败: {e}")