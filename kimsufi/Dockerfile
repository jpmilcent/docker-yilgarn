FROM python:3.7.4-slim-buster

LABEL authon="Jean-Pascal MILCENT" \
  version="1" \
  maintainer="jpm@clapas.org"

RUN apt-get update && apt-get -y install \
  git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN git clone https://git.pofilo.fr/pofilo/kimsufi.git

WORKDIR /app/kimsufi
RUN pip install -r requirements.txt
COPY ./kimsufi.conf /app/kimsufi/config/kimsufi.conf

WORKDIR /app/kimsufi/src
CMD ["python", "kimsufi.py"]
