#!/bin/bash
BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; MAGENTA='\033[1;35m'; WHITE='\033[1;37m'

loading() {
    local t="$1"
    local s="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0;i<5;i++)); do 
        for ((j=0;j<${#s};j++)); do 
            echo -ne "\r  ${CYAN}${s:$j:1} ${t}...${RESET}"
            sleep 0.05
        done
    done
    echo -ne "\r  ${GREEN}DONE: ${t}${RESET}\n"
}

clear
echo ""
echo -e "  ${BOLD}${WHITE}4N1 FAST DEPLOYER (QWIKLABS OPTIMIZED)${RESET}"
echo -e "  ${MAGENTA}MADE BY SAEKA TOJIRP${RESET}"
echo -e "  ${GREEN}fb.com/saekacutiee${RESET}"
echo ""

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "  ${RED}ERROR: No active GCP project detected. Please run 'gcloud init'.${RESET}"
    exit 1
fi
echo -e "  ${CYAN}PROJECT: ${GREEN}${PROJECT_ID}${RESET}"

# ==============================================================================
# QWIKLABS REAL-TIME REGION DETECTION
# ==============================================================================
echo -ne "  ${CYAN}DETECTING QWIKLABS REGION... ${RESET}"
# 1. Try compute/region (Standard in Qwiklabs)
REGION=$(gcloud config get-value compute/region 2>/dev/null | tr -d '[:space:]')

# 2. Try run/region if compute isn't set
if [ -z "$REGION" ]; then
    REGION=$(gcloud config get-value run/region 2>/dev/null | tr -d '[:space:]')
fi

# 3. Fallback: Ask Google Cloud for the first available Run region
if [ -z "$REGION" ]; then
    REGION=$(gcloud run regions list --format="value(REGION)" --limit=1 2>/dev/null | tr -d '[:space:]')
fi

# 4. Ultimate fallback (Highly unlikely to trigger)
if [ -z "$REGION" ]; then
    REGION="us-central1"
fi
echo -e "${GREEN}${REGION}${RESET}"
echo ""
# ==============================================================================

echo "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" > ~/.gh_token

read -r -p "$(echo -e "  ${CYAN}SERVICE NAME [prvtspyyy]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-prvtspyyy}

echo ""
echo -e "  ${CYAN}SELECT MODE:${RESET}"
echo -e "  ${YELLOW}1) BROWSING     (1 vCPU / 2Gi  RAM)${RESET}"
echo -e "  ${YELLOW}2) STREAMING    (2 vCPU / 4Gi  RAM)${RESET}"
echo -e "  ${YELLOW}3) GAMING       (4 vCPU / 8Gi  RAM)${RESET}"
echo -e "  ${YELLOW}4) ULTRA        (8 vCPU / 16Gi RAM)${RESET}"
echo -e "  ${YELLOW}5) CUSTOM${RESET}"
echo ""
read -r -p "$(echo -e "  ${CYAN}CHOICE: ${RESET}")" MODE_CHOICE

case "$MODE_CHOICE" in
    1) CPU="1"; RAM="2Gi"; MODE="BROWSING"; MAX_INSTANCES="4";;
    2) CPU="2"; RAM="4Gi"; MODE="STREAMING"; MAX_INSTANCES="4";;
    3) CPU="4"; RAM="8Gi"; MODE="GAMING"; MAX_INSTANCES="4";;
    5)
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CPU (1/2/4/8): ${RESET}")" CPU
        read -r -p "$(echo -e "  ${CYAN}RAM (2Gi/4Gi/8Gi/16Gi/32Gi): ${RESET}")" RAM
        echo ""
        echo -e "  ${CYAN}SELECT INSTANCES:${RESET}"
        echo -e "  ${YELLOW}1) 1 INSTANCE${RESET}"
        echo -e "  ${YELLOW}2) 2 INSTANCES${RESET}"
        echo -e "  ${YELLOW}3) 4 INSTANCES${RESET}"
        echo -e "  ${YELLOW}4) 8 INSTANCES${RESET}"
        echo ""
        read -r -p "$(echo -e "  ${CYAN}CHOICE: ${RESET}")" INST_CHOICE
        case "$INST_CHOICE" in
            2) MAX_INSTANCES="2";;
            3) MAX_INSTANCES="4";;
            4) MAX_INSTANCES="8";;
            *) MAX_INSTANCES="1";;
        esac
        MODE="CUSTOM"
        ;;
    *) CPU="8"; RAM="16Gi"; MODE="ULTRA"; MAX_INSTANCES="4";;
esac

echo ""
loading "BUILDING CONTAINER IMAGE"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" --project="$PROJECT_ID" --quiet > build.log 2>&1

if [ $? -ne 0 ]; then 
    echo -e "  ${RED}BUILD FAILED. CHECK LOGS BELOW:${RESET}"
    tail -n 10 build.log
    exit 1
fi

loading "DEPLOYING TO CLOUD RUN IN ${REGION}"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed --region "$REGION" \
  --cpu "$CPU" --memory "$RAM" --port 8080 \
  --concurrency 1000 --cpu-boost --no-cpu-throttling \
  --timeout 3600 --min-instances 1 --max-instances "$MAX_INSTANCES" \
  --allow-unauthenticated --project="$PROJECT_ID" --quiet > deploy.log 2>&1

if [ $? -ne 0 ]; then 
    echo -e "  ${RED}DEPLOYMENT FAILED. CHECK LOGS BELOW:${RESET}"
    tail -n 10 deploy.log
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

# Prepare Base64 Outputs
SS_B64=$(echo -n "aes-256-gcm:saeka" | base64 | tr -d '\n')
VMESS_WS_JSON='{"v":"2","ps":"VMESS-WS","add":"'"${CLEAN_HOST}"'","port":"443","id":"saekaaa","aid":"0","net":"ws","path":"/vmess-saeka","host":"'"${CLEAN_HOST}"'","tls":"tls","sni":"'"${CLEAN_HOST}"'","fp":"chrome","alpn":"h2"}'
VMESS_WS_B64=$(echo -n "$VMESS_WS_JSON" | base64 | tr -d '\n')

echo ""
echo -e "  ${GREEN} (⁠ ⁠ꈍ⁠ᴗ⁠ꈍ⁠) DEPLOYED SUCCESSFULLY${RESET}"
echo ""
echo -e "  ${CYAN}RAW HOST   ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}DASHBOARD  ${GREEN}${SERVICE_URL}${RESET}"
echo -e "  ${CYAN}PORT       ${GREEN}443${RESET}"
echo -e "  ${CYAN}PASS       ${GREEN}saeka${RESET}"
echo -e "  ${CYAN}MODE       ${GREEN}${MODE}${RESET}"
echo -e "  ${CYAN}CPU        ${GREEN}${CPU}${RESET}"
echo -e "  ${CYAN}RAM        ${GREEN}${RAM}${RESET}"
echo ""

echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}                    PATHS & PROTOCOLS${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${CYAN}  PROTOCOL     | WS PATH            | HTTPUPGRADE PATH${RESET}"
echo -e "  ${YELLOW}  ──────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}  VLESS${RESET}        | ${CYAN}/vless-saeka${RESET}       | ${CYAN}/vless-saeka-hu${RESET}"
echo -e "  ${GREEN}  VMess${RESET}        | ${CYAN}/vmess-saeka${RESET}       | ${CYAN}/vmess-saeka-hu${RESET}"
echo -e "  ${GREEN}  TROJAN${RESET}       | ${CYAN}/saeka-tojirp${RESET}     | ${CYAN}/saeka-tojirp-hu${RESET}"
echo -e "  ${GREEN}  Shadowsocks${RESET}  | ${CYAN}/ss-saeka${RESET}         | ${CYAN}/ss-saeka-hu${RESET}"
echo ""
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}  HOST: ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "  ${CYAN}  PORT: ${GREEN}443${RESET}"
echo -e "  ${CYAN}  SNI:  ${GREEN}fcmtoken.googleapis.com${RESET}"
echo -e "  ${CYAN}  ALPN: ${GREEN}h2${RESET}"
echo -e "  ${CYAN}  FP:   ${GREEN}chrome${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}                    CONNECTION CONFIG URI'S${RESET}"
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${GREEN}VLESS - WebSocket:${RESET}"
echo -e "  ${CYAN}vless://saekaaa@${CLEAN_HOST}:443?encryption=none&type=ws&path=%2Fvless-saeka&host=${CLEAN_HOST}&alpn=h2&fp=chrome#VLESS-WS${RESET}"
echo ""
echo -e "  ${GREEN}VLESS - HTTPUpgrade:${RESET}"
echo -e "  ${CYAN}vless://saekaaa@${CLEAN_HOST}:443?encryption=none&type=httpupgrade&path=%2Fvless-saeka-hu%3Fed%3D1280&host=${CLEAN_HOST}&alpn=h2&fp=chrome#VLESS-HU${RESET}"
echo ""
echo -e "  ${GREEN}VMess - WebSocket:${RESET}"
echo -e "  ${CYAN}vmess://${VMESS_WS_B64}${RESET}"
echo ""
echo -e "  ${GREEN}TROJAN - WebSocket:${RESET}"
echo -e "  ${CYAN}trojan://saeka@${CLEAN_HOST}:443?security=tls&sni=fcmtoken.googleapis.com&type=ws&path=%2Fsaeka-tojirp&host=${CLEAN_HOST}&alpn=h2&fp=chrome#Trojan-WS${RESET}"
echo ""
echo -e "  ${GREEN}TROJAN - HTTPUpgrade:${RESET}"
echo -e "  ${CYAN}trojan://saeka@${CLEAN_HOST}:443?security=tls&sni=fcmtoken.googleapis.com&type=httpupgrade&path=%2Fsaeka-tojirp-hu%3Fed%3D1280&host=${CLEAN_HOST}&alpn=h2&fp=chrome#Trojan-HU${RESET}"
echo ""
echo -e "  ${GREEN}Shadowsocks - WebSocket:${RESET}"
echo -e "  ${CYAN}ss://${SS_B64}@${CLEAN_HOST}:443?plugin=obfs-local%3Bobfs%3Dwebsocket%3Bobfs-host%3D${CLEAN_HOST}%3Bobfs-uri%3D%2Fss-saeka%3Bsni%3D${CLEAN_HOST}%3Btls#SS-WS${RESET}"
echo ""
echo -e "  ${GREEN}Shadowsocks - HTTPUpgrade:${RESET}"
echo -e "  ${CYAN}ss://${SS_B64}@${CLEAN_HOST}:443?plugin=obfs-local%3Bobfs%3Dwebsocket%3Bobfs-host%3D${CLEAN_HOST}%3Bobfs-uri%3D%2Fss-saeka-hu%3Bsni%3D${CLEAN_HOST}%3Btls#SS-HU${RESET}"
echo ""

# ==============================================================================
# GITHUB PAGES AUTOMATIC SYNC (ZERO-TOUCH)
# ==============================================================================
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "  ${CYAN}INITIATING...${RESET}"

# Read the token automatically from the hidden file
if [ -f "$HOME/.gh_token" ]; then
    GH_TOKEN=$(cat "$HOME/.gh_token")
    GH_USER="qkc404"
    GH_REPO="saeka-gcp-panel"
    
    loading "SETTING UP GCP PIPELINE..."
    rm -rf gh_temp_deploy
    git clone -q "https://${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git" gh_temp_deploy > /dev/null 2>&1
    
    if [ -d "gh_temp_deploy" ]; then
        cd gh_temp_deploy
        echo "$CLEAN_HOST" > host.txt
        
        git config user.name "Saeka Deployer"
        git config user.email "deploy@saekacutiee.local"
        git add host.txt
        git commit -m "🚀 Auto-Deploy: Update GCP Proxy Host to ${CLEAN_HOST}" > /dev/null 2>&1
        
        git push -q origin main > /dev/null 2>&1 || git push -q origin master > /dev/null 2>&1
        
        cd ..
        rm -rf gh_temp_deploy
        echo -e "  ${GREEN} DONE ${RESET}"
        echo -e "  ${CYAN} PANEL URL  ${GREEN}https://${GH_USER}.github.io/${GH_REPO}/${RESET}"
    else
        echo -e "  ${RED}FAILED.${RESET}"
    fi
else
    echo -e "  ${RED}.ERROR ${RESET}"
fi
echo -e "  ${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
fi

rm -f build.log deploy.log
