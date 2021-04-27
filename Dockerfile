FROM node:lts-alpine

# Set application folder to app
WORKDIR /app

# Copy all files to app folder
COPY . /app

RUN npm install

EXPOSE 80
ENV PORT=80

CMD ["npm", "run", "production"]
