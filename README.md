# Ferramentas BDS - Instaladores de Mods para Servidor Dedicado Minecraft Bedrock

Ferramentas PowerShell fáceis de usar para instalar e gerenciar addons/mods em um **Servidor Dedicado Minecraft Bedrock (BDS)**.

Construídas do zero para facilitar a vida ao lidar com arquivos `.mcaddon` e `.mcpack`.

## Recursos

- **BDS-Installers-Launcher** - Menu simples para executar tudo
- **BDS-Mcaddon-Installer** - Lida com pacotes .mcaddon (BP + RP)
- **BDS-Mcpack-Installer** - Suporte flexível para arquivos .mcpack únicos ou separados (BP/RP)
- **BDS-Uninstaller** - Remove mods de um mundo de forma limpa (com opção de deletar pastas)

## Início Rápido

1. Coloque seus arquivos `.mcaddon` e/ou `.mcpack` na mesma pasta dos scripts (ou no local esperado).
2. Clique duplo em `BDS-ADDON INSTALLER.bat`
3. Siga o menu na tela.

Os scripts cuidam de:
- Descompactar
- Copiar para `behavior_packs` / `resource_packs`
- Registrar UUIDs nos JSONs do seu mundo `world_behavior_packs.json` e `world_resource_packs.json`

## Requisitos

- Windows
- PowerShell (Windows PowerShell 5.1 ou PowerShell 7+ recomendado)
- Um Servidor Dedicado Bedrock

## Vídeo de Demonstração

[Adicione o link do seu vídeo aqui após o upload]

## Estrutura de Pastas

```
BDS drigotine/
├── BDS-ADDON INSTALLER.bat
├── .gitignore
├── README.md
└── TOOLS/
    ├── BDS-Installers-Launcher.ps1
    ├── BDS-Mcaddon-Installer.ps1
    ├── BDS-Mcpack-Installer.ps1
    └── BDS-Uninstaller.ps1
```

## Como Usar (Avançado)

Você também pode executar os scripts diretamente:
```powershell
pwsh .\TOOLS\BDS-Installers-Launcher.ps1
```

## Preparando um Servidor Mínimo (De-bloat para Compartilhamento)

Para criar uma versão compacta do servidor BDS para compartilhar:

1. Na raiz do servidor (ex: bedrock-server-1.26.32.2), remova apenas o que não é vital:
   - UNPACKED MODS (bloat grande de mods descompactados)
   - development_behavior_packs, development_resource_packs, development_skin_packs
   - world_templates
   - bedrock_server_how_to.html
   - packet-statistics.txt
   - release-notes.txt

2. **Mantenha obrigatoriamente**:
   - bedrock_server.exe
   - server.properties
   - permissions.json
   - allowlist.json
   - packetlimitconfig.json
   - profanity_filter.wlist
   - config/
   - data/
   - definitions/
   - behavior_packs/ (com customs e vanilla)
   - resource_packs/ (com customs e vanilla)
   - worlds/
   - TOOLS/ (nossas ferramentas)
   - BDS-ADDON INSTALLER.bat

3. Isso reduz drasticamente o tamanho para zipar/compactar.

4. Usuários só precisam: extrair, rodar o .exe ou o .bat, instalar mods via o instalador.

**Atenção**: Nunca delete os packs, worlds ou o exe. O servidor precisa deles para rodar.

## Contribuindo

Essas ferramentas foram desenvolvidas de forma iterativa. Melhorias são bem-vindas! (Suporte a PT-BR e EN via seletor no launcher).

## Licença

Sinta-se à vontade para usar e modificar.

Criado enquanto construía um setup custom de servidor Bedrock. Inclui de-bloat seguro e suporte a addons aninhados.
