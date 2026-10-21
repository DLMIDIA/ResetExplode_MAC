# RESET EXPLODE — Edição macOS (Apple Silicon) 🍏⚡

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(M1--M5)-black?style=flat-square&logo=apple)](https://www.apple.com/mac/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift)](https://swift.org/)
[![Package](https://img.shields.io/badge/Release-v1.1.0%20DMG-cyan?style=flat-square&logo=apple)](https://github.com/DLMIDIA/ResetExplode_MAC/releases)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

> **RESET EXPLODE MAC** é uma suíte de software nativa, ultra-leve (< 1 MB) e de altíssimo desempenho para diagnóstico de hardware, telemetria em tempo real, benchmarks de CPU, memória e discos, monitor de status 24/7 na barra de menus, otimização de RAM/caches e ferramentas para eletrônica e makers no macOS.

---

## 📸 Interface do Aplicativo

![ResetExplode macOS Dashboard](Assets/screenshot-dashboard.png)

---

## 🚀 Como Instalar (Instalador DMG Pronto)

Você pode instalar o **ResetExplode** no seu Mac através da imagem oficial **DMG** para Apple Silicon:

1. Baixe o arquivo **`ResetExplode-AppleSilicon.dmg`** da seção de [Releases](https://github.com/DLMIDIA/ResetExplode_MAC/releases) ou compile diretamente com `./package_dmg.sh`.
2. Dê um duplo clique no arquivo `.dmg` para abri-lo.
3. Arraste o ícone do **ResetExplode** para a pasta **Applications** (Aplicativos).
4. Pronto! O aplicativo está pronto para uso e integrado ao seu macOS.

---

## 🌟 Principais Recursos e Módulos

### 1. ⏱️ Status Item Modular na Barra de Menus (Inspirado em Stats)
* **Customização Total de Módulos (Aba Barra de Menus):** Escolha exatamente o que deseja ver no topo do seu Mac:
  * Ícone `⚡` do aplicativo (ativar/desativar).
  * Porcentagem de uso da CPU (ex: `CPU 12%`).
  * Porcentagem de uso de Memória RAM (ex: `RAM 48%`).
  * Velocidade de tráfego de rede em tempo real (ex: `↓ 2.4M`).
  * Percentual de bateria e ícone de status de carregador.
* **Pré-visualização Ao Vivo:** Veja como o texto ficará na barra de menus antes de aplicar.
* **Controle de Brilho do Monitor no Popover:** Deslizador rápido de brilho direto pelo menu bar popover.
* **Painel Popover Flutuante:** Clique no ícone para abrir um painel rápido contendo:
  * Barra de carga da CPU e medidor de RAM ao vivo.
  * Indicador de **Pressão de Memória** (Normal / Atenção / Crítica) e Swap do macOS.
  * Velocímetro de download e upload em tempo real.
  * **Top 3 processos** mais pesados consumindo CPU (sem travar a interface).
  * Medidor de bateria, contagem de ciclos e status de tomada.
  * Botões de ação rápida: **Limpeza de RAM** e **Flush DNS**.
* **Permanência Contínua:** Fechar a janela principal não encerra o aplicativo; ele continua rodando silenciosamente na barra de menus com consumo desprezível de bateria e processamento.

### 2. 💻 RESET SISTEMA & Telemetria Apple Silicon
* **Ajuste de Brilho dos Monitores:**
  * Integração de baixo nível com o framework nativo `DisplayServices`.
  * Controle contínuo de brilho (0 a 100%) e botões de atalho rápido (25%, 50%, 75%, 100%).
* **Processador Apple Silicon & Carga por Núcleo:**
  * Identificação do modelo exato (Apple M1, M2, M3, M4, M5).
  * **Monitoramento Núcleo a Núcleo:** Chamadas de baixo nível ao Mach Kernel (`host_processor_info`) inspiradas na arquitetura do projeto [exelban/stats](https://github.com/exelban/stats), exibindo medidores individuais para núcleos de **Performance (P-Cores)** e **Eficiência (E-Cores)**.
* **Memória Unificada & Pressão:** Detalhamento ao vivo de memória ativa, presa (*wired*), comprimida, livre e uso de arquivo de Swap (`vm.swapusage`), além da classificação de pressão de memória (`memorystatus_vm_pressure_level`).
* **Monitor de Processos Pesados Não-Bloqueante:** Amostragem em segundo plano que garante 0 ms de atraso ou travamentos ao navegar pelas abas.
* **Diagnóstico Completo da Bateria:**
  * **Ciclos de Carga Reais:** Contagem exata de ciclos (ex: `81 / 1000 ciclos recomendados`).
  * **Saúde Real da Bateria:** Percentual de integridade de fábrica calculado com base na capacidade máxima atual vs. capacidade de projeto original.
  * **Status de Alimentação Inteligente:** Diferenciação entre bateria descarregando, carregando ou conectado à tomada em carga completa (100%).
  * **Tensão e Capacidade:** Leitura precisa em Volts e mAh via telemetria nativa IOKit.
* **Dispositivos Conectados:**
  * **Monitores e Telas:** Detecção de resolução nativa, taxa de atualização (Hz) e tipo de tela (Retina integrada vs. monitores externos como LG UltraWide).
  * **Periféricos USB & Áudio:** Mapeamento de microfones (HyperX, etc.), discos externos (Seagate, etc.), interfaces de rede e hubs.
  * **Dispositivos Bluetooth:** Detecção de fones (AirPods Pro, Beats), teclados (MX Keys) e periféricos pareados/conectados via JSON assíncrono sem riscos de travamento de permissões TCC.
* **Discos Rígidos e Partições:** Lista todos os discos montados (SSD principal APFS, discos externos e volumes de rede como *MAC SERVER*) com capacidade total, espaço livre e barra de uso.

### 3. ⚡ RESET BENCH (Benchmarks Determinísticos e Profundos)
* **CPU Path Tracer (Multi-Core & Single-Core Calibrados):**
  * Renderizador volumétrico determinístico baseado em Monte Carlo com sombreamento Phong e cálculo real de reflexão.
  * **Eliminação de Otimização Indesejada (DCE):** Alocação de buffer real de 32 bits de pixels em memória que força a CPU a processar cada raio matemático.
  * Teste Single-Core e Multi-Core com duração realista (~4 a 6 segundos) e pontuações calibradas de acordo com as referências Apple Silicon.
  * Visualizador de blocos em tempo real com contagem de threads e progresso.
  * **Escala Comparativa Global:** Posiciona a pontuação do seu processador lado a lado com referências de mercado (**Apple M4 Max, M4 Pro, M3 Max, M3, M2, M1, Intel Core i9-14900K, AMD Ryzen 7950X**).
* **Stream Memory Benchmark (Largura de Banda & Latência):**
  * Teste real de transferência de dados em blocos vetoriais, medindo a vazão real da memória unificada em **GB/s**.
  * Medição de **latência de acesso** em nanossegundos (*pointer chasing*).
  * Comparativo visual com memórias PC DDR4, DDR5 e barramentos Apple Silicon.
* **Benchmark de Armazenamento Completo:**
  * **Grid Responsivo em 2 Colunas:** Cartões espaçosos sem cortes laterais para qualquer tamanho de tela.
  * **Seleção de Qualquer Disco:** Teste qualquer volume interno ou externo montado.
  * **Leitura e Escrita Sequencial (MB/s):** Acesso físico direto ignorando o cache de memória do macOS (`F_NOCACHE`).
  * **Leitura e Escrita Aleatória 4K (IOPS):** Mede as operações por segundo em blocos pequenos de 4 KB para avaliar a agilidade real do SSD ao abrir aplicativos e inicializar sistemas.

### 4. 🌐 RESET REDE (Tráfego, Diagnóstico & Latência)
* **Teste de Velocidade de Internet Integrado (Speedtest Cloudflare CDN):**
  * Medição ao vivo de taxa de download (Mbps), vazão de transferência (MB/s) e latência de ping.
  * Medidor com barra de progresso em tempo real e tempo decorrido.
* **Velocímetro de Tráfego de Rede:** Medição contínua de download e upload com suporte a KB/s e MB/s.
* **Teste de Latência / Ping ao Vivo:** Mede o tempo de resposta em milissegundos (ms) para **Cloudflare DNS (1.1.1.1)** e **Google DNS (8.8.8.8)** com classificação qualitativa (Excelente para streaming/jogos, Bom ou Lento).
* **Parâmetros de Conexão:** Exibe IP local (IPv4), Gateway padrão (roteador), Servidores DNS ativos, MAC Address e nome da interface ativa.
* **Ferramenta de Flush DNS:** Limpa e renova o cache de nomes do sistema operacional (`dscacheutil` e `mDNSResponder`) com 1 clique.

### 5. 🚀 RESET OTIMIZA (RAM & Limpeza de Caches)
* **Liberação de Memória Inativa:** Esvazia os buffers inativos da memória unificada do Mac com 1 clique, sem fechar aplicativos abertos.
* **Limpador de Caches e Logs:** Escaneia e remove caches obsoletos de aplicativos (`~/Library/Caches`), arquivos de log antigos (`~/Library/Logs`) e esvazia o Lixo com segurança, recuperando múltiplos gigabytes de espaço.
* **Inicialização com o Mac:** Opção nativa via `SMAppService` para iniciar automaticamente com o macOS.
* **Lista de Processos Ativos:** Visualização dos aplicativos com janela ativa e seus respectivos PIDs.

### 6. 🔌 RESET MAKER (Arduino / ESP32 / Eletrônica)
* **Scanner de Portas Seriais:** Mapeia portas `/dev/cu.*` em tempo real.
* **Identificação Automática:** Reconhece placas **Arduino (Uno, Mega, Nano), Raspberry Pi Pico, ESP32, ESP8266** e conversores USB-UART com chips **CH340/CH341, CP2102/CP2104 e FTDI**.

---

## ⚖️ Créditos e Atribuição

* **Conceito Original & Benchmarks (Windows):** Desenvolvido originalmente por **[GustavoReset](https://github.com/GustavoReset)** no projeto [ResetExplode](https://github.com/GustavoReset/ResetExplode) sob licença MIT.
* **Referência de Telemetria macOS & Menu Bar:** Arquitetura de chamadas Mach Kernel e boas práticas inspiradas no projeto open-source **[Stats](https://github.com/exelban/stats)** por **Serhiy Mytrovtsiy** sob licença MIT.
* **Adaptação & Edição Nativa macOS:** Desenvolvido por **[DL MIDIA](https://github.com/DLMIDIA/ResetExplode_MAC)**.
* **Licença:** Distribuído sob os termos da licença **MIT** (veja [LICENSE](LICENSE) para mais detalhes).

---

## 🔨 Como Compilar e Gerar o DMG Localmente

### Requisitos:
* macOS 13.0 (Ventura) ou superior.
* Apple Silicon (M1, M2, M3, M4, M5 ou superior).
* Swift 6.0+ instalado (acompanha o Xcode ou Command Line Tools: `xcode-select --install`).

### Compilação e Empacotamento em 1 Passo:
```bash
# Clone o repositório
git clone https://github.com/DLMIDIA/ResetExplode_MAC.git
cd ResetExplode_MAC

# Gerar o instalador DMG completo
./package_dmg.sh
```
O script compilará a aplicação em modo Release otimizado, assinará o pacote, gerará `ResetExplode-AppleSilicon.dmg` pronto para instalação e testará a integridade do disco.
