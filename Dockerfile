FROM alpine:latest
# FROM fireflylzh/subconverter:latest
LABEL maintainer "firefly.lzh@gmail.com"
# ADD https://github.com/LM-Firefly/subconverter/commits/master.atom cache_bust
# ARG THREADS="2"

# build minimized
WORKDIR /
RUN apk add tzdata && ls /usr/share/zoneinfo && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone && date && apk del tzdata
RUN apk add --no-cache --virtual .build-tools git g++ build-base linux-headers cmake && \
    apk add --no-cache --virtual .build-deps curl-dev rapidjson-dev libevent-dev pcre2-dev yaml-cpp-dev && \
    git clone https://github.com/ftk/quickjspp --depth=1 && \
    cd quickjspp && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make quickjs -j $THREADS && \
    install -m644 quickjs/libquickjs.a /usr/lib && \
    install -d /usr/include/quickjs/ && \
    install -m644 quickjs/quickjs.h quickjs/quickjs-libc.h /usr/include/quickjs/ && \
    install -m644 quickjspp.hpp /usr/include && \
    cd .. && \
    git clone https://github.com/PerMalmberg/libcron --depth=1 && \
    cd libcron && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make libcron -j $THREADS && \
    install -m644 libcron/out/Release/liblibcron.a /usr/lib/ && \
    install -d /usr/include/libcron/ && \
    install -m644 libcron/include/libcron/* /usr/include/libcron/ && \
    install -d /usr/include/date/ && \
    install -m644 libcron/externals/date/include/date/* /usr/include/date/ && \
    cd .. && \
    git clone https://github.com/ToruNiina/toml11 --depth=1 && \
    cd toml11 && \
    git submodule update --init && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=20 . && \
    make install -j $THREADS && \
    cd .. && \
    git clone https://github.com/LM-Firefly/subconverter.git --depth=1 && \
    cd subconverter && \
    time=$(date +%y.%m%d.%H%M-) && sha=$(git rev-parse --short HEAD) && sed -i 's/\(v[0-9]\.[0-9]\.[0-9]\)/\1-'"$time$sha"'/' src/version.h && \
    cmake -DCMAKE_BUILD_TYPE=Release . && \
    make -j $THREADS && \
    mv subconverter /usr/bin && \
    mv base ../ && \
    cd .. && \
    rm -rf subconverter quickjspp libcron toml11 /usr/lib/lib*.a /usr/include/* /usr/local/include/lib*.a /usr/local/include/* && \
    apk add --no-cache --virtual subconverter-deps pcre2 libcurl yaml-cpp libevent && \
    apk del .build-tools .build-deps

COPY base/ /base/
# set entry
WORKDIR /base
EXPOSE 25500
CMD subconverter
