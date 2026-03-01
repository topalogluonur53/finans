FROM python:3.11-slim

WORKDIR /app

# Upgrade pip and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -U pip setuptools \
    && pip install --no-cache-dir -r requirements.txt

# Copy the app files
COPY . .

# Ensure entrypoint has execution rights
RUN chmod +x entrypoint.sh

EXPOSE 2223

CMD ["./entrypoint.sh"]
