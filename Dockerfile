FROM openresty/openresty:buster

RUN mkdir /home/rogon
RUN apt update
RUN apt install -y procps vim curl luarocks
RUN luarocks install busted

CMD ["openresty"]
