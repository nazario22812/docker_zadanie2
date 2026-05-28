## Sprawozdanie z Zadania 2

### Autor: Nazarii Kravchenko

---

### 1. Opis konfiguracji poszczególnych etapów zadania
Potok został w pełni zautomatyzowany przy użyciu GitHub Actions (`.github/workflows/deploy.yml`) i uruchamia się automatycznie po każdym zdarzeniu `push` na gałąź `main`. Składa się z następujących kroków:
* **Przygotowanie środowiska:** Pobranie kodu źródłowego (`actions/checkout`), konfiguracja emulatora QEMU (w celu emulacji architektury ARM64 na maszynie wirtualnej AMD64) oraz inicjalizacja rozszerzenia Docker Buildx.
* **Autentykacja:** Bezpieczne logowanie do zewnętrznych rejestrów za pomocą tokenów: do rejestru Docker Hub (poprzez sekrety repozytorium `DOCKERHUB_USERNAME` i `DOCKERHUB_TOKEN`) oraz do GitHub Container Registry (`ghcr.io`) przy użyciu systemowego `${{ secrets.GITHUB_TOKEN }}` z nadanymi uprawnieniami zapisu (`write`).
* **Test CVE (Bezpieczeństwo):** Budowa tymczasowego obrazu lokalnego i przeskanowanie go za pomocą narzędzia **Trivy**. Flaga `exit-code: '1'` oraz filtr `severity: 'HIGH,CRITICAL'` gwarantują pełne bezpieczeństwo – jeśli wykryte zostaną realne zagrożenia aplikacji, potok zostanie przerwany. Podatność typu HIGH wbudowana w wewnętrzny menedżer pakietów npm (`CVE-2026-33671`), na którą autor aplikacji nie ma bezpośredniego wpływu, została jawnie odfiltrowana za pomocą mechanizmu wyjątków w pliku `.trivyignore`.
* **Budowanie docelowe i publikacja:** Równoległe budowanie obrazu dla architektur `linux/amd64` oraz `linux/arm64`, przesłanie gotowego artefaktu na `ghcr.io` oraz eksport pełnych danych bufora (`mode=max`) do dedykowanego repozytorium na Docker Hub.

---

### 2. Sposób i uzasadnienie tagowania obrazów oraz danych cache

Dla obrazu produkcyjnego zastosowano strategię **podwójnego tagowania**:
1.  `ghcr.io/${{ github.repository }}:latest` – tag statyczny, wskazujący na najnowszą, zweryfikowaną wersję aplikacji.
2.  `ghcr.io/${{ github.repository }}:${{ github.sha }}` – tag dynamiczny, powiązany z unikalnym identyfikatorem SHA-1 konkretnego commitu w systemie Git.

#### Uzasadnienie wyboru:
Zgodnie z najlepszymi praktykami, stosowanie niezmiennych tagów opartych na SHA commitu gwarantuje pełną identyfikowalność oprogramowania. Pozwala to na jednoznaczne powiązanie kontenera z kodem źródłowym, eliminuje ryzyko przypadkowego nadpisania obrazu produkcyjnego oraz umożliwia błyskawiczne wykonanie procedury wycofania zmian w przypadku awarii.

Dla danych cache przyjęto stały tag `:latest` w dedykowanym repozytorium na Docker Hub, ponieważ pamięć podręczna BuildKita ma charakter przyrostowy i powinna odzwierciedlać stan zależności najświeższego, udanego zbudowania projektu.

---

### 3. Uzasadnienie wyboru skanera CVE
Do realizacji testów bezpieczeństwa wybrano narzędzie **Trivy** zamiast *Docker Scout*. 
* Trivy jest rozwiązaniem w pełni otwartoźródłowym , lekkim i niezależnym od komercyjnych pakietów czy subskrypcji Docker Desktop.
* Posiada oficjalną, świetnie wspieraną akcję w GitHub Marketplace , co pozwoliło na natywne sterowanie kodami wyjścia procesu (`exit-code`) wewnątrz potoku CI/CD, a także na precyzyjne ignorowanie wyjątków systemowych za pomocą pliku `.trivyignore`.
