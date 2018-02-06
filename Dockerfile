FROM clearlinux:latest

ENV GOPATH /home/gopath
ENV PATH="/home/gopath/bin:${PATH}"

RUN mkdir -p /home/gopath/src/github.com/clearlinux/mixer-tools
COPY . / /home/gopath/src/github.com/clearlinux/mixer-tools/
RUN swupd bundle-add mixer go-basic c-basic dev-utils os-core-update-dev
RUN clrtrust generate
RUN go get -u gopkg.in/alecthomas/gometalinter.v2
RUN gometalinter.v2 --install


CMD ["/bin/bash"]
