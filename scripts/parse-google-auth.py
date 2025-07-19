#!/usr/bin/env python3
"""
Google Authenticator导出数据解析工具
解析otpauth-migration://格式的URI并提取TOTP密钥
"""

import base64
import urllib.parse
import sys
import base32hex

def decode_migration_data(migration_uri):
    """解析Google Authenticator导出的migration URI"""
    
    # 解析URI
    parsed = urllib.parse.urlparse(migration_uri)
    if parsed.scheme != 'otpauth-migration':
        raise ValueError("不是有效的Google Authenticator导出URI")
    
    # 获取data参数
    query_params = urllib.parse.parse_qs(parsed.query)
    if 'data' not in query_params:
        raise ValueError("URI中缺少data参数")
    
    # Base64解码
    data = query_params['data'][0]
    # URL safe base64解码
    data = data.replace('-', '+').replace('_', '/')
    # 添加padding
    padding = 4 - len(data) % 4
    if padding != 4:
        data += '=' * padding
    
    try:
        decoded_data = base64.b64decode(data)
    except Exception as e:
        raise ValueError(f"Base64解码失败: {e}")
    
    return decoded_data

def parse_protobuf_simple(data):
    """简单的protobuf解析（针对Google Authenticator格式）"""
    accounts = []
    i = 0
    
    while i < len(data):
        # 查找account开始标记 (通常是0x0a)
        if i >= len(data):
            break
            
        if data[i] == 0x0a:  # 字段1，wire type 2 (length-delimited)
            i += 1
            if i >= len(data):
                break
                
            # 读取长度
            length = data[i]
            i += 1
            
            if i + length > len(data):
                break
                
            # 解析account数据
            account_data = data[i:i+length]
            account = parse_account_data(account_data)
            if account:
                accounts.append(account)
            
            i += length
        else:
            i += 1
    
    return accounts

def parse_account_data(data):
    """解析单个账户数据"""
    account = {}
    i = 0
    
    while i < len(data):
        if i >= len(data):
            break
            
        field_tag = data[i]
        wire_type = field_tag & 0x07
        field_number = field_tag >> 3
        i += 1
        
        if wire_type == 2:  # length-delimited
            if i >= len(data):
                break
            length = data[i]
            i += 1
            
            if i + length > len(data):
                break
                
            value = data[i:i+length]
            
            if field_number == 1:  # secret
                # 转换为base32
                try:
                    account['secret'] = base64.b32encode(value).decode().rstrip('=')
                except:
                    account['secret'] = value.hex()
            elif field_number == 2:  # name/account
                try:
                    account['name'] = value.decode('utf-8')
                except:
                    account['name'] = value.hex()
            elif field_number == 3:  # issuer
                try:
                    account['issuer'] = value.decode('utf-8')
                except:
                    account['issuer'] = value.hex()
            
            i += length
        elif wire_type == 0:  # varint
            # 跳过varint值
            while i < len(data) and data[i] & 0x80:
                i += 1
            if i < len(data):
                i += 1
        else:
            i += 1
    
    return account

def main():
    if len(sys.argv) != 2:
        print("用法: python3 parse-google-auth.py <migration_uri>")
        sys.exit(1)
    
    migration_uri = sys.argv[1]
    
    try:
        # 解码数据
        decoded_data = decode_migration_data(migration_uri)
        
        # 解析账户
        accounts = parse_protobuf_simple(decoded_data)
        
        if not accounts:
            print("未找到任何TOTP账户")
            return
        
        print(f"找到 {len(accounts)} 个TOTP账户:")
        print()
        
        # 生成配置文件格式
        config_lines = []
        for i, account in enumerate(accounts, 1):
            name = account.get('name', f'Account{i}')
            issuer = account.get('issuer', '')
            secret = account.get('secret', '')
            
            if issuer and name:
                display_name = f"{issuer}_{name}"
            elif issuer:
                display_name = issuer
            elif name:
                display_name = name
            else:
                display_name = f"Account{i}"
            
            # 清理显示名称
            display_name = display_name.replace(':', '_').replace('@', '_at_')
            
            print(f"{i}. {display_name}")
            print(f"   发行方: {issuer}")
            print(f"   账户: {name}")
            print(f"   密钥: {secret}")
            print()
            
            if secret:
                config_lines.append(f"{display_name}:{secret}")
        
        # 写入配置文件
        if config_lines:
            config_file = "/home/laofahai/.config/totp/secrets.conf"
            with open(config_file, 'w', encoding='utf-8') as f:
                f.write("# TOTP密钥配置文件\n")
                f.write("# 从Google Authenticator导入\n")
                f.write("# 格式: 服务名称:密钥\n\n")
                for line in config_lines:
                    f.write(line + "\n")
            
            print(f"✅ 配置已保存到: {config_file}")
            print(f"✅ 共导入 {len(config_lines)} 个账户")
            
    except Exception as e:
        print(f"❌ 解析失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()