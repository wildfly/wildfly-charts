FROM ruby:3.2.2

ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
EXPOSE 4000
ENTRYPOINT ["/usr/src/app/entrypoint.sh"]
CMD ["bundle exec jekyll serve --host 0.0.0.0"]
