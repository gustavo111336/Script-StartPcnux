# 🚀 Pcnux Manager Ultimate v3.5-PRO

[![Termux](https://img.shields.io/badge/Platform-Termux-orange.svg)](https://termux.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/)

O **Pcnux Manager** é um script avançado de gerenciamento para ambientes desktop no Termux. Ele foi projetado para eliminar as frustrações comuns (como telas cinzas e arquivos de trava) e oferecer uma experiência "estilo PC" no Android com um único comando.

---

## 📸 Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/adi1090x/termux-desktop/previews/app_1.png" width="400" alt="Menu do Script">
  <img src="https://raw.githubusercontent.com/adi1090x/termux-desktop/previews/app_2.png" width="400" alt="Desktop Rodando">
</p>
<p align="center"><i>Interface limpa, menu interativo e suporte total ao XFCE4.</i></p>

---

## ✨ Diferenciais (Por que usar?)

* **🛡️ Auto-Repair:** Corrige automaticamente o erro da "Tela Cinza" reconstruindo o `xstartup`.
* **🧹 Lock Cleaner:** Remove arquivos de trava (`.X1-lock`) que impedem o servidor de iniciar após um fechamento forçado.
* **📱 Multi-User Support:** Inteligência para detectar caminhos de armazenamento em usuários secundários (`/storage/emulated/10/`, etc).
* **🎨 UI Elegante:** Cabeçalho em ASCII Art e logs coloridos para facilitar o monitoramento.
* **⚙️ Wizard de Resolução:** Configure a tela (1600x900, 1280x720) sem editar arquivos manualmente.

---

## 🛠️ Instalação Rápida

Copie e cole o comando abaixo no seu Termux:

```bash
pkg install git
git clone https://github.com/gustavo111336/Script-StartPcnux/
cd Script-StartPcnux
./startPcnux.sh
```
