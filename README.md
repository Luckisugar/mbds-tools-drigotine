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

## Contribuindo

Essas ferramentas foram desenvolvidas de forma iterativa. Melhorias são bem-vindas!

## Licença

Sinta-se à vontade para usar e modificar.

Criado enquanto construía um setup custom de servidor Bedrock.
