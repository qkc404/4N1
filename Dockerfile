FROM openresty/openresty:alpine
RUN apk add --no-cache ca-certificates wget unzip netcat-openbsd

# Download latest stable Xray Core binary
RUN wget -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
    unzip -j /tmp/xray.zip xray -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/xray && rm -rf /tmp/xray.zip

# Inject Ultra-Aggressive Adblocking & Tracking Geo-databases
RUN wget -qO /usr/local/bin/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat && \
    wget -qO /usr/local/bin/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat

COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY index.html /usr/local/openresty/nginx/html/index.html
EXPOSE 8080

# Starts xray immediately in background, then hands over foreground thread control to OpenResty
CMD /usr/local/bin/xray run -c /etc/xray.json & exec /usr/local/openresty/bin/openresty -g "daemon off;"
