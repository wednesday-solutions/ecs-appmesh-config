FROM node:16-alpine
RUN mkdir -p /app
ADD . /app
WORKDIR /app
RUN yarn --frozen-lockfile
CMD ["yarn", "run", "start:production"]
EXPOSE 3000