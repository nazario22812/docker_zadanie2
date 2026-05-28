# ETAP 1: Budowanie (Builder) - Wieloetapowe budowanie obrazu
# Wykorzystujemy lekką wersję Alpine z Node.js, aby zminimalizować rozmiar bazowy.
# Używamy aliasu 'builder', aby móc skopiować z niego pliki w kolejnym etapie.
FROM node:22-alpine AS builder

# Ustawiamy katalog roboczy dla pierwszego etapu budowania.
WORKDIR /pogoda



RUN apk update && apk upgrade --no-cache

# Optymalizacja funkcjonowania cache-a:
# Kopiujemy najpierw TYLKO pliki package.json oraz package-lock.json.
# Dzięki temu kosztowna czasowo warstwa z 'npm install' przebuduje się tylko wtedy, 
# gdy zmienią się zależności, a nie przy każdej najmniejszej zmianie w kodzie .js czy .hbs.
COPY package*.json ./

# Instalujemy tylko pakiety niezbędne do działania na produkcji (--omit=dev),
# co pozwala znacząco zaoszczędzić miejsce i odciążyć finalny obraz.
RUN npm install --omit=dev

# Kopiujemy resztę kodu źródłowego naszej aplikacji.
COPY . .

# ETAP 2: Obraz docelowy (Runner) - Optymalizacja rozmiaru i warstw
# Ponownie używamy czystego i lekkiego obrazu Alpine dla finalnego kontenera.
FROM node:22-alpine

# Wymóg z zadania: Dodanie informacji na temat autora zgodej ze standardem OCI.
LABEL org.opencontainers.image.authors="Nazarii Kravchenko"

# Ustawiamy docelowy katalog roboczy dla działającej aplikacji.
WORKDIR /pogoda


RUN apk update && apk upgrade --no-cache

# Optymalizacja pod kątem zawartości i ilości warstw:
# Zamiast kopiować całą zawartość z poprzedniego etapu, przenosimy (cherry-picking)
# wyłącznie te pliki i katalogi, które są krytyczne do uruchomienia aplikacji.
# Dzięki temu finalny obraz pozbawiony jest śmieci i plików systemowych z etapu budowy.
COPY --from=builder /pogoda/node_modules ./node_modules
COPY --from=builder /pogoda/index.js ./
COPY --from=builder /pogoda/controllers ./controllers
COPY --from=builder /pogoda/views ./views

# Praktyka bezpieczeństwa: uruchamiamy aplikację jako użytkownik o ograniczonych
# prawach ('node'), a nie jako domyślny administrator ('root').
USER node

# Informacyjnie deklarujemy port TCP, na którym nasłuchuje nasza aplikacja.
EXPOSE 3000

# Wymóg z zadania: Definicja mechanizmu Healthcheck.
# Docker co 30 sekund użyje lekkiego narzędzia 'wget', aby sprawdzić, czy aplikacja
# prawidłowo odpowiada na zapytania HTTP. Jeśli nie, kontener zostanie oznaczony jako 'unhealthy'.
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Domyślna komenda uruchamiająca główny skrypt serwera po starcie kontenera.
CMD ["node", "index.js"]