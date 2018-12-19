FROM node:8-stretch

WORKDIR /app

COPY package.json ./

RUN npm install

COPY . .

RUN npm uninstall grunt-contrib-imagemin && npm install grunt-contrib-imagemin

RUN npm run dist

EXPOSE 9001

CMD ["npm", "start"]