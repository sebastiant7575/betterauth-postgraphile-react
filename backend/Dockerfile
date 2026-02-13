FROM node:20-slim

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY . .

RUN chmod +x scripts/start.sh

EXPOSE 4000

CMD ["./scripts/start.sh"]
