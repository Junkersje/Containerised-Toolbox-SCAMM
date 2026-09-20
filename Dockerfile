# 1. Base image with minimal Linux distribution
FROM alpine:3.20

# 2. Install necessary dependencies (curl for networking, gawk for decimal numbers)
RUN apk add --no-cache curl gawk

# 3. Copy the script into the container's system PATH
COPY checker.sh /usr/local/bin/checker.sh

#4. Make the script executable
RUN chmod +x /usr/local/bin/checker.sh

# 5. Execution command on container start
CMD ["/usr/local/bin/checker.sh"]