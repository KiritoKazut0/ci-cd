FROM node:20.19-alpine3.21
WORKDIR /ci-cd
COPY . .
RUN npm install 
EXPOSE 3000
CMD [ "npm", "start" ]