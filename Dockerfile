FROM ruby:3.3

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    graphviz \
  && rm -rf /var/lib/apt/lists/*

RUN gem install foreman

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 3000

CMD ["bash", "bin/docker-dev-start"]
