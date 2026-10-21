# RESET EXPLODE — Edição macOS (Apple Silicon) 🍏⚡

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(M1--M5)-black?style=flat-square&logo=apple)](https://www.apple.com/mac/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)](https://swift.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

> **RESET EXPLODE MAC** é uma suíte nativa, ultra-leve (< 1 MB) e de alto desempenho para diagnóstico de hardware, monitoramento em tempo real, benchmarks de CPU e discos, otimização de memória/caches e ferramentas para makers e eletrônica no macOS.

---

## 📸 Interface do Aplicativo

![ResetExplode macOS Dashboard](Assets/screenshot-dashboard.png)

---

## 🌟 Principais Recursos e Módulos

### 1. 💻 RESET SISTEMA (Telemetria em Tempo Real)
* **Processador Apple Silicon:** Identificação exata do SoC (Apple M1, M2, M3, M4, M5), separando com precisão os núcleos de **Performance (P-Cores)** e de **Eficiência (E-Cores)**.
* **Memória Unificada:** Detalhamento ao vivo de memória ativa, presa (*wired*), comprimida e livre, com medidor circular de pressão de memória.
* **GPU Metal:** Detecção de recursos da GPU Apple, suporte nativo a **Metal 3** e acelerador de **Ray Tracing por Hardware**.
* **Armazenamento Principal (APFS):** Monitoramento contínuo de espaço ocupado e disponível no SSD interno.
* **Bateria & Energia:** Porcentagem atual, fonte de energia (tomada vs. bateria) e estado de carregamento.

### 2. ⚡ RESET BENCH (Benchmarks Determinísticos)
* **CPU Path Tracer (Multi-Core & Single-Core):**
  * Renderizador volumétrico de iluminação global e traçado de raios (estilo *Cinebench* / *ResetExplode original*).
  * Executa divisão por blocos (*buckets* de 32×32) do centro para fora, eliminando concorrência de travas.
  * Fórmula de pontuação oficial preservada: `Pontos = (Amostras / Segundos) / 10.000`.
* **Benchmark de Armazenamento Multi-Discos:**
  * **Suporte a Múltiplos Discos:** Lista e permite selecionar qualquer volume montado (SSD interno, SSDs externos USB/Thunderbolt, pendrives e servidores locais como *MAC SERVER*).
  * **Acesso Direto Sem Cache (`F_NOCACHE`):** Mede a velocidade física real do drive em MB/s para leitura e escrita sequenciais, ignorando o buffer de memória do macOS.

### 3. 🌐 RESET REDE (Tráfego e Diagnóstico)
* **Monitor de Tráfego em Tempo Real:** Velocidade instantânea de **Download** e **Upload** (em KB/s e MB/s).
* **Identificação de Interface:** Detecção de interface ativa (Wi-Fi, Ethernet) e endereço IP local na rede.

### 4. 🚀 RESET OTIMIZA (RAM & Limpeza de Caches)
* **Liberação de Memória Inativa:** Esvazia os buffers inativos da memória unificada do Mac com 1 clique, sem fechar aplicativos abertos.
* **Limpador de Caches e Logs:** Escaneia e remove caches obsoletos de aplicativos (`~/Library/Caches`), arquivos de log antigos (`~/Library/Logs`) e esvazia o Lixo com segurança, recuperando múltiplos gigabytes de espaço.
* **Inicialização com o Mac:** Opção nativa via `SMAppService` para iniciar automaticamente com o macOS.
* **Lista de Processos Ativos:** Visualização dos aplicativos com janela ativa e seus respectivos PIDs.

### 5. 🔌 RESET MAKER (Arduino / ESP32 / Eletrônica)
* **Scanner de Portas Seriais:** Mapeia portas `/dev/cu.*` em tempo real.
* **Identificação Automática:** Reconhece placas **Arduino (Uno, Mega, Nano), Raspberry Pi Pico, ESP32, ESP8266** e conversores USB-UART com chips **CH340/CH341, CP2102/CP2104 e FTDI**.

### 6. ⏱️ STATUS ITEM NA BARRA DE MENUS (Menu Bar Extra)
* Ícone permanente e ultra-leve na barra superior do Mac, permitindo monitorar CPU, RAM e Rede 24/7 sem consumir recursos (substituindo ferramentas pesadas de terceiros).
* Atalho rápido para **Limpeza de RAM** e abertura do painel principal.

---

## ⚖️ Créditos e Atribuição

* **Conceito Original & Benchmarks (Windows):** Desenvolvido originalmente por **[GustavoReset](https://github.com/GustavoReset)** no projeto [ResetExplode](https://github.com/GustavoReset/ResetExplode) sob licença MIT.
* **Adaptação & Edição Nativa macOS:** Desenvolvido por **[DL MIDIA](https://github.com/DLMIDIA/ResetExplode_MAC)**.
* **Licença:** Distribuído sob os termos da licença **MIT** (veja [LICENSE](LICENSE) para mais detalhes).

---

## 🔨 Como Compilar e Rodar no Mac

### Requisitos:
* macOS 13.0 (Ventura) ou superior.
* Apple Silicon (M1, M2, M3, M4, M5 ou superior).
* Swift 6.0+ instalado (acompanha o Xcode ou Command Line Tools: `xcode-select --install`).

### Compilação em 1 Clique:
```bash
# Clone o repositório
git clone https://github.com/DLMIDIA/ResetExplode_MAC.git
cd ResetExplode_MAC

# Execute o script de compilação e empacotamento
./build_app.sh

# Abra o aplicativo
open ResetExplode.app
```
O script compilará os binários em modo Release e gerará o pacote autônomo `ResetExplode.app`.
