# Ferramenta DMBDS - Drigotine Minecraft BeDrock Server

Ferramenta de PowerShell fácil de usar para instalar e gerenciar addons/mods em um **Minecraft Bedrock Server (BDS)**.

Construídas do zero para facilitar a vida ao lidar com arquivos `.mcaddon` e `.mcpack`.

## DOWNLOAD

- **Vá para seção Releases** - Se tu tiver pelo pc, na direita ali tem um "Server + Tool V####", é ali, baixa o server ou as tools lá.

## Recursos

- **BDS-Installers-Launcher** - Menu simples para executar os outros negocio ai.
- **BDS-Mcaddon-Installer** - Lida com pacotes .mcaddon (BP + RP)
- **BDS-Mcpack-Installer** - Suporte flexível para arquivos .mcpack únicos ou separados (BP/RP)
- **BDS-Uninstaller** - Remove mods de um mundo de forma rapida

## Início Rápido

1. Coloque seus arquivos `.mcaddon` e/ou `.mcpack` na pasta server/"UNPACKED MODS", se ela não existir crie ela, essa pasta é criada automaticamente rodando o script de .mcaddon.
2. Clique duplo em `BDS-ADDON INSTALLER.bat`
3. Siga o menu na tela.

Os scripts cuidam de:
- Descompactar
- Copiar para `behavior_packs` / `resource_packs`
- Registrar UUIDs nos JSONs do seu mundo `world_behavior_packs.json` e `world_resource_packs.json`
- Desinstalar mods

## Requisitos

- Windows 11
- PowerShell (Windows PowerShell 5.1 ou PowerShell 7+ recomendado)
- inteligência

## Vídeo de Demonstração

https://youtu.be/0bPNz-NDYRg?si=llTP2ZDBA0yB53Zi

Usuários só precisam: baixar o drigotine server, rodar o bedrock-server.exe.
se quiser, instala mods via o instalador BDS-ADDON-INSTALLER.bat.

**Atenção**: Nunca delete os tools, worlds ou o .bat. vai quebrar tudo zé.

## Contribuindo

Essas ferramentas foram desenvolvidas de forma iterativa. Melhorias são bem-vindas! (Suporte a PT-BR e EN via seletor no launcher).

## Licença

Sinta-se à vontade para usar e modificar.

Criado enquanto construía um setup custom de servidor Bedrock. Inclui de-bloat seguro e suporte a addons aninhados.
