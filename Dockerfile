# syntax=docker/dockerfile:1
FROM ruby:3.4-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libssl-dev && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 8080
CMD ["bundle", "exec", "falcon", "serve", "--bind", "http://0.0.0.0:8080"]
