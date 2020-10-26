FROM nimlang/nim as builder
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN nimble install -y
RUN nim c --passL:"-static -no-pie" -d:ssl -d:release src/nhxn.nim


FROM ubuntu
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /root/
COPY --from=builder /usr/src/app/ .
CMD ["./nhxn"]
