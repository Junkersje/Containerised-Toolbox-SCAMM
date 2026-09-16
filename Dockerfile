# 1. Base image med minimal Linux-distribution
FROM alpine:3.20

# 2. Installer nødvendige dependencies (curl til netværk, gawk til decimaltal)
RUN apk add --no-cache curl gawk

# 3. Kopiér scriptet ind i containerens system-PATH
COPY checker.sh /usr/local/bin/checker.sh

# 4. Gør scriptet eksekverbart
RUN chmod +x /usr/local/bin/checker.sh

# 5. Eksekveringskommando ved container-start
CMD ["/usr/local/bin/checker.sh"]